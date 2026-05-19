#!/usr/bin/env bash
# Fetch a sample worship song + subtitle for the Phase 0 prototype.
#
# WHY THIS IS A SEPARATE SCRIPT (and the audio is NOT in the repo):
#   The default sample is "禱告的力量 (The Power of Prayer)" by 讚美之泉
#   (Stream of Praise Music Ministries) — a copyrighted recording under
#   Standard YouTube License. CCLI covers live church performance but does
#   NOT cover redistributing the official recording. We therefore download
#   it on-demand to each user's machine (personal use) and never commit
#   it to git.
#
# To use your own song instead:
#   ./scripts/fetch-sample.sh "https://www.youtube.com/watch?v=YOUR_VIDEO_ID"
#
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
URL="${1:-https://www.youtube.com/watch?v=AfWZ-1taIfw}"
SUB_LANG="${SUB_LANG:-en-US}"

case "$(uname -s)-$(uname -m)" in
  Darwin-*) PLATFORM="darwin-arm64" ;;
  Linux-*)  PLATFORM="linux-x64" ;;
  *) echo "Unsupported platform"; exit 1 ;;
esac

YTDLP="$ROOT/helper/bin/$PLATFORM/yt-dlp"
FFMPEG="$ROOT/helper/bin/$PLATFORM/ffmpeg"

if [[ ! -x "$YTDLP" || ! -x "$FFMPEG" ]]; then
  echo "yt-dlp/ffmpeg not found. Run ./scripts/fetch-binaries.sh first."
  exit 1
fi

mkdir -p "$ROOT/test"

echo "==> Source: $URL"
echo "==> Downloading audio + subtitle ($SUB_LANG)..."

"$YTDLP" \
  --ffmpeg-location "$FFMPEG" \
  -x --audio-format mp3 --audio-quality 0 \
  --write-sub --sub-lang "$SUB_LANG" --sub-format vtt \
  -o "$ROOT/test/song.%(ext)s" \
  "$URL"

echo ""
echo "==> Done:"
ls -lh "$ROOT/test/" | grep -E "song\."
echo ""
echo "Next: cd test && python3 -m http.server 8765"
echo "Then open: http://localhost:8765/player.html"
