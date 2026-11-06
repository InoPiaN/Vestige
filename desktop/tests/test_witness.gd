extends SceneTree
const Rules=preload("res://world.gd")
const Archive=Rules.Investigation
const Witness=Archive.Witness
const Demo=preload("res://investigation_demo.gd")
var failures:=0
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failures+=1
		push_error(text)
func place(p: Dictionary,point: Vector2) -> void:
	p.x=point.x
	p.y=point.y
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	check(Witness.observe(Vector2.ZERO,Vector2(15,0),Vector2(15,1),"고리",[],1).is_empty(),"Outside sight range yields no testimony")
	check(Witness.observe(Vector2(5,5),Vector2(5,8),Vector2(5.5,8),"고리",Rules.PLACES,1).is_empty(),"Forge wall blocks line of sight")
	var w:=Demo.murder()
	var p: Dictionary=w.people.local
	var id: String=w.estate.owner
	check(w.cases[id].observation.mark=="갈라진 고리" and w.graves[0].cause=="사인 미확인","Scheduled lethal blow leaves observed detail and unresolved grave")
	var view:=w.duplicate(true)
	Archive.redact(view,"local")
	check(not view.has("cases") and view.books.is_empty() and not JSON.stringify(view).contains("하렌"),"Remote newcomer receives no suspect or hidden truth")
	Rules.act(w,"local","investigate")
	check(p.notebook.is_empty(),"Distant investigator cannot hear testimony")
	place(p,Archive.HOME+Vector2.DOWN)
	Rules.act(w,"local","interact")
	place(p,Vector2(16,13))
	Rules.act(w,"local","investigate")
	place(p,Archive.CEMETERY)
	Rules.act(w,"local","investigate")
	Rules.act(w,"local","identify","2")
	check(not w.cases[id].resolved and not p.notebook[id].has("finding"),"Correct guess without witness cannot solve murder")
	place(p,Witness.STATION)
	Rules.act(w,"local","investigate")
	check(p.notebook[id].witness.contains("갈라진 고리") and not p.notebook[id].witness.contains("하렌"),"Witness describes visible clasp without naming the culprit")
	# The save/reload boundary preserves who actually obtained each piece.
	var path:=OS.get_temp_dir()+"/vestige-witness-"+str(OS.get_process_id())+".json"
	check(Rules.save_world(w,path),"Investigation with testimony saved")
	w=Rules.load_world(path)
	Rules.act(w,"local","resume")
	p=w.people.local
	Rules.act(w,"local","identify","2")
	check(not w.cases[id].resolved,"Identification requires return to grave")
	place(p,Archive.CEMETERY)
	Rules.act(w,"local","identify","1")
	check(not w.cases[id].resolved and w.graves[0].cause=="사인 미확인","Wrong identification keeps case open")
	var game:=preload("res://main.gd").new()
	root.add_child(game)
	game.mode="single"
	game.world=w
	game.me="local"
	game.save_path=path
	press(game,KEY_F)
	check(game.panel.visible and game.panel_text.text.contains("지목할 이를 고르세요"),"F at grave opens suspect choices")
	press(game,KEY_2)
	check(w.cases[id].resolved and w.graves[0].cause=="살해 · 하렌" and game.panel_text.text.contains("칼에 의한 살해"),"Second suspect selected via game input resolves case")
	Rules.act(w,"local","identify","2")
	check(p.events.count(p.notebook[id].finding)==1,"Resolution journaled once")
	Rules.born(w,"second","다른 조사자")
	view=w.duplicate(true)
	Archive.redact(view,"second")
	check(not view.people.local.has("notebook") and view.books.is_empty() and view.graves[0].cause=="살해 · 하렌","Public outcome preserves investigators' private notes")
	w=Demo.murder()
	id=w.estate.owner
	w.cases[id].observation={}
	place(w.people.local,Witness.STATION)
	check(Rules.act(w,"local","investigate").contains("보지 못했다") and not w.people.local.notebook.has(id),"Unwitnessed attack cannot produce a positive witness note")
	game.queue_free()
	for ext in ["",".bak"]: DirAccess.remove_absolute(path+ext)
	quit(1 if failures else 0)
func press(game: Node,key: Key) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=key
	event.pressed=true
	game._unhandled_key_input(event)
