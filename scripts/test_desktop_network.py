"""Run isolated ENet regression + dialogue clients, then restart the saved server."""
import json
import pathlib
import subprocess
import tempfile
import time

ROOT = pathlib.Path(__file__).resolve().parents[1]
GODOT = ROOT / ".tools/godot/Godot.app/Contents/MacOS/Godot"
BASE = [str(GODOT), "--headless", "--path", str(ROOT / "desktop")]


def clients(script, args):
    processes = [subprocess.Popen(BASE + ["--script", f"res://tests/{script}.gd", "--"] + a,
                                  stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True) for a in args]
    try:
        for p in processes:
            output, _ = p.communicate(timeout=50)
            print(output, end="")
            if p.returncode or "SCRIPT ERROR" in output or "ERROR:" in output:
                raise RuntimeError(f"{script} failed: {p.returncode}")
    finally:
        for p in processes:
            if p.poll() is None:
                p.kill()
                p.wait()


def start_server(path, log):
    p = subprocess.Popen(BASE + ["--", "--server", f"--world-file={path}"], stdout=log, stderr=log)
    for _ in range(100):
        if p.poll() is not None:
            raise RuntimeError("Server failed to start:\n" + pathlib.Path(log.name).read_text())
        log.flush()
        if "Vestige server ready" in pathlib.Path(log.name).read_text():
            return p
        time.sleep(0.05)
    p.kill()
    p.wait()
    raise RuntimeError("Server start timed out")


def stop(p):
    p.terminate()
    p.wait(timeout=5)


with tempfile.TemporaryDirectory(prefix="vestige-dialogue-net-") as tmp:
    folder = pathlib.Path(tmp)
    world = folder / "world.json"
    tokens = [["--token=" + char * 48] for char in ("a", "b")]
    investigators = [["--token=" + char * 48] for char in ("c", "d")]
    # Controlled defeated-wolf fixture; combat and live-wolf gating are tested in rules.
    world.write_text(json.dumps({"version": 1, "time": 0.0, "saved": time.time(),
        "people": {}, "graves": [], "books": [],
        "wolf": {"x": 25.0, "y": 10.0, "hp": 0, "cooldown": 0.0, "warning": 0.0, "respawn": 999999.0}}))
    for phase in range(2):
        with (folder / f"server-{phase}.log").open("w+") as log:
            server = start_server(world, log)
            try:
                if phase == 0:
                    clients("network_client", [[], []])
                    clients("network_dialogue_client", tokens)
                    clients("network_investigation_client", investigators)
                else:
                    clients("network_dialogue_client", [a + ["--verify"] for a in tokens])
                    clients("network_investigation_client", [a + ["--verify"] for a in investigators])
            finally:
                stop(server)
                log.seek(0)
                output = log.read()
                print(output, end="")
                if "SCRIPT ERROR" in output or "ERROR:" in output:
                    raise RuntimeError("Server logged errors")
print("PASS: ENet regression, dialogue and investigation isolation, server restart and reconnect")
