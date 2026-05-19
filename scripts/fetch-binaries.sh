#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

case "$(uname -s)-$(uname -m)" in
  Darwin-arm64) PLATFORM="darwin-arm64" ;;
  Darwin-x86_64) PLATFORM="darwin-x64" ;;
  *) echo "Unsupported platform: $(uname -s)-$(uname -m)"; exit 1 ;;
esac

BIN_DIR="$ROOT/helper/bin/$PLATFORM"
mkdir -p "$BIN_DIR"

echo "==> Target: $BIN_DIR"

# --- yt-dlp -----------------------------------------------------------------
if [[ ! -x "$BIN_DIR/yt-dlp" ]]; then
  echo "==> Downloading yt-dlp..."
  if [[ "$PLATFORM" == "darwin-arm64" || "$PLATFORM" == "darwin-x64" ]]; then
    URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_macos"
  fi
  curl -L --fail -o "$BIN_DIR/yt-dlp" "$URL"
  chmod +x "$BIN_DIR/yt-dlp"
else
  echo "==> yt-dlp already present, skipping"
fi

# --- ffmpeg -----------------------------------------------------------------
if [[ ! -x "$BIN_DIR/ffmpeg" ]]; then
  echo "==> Downloading ffmpeg (static build from evermeet.cx)..."
  TMP="$(mktemp -d)"
  curl -L --fail -o "$TMP/ffmpeg.zip" "https://evermeet.cx/ffmpeg/getrelease/zip"
  unzip -q "$TMP/ffmpeg.zip" -d "$TMP"
  mv "$TMP/ffmpeg" "$BIN_DIR/ffmpeg"
  chmod +x "$BIN_DIR/ffmpeg"
  rm -rf "$TMP"
else
  echo "==> ffmpeg already present, skipping"
fi

echo ""
echo "==> Done. Binaries in $BIN_DIR:"
ls -lh "$BIN_DIR"
echo ""
"$BIN_DIR/yt-dlp" --version | sed 's/^/    yt-dlp: /'
"$BIN_DIR/ffmpeg" -version | head -1 | sed 's/^/    ffmpeg: /'
