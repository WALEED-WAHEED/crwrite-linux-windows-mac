#!/usr/bin/env bash
# Removes build artifacts and caches to free disk space.
# Run from repo root. BACK UP your installer from UI/dist/ first if you need it.
# To rebuild: re-clone vcpkg, bootstrap, vcpkg install, CMake, npm install (see docs/BUILD-EXECUTABLES.md).

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "This will DELETE:"
echo "  - vcpkg/"
echo "  - build/"
echo "  - node_modules/ (root)"
echo "  - UI/node_modules/"
echo "  - UI/app/Backend/crwrite.node (if present)"
echo ""
echo "UI/dist/ (your built installer) will be KEPT. Copy it elsewhere first if you want a backup."
read -p "Type YES to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
  echo "Aborted."
  exit 0
fi

rm -rf "$ROOT/vcpkg" "$ROOT/build" "$ROOT/node_modules" "$ROOT/UI/node_modules" "$ROOT/UI/app/Backend/crwrite.node"
echo "Done. Rebuild using docs/BUILD-EXECUTABLES.md"
