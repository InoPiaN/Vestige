extends SceneTree
const Rules=preload("res://world.gd")
const Archive=preload("res://investigation.gd")
var failed:=0
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failed+=1
		push_error(text)
func locate(p: Dictionary,v: Vector2) -> void:
	p.x=v.x
	p.y=v.y+1
func _initialize() -> void:
	var demo:=preload("res://investigation_demo.gd").create()
	check(demo.graves.size()==1 and demo.people.local.alive and demo.people.local.notebook.is_empty() and demo.estate.shelf.contains("예배당"),"Demo opens with a living investigator and a real archived case")
	var w:=Rules.fresh()
	Rules.born(w,"a","솔")
	Rules.born(w,"b","방문객")
	var first: Dictionary=w.people.a
	locate(first,Archive.HOME)
	first.gold=7
	Rules.act(w,"a","interact")
	check(w.estate.owner=="" and first.gold==7,"Insufficient funds preserve ownership and wallet")
	first.gold=12
	first.events.append("동쪽 예배당에 약초를 가져가기로 했다.")
	Rules.act(w,"a","interact")
	Rules.act(w,"a","interact")
	var life: String=first.life
	check(w.estate.owner==life and first.gold==4 and w.estate.shelf.contains("예배당"),"Purchase and journal deposit are idempotent")
	locate(w.people.b,Archive.HOME)
	var denied:=Rules.act(w,"b","interact")
	check(denied.contains("다른 주민") and w.people.b.gold==12,"Living owner keeps private house")
	first.events.append("길에서만 남긴 마지막 메모")
	locate(first,Vector2(25,9))
	first.hp=1
	Rules.tick(w,0.05)
	Rules.tick(w,0.7)
	check(not first.alive and w.graves.size()==1 and w.graves[0].cause=="사인 미확인","Actual wolf death creates an unresolved grave")
	Rules.born(w,"a","솔")
	var p: Dictionary=w.people.a
	check(p.life!=life and p.notebook.is_empty(),"Same-name successor receives a distinct life")
	var snap:=w.duplicate(true)
	Archive.redact(snap,"a")
	check(not snap.has("cases") and not snap.estate.has("shelf") and snap.books.is_empty() and snap.visible_traces.is_empty(),"Undiscovered truth, shelf, book and distant marker omitted from client")
	locate(p,Archive.CEMETERY)
	Rules.act(w,"a","investigate")
	check(p.notebook[life].has("lead") and not w.cases[life].resolved,"Grave provides search region without solution")
	locate(p,Archive.HOME)
	Rules.act(w,"a","interact")
	check(p.notebook[life].home.contains("약초") and not p.notebook[life].home.contains("마지막 메모") and not Archive.may_read(p,w.books[0]),"Shelf contains only what was deposited in life")
	locate(p,Archive.CEMETERY)
	Rules.act(w,"a","investigate")
	check(not w.cases[life].resolved,"House alone cannot resolve cause")
	locate(p,Vector2(25,9))
	Rules.act(w,"a","investigate")
	check(p.notebook[life].scene.contains("늑대 발자국") and Archive.may_read(p,w.books[0]),"Site observation grants distinct clue and access to recovered book")
	var path:=OS.get_temp_dir()+"/vestige-investigation-"+str(OS.get_process_id())+".json"
	check(Rules.save_world(w,path),"Investigation saved")
	w=Rules.load_world(path)
	Rules.act(w,"a","resume")
	p=w.people.a
	locate(p,Archive.CEMETERY)
	Rules.act(w,"a","investigate")
	Rules.act(w,"a","investigate")
	check(w.cases[life].resolved and w.graves[0].cause=="늑대와의 전투" and p.notebook[life].has("finding"),"Reloaded evidence resolves grave")
	check(p.events.count(p.notebook[life].finding)==1,"Repeated investigation records a single conclusion")
	snap=w.duplicate(true)
	Archive.redact(snap,"b")
	check(not snap.people.a.has("notebook") and snap.books.is_empty() and snap.graves[0].cause=="늑대와의 전투","Visitor sees amended public grave, not private notes or book")
	var quiet:=Rules.fresh()
	Rules.born(quiet,"resident","노인")
	var elder: Dictionary=quiet.people.resident
	locate(elder,Archive.HOME)
	Rules.act(quiet,"resident","interact")
	elder.age=elder.limit-1
	Rules.advance(quiet,Rules.DAY)
	Rules.born(quiet,"resident","조사자")
	var investigator: Dictionary=quiet.people.resident
	locate(investigator,Archive.HOME)
	Rules.act(quiet,"resident","investigate")
	locate(investigator,Archive.CEMETERY)
	Rules.act(quiet,"resident","investigate")
	check(quiet.graves[0].cause=="노환","Death at home preserves both clues and resolves natural death")
	var legacy:=Rules.fresh()
	legacy.version=1
	legacy.erase("estate")
	legacy.erase("cases")
	Rules.born(legacy,"a","구버전")
	legacy.people.a.erase("life")
	legacy.people.a.erase("notebook")
	Rules.save_world(legacy,path)
	var migrated:=Rules.load_world(path)
	check(migrated.version==18 and migrated.people.a.name=="구버전" and not migrated.people.a.life.is_empty() and migrated.estate.owner=="","Version 1 save acquires persistent life and empty plot")
	for suffix in ["",".bak"]: DirAccess.remove_absolute(path+suffix)
	quit(1 if failed else 0)
