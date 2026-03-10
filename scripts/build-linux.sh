#!/usr/bin/env bash
# Full Linux build: vcpkg deps -> CMake (native addon) -> Electron AppImage.
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
"$VCPKG" install --overlay-triplets=./custom-triplets @./vcpkg.txt --triplet x64-linux

echo "=== 2. CMake configure + build ==="
mkdir -p build && cd build
cmake -DVCPKG_TARGET_TRIPLET=x64-linux \
  -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  ../src
cmake --build . --config Release
cd "$ROOT"

echo "=== 3. UI npm install + release:linux ==="
cd UI
npm install
npm run release:linux

echo "Done. Output is in UI/dist/"
