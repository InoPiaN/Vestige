extends RefCounted
## Content adapter, never a Core dependency. Caller supplies trusted actor/mode.
const Bridge = preload("res://story/chapter1_bridge.gd")
const Investigation = preload("res://story/chapter1_investigation.gd")

static func candidate(world: Dictionary, actor: String) -> Dictionary:
	if not Bridge.allowed(world, actor): return {}
	var person: Dictionary = world.people[actor]
	var id := Investigation.nearby(person)
	if id.is_empty(): return {}
	var collected := Investigation.has_evidence(person, id)
	var guarded: bool = id != "last_promise" and world.wolf.hp > 0
	# Never return facts, inference text, other actors' records, or mutable world data.
	return {"target_id":id, "can_collect":not collected and not guarded}

static func execute(world: Dictionary, actor: String, target: String, role: String, expected_life: String) -> Dictionary:
	if role not in ["single", "server"]:
		return {"recorded":false, "message":"권한이 없는 조사 요청입니다."}
	if not world.get("people", {}).has(actor):
		return {"recorded":false, "message":Bridge.inspect(world, actor, target)}
	var person: Dictionary = world.people[actor]
	if expected_life.is_empty() or person.get("life", "") != expected_life:
		return {"recorded":false, "message":"생애가 변경되어 조사 요청을 취소했습니다."}
	var existed := Investigation.has_evidence(person, target)
	# Revalidate through existing domain rules at execution time, not from candidate().
	var report := Bridge.inspect(world, actor, target)
	return {"recorded":not existed and Investigation.has_evidence(person, target), "message":report}
