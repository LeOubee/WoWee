#!/usr/bin/env bash
# Builds OpenSSL for iOS arm64 (static), the one dependency CMake cannot fetch.
#   tools/build-ios-deps.sh      -> build-ios-deps/arm64
# Pass -DOPENSSL_ROOT_DIR=<that folder> to the iOS CMake configure.
set -euo pipefail
OPENSSL_VERSION="${OPENSSL_VERSION:-3.5.1}"
MIN_IOS="${MIN_IOS:-16.0}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WORK="$ROOT/build-ios-deps"; PREFIX="$WORK/arm64"
mkdir -p "$WORK"
if [ -f "$PREFIX/lib/libcrypto.a" ]; then echo "OpenSSL already built: $PREFIX"; exit 0; fi
TARBALL="$WORK/openssl-$OPENSSL_VERSION.tar.gz"; SRC="$WORK/openssl-$OPENSSL_VERSION"
[ -f "$TARBALL" ] || curl -fL --retry 3 -o "$TARBALL" \
  "https://github.com/openssl/openssl/releases/download/openssl-$OPENSSL_VERSION/openssl-$OPENSSL_VERSION.tar.gz"
[ -d "$SRC" ] || tar -xzf "$TARBALL" -C "$WORK"
export CROSS_TOP="$(xcrun --sdk iphoneos --show-sdk-platform-path)/Developer"
export CROSS_SDK="$(basename "$(xcrun --sdk iphoneos --show-sdk-path)")"
(cd "$SRC" && ./Configure ios64-xcrun no-shared no-tests no-apps no-asm \
    -mios-version-min="$MIN_IOS" --prefix="$PREFIX" --openssldir="$PREFIX/ssl")
make -C "$SRC" -j"$(sysctl -n hw.ncpu)"
make -C "$SRC" install_sw
echo "OpenSSL built: $PREFIX"
