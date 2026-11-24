extends Node
## Independent experiment: not connected to the existing world, store or RPCs.
const Module = preload("res://core/game_module.gd")
const MAX_RECEIPTS := 1024
signal event_committed(module_id: String, event_id: String, event_type: String)
var _role: String
var _modules: Dictionary = {}
var _states: Dictionary = {}
var _dependencies: Dictionary = {}
var _versions: Dictionary = {}
var _receipts: Dictionary = {}
var _active: Dictionary = {}
var _order: Array[String] = []
var _busy := false

func _init(role: String = "single") -> void: _role = role

static func json_value(value: Variant, depth: int = 0) -> bool:
	if depth > 64: return false
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_STRING: return true
		TYPE_FLOAT: return is_finite(value)
		TYPE_ARRAY:
			for entry in value:
				if not json_value(entry, depth + 1): return false
			return true
		TYPE_DICTIONARY:
			for key in value:
				if not key is String or not json_value(value[key], depth + 1): return false
			return true
	return false

func register_module(module: Module) -> bool:
	if _busy or module == null: return false
	var id := module.module_id()
	if id.is_empty() or _modules.has(id) or module.state_version() < 1: return false
	var seen := {}
	for dependency in module.dependencies():
		if dependency == id or not _modules.has(dependency) or seen.has(dependency): return false
		seen[dependency] = true
	var state := module.initial_state()
	if not json_value(state) or not module.valid_state(state.duplicate(true)): return false
	_modules[id] = module
	_dependencies[id] = module.dependencies().duplicate()
	_versions[id] = module.state_version()
	_states[id] = state.duplicate(true)
	_receipts[id] = []
	_order.append(id)
	return true

func enable_module(id: String) -> bool:
	if _busy or not _modules.has(id): return false
	if _active.has(id): return true
	for dependency in _dependencies[id]:
		if not _active.has(dependency): return false
	_busy = true
	var ok: bool = _modules[id].on_enable()
	if ok: _active[id] = true
	_busy = false
	return ok

func disable_module(id: String) -> bool:
	if _busy or not _modules.has(id): return false
	if not _active.has(id): return true
	for other in _active:
		if id in _dependencies[other]: return false
	_busy = true
	_modules[id].on_disable()
	_active.erase(id)
	_busy = false
	return true

func unregister_module(id: String) -> bool:
	if _busy or not _modules.has(id) or _active.has(id): return false
	for other in _modules:
		if id in _dependencies[other]: return false
	_modules.erase(id)
	_dependencies.erase(id)
	_versions.erase(id)
	_states.erase(id)
	_receipts.erase(id)
	_order.erase(id)
	return true

func state_for(id: String) -> Dictionary:
	return _states.get(id, {}).duplicate(true)

func dispatch(id: String, event: Dictionary) -> bool:
	if _busy or _role not in ["single", "server"] or not _active.has(id): return false
	if not json_value(event): return false
	if not event.get("id") is String or event.id.is_empty(): return false
	if not event.get("type") is String or event.type.is_empty() or not event.get("payload") is Dictionary: return false
	if event.id in _receipts[id] or _receipts[id].size() >= MAX_RECEIPTS: return false
	_busy = true
	var result: Dictionary = _modules[id].reduce(state_for(id), event.duplicate(true))
	var accepted := false
	if result.get("accepted") is bool and result.accepted and result.get("state") is Dictionary:
		accepted = json_value(result.state) and _modules[id].valid_state(result.state.duplicate(true))
	if accepted:
		_states[id] = result.state.duplicate(true)
		_receipts[id].append(event.id)
		event_committed.emit(id, event.id, event.type)
	_busy = false
	return accepted

func snapshot() -> Dictionary:
	var modules := {}
	for id in _order:
		modules[id] = {"state_version":_versions[id], "state":state_for(id), "processed_event_ids":_receipts[id].duplicate()}
	return {"format_version":1, "modules":modules}

func restore(data: Dictionary) -> bool:
	if _busy or not _active.is_empty() or not json_value(data): return false
	if data.get("format_version") != 1 or not data.get("modules") is Dictionary: return false
	if data.modules.size() != _modules.size(): return false
	var states := {}
	var receipts := {}
	for id in _order:
		var entry: Variant = data.modules.get(id)
		if not entry is Dictionary or entry.get("state_version") != _versions[id]: return false
		if not entry.get("state") is Dictionary or not _modules[id].valid_state(entry.state.duplicate(true)): return false
		if not entry.get("processed_event_ids") is Array or entry.processed_event_ids.size() > MAX_RECEIPTS: return false
		var seen := {}
		for receipt in entry.processed_event_ids:
			if not receipt is String or receipt.is_empty() or seen.has(receipt): return false
			seen[receipt] = true
		states[id] = entry.state.duplicate(true)
		receipts[id] = entry.processed_event_ids.duplicate()
	_states = states
	_receipts = receipts
	return true

func shutdown() -> void:
	if _busy: return
	_busy = true
	for index in range(_order.size() - 1, -1, -1):
		var id := _order[index]
		if _active.has(id): _modules[id].on_disable()
	_active.clear()
	_modules.clear()
	_dependencies.clear()
	_versions.clear()
	_states.clear()
	_receipts.clear()
	_order.clear()
	_busy = false

func _exit_tree() -> void: shutdown()
