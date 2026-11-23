extends SceneTree
const Runtime = preload("res://core/module_runtime.gd")
const Observation = preload("res://tests/fixtures/observation_module.gd")
var failed := 0
var notices := 0
var runtime: Node
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failed += 1
		push_error(label)
func event(id: String = "one", target: String = "object") -> Dictionary:
	return {"id":id,"type":"observation.record","payload":{"target":target}}
func on_commit(_module: String, _id: String, _type: String) -> void:
	notices += 1
	check(not runtime.dispatch("test.observation", event("recursive")), "signal reentrant dispatch rejected")
	check(not runtime.disable_module("test.observation"), "signal reentrant lifecycle rejected")
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	runtime = Runtime.new()
	root.add_child(runtime)
	var module = Observation.new()
	check(runtime.register_module(module), "register content without Core edits")
	check(not runtime.register_module(module), "duplicate module rejected")
	var dependent = Observation.new()
	dependent.identity = "test.dependent"
	dependent.needs = ["missing"]
	check(not runtime.register_module(dependent), "missing dependency rejected")
	dependent.needs = ["test.dependent"]
	check(not runtime.register_module(dependent), "self dependency rejected")
	dependent.needs = ["test.observation"]
	check(runtime.register_module(dependent), "dependency registration")
	check(not runtime.enable_module(dependent.identity), "inactive dependency blocks enable")
	check(not runtime.dispatch(module.identity, event()), "disabled module cannot mutate")
	check(runtime.enable_module(module.identity) and runtime.enable_module(module.identity) and module.enables == 1, "enable is idempotent")
	check(runtime.enable_module(dependent.identity), "dependent enables")
	dependent.needs = []
	check(not runtime.disable_module(module.identity), "registered dependencies remain stable after definition mutation")
	runtime.event_committed.connect(on_commit)
	check(runtime.dispatch(module.identity, event()) and notices == 1, "event commits then emits Signal")
	check(not runtime.dispatch(module.identity, event()) and notices == 1, "duplicate does not emit or mutate")
	var state: Dictionary = runtime.state_for(module.identity)
	state.observed.clear()
	check(runtime.state_for(module.identity).observed == ["object"], "read state is a deep copy")
	check(not runtime.dispatch(module.identity, event("retry", "")), "invalid reduced state rejected")
	check(runtime.dispatch(module.identity, event("retry")), "failed event can retry")
	runtime.event_committed.disconnect(on_commit)
	check(runtime.dispatch(module.identity, event("after_disconnect")) and notices == 2, "explicit Signal unsubscribe")
	check(runtime.disable_module(dependent.identity) and runtime.disable_module(module.identity), "disable dependencies in reverse order")
	check(runtime.state_for(module.identity).observed.size() == 3, "disable preserves state")
	check(runtime.disable_module(module.identity) and module.disables == 1, "disable is idempotent")
	var detached: Dictionary = runtime.snapshot()
	detached.modules[module.identity].state.observed.clear()
	check(runtime.state_for(module.identity).observed.size() == 3, "snapshot cannot mutate runtime state")
	var saved: Dictionary = runtime.snapshot()
	var path := "/tmp/vestige-core-runtime-%s.json" % OS.get_process_id()
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "isolated snapshot file opens")
	if file == null:
		runtime.free()
		quit(1)
		return
	file.store_string(JSON.stringify(saved))
	file.close()
	var decoded: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(path)
	var restored = Runtime.new("server")
	root.add_child(restored)
	var second = Observation.new()
	var second_dependent = Observation.new()
	second_dependent.identity = dependent.identity
	second_dependent.needs = [module.identity]
	restored.register_module(second)
	restored.register_module(second_dependent)
	check(restored.restore(decoded) and restored.snapshot() == saved, "JSON disk roundtrip preserves state and receipts")
	var invalid := decoded.duplicate(true)
	invalid.modules[dependent.identity].state = {"observed":[99]}
	check(not restored.restore(invalid) and restored.snapshot() == saved, "multi-module restore is atomic")
	invalid = decoded.duplicate(true)
	invalid.format_version = 2
	check(not restored.restore(invalid), "future envelope rejected")
	invalid = decoded.duplicate(true)
	invalid.modules[module.identity].state_version = 2
	check(not restored.restore(invalid), "unmigrated module version rejected")
	invalid = decoded.duplicate(true)
	invalid.modules.erase(dependent.identity)
	check(not restored.restore(invalid), "missing module rejected")
	invalid.modules.unknown = decoded.modules[dependent.identity]
	check(not restored.restore(invalid), "unknown module rejected")
	invalid = decoded.duplicate(true)
	invalid.modules[module.identity].processed_event_ids.append("one")
	check(not restored.restore(invalid), "duplicate saved receipt rejected")
	restored.enable_module(module.identity)
	check(not restored.restore(decoded), "active restore rejected")
	check(not restored.dispatch(module.identity, event()), "deduplication survives restore")
	runtime.enable_module(module.identity)
	check(runtime.dispatch(module.identity, event("shared")) and restored.dispatch(module.identity, event("shared")) and runtime.state_for(module.identity) == restored.state_for(module.identity), "single and server use identical reduction")
	check(not runtime.dispatch(module.identity, {"id":"bad", "type":"observation.record", "payload":[]}), "malformed event payload rejected")
	var client = Runtime.new("client")
	client.register_module(Observation.new())
	client.enable_module(module.identity)
	var forged := event()
	forged.payload.authority = "server"
	check(not client.dispatch(module.identity, forged) and client.state_for(module.identity).observed.is_empty(), "client cannot grant itself mutation authority")
	client.free()
	check(not Runtime.json_value({"object":module}) and not Runtime.json_value({"nan":NAN}) and not Runtime.json_value({1:"key"}) and not Runtime.json_value(Vector2.ZERO), "non JSON values rejected")
	check(not runtime.unregister_module(module.identity), "active module cannot unregister")
	runtime.disable_module(module.identity)
	check(not runtime.unregister_module(module.identity), "registered dependent blocks removal")
	check(runtime.unregister_module(dependent.identity), "inactive leaf can unregister")
	check(runtime.enable_module(module.identity), "reenable preserved module")
	root.remove_child(runtime)
	check(module.disables == 3 and runtime.snapshot().modules.is_empty(), "tree exit cleans lifecycle and registry")
	runtime.free()
	restored.shutdown()
	check(second.disables == 1 and restored.snapshot().modules.is_empty(), "explicit shutdown cleans resources")
	restored.free()
	var capped = Runtime.new()
	capped.register_module(Observation.new())
	capped.enable_module(module.identity)
	var all_ok := true
	for index in range(Runtime.MAX_RECEIPTS):
		all_ok = capped.dispatch(module.identity, event(str(index))) and all_ok
	check(all_ok and not capped.dispatch(module.identity, event("overflow")) and not capped.dispatch(module.identity, event("0")), "receipt limit rejects new events without evicting history")
	capped.shutdown()
	capped.free()
	quit(1 if failed else 0)
