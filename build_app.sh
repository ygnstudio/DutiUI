#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "==> 1/4 Building executable..."
swift build -c release 2>&1 | tail -2

BIN_DIR=$(swift build --show-bin-path -c release)
EXEC="$BIN_DIR/DutiUI"
BUNDLE="$BIN_DIR/DutiUI_DutiUI.bundle"

if [ ! -f "$EXEC" ]; then
    echo "ERROR: Executable not found at $EXEC"
    exit 1
fi
echo "   Binary: $EXEC"

echo "==> 2/4 Generating icon..."
if [ ! -f "AppIcon.icns" ]; then
    swift gen_icon.swift 2>&1 | tail -1
else
    echo "   AppIcon.icns already exists, skipping"
fi

echo "==> 3/4 Creating app bundle..."
APP_DIR="DutiUI.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "$EXEC" "$APP_DIR/Contents/MacOS/DutiUI"
chmod +x "$APP_DIR/Contents/MacOS/DutiUI"

if [ -d "$BUNDLE" ]; then
    cp -R "$BUNDLE" "$APP_DIR/Contents/Resources/"
fi

if [ -f "AppIcon.icns" ]; then
    cp AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"
fi

echo -n 'APPLa' > "$APP_DIR/Contents/PkgInfo"

cat > "$APP_DIR/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>zh-Hans</string>
    <key>CFBundleDisplayName</key>
    <string>DutiUI</string>
    <key>CFBundleExecutable</key>
    <string>DutiUI</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.ygnstudio.DutiUI</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>DutiUI</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST

echo "==> 4/4 Code signing..."
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null

echo ""
echo "============================================"
echo " ✅ DutiUI.app ready: $(pwd)/$APP_DIR"
echo " Size: $(du -sh "$APP_DIR" | cut -f1)"
echo "============================================"
echo ""
echo "Launch: open $(pwd)/$APP_DIR"
