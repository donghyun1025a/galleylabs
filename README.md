# GalleyLabs — Set in Fable

A single-file showcase site for **GalleyLabs × Fable 5**, designed as a living
*galley proof* — the first sheet pulled off a letterpress.

## The concept

GalleyLabs takes its name from the galley proof, so the whole page borrows the
language of the composing room:

- **Live ink physics.** The hero's ink is a real fluid — a Navier–Stokes
  solver written from scratch in raw WebGL2 (semi-Lagrangian advection,
  vorticity confinement, Jacobi pressure projection), running on your GPU.
  Two ink channels composite subtractively on paper in light mode and
  additively in the dark. Drag through it. Falls back to a static wash when
  WebGL2 or motion isn't available.
- **Crop marks & a registration strip** frame the viewport like a proof
  sheet, and the headline overprints with live misregistration parallax.
- **The Press** is an interactive demo: pick a manuscript (Reason / Compose /
  Build) and watch Fable 5 set it — extended thinking first, then ink. The
  Build job streams real CSS and then renders the working result.
- **The Foundry** is a working press: type any line, choose your inks, and
  pull a proof. It prints to canvas with plate misregistration, per-sort
  jitter, ink starvation, and paper grain — every pull unique — then lets
  you download the sheet as a PNG poster.
- **The Fable Engine** sets one of **144,000,000** distinct fables from a
  case of interchangeable sorts (seeded PRNG, exact mixed-radix edition
  numbering). Pull the lever; that edition is yours alone.
- **The Job Ticket** (⌘K / Ctrl+K) is a command palette for the whole shop.
- **Press sounds** — the sort-clack, the platen thunk, the job-done bell —
  are synthesized in-browser with the Web Audio API. No audio files. Off by
  default; toggle in the header.
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
