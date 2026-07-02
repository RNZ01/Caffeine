#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
APP="$ROOT/build/Caffeine.app"
ARCH="${ARCH:-$(uname -m)}"
DMG="$ROOT/build/Caffeine-1.0-$ARCH.dmg"
PLIST="$APP/Contents/Info.plist"

assert_eq() {
  local expected="$1" actual="$2" label="$3"
  [[ "$actual" == "$expected" ]] || { echo "$label: expected '$expected', got '$actual'" >&2; exit 1; }
}

bash -n "$ROOT/build.sh"
MACOSX_DEPLOYMENT_TARGET=11.0 swiftc "$ROOT/Sources/Caffeine/main.swift" -typecheck -framework AppKit
ARCH="$ARCH" "$ROOT/build.sh" >/tmp/caffeine-build.log

[[ -x "$APP/Contents/MacOS/Caffeine" ]] || { echo "missing executable" >&2; exit 1; }
[[ -f "$APP/Contents/Resources/AppIcon.icns" ]] || { echo "missing app icon" >&2; exit 1; }
[[ -f "$DMG" ]] || { echo "missing DMG" >&2; exit 1; }
[[ -f "$DMG.sha256" ]] || { echo "missing checksum" >&2; exit 1; }

plutil -lint "$PLIST" >/dev/null
assert_eq "local.caffeine" "$(plutil -extract CFBundleIdentifier raw "$PLIST")" "bundle id"
assert_eq "1.0" "$(plutil -extract CFBundleShortVersionString raw "$PLIST")" "version"
assert_eq "11.0" "$(plutil -extract LSMinimumSystemVersion raw "$PLIST")" "minimum macOS"
assert_eq "true" "$(plutil -extract LSUIElement raw "$PLIST")" "menu bar mode"
file "$APP/Contents/MacOS/Caffeine" | grep -q "$ARCH" || { echo "wrong executable architecture" >&2; exit 1; }

codesign --verify --deep --strict "$APP"
hdiutil imageinfo "$DMG" >/dev/null
(cd "$(dirname "$DMG")" && shasum -a 256 -c "$(basename "$DMG").sha256") >/dev/null
MOUNT="$(mktemp -d /tmp/caffeine-dmg.XXXX)"
hdiutil attach "$DMG" -mountpoint "$MOUNT" -nobrowse -quiet >/dev/null
trap 'hdiutil detach "$MOUNT" -quiet 2>/dev/null || true; rmdir "$MOUNT" 2>/dev/null || true' EXIT
[[ -d "$MOUNT/Caffeine.app" ]] || { echo "DMG missing app" >&2; exit 1; }
[[ "$(readlink "$MOUNT/Applications")" == "/Applications" ]] || { echo "DMG missing Applications shortcut" >&2; exit 1; }
hdiutil detach "$MOUNT" -quiet
trap - EXIT
rmdir "$MOUNT"

echo "Tests passed"
