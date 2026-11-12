#!/bin/sh
set -eu
folder=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -d "$folder/Vestige-0.5.9.app" ]; then folder="$folder/../builds"; fi
exec "$folder/Vestige-0.5.9.app/Contents/MacOS/Vestige" -- --detail-demo
