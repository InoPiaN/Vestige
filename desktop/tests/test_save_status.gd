extends SceneTree
const Main = preload("res://main.gd")
const World = preload("res://world.gd")
const Store = preload("res://world_store.gd")
const Checkpoint = preload("res://core/save_checkpoint.gd")
const Paths = preload("res://tests/fixtures/test_paths.gd")
var failures := 0
var writes := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error(label)
func fake_write(_world: Dictionary, _path: String) -> bool:
	writes += 1
	return false
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var service := Checkpoint.new()
	check(not service.attempt({"data":1}, "a", "client", fake_write) and writes == 0, "client cannot invoke writer")
	check(not service.attempt({}, "a", "single", fake_write) and writes == 0, "empty world rejected before writer")
	check(not service.attempt({"data":1}, "a", "single", fake_write) and service.pending("a"), "failed writer sets pending")
	check(not service.pending("b"), "pending status scoped by save path")
	var game := Main.new()
	root.add_child(game)
	game.set_process(false)
	game.set_physics_process(false)
	game.mode = "single"
	game.me = "local"
	game.save_path = Paths.path("status.json")
	game.world = World.fresh()
	World.born(game.world, "local", "Observer")
	game.world.people.local.offline = false
	game.world.people.local.x = 16.0
	game.world.people.local.y = 7.0
	check(game.checkpoint_current(), "initial checkpoint succeeds")
	DirAccess.make_dir_absolute(game.save_path + ".tmp")
	game.perform("chapter1_inspect", "last_promise")
	check(game.checkpoints.pending(game.save_path) and game.save_warning.visible and game.retry_save_button.visible, "failed inspection checkpoint displays persistent warning and retry")
	var events: Array = game.world.people.local.events.duplicate(true)
	check(game.world.people.local.story.evidence.has("last_promise"), "failed save preserves new discovery in memory")
	game.retry_save_button.pressed.emit()
	check(game.checkpoints.pending(game.save_path) and game.world.people.local.events == events, "failed retry does not repeat investigation")
	DirAccess.remove_absolute(game.save_path + ".tmp")
	game.world.people.local.gold += 3
	game.retry_save_button.pressed.emit()
	check(not game.checkpoints.pending(game.save_path) and not game.save_warning.visible and not game.retry_save_button.visible, "successful retry clears warning and button")
	var disk := Store.read(game.save_path)
	check(disk.people.local.events == events and disk.people.local.gold == game.world.people.local.gold, "retry saves current state including later changes without duplicate records")
	game.mode = "client"
	var before := FileAccess.get_file_as_string(game.save_path)
	check(not game.checkpoint_current() and FileAccess.get_file_as_string(game.save_path) == before, "client composition cannot write disk")
	game.mode = "server"
	DirAccess.make_dir_absolute(game.save_path + ".tmp")
	check(not game.checkpoint_current() and game.checkpoints.pending(game.save_path), "server uses same failure status")
	DirAccess.remove_absolute(game.save_path + ".tmp")
	game.save_clock = 11.0
	game._physics_process(0.0)
	check(not game.checkpoints.pending(game.save_path), "existing server autosave retries pending checkpoint")
	game.mode = "single"
	DirAccess.make_dir_absolute(game.save_path + ".tmp")
	game._notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	check(game.checkpoints.pending(game.save_path) and not game.world.people.local.offline, "failed quit restores control and retains pending warning")
	DirAccess.remove_absolute(game.save_path + ".tmp")
	game.free()
	quit(1 if failures else 0)
