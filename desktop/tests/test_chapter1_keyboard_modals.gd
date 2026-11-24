extends SceneTree
const TestPaths = preload("res://tests/fixtures/test_paths.gd")
## P1-I keyboard/controller path regression: deliver real InputEventKey objects to Main.
## Uses only isolated /tmp save and does not require a GUI display.
const Main = preload("res://main.gd")
const Clues = preload("res://story/chapter1_investigation.gd")
const Dialogue = preload("res://story/chapter1_dialogue.gd")
var failures: int=0

func check(ok: bool,label: String) -> void:
	if ok:
		print("PASS: P1I ",label)
	else:
		failures+=1
		push_error("FAIL: P1I "+label)

func key(game: Node, code: Key) -> void:
	var event:=InputEventKey.new()
	event.pressed=true
	event.echo=false
	event.keycode=code
	event.physical_keycode=code
	game._unhandled_key_input(event)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game:=Main.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.save_path=TestPaths.path("vestige-p1i-keys-%d.json") % OS.get_process_id()
	game.start_single()
	var p: Dictionary=game.world.people["local"]
	check(game.mode=="single","isolated keyboard test started")
	key(game,KEY_N)
	check(game.panel.visible and game.chapter1_board_button.visible,"N opens notebook and board entry")
	key(game,KEY_L)
	check(not game.requests.visible and game.panel.visible,"L cannot stack requests over notebook")
	key(game,KEY_M)
	check(not game.travel.visible and game.panel.visible,"M cannot stack travel over notebook")
	key(game,KEY_I)
	check(not game.bag.visible and game.panel.visible,"I cannot stack bag over notebook")
	game.open_chapter1_board()
	check(game.chapter1_board.visible and not game.panel.visible,"board becomes active modal")
	key(game,KEY_N)
	check(not game.chapter1_board.visible and game.panel.visible,"N closes board to notebook")
	key(game,KEY_ESCAPE)
	check(not game.panel.visible,"ESC closes notebook")
	p.room="village"
	p.x=Clues.EVIDENCE.last_promise.x
	p.y=Clues.EVIDENCE.last_promise.y
	key(game,KEY_E)
	check(p.get("story",{}).get("evidence",{}).has("last_promise"),"E records E01 through keyboard path")
	key(game,KEY_N)
	check(game.panel.visible,"N opens discovered evidence")
	key(game,KEY_ESCAPE)
	p.x=Dialogue.NPCS.sera.x
	p.y=Dialogue.NPCS.sera.y
	key(game,KEY_T)
	check(game.dialogue_npc=="sera" and game.panel.visible,"T opens Sera dialogue")
	key(game,KEY_L)
	check(not game.requests.visible,"L does not obscure active Sera dialogue")
	key(game,KEY_ESCAPE)
	check(game.dialogue_npc.is_empty() and not game.panel.visible,"ESC ends NPC dialogue")
	p.x=6.0
	p.y=7.5
	key(game,KEY_E)
	check(game.forge.visible and game.dialogue_npc.is_empty(),"E keeps forge priority at Bran hotspot")
	key(game,KEY_ESCAPE)
	check(not game.forge.visible,"ESC exits forge")
	key(game,KEY_T)
	check(game.dialogue_npc=="bran","T talks to Bran after forge closes")
	key(game,KEY_ESCAPE)
	p.room="harbor"
	key(game,KEY_T)
	check(game.dialogue_npc.is_empty(),"T cannot open village NPC in other region")
	game.mode="menu"
	game.queue_free()
	DirAccess.remove_absolute(game.save_path)
	DirAccess.remove_absolute(game.save_path+".bak")
	DirAccess.remove_absolute(game.save_path+".tmp")
	print("P1I_KEYBOARD: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
