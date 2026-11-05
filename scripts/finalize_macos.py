"""Normalize generated executable/resource names, then ad-hoc sign the local app.

Usage: python3 scripts/finalize_macos.py builds/Vestige-0.2.1.app
The display name remains Korean. ASCII file names avoid resource-seal failures
observed with the exported Unicode executable/PCK names on this Mac.
"""
from pathlib import Path
import plistlib
import subprocess
import sys

bundle = Path(sys.argv[1]).resolve()
if bundle.suffix != '.app' or not (bundle / 'Contents/Info.plist').is_file():
    raise SystemExit('Expected a generated .app bundle')
contents = bundle / 'Contents'
plist_path = contents / 'Info.plist'
info = plistlib.loads(plist_path.read_bytes())
old_name = info['CFBundleExecutable']
if old_name != 'Vestige':
    for folder, suffix in [('MacOS', ''), ('Resources', '.pck')]:
        source = contents / folder / (old_name + suffix)
        target = contents / folder / ('Vestige' + suffix)
        if not source.is_file() or target.exists():
            raise SystemExit(f'Unexpected bundle layout: {source}')
    (contents / 'MacOS' / old_name).rename(contents / 'MacOS/Vestige')
    (contents / 'Resources' / (old_name + '.pck')).rename(contents / 'Resources/Vestige.pck')
    info['CFBundleExecutable'] = 'Vestige'
    plist_path.write_bytes(plistlib.dumps(info))
subprocess.run(['codesign', '--force', '--deep', '--sign', '-', str(bundle)], check=True)
subprocess.run(['codesign', '--verify', '--deep', '--strict', str(bundle)], check=True)
