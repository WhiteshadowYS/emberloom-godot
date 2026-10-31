#!/usr/bin/env bash
# apply.sh — materialise godot/ = stock BASE + every patch in patches/, in numeric order.
# Idempotent: re-clones when BASE changed, otherwise resets to the base commit and re-applies.
# Fails loudly on the first conflict (git am leaves the tree in the conflicted state for inspection).
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
read -r TAG SHA < <(tr -d "\r" < "$ROOT/BASE")
[ -n "${TAG:-}" ] && [ -n "${SHA:-}" ] || { echo "apply.sh: BASE must be '<tag> <commit>'" >&2; exit 1; }
SRC="${GODOT_SRC:-$ROOT/godot}"

if [ ! -d "$SRC/.git" ]; then
  echo "apply.sh: cloning godotengine/godot at $TAG ($SHA) …" >&2
  git clone --filter=blob:none --no-checkout https://github.com/godotengine/godot.git "$SRC"
fi
cd "$SRC"
if ! git cat-file -e "$SHA^{commit}" 2>/dev/null; then
  git fetch --depth=1 origin "$SHA" || git fetch origin "refs/tags/$TAG:refs/tags/$TAG"
fi
git checkout -q --detach "$SHA"
git reset -q --hard "$SHA"
git clean -qfdx -e bin/ -e .scons_cache/ -e .sconsign.dblite
git config user.name  "emberloom-godot"
git config user.email "emberloom-godot@users.noreply.github.com"

n=0
for p in "$ROOT"/patches/[0-9]*.patch; do
  [ -e "$p" ] || continue
  echo "apply.sh: $(basename "$p")" >&2
  git am --3way --keep-cr "$p" || { echo "apply.sh: CONFLICT in $(basename "$p") — resolve in $SRC, then 'git am --continue'" >&2; exit 2; }
  n=$((n+1))
done
echo "apply.sh: $TAG + $n patch(es) → $(git rev-parse --short HEAD) ($(tr -d "\r" < "$ROOT/VERSION"))" >&2
