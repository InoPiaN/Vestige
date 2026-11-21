extends SceneTree
const Main=preload("res://main.gd")
var failed:=0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failed+=1
		push_error(label)
func key(g: Node, code: Key) -> void:
	var e:=InputEventKey.new()
	e.pressed=true
	e.keycode=code
	e.physical_keycode=code
	if g.dialogue.visible: g._input(e)
	else: g._unhandled_key_input(e)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var g:=Main.new()
	root.add_child(g)
	g.set_physics_process(false)
	g.save_path="/tmp/vestige-investigation-ui-%d.json" % OS.get_process_id()
	g.start_single()
	key(g,KEY_N)
	check(g.panel.visible and g.panel_text.text.contains("아직 발견한"),"N opens empty notebook")
	key(g,KEY_ESCAPE)
	var p: Dictionary=g.world.people.local
	p.x=16
	p.y=7
	g.refresh()
	check(g.prompt.text.contains("마지막 약속"),"house entrance shows investigation hint")
	key(g,KEY_E)
	key(g,KEY_N)
	check(g.panel_text.text.contains("last_promise") and g.panel_text.text.contains("추정 · 미확인"),"E records diary and N shows provenance")
	var count: int=p.story.evidence.size()
	key(g,KEY_E)
	key(g,KEY_SPACE)
	check(p.story.evidence.size()==count and p.attack==0,"notebook blocks inspect and combat keys")
	# A snapshot arriving after N must update the already-open notebook.
	p.x=27
	p.y=12
	g.world.wolf.hp=0
	Main.Rules.act(g.world,"local","inspect","chapel_traces")
	g.refresh()
	check(g.panel_text.text.contains("chapel_traces"),"open notebook refreshes when authoritative evidence arrives")
	p.story.evidence.erase("chapel_traces")
	key(g,KEY_ESCAPE)
	key(g,KEY_J)
	check(g.panel_text.text.contains("마지막 약속"),"journal keeps investigation note")
	key(g,KEY_ESCAPE)
	p.x=7
	p.y=7.5
	key(g,KEY_E)
	check(g.dialogue_choices.get_child_count()==3,"evidence unlocks NPC choice")
	g.dialogue_choices.get_child(1).pressed.emit()
	check(g.dialogue_text.text.contains("약속 상대"),"NPC evidence choice renders branch")
	key(g,KEY_N)
	check(not g.panel.visible,"notebook cannot interrupt dialogue")
	key(g,KEY_ESCAPE)
	g.start_single()
	check(g.world.people.local.story.evidence.size()==1,"UI single restart preserves evidence")
	DirAccess.remove_absolute(g.save_path)
	DirAccess.remove_absolute(g.save_path+".bak")
	g.queue_free()
	quit(1 if failed else 0)
