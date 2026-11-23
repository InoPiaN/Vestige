extends SceneTree
const Paths = preload("res://tests/fixtures/test_paths.gd")
const World = preload("res://world.gd")
const Store = preload("res://world_store.gd")
const Adapter = preload("res://story/chapter1_interaction_adapter.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error(label)
func fresh() -> Dictionary:
	var w := World.fresh()
	w.saved = 1000.0
	World.born(w, "a", "Observer")
	w.people.a.offline = false
	w.people.a.x = 16.0
	w.people.a.y = 7.0
	return w
func _initialize() -> void:
	# Real filesystem failures, confined to synthetic fixture directories.
	for obstruction in [".tmp", ".bak.tmp"]:
		var path := Paths.path("world" + obstruction + ".json")
		var w := fresh()
		check(World.save_world(w, path, 1000.0), "seed checkpoint " + obstruction)
		var primary := FileAccess.get_file_as_string(path)
		var backup := FileAccess.get_file_as_string(path + ".bak")
		var result := Adapter.execute(w, "a", "last_promise", "single", w.people.a.life)
		check(result.recorded, "discovery happens before save " + obstruction)
		var record: Dictionary = w.people.a.story.evidence.last_promise.duplicate(true)
		var events: Array = w.people.a.events.duplicate(true)
		check(DirAccess.make_dir_absolute(path + obstruction) == OK, "inject blocked staging path " + obstruction)
		check(not World.save_world(w, path, 2000.0), "failed write returns false " + obstruction)
		check(w.saved == 1000.0 and w.people.a.story.evidence.last_promise == record, "failed save retains pending memory and prior timestamp " + obstruction)
		check(FileAccess.get_file_as_string(path) == primary and FileAccess.get_file_as_string(path + ".bak") == backup, "failure preserves durable primary and backup " + obstruction)
		check(not Store.read(path).people.a.get("story", {}).get("evidence", {}).has("last_promise"), "unsaved discovery absent from durable state " + obstruction)
		check(not Adapter.execute(w, "a", "last_promise", "single", w.people.a.life).recorded and w.people.a.events == events, "repeat command is not a save retry or another discovery " + obstruction)
		check(DirAccess.remove_absolute(path + obstruction) == OK, "remove only injected fixture obstruction " + obstruction)
		check(World.save_world(w, path, 2000.0) and w.saved == 2000.0, "retry checkpoint commits pending state " + obstruction)
		var saved := Store.read(path)
		check(saved.version == 23 and saved.people.a.story.evidence.last_promise == JSON.parse_string(JSON.stringify(record)) and saved.people.a.events == events, "retry retains v23 and single discovery record " + obstruction)
		check(World.save_world(w, path, 2000.0) and Store.read(path).people.a.events == events, "repeated checkpoint is not repeated domain action " + obstruction)
	var path := Paths.path("future.json")
	var w := fresh()
	check(World.save_world(w, path, 1000.0), "seed future-version fixture")
	var future := Store.read(path)
	future.version = 24
	var raw := JSON.stringify(future)
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(raw)
	file.close()
	Adapter.execute(w, "a", "last_promise", "server", w.people.a.life)
	check(not World.save_world(w, path, 2000.0) and w.saved == 1000.0, "future version rejection does not advance timestamp")
	check(FileAccess.get_file_as_string(path) == raw, "future-version save bytes preserved")
	quit(1 if failures else 0)
