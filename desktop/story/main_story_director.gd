extends RefCounted
## Pure per-character story progression. Caller must authorize actor, position,
## interaction, and trusted event definition BEFORE invoking this module.
const Contract = preload("res://story/main_story_contract.gd")

## Definition: {act:int, requires_events:Array[String], requires_knowledge:Array[String],
##              grants_knowledge:Array[String]}. Definitions come from trusted content.
static func apply_event(state: Dictionary, event_id: String, definition: Dictionary) -> Dictionary:
	if not Contract.valid_state(state):
		return {"accepted": false, "reason": "invalid_state"}
	if event_id.is_empty() or not event_id.begins_with("main."):
		return {"accepted": false, "reason": "invalid_event"}
	if not _valid_definition(definition):
		return {"accepted": false, "reason": "invalid_definition"}
	if state["completed_events"].get(event_id, false):
		return {"accepted": false, "reason": "already_completed"}
	if int(state["current_act"]) != int(definition["act"]):
		return {"accepted": false, "reason": "wrong_act"}
	for required_id in definition["requires_events"]:
		if not state["completed_events"].get(required_id, false):
			return {"accepted": false, "reason": "missing_event"}
	for knowledge_id in definition["requires_knowledge"]:
		if not state["knowledge"].get(knowledge_id, false):
			return {"accepted": false, "reason": "missing_knowledge"}
	# All conditions were checked before the first mutation.
	state["completed_events"][event_id] = true
	for knowledge_id in definition["grants_knowledge"]:
		state["knowledge"][knowledge_id] = true
	return {"accepted": true, "reason": "completed"}

## An act transition is explicit and requires a trusted final-event ID.
## No terminal transition beyond act 5 exists.
static func advance_act(state: Dictionary, from_act: int, required_event_id: String) -> bool:
	if not Contract.valid_state(state):
		return false
	if from_act < Contract.MIN_ACT or from_act >= Contract.MAX_ACT:
		return false
	if int(state["current_act"]) != from_act:
		return false
	if required_event_id.is_empty() or not state["completed_events"].get(required_event_id, false):
		return false
	state["current_act"] = from_act + 1
	return true

static func _valid_ids(value: Variant) -> bool:
	if not value is Array:
		return false
	for item in value:
		if not item is String or item.is_empty() or not item.begins_with("main."):
			return false
	return true

static func _valid_definition(definition: Dictionary) -> bool:
	if not definition.has("act") or not definition["act"] is int:
		return false
	if definition["act"] < Contract.MIN_ACT or definition["act"] > Contract.MAX_ACT:
		return false
	for key in ["requires_events", "requires_knowledge", "grants_knowledge"]:
		if not _valid_ids(definition.get(key)):
			return false
	return true
