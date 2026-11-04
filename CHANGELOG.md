# Changelog

## 4.7.2-el.0.2 — 2026-11-04

- Base: unchanged (`4.7.2-stable`, `ed1daf0bf`). Patches: none. Flags: `production=yes` (unchanged).
- Windows template toolchain: **MinGW-GCC 15.2 (Fedora 43 container, cross build)** instead of MSVC — the official
  godot-build-scripts recipe (`use_mingw=yes`, D3D12 + ANGLE + AccessKit deps). el.0.1's MSVC template was a
  CPU regression on script-bound frames (build-arena PRG, RX 9070 XT / 5700X3D: run300 66.7 → 55.8 fps,
  −17 %): Godot's MSVC path sets `lto=none` under `production=yes`, and the GDScript VM's computed-goto opcode
  dispatch is GCC / Clang only (switch dispatch on MSVC).
- Deps: Mesa NIR / ANGLE / AccessKit at the versions pinned by the base commit's `misc/scripts/install_*.py`
  (Mesa NIR 25.3.1-3 = official; ANGLE `chromium/7219` and AccessKit 0.22.3 may differ from the gbs revision that
  built 4.7.2-stable — not perf-relevant: Vulkan Forward+ uses neither).
- Linux editor / template: same recipe as el.0.1 (Ubuntu 24.04 GCC 13.3, production) — measured equal to stock.

## 4.7.2-el.0.1 — 2026-11-03

- Base: unchanged (`4.7.2-stable`, `ed1daf0bf`). Patches: none.
- Flags: `production=yes` only — XR modules re-enabled. el.0 removed 66 classes from the API; the game's
  godot-rust extension panics at load (`Failed to load class method OpenXRExtensionWrapper::get_openxr_api`).
  el.0 is superseded; do not pin it.

## 4.7.2-el.0 — 2026-10-31

- Base: Godot `4.7.2-stable` (`ed1daf0bf001b61586d9930840f2f1394092c079`).
- Patches: none (revision 0 is stock by design — build infrastructure first, hooks from el.1).
- Flags: `production=yes` (LTO full, optimize=speed), XR modules off (`openxr`, `mobile_vr`, `webxr`).
- Artefacts: linux editor, linux x86_64 release template, windows x86_64 release template (MSVC, d3d12 + vulkan).
