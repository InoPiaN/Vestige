extends RefCounted
## Main-story-only state contract. Never merges with legacy story.chapter1.
## This module does not alter world saves until a caller explicitly opts in.
const SCHEMA_VERSION := 1
const MIN_ACT := 1
const MAX_ACT := 5
const ARDEN_OUTCOMES := ["", "cooperate", "part", "oppose"]
const SIGNATURE_CHOICES := ["", "current", "both", "unsigned"]

static func initial_state() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"current_act": MIN_ACT,
		"completed_events": {},
		"knowledge": {},
		"decisions": {},
		"relationships": {},
		"ending": {
			"completed": false,
			"arden_outcome": "",
			"signature_choice": ""
		}
	}

## Explicit, non-destructive initialization. Existing invalid data is NOT repaired.
static func ensure_person(person: Dictionary) -> bool:
	if person.has("main_story"):
		return valid_state(person["main_story"])
	person["main_story"] = initial_state()
	return true

static func _boolean_flags(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for key in value:
		if not key is String or (key as String).is_empty() or not value[key] is bool:
			return false
	return true

static func valid_state(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	var state: Dictionary = value
	if not state.get("schema_version") is int and not state.get("schema_version") is float:
		return false
	if int(state.schema_version) != SCHEMA_VERSION or float(state.schema_version) != float(SCHEMA_VERSION):
		return false
	if not state.get("current_act") is int and not state.get("current_act") is float:
		return false
	var act := float(state.current_act)
	if act < MIN_ACT or act > MAX_ACT or floor(act) != act:
		return false
	if not _boolean_flags(state.get("completed_events")):
		return false
	if not _boolean_flags(state.get("knowledge")):
		return false
	if not state.get("decisions") is Dictionary or not state.get("relationships") is Dictionary:
		return false
	for decision in state.decisions:
		if not decision is String or not state.decisions[decision] is String:
			return false
	for character_id in state.relationships:
		if not character_id is String or not state.relationships[character_id] is String:
			return false
	if not state.get("ending") is Dictionary:
		return false
	var ending: Dictionary = state.ending
	if not ending.get("completed") is bool:
		return false
	if not ending.get("arden_outcome") is String or not ending.arden_outcome in ARDEN_OUTCOMES:
		return false
	if not ending.get("signature_choice") is String or not ending.signature_choice in SIGNATURE_CHOICES:
		return false
	return true

static func valid_person(person: Dictionary) -> bool:
	# Story-free saves (including version 1..23) remain valid.
	return not person.has("main_story") or valid_state(person["main_story"])
