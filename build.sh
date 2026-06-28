#!/bin/zsh
# Builds "Periodic Table.app" — a native macOS app bundle, no Xcode project needed.
set -e
cd "$(dirname "$0")"

APP="Periodic Table.app"
BIN="PeriodicTable"
BUNDLE_ID="com.nate.periodictable"

echo "→ Compiling SwiftUI source…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -parse-as-library \
  -framework SwiftUI -framework AppKit \
  PeriodicTable.swift \
  -o "$APP/Contents/MacOS/$BIN"

echo "→ Writing Info.plist…"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>Periodic Table</string>
  <key>CFBundleDisplayName</key><string>Periodic Table</string>
  <key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
  <key>CFBundleVersion</key><string>1.0</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleExecutable</key><string>$BIN</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>LSMinimumSystemVersion</key><string>13.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

# --- Generate a simple app icon (a colored "atom" tile) ---
echo "→ Generating icon…"
ICONSET="$(mktemp -d)/AppIcon.iconset"
mkdir -p "$ICONSET"
SVG="$(mktemp).svg"
cat > "$SVG" <<'SVGEOF'
<svg xmlns="http://www.w3.org/2000/svg" width="1024" height="1024">
  <defs>
    <linearGradient id="g" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stop-color="#5b8def"/><stop offset="1" stop-color="#9b59d0"/>
    </linearGradient>
  </defs>
  <rect width="1024" height="1024" rx="200" fill="url(#g)"/>
  <g fill="none" stroke="#ffffff" stroke-width="26" opacity="0.95">
    <ellipse cx="512" cy="512" rx="360" ry="150"/>
    <ellipse cx="512" cy="512" rx="360" ry="150" transform="rotate(60 512 512)"/>
    <ellipse cx="512" cy="512" rx="360" ry="150" transform="rotate(120 512 512)"/>
  </g>
  <circle cx="512" cy="512" r="70" fill="#ffffff"/>
  <text x="512" y="880" font-family="Helvetica" font-size="150" font-weight="bold"
        fill="#ffffff" text-anchor="middle">Pt</text>
</svg>
SVGEOF

# Rasterize via qlmanage/sips fallback chain. Prefer rsvg/cairosvg if present.
RASTER_OK=0
if command -v rsvg-convert >/dev/null 2>&1; then
  for s in 16 32 64 128 256 512 1024; do rsvg-convert -w $s -h $s "$SVG" -o "$ICONSET/icon_${s}x${s}.png"; done
  RASTER_OK=1
fi
if [ "$RASTER_OK" = "0" ]; then
  # Build a PNG with sips from a solid color as a guaranteed fallback,
  # then create the iconset by scaling.
  BASE="$(mktemp).png"
  # 1024 base: use a python one-liner if available, else a plain colored block.
  if command -v python3 >/dev/null 2>&1; then
    python3 - "$BASE" <<'PY'
import sys
from struct import pack
import zlib
W=H=1024
def px(x,y):
    # gradient blue->purple with a white dot center
    import math
    t=(x+y)/(2*1024)
    r=int(0x5b+(0x9b-0x5b)*t); g=int(0x8d+(0x59-0x8d)*t); b=int(0xef+(0xd0-0xef)*t)
    dx,dy=x-512,y-512
    if dx*dx+dy*dy < 70*70: return (255,255,255)
    return (r,g,b)
raw=bytearray()
for y in range(H):
    raw.append(0)
    for x in range(W):
        raw += bytes(px(x,y))
def chunk(t,d):
    c=t+d; return pack('>I',len(d))+c+pack('>I',zlib.crc32(c)&0xffffffff)
png=b'\x89PNG\r\n\x1a\n'
png+=chunk(b'IHDR',pack('>IIBBBBB',W,H,8,2,0,0,0))
png+=chunk(b'IDAT',zlib.compress(bytes(raw),9))
png+=chunk(b'IEND',b'')
open(sys.argv[1],'wb').write(png)
PY
  else
    BASE=""
  fi
  if [ -n "$BASE" ] && [ -f "$BASE" ]; then
    for s in 16 32 64 128 256 512 1024; do sips -z $s $s "$BASE" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null 2>&1; done
    RASTER_OK=1
  fi
fi

if [ "$RASTER_OK" = "1" ]; then
  # iconutil needs the @2x naming convention; create a minimal valid set.
  cp "$ICONSET/icon_32x32.png"   "$ICONSET/icon_16x16@2x.png"   2>/dev/null || true
  cp "$ICONSET/icon_64x64.png"   "$ICONSET/icon_32x32@2x.png"   2>/dev/null || true
  cp "$ICONSET/icon_256x256.png" "$ICONSET/icon_128x128@2x.png" 2>/dev/null || true
  cp "$ICONSET/icon_512x512.png" "$ICONSET/icon_256x256@2x.png" 2>/dev/null || true
  cp "$ICONSET/icon_1024x1024.png" "$ICONSET/icon_512x512@2x.png" 2>/dev/null || true
  if iconutil -c icns "$ICONSET" -o "$APP/Contents/Resources/AppIcon.icns" 2>/dev/null; then
    echo "  icon embedded."
  else
    echo "  (icon build skipped — app still works)"
  fi
fi

# Ad-hoc codesign so Gatekeeper/Dock treat it as a normal app on this machine.
echo "→ Code signing (ad-hoc)…"
codesign --force --deep --sign - "$APP" 2>/dev/null || echo "  (codesign skipped)"

echo "✓ Built: $APP"
