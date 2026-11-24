extends SceneTree
## Run: godot --headless --path desktop --script res://tests/test_main_story_contract.gd
const Contract = preload("res://story/main_story_contract.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var legacy: Dictionary = {"name": "traveler", "story": {"chapter1": {"legacy": true}}}
	_check(Contract.valid_person(legacy), "legacy save accepted", failures)
	_check(Contract.ensure_person(legacy), "initialization succeeds", failures)
	_check(Contract.valid_person(legacy), "new state validates", failures)
	_check(legacy["story"]["chapter1"]["legacy"] == true, "legacy chapter untouched", failures)
	var first: Dictionary = legacy["main_story"].duplicate(true)
	_check(Contract.ensure_person(legacy), "second initialization succeeds", failures)
	_check(legacy["main_story"] == first, "initialization is idempotent", failures)
	var state: Dictionary = legacy["main_story"]
	state["knowledge"]["main.living_path_confirmed"] = true
	state["completed_events"]["main.act1.old_waymarker"] = true
	state["decisions"]["name_attitude"] = "present"
	state["relationships"]["arden"] = "distance"
	_check(Contract.valid_state(state), "valid personal choices", failures)
	_check(Contract.valid_state(JSON.parse_string(JSON.stringify(state))), "JSON round trip", failures)
	var bad: Dictionary = state.duplicate(true)
	bad["ending"]["completed"] = "yes"
	_check(not Contract.valid_state(bad), "invalid ending rejected", failures)
	var bad_act: Dictionary = state.duplicate(true)
	bad_act["current_act"] = 9
	_check(not Contract.valid_state(bad_act), "invalid act rejected", failures)
	var bad_flags: Dictionary = state.duplicate(true)
	bad_flags["knowledge"]["main.living_path_confirmed"] = "true"
	_check(not Contract.valid_state(bad_flags), "untrusted knowledge rejected", failures)
	var with_invalid: Dictionary = {"main_story": bad}
	_check(not Contract.ensure_person(with_invalid), "invalid existing data rejected", failures)
	_check(with_invalid["main_story"] == bad, "invalid existing data not overwritten", failures)
	if failures.is_empty():
		print("MAIN STORY CONTRACT: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(value: bool, description: String, failures: Array[String]) -> void:
	if not value:
		failures.append(description)
