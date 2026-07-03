# GalleyLabs — Set in Fable

A single-file showcase site for **GalleyLabs × Fable 5**, designed as a living
*galley proof* — the first sheet pulled off a letterpress.

## The concept

GalleyLabs takes its name from the galley proof, so the whole page borrows the
language of the composing room:

- **Crop marks & a registration strip** frame the viewport like a proof sheet.
- **A risograph duotone** (riso blue `#0078BF` + fluorescent pink `#FF48B0`)
  overprints the hero headline with a live misregistration effect — move the
  cursor and the ink plates shift.
- **The Press** is an interactive demo: pick a manuscript (Reason / Compose /
  Build) and watch Fable 5 set it — extended thinking first, then ink. The
  Build job streams real CSS and then renders the working result.
- **Specimens** present six capabilities as type-specimen cards with hover
  micro-interactions.
- **The Densitometer** measures "ink density" — an illustrative benchmark
  chart with direct labels, tooltips, and a table view.
- **The Colophon** closes the sheet the way every well-made book does.

## Details

- One self-contained `index.html` — no build step, no external requests.
  Fraunces, Schibsted Grotesk, and IBM Plex Mono are embedded as data URIs.
- Light and dark themes (paper / midnight pressroom), token-driven, with a
  manual toggle that overrides the OS preference.
- `prefers-reduced-motion` is respected everywhere: the halftone canvas,
  the letterpress load-in, the marquee, and the typing demos all settle to
  their final states.
- Chart densities are illustrative, and labeled as such on the sheet.

## Run it

Open `index.html` in a browser, or serve the folder:

```sh
npx http-server .
```
