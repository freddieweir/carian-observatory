#!/usr/bin/env bash
# Turn a screen recording into the two demo assets a PR needs and host them on a
# prerelease tag, the way tracksplit PR #1 did. Prints the markdown to paste into
# the PR's "## Demo" section.
#
#   scripts/publish-demo.sh <pr-number> <recording.(mp4|mov|webm|gif)> [asset-name]
#
# Needs ffmpeg and gh (authenticated; igris wraps it with a hardware tap).
# Re-running replaces the assets on the same tag. The tag is a prerelease named
# demo-pr-<N>, marked "Not a software release", so it never shows up as a version.
#
# Redact BEFORE recording: names, titles, hosts, paths, serials. A GIF cannot be
# un-published from the browser cache of everyone who opened the PR.
set -euo pipefail

usage() { sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 2; }
[ $# -ge 2 ] || usage
command -v ffmpeg >/dev/null || { echo "ffmpeg not found (brew install ffmpeg)" >&2; exit 1; }
command -v gh >/dev/null || { echo "gh not found (brew install gh)" >&2; exit 1; }

PR="$1"; IN="$2"
REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
NAME="${3:-${REPO##*/}-demo}"
TAG="demo-pr-${PR}"
FPS="${DEMO_FPS:-10}"       # GIF frame rate; 10 keeps a terminal demo under ~1 MB/min
WIDTH="${DEMO_WIDTH:-960}"  # output width in px; height follows the source aspect
OUT="${DEMO_OUT:-$(mktemp -d)}"
GIF="$OUT/$NAME.gif"; MP4="$OUT/$NAME.mp4"

case "${IN,,}" in
  *.gif)
    cp "$IN" "$GIF"
    # mp4 from a GIF: even dimensions are required by yuv420p
    ffmpeg -loglevel error -y -i "$IN" -movflags faststart -pix_fmt yuv420p \
      -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" "$MP4" ;;
  *)
    ffmpeg -loglevel error -y -i "$IN" -movflags faststart -pix_fmt yuv420p -an \
      -vf "scale=${WIDTH}:-2" -c:v libx264 -crf 23 -preset veryslow "$MP4"
    # two-pass palette GIF: far smaller and cleaner than a one-pass convert
    ffmpeg -loglevel error -y -i "$MP4" \
      -filter_complex "[0:v]fps=${FPS},scale=${WIDTH}:-1:flags=lanczos,split[a][b];[a]palettegen=stats_mode=diff[p];[b][p]paletteuse=dither=bayer:bayer_scale=5:diff_mode=rectangle" \
      "$GIF" ;;
esac

printf 'gif %s\nmp4 %s\n' "$(du -h "$GIF" | cut -f1)" "$(du -h "$MP4" | cut -f1)" >&2

if ! gh release view "$TAG" >/dev/null 2>&1; then
  gh release create "$TAG" --prerelease --title "Demo for PR #${PR}" \
    --notes "Terminal demo for PR #${PR}, redacted on screen. Not a software release." >/dev/null
fi
gh release upload "$TAG" "$GIF" "$MP4" --clobber >/dev/null

BASE="https://github.com/${REPO}/releases/download/${TAG}"
cat <<MD

Paste into the PR's "## Demo" section:

![${NAME}](${BASE}/${NAME}.gif)

_[mp4 with player controls](${BASE}/${NAME}.mp4)_

_<caption: what happens on screen, and what was redacted>_
MD
