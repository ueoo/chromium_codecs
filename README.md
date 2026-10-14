# chromium_codecs

Weekly macOS arm64 builds of plain Chromium with the proprietary media codecs
(H.264, AAC, HEVC).

The official Chromium snapshots are built with `proprietary_codecs=false`.
That switch is compile-time. This repo builds the revision of the latest
official arm64 snapshot with the GN args of the official snapshot builder
(`mac-arm64-archive-rel`) plus `proprietary_codecs=true ffmpeg_branding="Chrome"`.
No other change: no patches, no Google branding.
