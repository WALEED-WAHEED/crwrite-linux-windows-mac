# Apple Silicon (M1/M2/M3) - use this triplet on arm64 Macs instead of x64-osx_b
set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)

set(VCPKG_CMAKE_SYSTEM_NAME Darwin)

set(VCPKG_OSX_DEPLOYMENT_TARGET "10.12")
set(VCPKG_C_FLAGS "-mmacosx-version-min=10.12 -Wno-implicit-function-declaration")
set(VCPKG_CXX_FLAGS "-mmacosx-version-min=10.12")
