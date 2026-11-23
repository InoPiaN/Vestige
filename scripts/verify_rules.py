"""Run Godot rules with per-run logs and per-process synthetic save directories."""
import os
import pathlib
import subprocess
import sys
import tempfile

root = pathlib.Path(__file__).resolve().parents[1]
godot = os.environ.get('GODOT_BIN') or str(root / '.tools/godot/Godot.app/Contents/MacOS/Godot')
run_dir = pathlib.Path(tempfile.mkdtemp(prefix='vestige-rules-'))
env = os.environ.copy()
env['VESTIGE_TEST_ROOT'] = str(run_dir)
fail = []
count = 0
print('ARTIFACTS', run_dir, flush=True)
for script in sorted((root / 'desktop/tests').glob('test_*.gd')):
    try:
        result = subprocess.run(
            [godot, '--headless', '--path', 'desktop', '--script', 'tests/' + script.name,
             '--log-file', str(run_dir / (script.stem + '.godot.log'))],
            cwd=root, env=env, capture_output=True, text=True, timeout=40)
        output = result.stdout + result.stderr
        (run_dir / (script.stem + '.txt')).write_text(output)
        passed = output.count('PASS:')
        count += passed
        bad = result.returncode != 0 or 'SCRIPT ERROR' in output
        print(script.name, passed, 'FAIL' if bad else 'OK', flush=True)
        if bad:
            fail.append(script.name)
            print(output, flush=True)
    except subprocess.TimeoutExpired as exc:
        # Preserve output even when a script never reaches quit().
        output = (exc.stdout or b'') + (exc.stderr or b'')
        (run_dir / (script.stem + '.txt')).write_bytes(output)
        fail.append(script.name)
        print('TIMEOUT', script.name, flush=True)
print('TOTAL', count, 'FAILURES', fail, flush=True)
sys.exit(bool(fail))
