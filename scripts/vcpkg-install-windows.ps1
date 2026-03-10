# Run vcpkg install for Windows (x86-windows-static).
# Use this from the repo root so PowerShell runs the vcpkg executable instead of loading a module.
# Requires: vcpkg cloned and bootstrapped (bootstrap-vcpkg.bat) in the vcpkg folder.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$vcpkgExe = Join-Path $root "vcpkg\vcpkg.exe"

if (-not (Test-Path $vcpkgExe)) {
    Write-Error "vcpkg.exe not found at: $vcpkgExe. Clone vcpkg, checkout 769f5bc, and run bootstrap-vcpkg.bat in the vcpkg folder."
    exit 1
}

Set-Location $root
& $vcpkgExe install --overlay-triplets=custom-triplets '@vcpkg.txt' --triplet x86-windows-static
