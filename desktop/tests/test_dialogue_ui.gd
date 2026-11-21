extends SceneTree
const Main=preload("res://main.gd")
const Rules=preload("res://world.gd")
var failed:=0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failed+=1
		push_error(label)
func key(game: Node, code: Key) -> void:
	var event:=InputEventKey.new()
	event.pressed=true
	event.keycode=code
	event.physical_keycode=code
	if game.dialogue.visible: game._input(event)
	else: game._unhandled_key_input(event)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game:=Main.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.save_path="/tmp/vestige-dialogue-ui-%d.json" % OS.get_process_id()
	game.start_single()
	var p: Dictionary=game.world.people.local
	p.x=7
	p.y=7.5
	key(game,KEY_E)
	check(game.dialogue.visible and game.dialogue_text.text.contains("브란"),"E opens Bran dialogue")
	var before: float=game.world.time
	game._physics_process(1)
	for code in [KEY_I,KEY_J,KEY_SPACE,KEY_SHIFT,KEY_Q]: key(game,code)
	check(not game.bag.visible and not game.panel.visible and p.attack==0 and p.dodge==0 and game.world.time==before,"modal blocks gameplay, inventory and journal keys")
	var request_id: int=game.dialogue_request_id
	game.receive_dialogue({},request_id-1)
	check(game.dialogue.visible,"stale network response cannot close a new conversation")
	game.dialogue_choices.get_child(0).pressed.emit()
	check(p.story.iren_missing_rumor,"rumor button applies choice")
	key(game,KEY_ESCAPE)
	check(not game.dialogue.visible and game.dialogue_sessions.is_empty(),"ESC closes session")
	key(game,KEY_J)
	check(game.panel_text.text.contains("소문"),"journal UI shows rumor immediately")
	key(game,KEY_ESCAPE)
	p.x=12
	p.y=4.5
	key(game,KEY_E)
	check(game.dialogue_text.text.contains("세라") and game.dialogue_text.text.contains("소문을 들으셨군요"),"Sera reflects known rumor")
	game.dialogue_choices.get_child(1).pressed.emit()
	game.start_single()
	check(game.world.people.local.story.visits.sera and game.world.people.local.story.iren_missing_rumor,"single restart preserves dialogue")
	p=game.world.people.local
	p.x=10
	p.y=5
	key(game,KEY_E)
	check(game.panel.visible and game.panel_text.text.begins_with("기억의 서재"),"E still opens library at entrance")
	DirAccess.remove_absolute(game.save_path)
	DirAccess.remove_absolute(game.save_path+".bak")
	game.queue_free()
	quit(1 if failed else 0)
