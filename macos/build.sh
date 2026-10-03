#!/usr/bin/env bash
# Builds LifeDots.app. Pass --install to copy it into /Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")"

# UNIVERSAL=1 builds for Apple Silicon and Intel (used by the release workflow).
# VERSION / BUILD_NUMBER set the app's version (defaults: 1.0 / 1).
VERSION="${VERSION:-1.0}"
BUILD_NUMBER="${BUILD_NUMBER:-1}"

if [[ "${UNIVERSAL:-0}" == "1" ]]; then
    BINS=()
    for ARCH in arm64 x86_64; do
        swift build -c release --arch "$ARCH"
        BINS+=("$(swift build -c release --arch "$ARCH" --show-bin-path)/LifeDots")
    done
    mkdir -p build
    lipo -create "${BINS[@]}" -output build/LifeDots-universal
    BIN="build/LifeDots-universal"
else
    swift build -c release
    BIN="$(swift build -c release --show-bin-path)/LifeDots"
fi

APP="build/LifeDots.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/LifeDots"

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>             <string>LifeDots</string>
    <key>CFBundleDisplayName</key>      <string>LifeDots</string>
    <key>CFBundleIdentifier</key>       <string>io.github.ayush3401.lifedots</string>
    <key>CFBundleExecutable</key>       <string>LifeDots</string>
    <key>CFBundlePackageType</key>      <string>APPL</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>CFBundleVersion</key>          <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>   <string>13.0</string>
    <key>LSUIElement</key>              <true/>
    <key>NSHighResolutionCapable</key>  <true/>
</dict>
</plist>
PLIST

# Ad-hoc signature so macOS will run it locally and allow Launch at Login.
codesign --force --deep --sign - "$APP"
echo "Built $APP"

if [[ "${1:-}" == "--install" ]]; then
    # /Applications needs admin rights on many (e.g. managed) Macs; fall back to
    # the per-user ~/Applications, which works the same, Launch at Login included.
    DEST="/Applications"
    if [[ ! -w "$DEST" ]] || { [[ -e "$DEST/LifeDots.app" ]] && [[ ! -w "$DEST/LifeDots.app" ]]; }; then
        DEST="$HOME/Applications"
        mkdir -p "$DEST"
    fi
    pkill -x LifeDots 2>/dev/null || true
    rm -rf "$DEST/LifeDots.app"
    cp -R "$APP" "$DEST/"
    open "$DEST/LifeDots.app"
    echo "Installed and launched $DEST/LifeDots.app"
fi
