# Removes only heavy caches; keeps vcpkg and vcpkg/installed so you can rebuild without re-downloading.
# Run from repo root. Frees several GB. See docs/CLEANUP-DISK-SPACE.md.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

$dirs = @(
    "vcpkg\downloads",
    "vcpkg\buildtrees",
    "vcpkg\packages",
    "build",
    "node_modules",
    "UI\node_modules"
)
foreach ($d in $dirs) {
    $full = Join-Path $root $d
    if (Test-Path $full) {
        Write-Host "Removing: $d"
        Remove-Item -Recurse -Force $full
    }
}
Write-Host "Done. vcpkg and vcpkg/installed kept; run CMake + npm install to rebuild." -ForegroundColor Green
