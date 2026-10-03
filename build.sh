#!/usr/bin/env bash
# Builds LifeDots.app. Pass --install to copy it into /Applications and launch it.
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release
BIN="$(swift build -c release --show-bin-path)/LifeDots"

APP="build/LifeDots.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/LifeDots"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>             <string>LifeDots</string>
    <key>CFBundleDisplayName</key>      <string>LifeDots</string>
    <key>CFBundleIdentifier</key>       <string>com.ayush.lifedots</string>
    <key>CFBundleExecutable</key>       <string>LifeDots</string>
    <key>CFBundlePackageType</key>      <string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key>          <string>1</string>
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
