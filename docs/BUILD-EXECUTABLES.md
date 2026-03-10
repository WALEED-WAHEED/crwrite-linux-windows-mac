## CRWrite Executable Build Guide (Windows, Linux, macOS)

This document explains how to build **CRWrite** executables on all three platforms:

- **Windows installer** (`.exe`)
- **Linux AppImage** (built natively or via **WSL** on Windows)
- **macOS DMG/zip**

It is written for the current project layout and tools (CMake, vcpkg, Electron + electron-builder).

---

## 1. Common Concepts

- **Native addon**: C++ code in `src` builds a Node addon (`crwrite.node`) using **CMake** + **vcpkg**.
  - The addon is copied to `UI/app/Backend/crwrite.node` by a CMake **POST_BUILD** step.
  - This addon **must be compiled on the same OS/ABI** you target. No generic Windows→Linux cross-compile.
- **Electron UI**:
  - Lives under `UI/`.
  - Built and packaged by **electron-builder** (`npm run release`, `release:mac`, `release:linux`).
  - Final installers and AppImages appear in `UI/dist/`.
- **vcpkg**:
  - Dependency list: `vcpkg.txt` at repo root.
  - Triplets:
    - Windows: `x86-windows-static`
    - macOS: `x64-osx_b` (custom triplet in `custom-triplets/x64-osx_b.cmake`)
    - Linux: `x64-linux`
  - Required commit (known-good): **769f5bc**.

### 1.1 Required files / scripts

From the repo root (`crwrite-v1`), you should see:

- `vcpkg.txt`
- `src/CMakeLists.txt`
- `UI/package.json`
- `scripts/build-windows.ps1`
- `scripts/build-linux.sh`
- `scripts/build-mac.sh`

These scripts wrap the exact commands in this document.

---

## 2. Windows Build (Installer `.exe`)

### 2.1 Prerequisites (Windows)

Install these on **Windows**:

- **Node.js 10.11.0 (32-bit)** and npm  
  - Recommended by existing `BUILD.md`:
  - You can use nvm-windows:
    ```powershell
    nvm install 10.11.0 32
    nvm use 10.11.0 32
    ```
- **Visual Studio 2019 Build Tools** with **“Desktop development with C++”** workload  
  Download: `https://aka.ms/vs/16/release/vs_buildtools.exe`
- **CMake 3.12.4+**
- **Git**

> If you want the fastest path and `vcpkg` is already cloned and bootstrapped, jump directly to **2.4 One‑Command Build**.

### 2.2 Clone and bootstrap vcpkg (Windows)

From a **Developer PowerShell** or regular PowerShell (with VS Build Tools installed), at the repo root:

```powershell
cd "C:\Users\Programmer\Desktop\Developments\Side Projects\crwrite-v1"

git clone https://github.com/microsoft/vcpkg.git vcpkg
cd vcpkg
git checkout 769f5bc
.\bootstrap-vcpkg.bat
cd ..
```

You should now have `vcpkg\vcpkg.exe`.

### 2.3 Install C++ dependencies (Windows, vcpkg)

```powershell
cd "C:\Users\Programmer\Desktop\Developments\Side Projects\crwrite-v1"
.\vcpkg\vcpkg.exe install --overlay-triplets=custom-triplets '@vcpkg.txt' --triplet x86-windows-static
```

Notes:

- The quotes `'@vcpkg.txt'` are important so PowerShell does not treat `@vcpkg.txt` as a splat.
- This can take a long time the first time (Boost, OpenSSL, etc.).

### 2.4 Configure and build native addon (Windows, CMake)

From the repo root:

```powershell
cd "C:\Users\Programmer\Desktop\Developments\Side Projects\crwrite-v1"

mkdir build
cd build

cmake -DVCPKG_TARGET_TRIPLET=x86-windows-static `
  -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake `
  -DCMAKE_EXPORT_COMPILE_COMMANDS:BOOL=ON `
  -A Win32 `
  -DOPENSSL_ROOT_DIR:PATH=../vcpkg/installed/x86-windows-static `
  ../src

cmake --build . --config Release
```

This will:

- Build the C++ code (daemon + addon).
- Copy the built addon to `UI/app/Backend/crwrite.node`.

### 2.5 Build the Windows installer (Electron)

From the repo root:

```powershell
cd "C:\Users\Programmer\Desktop\Developments\Side Projects\crwrite-v1\UI"
npm install
npm run release
```

Result:

- Output installer in:
  - `C:\Users\Programmer\Desktop\Developments\Side Projects\crwrite-v1\UI\dist`
  - Example: `CoastRunner 1.3.1 Setup x32.exe` (name controlled by `UI/package.json`).

### 2.6 One‑command Windows build

After `vcpkg` is cloned and bootstrapped, you can use:

```powershell
cd "C:\Users\Programmer\Desktop\Developments\Side Projects\crwrite-v1"
.\scripts\build-windows.ps1
```

This runs:

1. `vcpkg install` (x86-windows-static)
2. CMake configure + build
3. `cd UI && npm install && npm run release`

---

## 3. Linux Build (Native Linux or WSL on Windows)

You can build on:

- A **real Linux machine/VM**, or
- **WSL2** on Windows (Ubuntu recommended).

The steps are the same; only the path to the repo differs.

### 3.1 Prerequisites (Linux / WSL)

On your Linux system **or** in Ubuntu WSL:

```bash
sudo apt update
sudo apt install -y build-essential cmake git nodejs npm
```

Optional (if you want a specific Node version): install Node from NodeSource or use `nvm`.

#### If using WSL on Windows

1. Enable WSL and install Ubuntu once (PowerShell as Administrator):
   ```powershell
   wsl --install
   ```
   Restart if prompted, then open **Ubuntu** from Start menu and create your Linux user.
2. In Ubuntu, go to your project under `/mnt/c`:
   ```bash
   cd "/mnt/c/Users/Programmer/Desktop/Developments/Side Projects/crwrite-v1"
   ```

All following Linux commands assume your repo root is the current directory.

### 3.2 Clone and bootstrap vcpkg (Linux)

Only if `vcpkg/` is missing:

```bash
cd "/path/to/crwrite-v1"     # or /mnt/c/... if using WSL

git clone https://github.com/microsoft/vcpkg.git vcpkg
cd vcpkg
git checkout 769f5bc
./bootstrap-vcpkg.sh
cd ..
```

### 3.3 Install C++ dependencies (Linux, vcpkg)

From repo root:

```bash
./vcpkg/vcpkg install --overlay-triplets=./custom-triplets @./vcpkg.txt --triplet x64-linux
```

This installs:

- Boost (asio, thread, system, iostreams, filesystem)
- Catch2
- jsoncpp
- minizip
- OpenSSL
- spdlog
- tiny-process-library
- zlib

### 3.4 Configure and build native addon (Linux, CMake)

From repo root:

```bash
mkdir -p build
cd build

cmake \
  -DVCPKG_TARGET_TRIPLET=x64-linux \
  -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  ../src

cmake --build . --config Release
cd ..
```

This will build the Linux `crwrite.node` and copy it into `UI/app/Backend/crwrite.node`.

### 3.5 Build Linux AppImage (Electron)

From repo root:

```bash
cd UI
npm install
npm run release:linux
```

Result:

- Output in `UI/dist/` (same directory visible from Windows if using WSL).
- At least one `.AppImage` file; optionally `.deb` if configured.

### 3.6 One‑command Linux build

Once vcpkg is cloned + bootstrapped:

```bash
cd "/path/to/crwrite-v1"
chmod +x scripts/build-linux.sh
./scripts/build-linux.sh
```

This runs:

1. `vcpkg install` (x64-linux)
2. CMake configure + build
3. `cd UI && npm install && npm run release:linux`

---

## 4. macOS Build (DMG/zip)

macOS builds must run on **macOS** or in CI that provides a macOS runner (e.g. GitHub Actions).

### 4.1 Prerequisites (macOS)

On the Mac:

- Xcode or Command Line Tools (for `clang`/`clang++`).
- Homebrew or system-installed **cmake** if not already present.
- **Node.js** and npm (LTS is fine).
- **Git**.

Install tools (example using Homebrew):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install cmake git node
```

### 4.2 Clone and bootstrap vcpkg (macOS)

From the repo root on macOS:

```bash
git clone https://github.com/microsoft/vcpkg.git vcpkg
cd vcpkg
git checkout 769f5bc
./bootstrap-vcpkg.sh
cd ..
```

### 4.3 Install C++ dependencies (macOS, vcpkg)

```bash
./vcpkg/vcpkg install --overlay-triplets=./custom-triplets @./vcpkg.txt --triplet x64-osx_b
```

- `x64-osx_b` is defined in `custom-triplets/x64-osx_b.cmake`.

### 4.4 Configure and build native addon (macOS, CMake)

From repo root:

```bash
mkdir -p build
cd build

cmake \
  -DVCPKG_TARGET_TRIPLET=x64-osx_b \
  -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake \
  -DCMAKE_EXPORT_COMPILE_COMMANDS=ON \
  ../src

cmake --build . --config Release
cd ..
```

This builds `crwrite.node` for macOS and copies it into `UI/app/Backend/crwrite.node`.

### 4.5 Build macOS DMG/zip (Electron)

From repo root:

```bash
cd UI
npm install
npm run release:mac
```

Result:

- DMG and zip files under `UI/dist/` (names controlled by `UI/package.json` and `scripts/crwrite.yml`).

### 4.6 One‑command macOS build

Once vcpkg is cloned + bootstrapped:

```bash
cd "/path/to/crwrite-v1"
chmod +x scripts/build-mac.sh
./scripts/build-mac.sh
```

This runs:

1. `vcpkg install` (x64-osx_b)
2. CMake configure + build
3. `cd UI && npm install && npm run release:mac`

---

## 5. Troubleshooting & Common Errors

### 5.1 `Error: Could not open response file ./vcpkg.txt`

Cause: `vcpkg.txt` missing or you are in the wrong directory.

Fix:

```bash
cd "/path/to/crwrite-v1"
ls vcpkg.txt
```

If the file does not exist, create it with:

```bash
cat > vcpkg.txt << 'EOF'
boost-asio
boost-thread
boost-system
boost-iostreams
boost-filesystem
catch2
jsoncpp
minizip
openssl
spdlog
tiny-process-library
zlib
EOF
```

Then rerun your `vcpkg` command.

### 5.2 `vcpkg` cannot find or install a port

- Ensure you are on commit **769f5bc** in `vcpkg`:
  ```bash
  cd vcpkg
  git checkout 769f5bc
  ```
- Install missing system dev packages suggested by the error, e.g.:
  ```bash
  sudo apt install -y libssl-dev zlib1g-dev
  ```

### 5.3 CMake cannot find Boost / OpenSSL / jsoncpp / etc.

Check that:

- You passed the **toolchain** and **triplet** flags:
  - `-DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake`
  - `-DVCPKG_TARGET_TRIPLET=<your-triplet>`
- You are running CMake from a **clean build folder** on the same OS where vcpkg installed dependencies.

If in doubt, delete the `build` folder and configure again.

### 5.4 Electron or npm errors

- Ensure Node version matches expectations:
  - Windows: Node **10.11.0 32‑bit** (per `BUILD.md`) is safest.
  - Linux/macOS: an LTS Node (like 18) generally works, but if you see Electron/node‑gyp issues, try an older LTS closer to Electron 5.x era.
- Re-run:
  ```bash
  cd UI
  rm -rf node_modules
  npm install
  ```

### 5.5 electron-builder publish errors

Local builds often show errors about GitHub publishing if you do not configure tokens.  
These **do not prevent local installers/AppImages from being created** in `UI/dist/`.  
You can ignore publish failures if you only need local artifacts.

### 5.6 WSL path issues / permissions

- Always work under `/mnt/c/...` when using WSL so the same files are visible in Windows and Linux.
- Quote paths with spaces:
  ```bash
  cd "/mnt/c/Users/Programmer/Desktop/Developments/Side Projects/crwrite-v1"
  ```

---

## 6. Quick Reference

### 6.1 Windows

From `crwrite-v1` (PowerShell):

```powershell
.\vcpkg\vcpkg.exe install --overlay-triplets=custom-triplets '@vcpkg.txt' --triplet x86-windows-static
mkdir build
cd build
cmake -DVCPKG_TARGET_TRIPLET=x86-windows-static -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -A Win32 -DOPENSSL_ROOT_DIR=../vcpkg/installed/x86-windows-static ../src
cmake --build . --config Release
cd ..\UI
npm install
npm run release
```

Or:

```powershell
cd "C:\Users\Programmer\Desktop\Developments\Side Projects\crwrite-v1"
.\scripts\build-windows.ps1
```

### 6.2 Linux (or WSL)

From `crwrite-v1`:

```bash
./vcpkg/vcpkg install --overlay-triplets=./custom-triplets @./vcpkg.txt --triplet x64-linux
mkdir -p build
cd build
cmake -DVCPKG_TARGET_TRIPLET=x64-linux -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ../src
cmake --build . --config Release
cd ../UI
npm install
npm run release:linux
```

Or:

```bash
cd "/path/to/crwrite-v1"
chmod +x scripts/build-linux.sh
./scripts/build-linux.sh
```

### 6.3 macOS

From `crwrite-v1`:

```bash
./vcpkg/vcpkg install --overlay-triplets=./custom-triplets @./vcpkg.txt --triplet x64-osx_b
mkdir -p build
cd build
cmake -DVCPKG_TARGET_TRIPLET=x64-osx_b -DCMAKE_TOOLCHAIN_FILE=../vcpkg/scripts/buildsystems/vcpkg.cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ../src
cmake --build . --config Release
cd ../UI
npm install
npm run release:mac
```

Or:

```bash
cd "/path/to/crwrite-v1"
chmod +x scripts/build-mac.sh
./scripts/build-mac.sh
```

All final executables/installers will be under **`UI/dist/`**.

