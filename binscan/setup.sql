-- BinScan 백엔드 설정 (Supabase SQL Editor에 통째로 붙여넣고 Run)
-- 구조: 폰은 anon 키로 "쓰기만" 가능. 읽기는 관리자 토큰을 아는 대시보드만 RPC로 가능.

-- 1) 이벤트 테이블 ----------------------------------------------------------
create table if not exists public.binscan_events (
  id          bigint generated always as identity primary key,
  created_at  timestamptz not null default now(),
  session_id  uuid,
  device      text,
  mode        text,
  type        text not null,          -- session_start / calibration / scan_start / alarm / clip / normal_registered / scan_stop / session_end
  ts          timestamptz,
  margin      numeric,
  data        jsonb not null default '{}'::jsonb,
  clip_path   text,
  label       text,                   -- 관리자가 붙임: true_positive / false_alarm / unsure
  note        text
);
create index if not exists binscan_events_session_idx on public.binscan_events (session_id);
create index if not exists binscan_events_created_idx on public.binscan_events (created_at desc);
create index if not exists binscan_events_type_idx    on public.binscan_events (type);

alter table public.binscan_events enable row level security;
drop policy if exists "phones insert" on public.binscan_events;
create policy "phones insert" on public.binscan_events
  for insert to anon with check (true);
-- select/update/delete 정책 없음 → anon 키로는 읽을 수 없음

-- 2) 관리자 토큰 (anon이 절대 못 읽는 테이블) --------------------------------
create table if not exists public.binscan_config (k text primary key, v text);
alter table public.binscan_config enable row level security;   -- 정책 없음 = 외부에서 접근 불가
insert into public.binscan_config (k, v) values
  ('admin_token', 'CHANGE-ME-to-a-long-random-string'),       -- ★ 꼭 바꾸세요. 대시보드에 입력할 토큰
  ('tg_token', ''),                                            -- (선택) 텔레그램 봇 토큰
  ('tg_chat', '')                                              -- (선택) 알림 받을 chat_id
on conflict (k) do nothing;

-- 3) 대시보드용 RPC ----------------------------------------------------------
create or replace function public.binscan_admin_events(p_token text, p_limit int default 500, p_before timestamptz default null)
returns setof public.binscan_events
language sql security definer set search_path = public as $$
  select * from public.binscan_events
  where p_token = (select v from public.binscan_config where k = 'admin_token')
    and (p_before is null or created_at < p_before)
  order by created_at desc
  limit least(coalesce(p_limit, 500), 2000);
$$;

create or replace function public.binscan_admin_label(p_token text, p_id bigint, p_label text, p_note text default null)
returns boolean
language plpgsql security definer set search_path = public as $$
begin
  if p_token is distinct from (select v from public.binscan_config where k = 'admin_token') then return false; end if;
  update public.binscan_events set label = p_label, note = coalesce(p_note, note) where id = p_id;
  return found;
end $$;

revoke all on function public.binscan_admin_events(text, int, timestamptz) from public;
revoke all on function public.binscan_admin_label(text, bigint, text, text) from public;
grant execute on function public.binscan_admin_events(text, int, timestamptz) to anon, authenticated;
grant execute on function public.binscan_admin_label(text, bigint, text, text) to anon, authenticated;

-- 4) 영상 클립 버킷 -----------------------------------------------------------
-- 공개 버킷 + 추측 불가능한 UUID 경로. 목록 조회는 막혀 있어 경로를 모르면 못 봅니다.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('binscan-clips', 'binscan-clips', true, 52428800, array['video/webm','video/mp4'])
on conflict (id) do nothing;

drop policy if exists "binscan phones upload" on storage.objects;
create policy "binscan phones upload" on storage.objects
  for insert to anon with check (bucket_id = 'binscan-clips');
-- select 정책 없음 → anon으로 목록/삭제 불가 (공개 URL 직접 접근만 가능)

-- 5) (선택) 알림 즉시 텔레그램 전송 --------------------------------------------
-- binscan_config의 tg_token / tg_chat을 채우면 alarm 이벤트마다 메시지가 갑니다.
create extension if not exists pg_net;
create or replace function public.binscan_notify_tg()
returns trigger language plpgsql security definer set search_path = public as $$
declare tok text; chat text; msg text;
begin
  if new.type <> 'alarm' then return new; end if;
  select v into tok  from public.binscan_config where k = 'tg_token';
  select v into chat from public.binscan_config where k = 'tg_chat';
  if coalesce(tok, '') = '' or coalesce(chat, '') = '' then return new; end if;
  msg := format('⚠ BinScan 알림%s%s · 점수 %s · 위치 %s · 덩어리 %s패치 · 배수 %s',
                E'\n', coalesce(new.device, '기기미상') || ' ' || to_char(coalesce(new.ts, now()) at time zone 'Asia/Seoul', 'MM-DD HH24:MI:SS'),
                new.data->>'ratio', new.data->>'cell', new.data->>'cluster', new.margin);
  perform net.http_post(
    url := 'https://api.telegram.org/bot' || tok || '/sendMessage',
    body := jsonb_build_object('chat_id', chat, 'text', msg),
    headers := '{"Content-Type":"application/json"}'::jsonb);
  return new;
end $$;
drop trigger if exists binscan_notify_tg on public.binscan_events;
create trigger binscan_notify_tg after insert on public.binscan_events
  for each row execute function public.binscan_notify_tg();

-- 6) 편의 뷰: 세션별 요약 (대시보드가 RPC로 읽는 데이터와 동일 소스)
create or replace view public.binscan_session_summary as
select session_id,
       min(created_at)                                     as started,
       max(created_at)                                     as ended,
       max(device)                                         as device,
       count(*) filter (where type = 'alarm')              as alarms,
       count(*) filter (where type = 'alarm' and label = 'false_alarm') as false_alarms,
       count(*) filter (where type = 'alarm' and label = 'true_positive') as true_positives,
       count(*) filter (where type = 'clip')               as clips
from public.binscan_events group by session_id;
revoke all on public.binscan_session_summary from anon;
