"""Run all Godot rule scripts against isolated temporary fixtures."""
import subprocess,pathlib,sys,os
root=pathlib.Path(__file__).resolve().parents[1]
godot=os.environ.get('GODOT_BIN') or str(root/'.tools/godot/Godot.app/Contents/MacOS/Godot')
fail=[];count=0
for f in sorted((root/'desktop/tests').glob('test_*.gd')):
 try:
  p=subprocess.run([godot,'--headless','--path','desktop','--script','tests/'+f.name,'--log-file','/tmp/vestige-'+f.stem+'.log'],cwd=root,capture_output=True,text=True,timeout=40)
  out=p.stdout+p.stderr;n=out.count('PASS:');count+=n
  bad=p.returncode!=0 or 'SCRIPT ERROR' in out
  print(f.name,n,'FAIL' if bad else 'OK',flush=True)
  if bad: fail.append(f.name);print(out,flush=True)
 except subprocess.TimeoutExpired: fail.append(f.name);print('TIMEOUT',f.name,flush=True)
print('TOTAL',count,'FAILURES',fail,flush=True);sys.exit(bool(fail))
