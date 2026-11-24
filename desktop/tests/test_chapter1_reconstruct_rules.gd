extends SceneTree
const TestPaths = preload("res://tests/fixtures/test_paths.gd")
## Logical evidence is owned per player-life; other people cannot borrow it.
const World = preload("res://world.gd")
const Bridge = preload("res://story/chapter1_bridge.gd")
const Clues = preload("res://story/chapter1_investigation.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func collect(w: Dictionary, id: String, clue: String) -> void:
	var p: Dictionary = w.people[id]
	p.x = Clues.EVIDENCE[clue].x
	p.y = Clues.EVIDENCE[clue].y
	check(Bridge.inspect(w,id,clue).contains("증거 기록"), "gathered " + clue)

func _initialize() -> void:
	var w: Dictionary = World.fresh()
	World.born(w, "a", "첫 조사자")
	World.born(w, "b", "두 번째 조사자")
	var a: Dictionary = w.people["a"]
	var b: Dictionary = w.people["b"]
	a.offline = false
	b.offline = false
	Bridge.prepare_person(a)
	Bridge.prepare_person(b)
	w.wolf.hp = 0
	w.wolf.respawn = 999999.0
	check(not Bridge.reconstruct(w, "a", "E05", "E07").get("accepted",false), "unowned evidence denied")
	collect(w,"a","chapel_traces")
	collect(w,"a","device_log")
	check(not Bridge.reconstruct(w, "b", "E05", "E07").get("accepted",false), "other player cannot borrow evidence")
	b.room = "harbor"
	check(not Bridge.reconstruct(w, "b", "E05", "E07").get("accepted",false), "same coordinates in wrong region denied")
	b.room = "village"
	a.room = "harbor"
	check(not Bridge.reconstruct(w, "a", "E05", "E07").get("accepted",false), "owned evidence cannot be combined outside Ash Village")
	a.room = "village"
	check(Bridge.reconstruct(w, "a", "E07", "E05").get("accepted",false), "reversed E05/E07 proves I03 limited connection")
	check(not Bridge.reconstruct(w, "a", "E05", "E07").get("accepted",false), "duplicate I03 cannot be applied")
	check(not a.story.chapter1.inferences.has("I06"), "I06/operator identity not unlocked")
	check(not a.story.chapter1.chapter_completed, "no automatic Chapter I ending")
	collect(w, "a", "kael_token")
	a.x = Bridge.Dialogue.NPCS.kael.x
	a.y = Bridge.Dialogue.NPCS.kael.y
	check(Bridge.talk(w,"a","kael","kael_token","").is_empty(), "Kael evidence choice requires an active session")
	check(not Bridge.talk(w,"a","kael","kael_token","kael").is_empty(), "Kael confirms only his own statement")
	check(a.story.evidence.has("kael_statement"), "E08 recorded as testimony after authorized dialogue")
	check(Bridge.reconstruct(w,"a","E08","E06").get("accepted",false), "I04 limited testimony comparison")
	collect(w, "a", "device_key")
	check(Bridge.reconstruct(w,"a","E13","E07").get("accepted",false), "I07 limited tool/log connection")
	check(not a.story.chapter1.chapter_completed, "three limited inferences do not resolve missing story truths")
	var path: String = TestPaths.path("vestige-ch1-board-rule-%d.json") % OS.get_process_id()
	check(World.save_world(w,path), "v23 records per-life deductions")
	var loaded: Dictionary = World.load_world(path,false)
	check(loaded.people["a"].story.chapter1.inferences.size() == 3, "three limited connections persist")
	check(loaded.people["b"].get("story",{}).get("chapter1",{}).get("inferences",{}).is_empty(), "other person's story stays separate")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bak")
	DirAccess.remove_absolute(path + ".tmp")
	print("CHAPTER1_RECONSTRUCT_RULES: ", "PASS" if failures == 0 else "FAIL", " failures=",failures)
	quit(0 if failures == 0 else 1)
