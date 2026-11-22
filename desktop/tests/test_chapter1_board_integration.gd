extends SceneTree
## Chapter I P1-B3 board UI + single-game save integration. Temp fixtures only.
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
	var path := "/tmp/vestige-ch1-board-%d.json" % OS.get_process_id()
	game.save_path = path
	game.start_single()
	check(game.mode == "single", "isolated single QA session")
	var p: Dictionary = game.world.people["local"]
	p.room = "village"
	p.offline = false
	game.open_chapter1_notebook()
	check(game.chapter1_board_button.visible, "N notebook exposes evidence board")
	game.open_chapter1_board()
	check(game.chapter1_board.visible, "board opens from N notebook")
	check(game.chapter1_board.entries.get_child_count() == 1, "empty board informs missing evidence")
	game.submit_chapter1_combination("E05", "E07")
	check(not p.story.chapter1.inferences.has("I03"), "unowned evidence cannot generate inference")
	game.close_chapter1_board()
	p.x = Clues.EVIDENCE["chapel_traces"].x
	p.y = Clues.EVIDENCE["chapel_traces"].y
	game.world.wolf.hp = 0
	game.world.wolf.respawn = 999999.0
	check(game.Chapter1.inspect(game.world, "local", "chapel_traces").contains("증거 기록"), "E05 authorized")
	p.x = Clues.EVIDENCE["device_log"].x
	p.y = Clues.EVIDENCE["device_log"].y
	check(game.Chapter1.inspect(game.world, "local", "device_log").contains("증거 기록"), "E07 authorized")
	game.open_chapter1_board()
	game.chapter1_board.select_evidence("E05")
	game.chapter1_board.select_evidence("E07")
	check(game.chapter1_board.first_id == "E05" and game.chapter1_board.second_id == "E07", "board selection is pair of owned IDs")
	game.submit_chapter1_combination("E07", "E05")
	check(p.story.chapter1.inferences.get("I03", "") == "verified", "I03 limited inference recorded")
	check(game.chapter1_board.feedback.text.contains("I03"), "board shows accepted server-rule feedback")
	game.submit_chapter1_combination("E05", "E07")
	check(game.chapter1_board.feedback.text.contains("이미 기록"), "duplicate combination rejected")
	check(not p.story.chapter1.inferences.has("I06"), "operator identity not inferred")
	check(not p.story.chapter1.chapter_completed, "no automatic chapter ending")
	game.close_chapter1_board()
	check(not game.chapter1_board.visible and game.panel.visible, "close board returns to N notebook")
	check(game.Rules.save_world(game.world, path), "v23 stores inference")
	var loaded: Dictionary = game.Rules.load_world(path, false)
	check(loaded.people["local"].story.chapter1.inferences.get("I03", "") == "verified", "I03 persists after reload")
	game.mode = "menu"
	game.queue_free()
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bak")
	DirAccess.remove_absolute(path + ".tmp")
	print("CHAPTER1_BOARD_INTEGRATION: ", "PASS" if failures == 0 else "FAIL", " failures=", failures)
	quit(0 if failures == 0 else 1)
