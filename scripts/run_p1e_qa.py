#!/usr/bin/env python3
"""P1-E executable QA gate for VESTIGE's integrated Chapter I branch.

Reports real process exit codes; a test file's existence is never a PASS.
No user:// save is intentionally accessed by this driver. Its Chapter I scripts use
/tmp fixture paths, but always run in a dedicated isolated Godot user-data home.

Exit codes: 0 all checks executed and passed; 1 at least one failed; 2 environment
preflight failed. Never prints a false 'success' after missing Godot.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time

TESTS = (
    "test_chapter1_port_contract.gd",
    "test_chapter1_input_integration.gd",
    "test_chapter1_dialogue_integration.gd",
    "test_chapter1_board_integration.gd",
    "test_chapter1_reconstruct_rules.gd",
    "test_chapter1_reconstruct_replay.gd",
    "test_chapter1_save_compatibility.gd",
)


def run_command(args: list[str], cwd: Path, env: dict[str, str],
                timeout: int, log_path: Path) -> dict:
    began = time.monotonic()
    try:
        result = subprocess.run(args, cwd=cwd, env=env,
                                capture_output=True, text=True,
                                errors="replace", timeout=timeout, check=False)
        output = result.stdout + ("\n[stderr]\n" + result.stderr if result.stderr else "")
        status = "PASS" if result.returncode == 0 else "FAIL"
        detail = {"status": status, "returncode": result.returncode}
    except subprocess.TimeoutExpired as exc:
        output = f"TIMEOUT after {timeout} s\nstdout={exc.stdout!r}\nstderr={exc.stderr!r}"
        detail = {"status": "FAIL", "returncode": None, "reason": "timeout"}
    except OSError as exc:
        output = str(exc)
        detail = {"status": "FAIL", "returncode": None, "reason": "spawn_error"}
    log_path.write_text(output, encoding="utf-8")
    return {**detail, "elapsed_seconds": round(time.monotonic() - began, 2),
            "log": str(log_path), "command": args}


def run_suite(root: Path, godot: Path, logs: Path, timeout: int,
              include_rules: bool) -> dict:
    project = root / "desktop" / "project.godot"
    missing = [str(root / "desktop" / "tests" / name)
               for name in TESTS if not (root / "desktop" / "tests" / name).is_file()]
    if not project.is_file():
        missing.append(str(project))
    if include_rules and not (root / "scripts" / "verify_rules.py").is_file():
        missing.append(str(root / "scripts" / "verify_rules.py"))
    if not godot.is_file() or not os.access(godot, os.X_OK):
        missing.append(f"Godot executable: {godot}")
    if missing:
        return {"status": "BLOCKED", "reason": "required inputs missing",
                "missing": missing, "tests": {}, "results": {"pass": 0, "fail": 0}}
    logs.mkdir(parents=True, exist_ok=True)
    results: dict[str, dict] = {}
    with tempfile.TemporaryDirectory(prefix="vestige-p1e-home-") as temp:
        # Godot's user:// files are scoped away from the developer's real game.
        environment = os.environ.copy()
        # Both Unix/Linux XDG and macOS HOME-based Godot app_userdata paths.
        # This protects the actual player's user:// worlds even when a test instantiates Main.
        sandbox_home = Path(temp) / "home"
        sandbox_home.mkdir(parents=True, exist_ok=True)
        environment["HOME"] = str(sandbox_home)
        environment["XDG_DATA_HOME"] = str(Path(temp) / "data")
        environment["XDG_CONFIG_HOME"] = str(Path(temp) / "config")
        environment["XDG_CACHE_HOME"] = str(Path(temp) / "cache")
        environment["APPDATA"] = str(Path(temp) / "appdata")
        environment["LOCALAPPDATA"] = str(Path(temp) / "localappdata")
        if include_rules:
            results["existing_game_rules"] = run_command(
                [sys.executable, "scripts/verify_rules.py"], root, environment,
                timeout, logs / "existing_game_rules.log")
        for name in TESTS:
            test_name = name[:-3]
            # Godot handles the script within the specified project path.
            cmd = [str(godot), "--headless", "--path", str(root / "desktop"),
                   "--script", f"res://tests/{name}"]
            results[test_name] = run_command(
                cmd, root, environment, timeout, logs / f"{test_name}.log")
    passed = sum(x["status"] == "PASS" for x in results.values())
    failed = len(results) - passed
    return {"status": "PASS" if not failed else "FAIL", "tests": results,
            "results": {"pass": passed, "fail": failed}, "note":
            "Runtime process checks only; does not substitute two-client ENet or manual play QA."}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path,
                        default=Path(__file__).resolve().parents[1])
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"),
                        help="Godot 4.5.1 binary path or command in PATH")
    parser.add_argument("--logs", type=Path,
                        default=Path(tempfile.gettempdir()) / "vestige-p1e-logs")
    parser.add_argument("--timeout", type=int, default=120)
    parser.add_argument("--skip-rules", action="store_true")
    args = parser.parse_args()
    root = args.root.resolve()
    executable = shutil.which(args.godot)
    binary = Path(executable or args.godot).expanduser().resolve()
    report = run_suite(root, binary, args.logs.resolve(), args.timeout,
                       include_rules=not args.skip_rules)
    if report["status"] == "BLOCKED":
        report["environment"] = "Godot and tracked project files required; no tests executed"
        args.logs.mkdir(parents=True, exist_ok=True)
    (args.logs / "p1e-report.json").write_text(
        json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")
    print(json.dumps({"status": report["status"], "results": report["results"],
                      "missing": report.get("missing", []),
                      "report": str(args.logs / "p1e-report.json")},
                     ensure_ascii=False))
    return 2 if report["status"] == "BLOCKED" else (0 if report["status"] == "PASS" else 1)


if __name__ == "__main__":
    sys.exit(main())
