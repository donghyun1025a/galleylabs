# BinScan — 오버헤드빈 검색 보조 (프로토타입)

파일 3개:
- binscan.html   : 폰 앱 (카메라 폰 / 뷰어 폰 / 단독 테스트)
- dashboard.html : 관리자 대시보드 (기록·클립 열람, 진짜/오탐 판정, 작업자 설정 링크 생성)
- setup.sql      : Supabase 백엔드 설정 (테이블·버킷·RPC·텔레그램 알림)

## 설치 (10분)
1. supabase.com → New project → SQL Editor → setup.sql 전체 붙여넣기 → Run
   - 실행 전에 `admin_token` 값을 긴 랜덤 문자열로 바꾸세요.
   - (선택) 텔레그램: binscan_config의 tg_token / tg_chat에 봇 토큰과 chat_id 입력 → 알림마다 메시지.
2. Project Settings → API 에서 Project URL 과 anon public key 복사.
3. binscan.html, dashboard.html 을 HTTPS 호스팅에 업로드 (Vercel / Netlify Drop / GitHub Pages). 카메라는 HTTPS에서만 열립니다.
4. dashboard.html 열기 → URL, anon 키, 관리자 토큰 입력 → "작업자 폰 설정 링크" 생성 → 작업자 폰에서 한 번 열면 전송 설정 자동 저장.
   (또는 binscan.html ⚙ 설정 → 전송 항목에 직접 입력)

## 무엇이 올라가나
- 이벤트(JSON): session_start / calibration(기준점수·저장소 크기) / scan_start / alarm(점수·위치·덩어리·배수) / normal_registered / scan_stop / session_end(전체 로그)
- 클립(webm/mp4): 영상 전송 모드에 따라
  - 알림 클립만: 알림이 난 10초 구간 + 직전 10초 구간
  - 전체 세션: 10초 단위 전부
- 네트워크가 끊기면 이벤트는 폰에 대기했다가 자동 재전송. 클립은 앱을 닫으면 사라집니다.

## 보안 메모
- anon 키로는 "쓰기만" 됩니다. 읽기는 관리자 토큰을 아는 대시보드만.
- 클립 버킷은 공개 URL이지만 경로가 UUID라 목록 없이는 못 찾습니다. 제품화 시 서명 URL로 바꾸세요.
- 기내 촬영물을 외부 서버에 올리는 것이므로 항공사·공항 승인 범위를 먼저 확인하세요.
