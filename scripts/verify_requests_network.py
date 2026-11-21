"""Isolated ENet server and two clients; never touches user saves."""
from pathlib import Path
import subprocess, tempfile, time
ROOT=Path(__file__).resolve().parents[1]
BASE=[str(ROOT/'.tools/godot/Godot.app/Contents/MacOS/Godot'),'--headless','--path',str(ROOT/'desktop')]
with tempfile.TemporaryDirectory(prefix='vestige-requests-enet-') as directory:
    work=Path(directory)
    fixture=work/'world.json'
    subprocess.run(BASE+['--script','tests/network_requests.gd','--log-file',str(work/'fixture.log'),'--','--fixture='+str(fixture)],check=True,timeout=30)
    processes=[]
    try:
        with (work/'server-output.log').open('w') as serverlog, (work/'primary.log').open('w') as primarylog, (work/'observer.log').open('w') as observerlog:
            server=subprocess.Popen(BASE+['--log-file',str(work/'server.log'),'--','--server','--world-file='+str(fixture)],stdout=serverlog,stderr=subprocess.STDOUT)
            processes.append(server)
            time.sleep(1)
            if server.poll() is not None: raise RuntimeError((work/'server-output.log').read_text())
            clients=[]
            for name,log,args in [('primary',primarylog,[]),('observer',observerlog,['--','--observer'])]:
                child=subprocess.Popen(BASE+['--script','tests/network_requests.gd','--log-file',str(work/(name+'-engine.log'))]+args,stdout=log,stderr=subprocess.STDOUT)
                processes.append(child); clients.append((name,child))
            for name,child in clients:
                code=child.wait(timeout=110)
                output=(work/(name+'.log')).read_text()
                print(output,end='')
                if code or 'SCRIPT ERROR' in output or 'PASS: ENet' not in output: raise RuntimeError(name+' verification failed')
            server_output=(work/'server-output.log').read_text()
            if 'SCRIPT ERROR' in server_output: raise RuntimeError(server_output)
    finally:
        for process in reversed(processes):
            if process.poll() is None:
                process.terminate()
                try: process.wait(timeout=5)
                except subprocess.TimeoutExpired: process.kill(); process.wait()
