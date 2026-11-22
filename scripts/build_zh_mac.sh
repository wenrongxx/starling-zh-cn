#!/usr/bin/env bash
# 在 macOS（Apple Silicon）上编译 Starling 中文版游戏库
# 用法：把整个 starling_src2/starling-starling 目录拷到 Mac，在本目录执行 bash build_zh_mac.sh
set -euo pipefail

# 1) Rust（国内镜像；有 rustup 可跳过）
if ! command -v cargo >/dev/null 2>&1; then
  curl -sSf https://sh.rustup.rs | sh -s -- -y --profile minimal --default-toolchain stable
  . "$HOME/.cargo/env"
fi
export RUSTUP_DIST_SERVER=https://mirrors.tuna.tsinghua.edu.cn/rustup
rustup target add aarch64-linux-android
rustup component add rust-src

# 2) NDK（macOS 版，约 750MB）
NDK_DIR="${ANDROID_NDK_HOME:-$HOME/android-ndk-r27c}"
if [ ! -d "$NDK_DIR" ]; then
  curl -L -o ndk.zip https://dl.google.com/android/repository/android-ndk-r27c-darwin.zip
  unzip -q ndk.zip && mv android-ndk-r27c "$NDK_DIR"
fi
export ANDROID_NDK_HOME="$NDK_DIR"
BIN="$NDK_DIR/toolchains/llvm/prebuilt/darwin-x86_64/bin"
[ -x "$BIN/aarch64-linux-android26-clang" ] || BIN="$NDK_DIR/toolchains/llvm/prebuilt/darwin-arm64/bin"

RT=$(ls "$NDK_DIR"/toolchains/llvm/prebuilt/darwin-*/lib/clang/*/lib/linux/libclang_rt.builtins-aarch64-android.a | tail -1)

# 3) 编译
export CARGO_TARGET_AARCH64_LINUX_ANDROID_LINKER="$BIN/aarch64-linux-android26-clang"
export CC_aarch64_linux_android="$BIN/aarch64-linux-android26-clang"
export CXX_aarch64_linux_android="$BIN/aarch64-linux-android26-clang++"
export AR_aarch64_linux_android="$BIN/llvm-ar"
export RUSTC_BOOTSTRAP=1
export CARGO_INCREMENTAL=0
export RUSTFLAGS="-C link-arg=-Wl,-z,max-page-size=16384 -C link-arg=-Wl,--build-id=sha1 -Z has-thread-local=yes -C link-arg=$RT"

cargo build --target aarch64-linux-android -Zbuild-std=std,panic_unwind --profile fast -p horizon-android

echo
echo "产物： target/aarch64-linux-android/fast/libhorizon_android.so"
echo "拷回 Windows 后重命名为 libhorizon_mod_host.so 塞进 APK 即可。"
