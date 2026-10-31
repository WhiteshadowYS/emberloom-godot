#!/usr/bin/env bash
# build.sh <editor|linux|windows|macos> [extra scons args…] — build one artefact from godot/ with the Ember World flags.
# The same command runs locally, on the Mac (rx) and in CI. Never with LTO on the 2-vCPU VPS.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="${GODOT_SRC:-$ROOT/godot}"
what="${1:-}"; shift || true
[ -d "$SRC" ] || { echo "build.sh: run ./apply.sh first" >&2; exit 1; }

# Common flags (ledger "Build-flag changes"): production = LTO full + optimize=speed + static libstdc++; XR off.
COMMON=(production=yes module_openxr_enabled=no module_mobile_vr_enabled=no module_webxr_enabled=no
        verbose=no progress=no)
JOBS="${SCONS_JOBS:-$(nproc 2>/dev/null || sysctl -n hw.ncpu)}"
export SCONS_CACHE="${SCONS_CACHE:-$ROOT/.scons_cache}"

case "$what" in
  editor)  ARGS=(platform=linuxbsd target=editor arch=x86_64) ;;
  linux)   ARGS=(platform=linuxbsd target=template_release arch=x86_64) ;;
  windows)
    ARGS=(platform=windows target=template_release arch=x86_64)
    [[ "$(uname -s)" == MINGW* || "$(uname -s)" == MSYS* || -n "${WINDIR:-}" ]] || ARGS+=(use_mingw=yes d3d12=no)
    ;;
  macos)   [[ "$(uname -s)" == Darwin ]] || { echo "build.sh: macos needs a macOS host" >&2; exit 1; }
           ARGS=(platform=macos target=template_release arch=arm64) ;;
  *) echo "usage: build.sh <editor|linux|windows|macos> [scons args…]" >&2; exit 1 ;;
esac

cd "$SRC"
echo "build.sh: scons -j$JOBS ${ARGS[*]} ${COMMON[*]} $*" >&2
exec scons -j"$JOBS" "${ARGS[@]}" "${COMMON[@]}" "$@"
