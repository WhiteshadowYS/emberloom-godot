#!/usr/bin/env bash
# build.sh <editor|linux|windows|macos> [extra scons args…] — build one artefact from godot/ with the Ember World flags.
# The same command runs locally, on the Mac (rx) and in CI. Never with LTO on the 2-vCPU VPS.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${GODOT_SRC:-$ROOT/godot}"
what="${1:-}"; shift || true
[ -d "$SRC" ] || { echo "build.sh: run ./apply.sh first" >&2; exit 1; }

# Common flags (ledger "Build-flag changes"): production = LTO full (GCC) + optimize=speed + static libstdc++.
# Never disable a module that registers classes: godot-rust (gdext) binds every class of the stock
# extension_api.json at load and panics on a missing one (el.0 lesson: XR off → OpenXRExtensionWrapper panic).
COMMON=(production=yes verbose=no progress=no)
JOBS="${SCONS_JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu)}"
export SCONS_CACHE="${SCONS_CACHE:-$ROOT/.scons_cache}"

case "$what" in
  editor)  ARGS=(platform=linuxbsd target=editor arch=x86_64) ;;
  linux)   ARGS=(platform=linuxbsd target=template_release arch=x86_64) ;;
  windows)
    # MinGW-GCC like the official templates (godot-build-scripts: Fedora MinGW, use_mingw=yes, production=yes →
    # lto=full). Never MSVC: Godot's MSVC path turns LTO off under production (detect.py "No LTO by default for
    # MSVC") and the GDScript VM loses its computed-goto dispatch (GCC/Clang only) — el.0.1 was ~17 % slower on
    # script-bound frames (PRG). D3D12 / ANGLE / AccessKit come from godot/bin/build_deps (misc/scripts/install_*.py);
    # without the Mesa NIR libs D3D12 is switched off with a warning (local iteration only — CI installs them).
    ARGS=(platform=windows target=template_release arch=x86_64 use_mingw=yes)
    if [ ! -d "$SRC/bin/build_deps/mesa-x86_64-gcc" ] && [ ! -d "$SRC/bin/build_deps/mesa" ]; then
      echo "build.sh: no Mesa NIR in godot/bin/build_deps → d3d12=no (run misc/scripts/install_d3d12_sdk_windows.py)" >&2
      ARGS+=(d3d12=no)
    fi
    for dep in angle-x86_64-gcc accesskit; do
      [ -d "$SRC/bin/build_deps/$dep" ] || echo "build.sh: WARNING no godot/bin/build_deps/$dep — detect.py turns that driver off (not the official set)" >&2
    done
    ;;
  macos)   [[ "$(uname -s)" == Darwin ]] || { echo "build.sh: macos needs a macOS host" >&2; exit 1; }
           ARGS=(platform=macos target=template_release arch=arm64) ;;
  *) echo "usage: build.sh <editor|linux|windows|macos> [scons args…]" >&2; exit 1 ;;
esac

cd "$SRC"
echo "build.sh: scons -j$JOBS ${ARGS[*]} ${COMMON[*]} $*" >&2
exec scons -j"$JOBS" "${ARGS[@]}" "${COMMON[@]}" "$@"
