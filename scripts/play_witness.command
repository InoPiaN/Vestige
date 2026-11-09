#!/bin/sh
set -eu
folder=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ ! -d "$folder/Vestige-0.4.4.app" ]; then folder="$folder/../builds"; fi
exec "$folder/Vestige-0.4.4.app/Contents/MacOS/Vestige" -- --witness-demo
