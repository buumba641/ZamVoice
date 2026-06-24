#!/usr/bin/env bash
# build_whisper.sh — Download whisper.cpp and cross-compile libwhisper_bridge.so
#                     for Android arm64-v8a using the local NDK.
#
# Usage:  ./scripts/build_whisper.sh
# Output: android/app/src/main/jniLibs/arm64-v8a/libwhisper_bridge.so
set -euo pipefail

WHISPER_TAG="v1.7.4"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
NATIVE_DIR="$PROJECT_DIR/native"
BUILD_DIR="$PROJECT_DIR/_whisper_build"
OUTPUT_DIR="$PROJECT_DIR/android/app/src/main/jniLibs/arm64-v8a"

# ----- Locate SDK tools -----
NDK_PATH="${ANDROID_NDK_HOME:-$HOME/Android/Sdk/ndk/29.0.13113456}"
# Try the SDK-bundled cmake first, fall back to system cmake.
if [ -x "$HOME/Android/Sdk/cmake/3.22.1/bin/cmake" ]; then
    CMAKE="$HOME/Android/Sdk/cmake/3.22.1/bin/cmake"
else
    CMAKE="cmake"
fi

echo "=== whisper.cpp Android build ==="
echo "Tag:       $WHISPER_TAG"
echo "NDK:       $NDK_PATH"
echo "CMake:     $CMAKE"
echo "Output:    $OUTPUT_DIR"
echo ""

# ----- Download -----
mkdir -p "$BUILD_DIR"
TARBALL="$BUILD_DIR/whisper.tar.gz"
if [ ! -f "$TARBALL" ]; then
    echo ">>> Downloading whisper.cpp $WHISPER_TAG ..."
    curl -L --progress-bar \
        "https://github.com/ggml-org/whisper.cpp/archive/refs/tags/${WHISPER_TAG}.tar.gz" \
        -o "$TARBALL"
fi

TARBALL_SIZE=$(du -sh "$TARBALL" | cut -f1)
echo ">>> Tarball size: $TARBALL_SIZE"

# ----- Extract -----
echo ">>> Extracting ..."
cd "$BUILD_DIR"
tar xf whisper.tar.gz
WHISPER_SRC="$BUILD_DIR/whisper.cpp-${WHISPER_TAG#v}"

if [ ! -d "$WHISPER_SRC" ]; then
    echo "ERROR: Expected source directory $WHISPER_SRC not found."
    echo "       Contents of $BUILD_DIR:"
    ls "$BUILD_DIR"
    exit 1
fi

# ----- Configure -----
echo ">>> Configuring CMake ..."
"$CMAKE" \
    -S "$NATIVE_DIR" \
    -B "$BUILD_DIR/build" \
    -DCMAKE_TOOLCHAIN_FILE="$NDK_PATH/build/cmake/android.toolchain.cmake" \
    -DANDROID_ABI=arm64-v8a \
    -DANDROID_PLATFORM=android-24 \
    -DCMAKE_BUILD_TYPE=Release \
    -DWHISPER_SRC_DIR="$WHISPER_SRC"

# ----- Build -----
NPROC=$(nproc 2>/dev/null || echo 2)
echo ">>> Building with $NPROC threads ..."
"$CMAKE" --build "$BUILD_DIR/build" --config Release -j"$NPROC"

# ----- Install -----
echo ">>> Installing libwhisper_bridge.so ..."
mkdir -p "$OUTPUT_DIR"
cp "$BUILD_DIR/build/libwhisper_bridge.so" "$OUTPUT_DIR/libwhisper_bridge.so"
SO_SIZE=$(du -sh "$OUTPUT_DIR/libwhisper_bridge.so" | cut -f1)
echo ">>> Installed: $OUTPUT_DIR/libwhisper_bridge.so ($SO_SIZE)"

# ----- Cleanup -----
echo ">>> Cleaning build directory ..."
rm -rf "$BUILD_DIR"

echo ""
echo "=== Done! ==="
echo "libwhisper_bridge.so is ready at:"
echo "  $OUTPUT_DIR/libwhisper_bridge.so"
