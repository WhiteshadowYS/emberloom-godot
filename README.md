# emberloom-godot — the Ember World engine package

A **package of patches on a stock Godot tag**, not a fork and not a branch we live on. This repository holds no
engine source: it pins a stock Godot commit (`BASE`), carries numbered, upstream-shaped patches (`patches/`),
builds editor + export templates in CI, and publishes them as a GitHub Release `v<VERSION>` that the game repo
(`build-arena`) pins.

Design and rationale: `ws_cortex/workspace/dev/projects/build-arena/research/2026-10-31-graphics-tech-integration-plan.md`
§4 / §4.1 (owner decisions D-GT1–D-GT7, 2026-10-31).

## Layout

| Path | What |
|---|---|
| `BASE` | `<tag> <commit>` — the stock Godot the patches apply to |
| `VERSION` | `<tag-without-stable>-el.<N>` — N = patch-set revision; the Release tag is `v<VERSION>` |
| `patches/NNNN-<slug>.patch` | one upstream-shaped commit each, applied in numeric order by `apply.sh` |
| `patches/README.md` | the **patch ledger** — purpose · files · LOC · upstream PR · status · last rebase · notes |
| `apply.sh` | clone the base at the pinned commit into `godot/` and `git am` every patch; fails loudly on the first conflict |
| `build.sh` | SCons wrapper with the Ember World flags (production, LTO, XR modules off) — the same command locally, on the Mac and in CI |
| `.github/workflows/templates.yml` | builds Linux editor + Linux / Windows release templates, publishes the Release with `sha256sums.txt` |
| `smoke/` | (from el.1) a Godot project that exercises every hook the patches add |
| `CHANGELOG.md` | one entry per revision: base, patches in / out, flag changes |

## Rules of the package

- **What may enter:** only hooks the Rust GDExtension needs (custom upscaler, scene-data bindings, driver
  callback, Vulkan extension injection, opaque copy, low-latency Vulkan) and cherry-picks of merged upstream
  fixes. Never gameplay, never a fix that can live in the extension, never a renderer feature.
- **A patch is dropped the day upstream ships its equivalent.** Every patch carries its upstream PR / issue in
  the ledger; P2 / P3 / P5 get upstream PRs once stable.
- **Editor + templates from the same tree** — the hook classes must exist in the editor binary or the Rust
  subclasses cannot register. Dev machines move to `el.N` the day the game repo's pin moves.
- **Rebase per engine bump (≈ 0.5–1 day):** new `BASE` → `apply.sh` → resolve → `smoke/` green → bump
  `VERSION` → CI Release → game repo bumps its pin in one commit → full CI + hosted determinism → playtest zip.
- **Revision 0 is stock:** `el.0` has zero patches and only build-flag changes, so a template-build problem is
  never confused with a patch problem.
- **Never build with LTO on the 2-vCPU VPS** (≈ 7 GB RAM, hours): CI or the Mac.

## Using it

```sh
./apply.sh                 # godot/ = stock BASE + patches (idempotent; re-clones when BASE changed)
./build.sh editor          # Linux editor (this host)
./build.sh linux           # Linux x86_64 release template
./build.sh windows         # Windows x86_64 release template (MSVC on Windows, mingw elsewhere)
./build.sh macos           # macOS universal template (macOS host only)
```

Artefacts land in `godot/bin/`. CI runs the same script per matrix entry and publishes the Release when `VERSION`
changes on `main` (or on manual dispatch).

## Licence

Everything in this repository — the patches, the scripts, the workflow — is **MIT** (`LICENSE`), the same licence as
Godot, so every patch can be sent upstream unchanged. The built binaries are Godot: they carry Godot's own MIT licence and
the third-party notices in the engine's `COPYRIGHT.txt` / `thirdparty/` (the Release notes point there). Vendor SDKs the
game's extension may load at runtime (NGX, FidelityFX, XeSS) are **not** part of this package and keep their own licences.

Git flow: `auto` (agent commits and pushes after review; 1-line Conventional Commits; no AI trailers) — same
owner rules as `build-arena`.
