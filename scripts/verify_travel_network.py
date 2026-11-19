"""Run isolated local ENet fixture/server/client; never opens user worlds."""
from pathlib import Path
import subprocess, tempfile, time
ROOT = Path(__file__).resolve().parents[1]
GODOT = ROOT / '.tools/godot/Godot.app/Contents/MacOS/Godot'
BASE = [str(GODOT), '--headless', '--path', str(ROOT / 'desktop')]
with tempfile.TemporaryDirectory(prefix='vestige-travel-enet-') as directory:
    work = Path(directory)
    fixture = work / 'world.json'
    subprocess.run(BASE + ['--script', 'tests/network_travel.gd', '--log-file', str(work/'fixture.log'), '--', '--fixture='+str(fixture)], check=True, timeout=30)
    with (work/'server-output.log').open('w') as log:
        server = subprocess.Popen(BASE + ['--log-file', str(work/'server.log'), '--', '--server', '--world-file='+str(fixture)], stdout=log, stderr=subprocess.STDOUT)
        try:
            time.sleep(1)
            if server.poll() is not None:
                raise RuntimeError((work/'server-output.log').read_text())
            result = subprocess.run(BASE + ['--script', 'tests/network_travel.gd', '--log-file', str(work/'client.log')], capture_output=True, text=True, timeout=110)
            print(result.stdout, end='')
            print(result.stderr, end='')
            if result.returncode or 'SCRIPT ERROR' in result.stdout+result.stderr or 'PASS: ENet' not in result.stdout:
                raise RuntimeError('ENet travel verification failed')
        finally:
            server.terminate()
            try: server.wait(timeout=5)
            except subprocess.TimeoutExpired:
                server.kill()
                server.wait()
