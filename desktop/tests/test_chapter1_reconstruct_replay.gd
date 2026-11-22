extends SceneTree
## Server-side Chapter I replay/denial gate; synthetic peers and isolated save path.
const Main = preload("res://main.gd")
const Clues = preload("res://story/chapter1_investigation.gd")
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
	var game := Main.new()
	root.add_child(game)
	game.set_physics_process(false)
	var path: String = "/tmp/vestige-ch1-replay-%d.json" % OS.get_process_id()
	game.save_path = path
	game.start_single()
	game.Rules.born(game.world, "b", "두 번째 조사자")
	var p: Dictionary = game.world.people["local"]
	var other: Dictionary = game.world.people["b"]
	p.offline = false
	other.offline = false
	p.room = "village"
	other.room = "village"
	game.mode = "server"
	game.peers = {11:"local",22:"b"}
	check(not game.can_send_to_peer(11), "disconnected or offline transport cannot receive snapshots")
	check(not game.evaluate_chapter1_reconstruct_request(99,"E05","E07",1,1000).accepted, "unknown peer rejected")
	check(not game.evaluate_chapter1_reconstruct_request(11,"E05","E07",0,1000).accepted, "invalid serial rejected")
	check(not game.evaluate_chapter1_reconstruct_request(11,"E05","E07",1,1000).accepted, "unowned clues rejected with result")
	check(not game.evaluate_chapter1_reconstruct_request(11,"E05","E07",1,1200).accepted, "replayed request ID denied")
	check(not game.evaluate_chapter1_reconstruct_request(11,"E05","E07",2,1050).accepted, "rapid request receives rejection result")
	check(not game.evaluate_chapter1_reconstruct_request(11,"EVIL-LONG-EVIDENCE","E07",3,1250).accepted, "oversized ID rejected")
	game.world.wolf.hp = 0
	game.world.wolf.respawn = 999999
	p.x = Clues.EVIDENCE.chapel_traces.x
	p.y = Clues.EVIDENCE.chapel_traces.y
	check(game.Chapter1.inspect(game.world,"local","chapel_traces").contains("증거 기록"), "E05 fixture")
	p.x = Clues.EVIDENCE.device_log.x
	p.y = Clues.EVIDENCE.device_log.y
	check(game.Chapter1.inspect(game.world,"local","device_log").contains("증거 기록"), "E07 fixture")
	check(not game.evaluate_chapter1_reconstruct_request(22,"E05","E07",1,1400).accepted, "other peer cannot borrow clues")
	check(game.evaluate_chapter1_reconstruct_request(11,"E07","E05",4,1450).accepted, "owned clues permit I03")
	check(not game.evaluate_chapter1_reconstruct_request(11,"E05","E07",5,1650).accepted, "already applied inference rejected")
	check(p.story.chapter1.inferences.get("I03","")=="verified", "personal I03 recorded")
	check(other.get("story",{}).get("chapter1",{}).get("inferences",{}).is_empty(), "peer B untouched")
	check(not p.story.chapter1.chapter_completed, "no invented story resolution")
	game.mode = "single"
	check(game.Rules.save_world(game.world,path), "v23 persists server-authored inference")
	var loaded: Dictionary = game.Rules.load_world(path,false)
	check(loaded.people["local"].story.chapter1.inferences.get("I03","")=="verified", "I03 roundtrip")
	game.mode = "menu"
	game.queue_free()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bak")
	DirAccess.remove_absolute(path + ".tmp")
	print("CHAPTER1_REPLAY_GATE: ", "PASS" if failures==0 else "FAIL", " failures=",failures)
	quit(0 if failures==0 else 1)
