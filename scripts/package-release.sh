#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="AtollCodexUsage"
VERSION="${1:-}"
ARCH="${2:-$(uname -m)}"
NATIVE_ARCH="$(uname -m)"
RELEASE_DIR="build/release"
APP_DIR="build/$APP_NAME.app"
ARCHIVE="$RELEASE_DIR/$APP_NAME-v$VERSION-macOS-$ARCH.zip"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]; then
    echo "Usage: $0 <version> [architecture]" >&2
    echo "Example: $0 0.1.0 arm64" >&2
    exit 1
fi

if [[ "$ARCH" != "$NATIVE_ARCH" ]]; then
    echo "Requested architecture $ARCH does not match runner architecture $NATIVE_ARCH" >&2
    exit 1
fi

swift run AtollCodexUsageCoreTests
bash build.sh

plutil -replace CFBundleShortVersionString -string "$VERSION" "$APP_DIR/Contents/Info.plist"
codesign --force --sign - --timestamp=none "$APP_DIR"

mkdir -p "$RELEASE_DIR"
rm -f "$ARCHIVE" "$ARCHIVE.sha256"
ditto -c -k --sequesterRsrc --keepParent "$APP_DIR" "$ARCHIVE"

(
    cd "$RELEASE_DIR"
    shasum -a 256 "$(basename "$ARCHIVE")" > "$(basename "$ARCHIVE").sha256"
)

echo "Packaged $ARCHIVE"
echo "Checksum $ARCHIVE.sha256"
