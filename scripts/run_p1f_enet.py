#!/usr/bin/env python3
"""Execute real Godot ENet server and two client processes with isolated fixtures.

Result is based on subprocess exit codes and logs, not source-string checks.
The runner never opens the user's existing world or identity file.
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


def run(args: list[str], cwd: Path, env: dict[str,str], timeout: int, logfile: Path):
    with logfile.open("w", encoding="utf-8") as log:
        return subprocess.run(args,cwd=cwd,env=env,stdout=log,stderr=subprocess.STDOUT,
                              timeout=timeout,check=False).returncode


def main() -> int:
    p=argparse.ArgumentParser()
    p.add_argument("--godot",default=os.environ.get("GODOT_BIN","godot"))
    p.add_argument("--logs",type=Path,default=Path(tempfile.gettempdir())/"vestige-p1f-logs")
    p.add_argument("--root",type=Path,default=Path(__file__).resolve().parents[1])
    args=p.parse_args()
    root=args.root.resolve()
    logs=args.logs.resolve()
    logs.mkdir(parents=True,exist_ok=True)
    exe=shutil.which(args.godot) or args.godot
    godot=Path(exe).expanduser().resolve()
    results={"status":"BLOCKED","godot":str(godot),"checks":{},"logs":str(logs)}
    if not godot.is_file() or not os.access(godot,os.X_OK):
        results["reason"]="Godot executable missing"
        (logs/"p1f-report.json").write_text(json.dumps(results,indent=2))
        print(json.dumps(results))
        return 2
    project=root/"desktop"
    with tempfile.TemporaryDirectory(prefix="vestige-p1f-") as directory:
        tmp=Path(directory)
        env=os.environ.copy()
        env.update({"HOME":str(tmp/"home"),"XDG_DATA_HOME":str(tmp/"data"),
                    "XDG_CONFIG_HOME":str(tmp/"config"),"XDG_CACHE_HOME":str(tmp/"cache")})
        (tmp/"home").mkdir()
        base=[str(godot),"--headless","--path",str(project)]
        fixture=tmp/"chapter1-world.json"
        fixture_args=base+["--script","res://tests/network_chapter1.gd","--",
                           "--fixture="+str(fixture)]
        try:
            fixture_code=run(fixture_args,root,env,35,logs/"fixture.log")
        except (OSError,subprocess.TimeoutExpired) as exc:
            fixture_code=-1
            (logs/"fixture-error.log").write_text(repr(exc))
        results["checks"]["fixture"]={"code":fixture_code,"exists":fixture.is_file()}
        if fixture_code!=0 or not fixture.is_file():
            results["status"]="FAIL"
        else:
            server=None
            children=[]
            handles=[]
            try:
                slog=(logs/"server.log").open("w")
                handles.append(slog)
                server=subprocess.Popen(base+["--","--server","--world-file="+str(fixture)],
                                        cwd=root,env=env,stdout=slog,stderr=subprocess.STDOUT)
                time.sleep(1.5)
                if server.poll() is not None:
                    raise RuntimeError("Server exited during startup")
                for name,extra in [("primary",[]),("observer",["--observer"])]:
                    out=(logs/(name+".log")).open("w")
                    handles.append(out)
                    child=subprocess.Popen(base+["--script","res://tests/network_chapter1.gd",
                                                 "--"]+extra,cwd=root,env=env,stdout=out,
                                           stderr=subprocess.STDOUT)
                    children.append((name,child))
                for name,child in children:
                    try:
                        code=child.wait(timeout=48)
                    except subprocess.TimeoutExpired:
                        child.kill()
                        code=-9
                    results["checks"][name]={"code":code}
            except (OSError,RuntimeError) as exc:
                results["reason"]=str(exc)
            finally:
                for _,child in children:
                    if child.poll() is None:
                        child.terminate()
                        try: child.wait(timeout=4)
                        except subprocess.TimeoutExpired: child.kill();child.wait()
                if server is not None:
                    if server.poll() is None:
                        server.terminate()
                        try:server.wait(timeout=5)
                        except subprocess.TimeoutExpired: server.kill();server.wait()
                    results["checks"]["server"]={"code":server.returncode}
                for h in handles:h.close()
            for name in ("primary","observer"):
                path=logs/(name+".log")
                output=path.read_text(errors="replace") if path.is_file() else ""
                marker="PASS: ENet Chapter I "+("primary evidence" if name=="primary" else "observer private")
                results["checks"].setdefault(name,{})
                results["checks"][name].update(
                    {"pass_marker":marker in output,"script_error":"SCRIPT ERROR" in output,
                     "packet_error":"Unable to send packet" in output}
                )
            server_text=(logs/"server.log").read_text(errors="replace") if (logs/"server.log").is_file() else ""
            results["checks"]["server_log"]={
                "script_error":"SCRIPT ERROR" in server_text,
                "packet_error":"Unable to send packet" in server_text}
            ok=all(results["checks"][n].get("code")==0 and results["checks"][n]["pass_marker"]
                   and not results["checks"][n]["script_error"] and not results["checks"][n]["packet_error"]
                   for n in ("primary","observer"))
            ok=ok and not results["checks"]["server_log"]["script_error"] and not results["checks"]["server_log"]["packet_error"]
            results["status"]="PASS" if ok else "FAIL"
    (logs/"p1f-report.json").write_text(json.dumps(results,ensure_ascii=False,indent=2),encoding="utf-8")
    print(json.dumps(results,ensure_ascii=False))
    return 0 if results["status"]=="PASS" else 1


if __name__=="__main__":
    sys.exit(main())
