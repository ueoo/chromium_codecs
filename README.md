# chromium_codecs

Weekly macOS arm64 builds of plain Chromium with the proprietary media codecs
(H.264, AAC, HEVC).

The official Chromium snapshots are built with `proprietary_codecs=false`.
That switch is compile-time. This repo builds the revision of the latest
official arm64 snapshot with the GN args of the official snapshot builder
(`mac-arm64-archive-rel`) plus `proprietary_codecs=true ffmpeg_branding="Chrome"`.
No other change: no patches, no Google branding.

## Download

The newest build: <https://github.com/ueoo/chromium_codecs/releases/latest/download/Chromium-arm64.zip>

The app has an ad-hoc signature only. A download with `curl` gets no
quarantine flag, so the app starts without a Gatekeeper prompt.

## How the build works

`build.sh` holds all build steps. It also runs on a local Mac:

```sh
./build.sh fetch <sha>   # depot_tools + shallow checkout of chromium/src + gn gen
./build.sh build         # about 75 minutes on an M3 Max
./build.sh package Chromium-arm64.zip
```

`.github/workflows/build.yml` runs every Saturday on the free GitHub-hosted
runner (3 cores, 7 GB RAM). One job can run for 6 hours, and the build needs
more. The workflow is a chain of stages (`stage.yml`): each stage builds until
its time is up, and hands the work directory to the next stage as an artifact.
The last stage uploads `Chromium-arm64.zip`, and the `release` job publishes
it. The 4 newest releases are kept.

Start a build by hand: Actions → build → Run workflow. The `rev` input selects
a snapshot revision; the default is the latest one.
