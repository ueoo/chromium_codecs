#!/usr/bin/env bash
# build.sh — build Chromium for macOS arm64 with the proprietary media codecs.
#
#   ./build.sh fetch <sha>     depot_tools + shallow checkout of chromium/src at <sha>
#                              + patches/*.patch + gn gen
#   ./build.sh build [min]     build the "chrome" target; with [min], stop after that many
#                              minutes and exit with 124 (run "build" again to continue)
#   ./build.sh package <zip>   zip out/Release/Chromium.app
#   ./build.sh pack <file>     archive the work directory (source + build state)
#   ./build.sh unpack <file>   restore it; the work directory must have the same path
#
# The work directory is $ROOT (default: ./work). It grows to about 55 GB.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="${ROOT:-$PWD/work}"
# keep the depot_tools state inside the work directory
export PATH="$ROOT/depot_tools:$PATH" DEPOT_TOOLS_METRICS=0 VPYTHON_VIRTUALENV_ROOT="$ROOT/.vpython-root"

case "${1:-}" in
fetch)
  mkdir -p "$ROOT" && cd "$ROOT"
  [[ -d depot_tools ]] || git clone -q https://chromium.googlesource.com/chromium/tools/depot_tools.git
  [[ -f .gclient ]] || gclient config --unmanaged --name src https://chromium.googlesource.com/chromium/src.git
  gclient sync --no-history --revision "src@$2"
  # A patch that no longer applies stops the build here, before the long compile.
  for p in "$HERE"/patches/*.patch; do git -C src apply "$p"; done
  # The build does not use the git data (about 4 GB). Remove it before gn gen,
  # as in a source tarball, so that the state archive is smaller.
  find src -name .git -prune -exec rm -rf {} +
  cd src
  # GN args of the official snapshot builder (mac-arm64-archive-rel), without
  # remote execution, plus the two codec args. symbol_level=0 and
  # treat_warnings_as_errors=false only make the build shorter and more
  # tolerant; they do not change the browser.
  gn gen out/Release --args='
    is_debug=false is_component_build=false dcheck_always_on=false enable_stripping=true
    target_cpu="arm64" symbol_level=0 treat_warnings_as_errors=false
    proprietary_codecs=true ffmpeg_branding="Chrome"'
  ;;
build)
  cd "$ROOT/src"
  if [[ -n "${2:-}" ]]; then
    # coreutils timeout signals the whole process group. 124 = the time is up.
    exec gtimeout -s INT -k 5m "${2}m" autoninja -C out/Release chrome
  fi
  exec autoninja -C out/Release chrome
  ;;
package)
  # no extended attributes: ditto stores them as ._* files, which unzip
  # extracts as real files, and codesign then rejects the bundle
  ditto -c -k --norsrc --noextattr --keepParent "$ROOT/src/out/Release/Chromium.app" "$2"
  ;;
pack)
  # pax keeps the file times with full precision; the build tool compares them
  tar --format pax --no-mac-metadata --no-xattrs -C "${ROOT%/*}" -cf - "${ROOT##*/}" | zstd -q -T0 -3 -o "$2"
  ;;
unpack)
  zstd -dc "$2" | tar -C "${ROOT%/*}" -xf -
  ;;
*)
  sed -n '2,12p' "$0"
  exit 2
  ;;
esac
