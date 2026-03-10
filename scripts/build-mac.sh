#!/usr/bin/env bash
# Full macOS build: vcpkg deps -> CMake (native addon) -> Electron DMG/zip.
# Run from repo root. Requires: vcpkg cloned + bootstrapped.

set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

VCPKG="$ROOT/vcpkg/vcpkg"
if [[ ! -x "$VCPKG" ]]; then
  echo "vcpkg not found or not executable. See docs/BUILD-EXECUTABLES.md."
  exit 1
fi

echo "=== 1. vcpkg install ==="
"$VCPKG" install --overlay-triplets=./custom-triplets @./vcpkg.txt --triplet x64-osx_b

echo "=== 2. CMake configure + build ==="
mkdir -p build && cd build
cmake -DVCPKG_TARGET_TRIPLET=x64-osx_b \
  -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  ../src
cmake --build . --config Release
cd "$ROOT"

echo "=== 3. UI npm install + release:mac ==="
cd UI
npm install
npm run release:mac

echo "Done. Output is in UI/dist/"
