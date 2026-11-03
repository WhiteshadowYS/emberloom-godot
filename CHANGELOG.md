# Changelog

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
