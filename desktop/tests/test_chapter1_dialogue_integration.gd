extends SceneTree
## P1-B2: local dialogue UI + life-scoped memory smoke test. No user's save files.
const Main = preload("res://main.gd")
const Dialogue = preload("res://story/chapter1_dialogue.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game:=Main.new()
	root.add_child(game)
	game.set_physics_process(false)
	var path: String="/tmp/vestige-ch1-dialogue-%d.json" % OS.get_process_id()
	game.save_path=path
	game.start_single()
	check(game.mode=="single", "QA game started")
	var p: Dictionary=game.world.people["local"]
	p.room="village"
	p.offline=false
	p.x=Dialogue.NPCS.sera.x
	p.y=Dialogue.NPCS.sera.y
	game.interact()
	check(game.panel.visible and game.dialogue_npc=="sera", "E near Sera opens dialogue")
	check(game.dialogue_buttons.get_child_count()>0, "choices rendered")
	check(p.story.visits.sera, "first Sera meeting recorded")
	game.choose_chapter1_option("rumor")
	check(p.story.iren_missing_rumor, "rumor marked as source-limited")
	var count: int=p.events.size()
	game.choose_chapter1_option("rumor")
	check(p.events.size()==count, "rumor event idempotent")
	check(not p.story.chapter1.chapter_completed, "talk cannot complete chapter")
	game.finish_chapter1_dialogue()
	check(not game.panel.visible and game.dialogue_npc.is_empty(), "closing dialogue clears UI")
	p.room="harbor"
	p.x=Dialogue.NPCS.kael.x
	p.y=Dialogue.NPCS.kael.y
	game.interact()
	check(game.dialogue_npc.is_empty(), "other region cannot reach Chapter I NPC")
	p.room="village"
	p.x=Dialogue.NPCS.kael.x
	p.y=Dialogue.NPCS.kael.y
	game.interact()
	check(game.dialogue_npc=="kael", "Kael dialogue opens in Ash Village")
	check(not p.story.evidence.has("kael_statement"), "talk without metal token cannot create E08")
	game.finish_chapter1_dialogue()
	check(game.Rules.save_world(game.world,path), "v23 save accepts story and dialogue state")
	var loaded: Dictionary=game.Rules.load_world(path,false)
	check(loaded.people["local"].story.visits.sera, "visits persist after reload")
	check(loaded.people["local"].story.iren_missing_rumor, "rumor persists after reload")
	check(not loaded.people["local"].story.chapter1.chapter_completed, "story stays unresolved after reload")
	game.queue_free()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".bak")
	DirAccess.remove_absolute(path+".tmp")
	print("CHAPTER1_DIALOGUE_INTEGRATION: ", "PASS" if failures==0 else "FAIL", " failures=",failures)
	quit(0 if failures==0 else 1)
