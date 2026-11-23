extends SceneTree
const TestPaths = preload("res://tests/fixtures/test_paths.gd")
## Chapter I input integration: isolated QA save file; never touches user://single-world.json.
const Main = preload("res://main.gd")
const Investigation = preload("res://story/chapter1_investigation.gd")
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
	var path := TestPaths.path("vestige-ch1-input-%d.json") % OS.get_process_id()
	game.save_path = path
	game.start_single()
	check(game.mode == "single", "QA world started")
	var player: Dictionary = game.world.people["local"]
	player.room = "village"
	player.x = Investigation.EVIDENCE["last_promise"].x
	player.y = Investigation.EVIDENCE["last_promise"].y
	game.interact()
	check(player.get("story", {}).get("evidence", {}).has("last_promise"), "E route collects Chapter I diary")
	check(player.story.chapter1.evidence_links.has("E01"), "logical E01 linked")
	var count: int = int(player.story.evidence.size())
	game.interact()
	check(player.story.evidence.size() == count, "repeat E does not duplicate evidence")
	game.open_chapter1_notebook()
	check(game.panel.visible, "N journal UI opens")
	check(game.panel_text.text.contains("마지막 약속"), "N shows Chapter I evidence")
	game.panel.hide()
	player.room = "harbor"
	game.interact()
	check(player.story.evidence.size() == count, "other region cannot collect Chapter I clues")
	player.room = "village"
	player.offline = true
	var result: String = game.Chapter1.inspect(game.world, "local", "chapel_traces")
	check(not result.contains("증거 기록"), "offline direct call denied")
	player.offline = false
	check(game.Rules.save_world(game.world, path), "QA world saves via G v23 store")
	var restored: Dictionary = game.Rules.load_world(path, false)
	check(restored.get("version") == 23, "G world version remains unchanged")
	check(restored.people["local"].get("story", {}).get("evidence", {}).has("last_promise"), "Chapter I record survives G store")
	game.mode = "menu"
	game.queue_free()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bak")
	DirAccess.remove_absolute(path + ".tmp")
	print("CHAPTER1_INPUT_INTEGRATION: ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
	quit(0 if failures == 0 else 1)
