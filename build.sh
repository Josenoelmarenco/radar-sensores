#!/bin/bash
# Builds "Radar de sensores.app" from this folder. Run: bash build.sh
set -euo pipefail
cd "$(dirname "$0")"
APP="$HOME/Applications/Radar de sensores.app"
swiftc -O -target arm64-apple-macos13.0 main.swift -o RadarSensores -framework Cocoa -framework WebKit
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
mv RadarSensores "$APP/Contents/MacOS/RadarSensores"
cp index.html catalogo.json LEEME.md validar.py "$APP/Contents/Resources/"
ICONSET="$(mktemp -d)/AppIcon.iconset"; mkdir -p "$ICONSET"
for s in 16 32 128 256 512; do
  sips -z $s $s icon1024.png --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) icon1024.png --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Radar de sensores</string>
  <key>CFBundleDisplayName</key><string>Radar de sensores</string>
  <key>CFBundleIdentifier</key><string>com.josenoel.radarsensores</string>
  <key>CFBundleExecutable</key><string>RadarSensores</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundleDevelopmentRegion</key><string>es</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.developer-tools</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHumanReadableCopyright</key><string>Hecho para José Noel · catálogo curado con Claude</string>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
echo "OK: $APP"
