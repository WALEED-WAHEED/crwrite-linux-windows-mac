# Removes build artifacts and caches to free disk space.
# Run from repo root. BACK UP your installer from UI/dist/ first if you need it.
# To rebuild after this: re-clone vcpkg, bootstrap, vcpkg install, CMake, npm install (see docs/BUILD-EXECUTABLES.md).

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "This will DELETE:" -ForegroundColor Yellow
Write-Host "  - vcpkg/ (entire folder)"
Write-Host "  - build/"
Write-Host "  - node_modules/ (root)"
Write-Host "  - UI/node_modules/"
Write-Host "  - UI/app/Backend/crwrite.node (if present)"
Write-Host ""
Write-Host "UI/dist/ (your built installer) will be KEPT. Copy it elsewhere first if you want a backup." -ForegroundColor Cyan
$confirm = Read-Host "Type YES to continue"
if ($confirm -ne "YES") {
    Write-Host "Aborted."
    exit 0
}

$removed = 0
foreach ($path in @("vcpkg", "build", "node_modules", "UI\node_modules", "UI\app\Backend\crwrite.node")) {
    $full = Join-Path $root $path
    if (Test-Path $full) {
        Write-Host "Removing: $path"
        Remove-Item -Recurse -Force $full -ErrorAction SilentlyContinue
        $removed++
    }
}

Write-Host "Done. Freed space from $removed item(s). Rebuild using docs/BUILD-EXECUTABLES.md" -ForegroundColor Green
