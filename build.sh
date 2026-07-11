#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="AtollCodexUsage"
APP_DIR="build/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"

swift build -c release --product "$APP_NAME"

rm -rf "$APP_DIR"
mkdir -p "$CONTENTS/MacOS"
cp Resources/Info.plist "$CONTENTS/Info.plist"
cp ".build/release/$APP_NAME" "$CONTENTS/MacOS/$APP_NAME"
codesign --force --sign - --timestamp=none "$APP_DIR"

echo "Built $APP_DIR"
