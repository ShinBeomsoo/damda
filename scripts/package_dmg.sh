#!/bin/bash
set -euo pipefail

# Usage:
#   STAGE=staging BUILD_ID=<optional> VERSION=<optional> ./scripts/package_dmg.sh
#
# Outputs to:
#   dist/<stage>/<version>+<build_id>/damda-<version>+<build_id>-macOS-<arch>.dmg
#   dist/<stage>/<version>+<build_id>/checksums.txt
#   dist/<stage>/<version>+<build_id>/manifest.json
#   dist/<stage>/latest -> dist/<stage>/<version>+<build_id>

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
cd "$ROOT_DIR"

STAGE=${STAGE:-staging}   # dev | staging | prod
APP_PATH=${APP_PATH:-"$ROOT_DIR/build/Build/Products/Release/damda.app"}

if [[ ! -d "$APP_PATH" ]]; then
  echo "Building Release app..."
  xcodebuild -project damda.xcodeproj -scheme damda -configuration Release -destination 'platform=macOS' -derivedDataPath "$ROOT_DIR/build" build | cat
fi

PLIST="$APP_PATH/Contents/Info.plist"
if [[ ! -f "$PLIST" ]]; then
  echo "Info.plist not found at $PLIST" >&2
  exit 1
fi

VERSION=${VERSION:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST" 2>/dev/null || echo 0.0.0)}
GIT_SHA=$(git rev-parse --short HEAD 2>/dev/null || true)
BUILD_ID=${BUILD_ID:-${GIT_SHA:-$(date +%Y%m%d%H%M%S)}}
ARCH=$(uname -m)
TS_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)

OUT_BASE="dist/$STAGE/${VERSION}+${BUILD_ID}"
DMG_NAME="damda-${VERSION}+${BUILD_ID}-macOS-${ARCH}.dmg"
STAGING_DIR="dist/tmp-${STAGE}-${BUILD_ID}"

mkdir -p "$OUT_BASE" "$STAGING_DIR"

# Prepare staging (fresh)
rm -rf "$STAGING_DIR"/* || true
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -sfn /Applications "$STAGING_DIR/Applications"

# Add helper files for unsigned distribution
cat > "$STAGING_DIR/README.txt" <<TXT
damda 설치 안내

1) damda.app을 Applications에 드래그해서 복사하세요.
2) 처음 실행 시 보안 경고가 뜨면 아래 중 하나로 허용하세요.
   - Finder에서 damda.app을 Control-클릭 → "열기" → 확인
   - 또는 터미널에서:
       xattr -dr com.apple.quarantine "/Applications/damda.app"
3) 문제가 있으면 GitHub Releases의 checksums.txt로 무결성을 확인하세요.
TXT

cat > "$STAGING_DIR/Open Me First.command" <<'CMD'
#!/bin/bash
set -e
APP="/Applications/damda.app"
osascript -e 'tell application "Terminal" to activate'
if [ -d "$APP" ]; then
  echo "Removing quarantine attribute from $APP ..."
  xattr -dr com.apple.quarantine "$APP" || true
  echo "Done. Launching app..."
  open -a "$APP"
else
  echo "Please drag damda.app into /Applications first, then re-run this."
  open .
fi
read -n 1 -s -r -p "Press any key to close..."
CMD
chmod +x "$STAGING_DIR/Open Me First.command"

# Create DMG (compressed UDZO)
hdiutil create -volname "damda" -srcfolder "$STAGING_DIR" -ov -format UDZO "$OUT_BASE/$DMG_NAME" | cat

# Checksums
(
  cd "$OUT_BASE"
  shasum -a 256 "$DMG_NAME" > checksums.txt
)

# Manifest
cat > "$OUT_BASE/manifest.json" <<JSON
{
  "name": "damda",
  "stage": "$STAGE",
  "version": "$VERSION",
  "buildId": "$BUILD_ID",
  "arch": "$ARCH",
  "createdAt": "$TS_UTC",
  "git": {
    "commit": "${GIT_SHA:-}"
  },
  "artifacts": {
    "dmg": "$DMG_NAME",
    "checksumSha256File": "checksums.txt"
  }
}
JSON

# Latest symlink for the stage
ln -sfn "$(basename "$OUT_BASE")" "dist/$STAGE/latest"

echo
echo "Artifacts written to: $OUT_BASE"
ls -lh "$OUT_BASE" | cat

# Clean up staging by default; set KEEP_TMP=1 to keep for debugging
if [ "${KEEP_TMP:-0}" != "1" ]; then
  rm -rf "$STAGING_DIR"
fi


