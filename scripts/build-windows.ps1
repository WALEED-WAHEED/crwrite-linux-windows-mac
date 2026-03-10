# Full Windows build: vcpkg deps -> CMake (native addon) -> Electron installer.
# Run from repo root. Requires: vcpkg cloned + bootstrapped, VS 2019 Build Tools with C++.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$vcpkgExe = Join-Path $root "vcpkg\vcpkg.exe"

if (-not (Test-Path $vcpkgExe)) {
    Write-Error "vcpkg.exe not found. See docs/BUILD-EXECUTABLES.md: clone vcpkg, checkout 769f5bc, run bootstrap-vcpkg.bat."
    exit 1
}

Set-Location $root

Write-Host "=== 1. vcpkg install ===" -ForegroundColor Cyan
& $vcpkgExe install --overlay-triplets=custom-triplets '@vcpkg.txt' --triplet x86-windows-static
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "=== 2. CMake configure + build ===" -ForegroundColor Cyan
New-Item -ItemType Directory -Force -Path build | Out-Null
Set-Location build
$triplet = "x86-windows-static"
$toolchain = "..\vcpkg\scripts\buildsystems\vcpkg.cmake"
$openssl = "..\vcpkg\installed\x86-windows-static"
& cmake -DVCPKG_TARGET_TRIPLET=$triplet -DCMAKE_TOOLCHAIN_FILE=$toolchain -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -A Win32 -DOPENSSL_ROOT_DIR=$openssl ..\src
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& cmake --build . --config Release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
Set-Location $root

Write-Host "=== 3. UI npm install + release ===" -ForegroundColor Cyan
Set-Location (Join-Path $root "UI")
& npm install
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& npm run release
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Done. Installer is in UI\dist\" -ForegroundColor Green
