extends SceneTree
const World = preload("res://world.gd")
const Bridge = preload("res://story/chapter1_bridge.gd")
const Adapter = preload("res://story/chapter1_interaction_adapter.gd")
const Main = preload("res://main.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error(label)
func fresh() -> Dictionary:
	var w := World.fresh()
	World.born(w, "a", "Observer")
	World.born(w, "b", "Other")
	w.people.a.offline = false
	w.people.a.x = 16.0
	w.people.a.y = 7.0
	return w
func _initialize() -> void:
	var w := fresh()
	var before := w.duplicate(true)
	var view := Adapter.candidate(w, "a")
	check(view == {"target_id":"last_promise", "can_collect":true}, "projection exposes only target and availability")
	view.target_id = "tampered"
	check(w == before and not w.people.a.has("story"), "projection is read only and detached")
	check(Adapter.candidate(w, "missing").is_empty(), "unknown actor has no projection")
	for scenario in ["success", "dead", "offline", "region", "distance", "wolf", "unknown", "duplicate"]:
		w = fresh()
		var target := "last_promise"
		match scenario:
			"dead": w.people.a.alive = false
			"offline": w.people.a.offline = true
			"region": w.people.a.room = "harbor"
			"distance": w.people.a.x = 9.0
			"wolf":
				target = "chapel_traces"
				w.people.a.x = 27.0
				w.people.a.y = 12.0
			"unknown": target = "unknown"
			"duplicate": Bridge.inspect(w, "a", target)
		var legacy := w.duplicate(true)
		var server := w.duplicate(true)
		var other: Dictionary = w.people.b.duplicate(true)
		var message := Bridge.inspect(legacy, "a", target)
		var result := Adapter.execute(w, "a", target, "single", w.people.a.life)
		var remote := Adapter.execute(server, "a", target, "server", server.people.a.life)
		check(w == legacy and result.message == message, "legacy state and message parity: " + scenario)
		check(remote == result and server == w, "single/server parity: " + scenario)
		check(result.recorded == (scenario == "success") and w.people.b == other, "structured discovery and actor isolation: " + scenario)
	w = fresh()
	before = w.duplicate(true)
	check(not Adapter.execute(w, "a", "last_promise", "client", w.people.a.life).recorded and w == before, "client mutation rejected")
	check(not Adapter.execute(w, "a", "last_promise", "server", "old-life").recorded and w == before, "stale life rejected without mutation")
	check(not Adapter.execute(w, "missing", "last_promise", "server", "").recorded and w == before, "unknown actor execution rejected")
	Adapter.candidate(w, "a")
	w.people.a.room = "harbor"
	check(not Adapter.execute(w, "a", "last_promise", "server", w.people.a.life).recorded, "execution rechecks region after projection")
	var game := Main.new()
	game.mode = "single"
	game.world = before.duplicate(true)
	game.chapter1_interaction_adapter_enabled = true
	var enabled := game.inspect_chapter1("a", "last_promise")
	var enabled_world: Dictionary = game.world.duplicate(true)
	game.world = before.duplicate(true)
	game.chapter1_interaction_adapter_enabled = false
	var disabled := game.inspect_chapter1("a", "last_promise")
	check(enabled == disabled and game.world == enabled_world, "composition rollback preserves result and state")
	game.free()
	quit(1 if failures else 0)
