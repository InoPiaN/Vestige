extends SceneTree
## Run: godot --headless --path desktop --script res://tests/test_main_story_director.gd
const Contract = preload("res://story/main_story_contract.gd")
const Director = preload("res://story/main_story_director.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var person: Dictionary = {"story": {"chapter1": {"evidence": {"legacy": true}}}}
	_check(Contract.ensure_person(person), "opt-in state", failures)
	var s: Dictionary = person["main_story"]
	var first: Dictionary = {
		"act": 1,
		"requires_events": [],
		"requires_knowledge": [],
		"grants_knowledge": ["main.waymarker_found"]
	}
	var second: Dictionary = {
		"act": 1,
		"requires_events": ["main.act1.waymarker"],
		"requires_knowledge": ["main.waymarker_found"],
		"grants_knowledge": ["main.expedition_route_confirmed"]
	}
	var before: Dictionary = s.duplicate(true)
	_check(not Director.apply_event(s, "main.act1.route", second)["accepted"], "locked event rejected", failures)
	_check(s == before, "locked event has no side effects", failures)
	_check(Director.apply_event(s, "main.act1.waymarker", first)["accepted"], "first event accepted", failures)
	_check(s["knowledge"].get("main.waymarker_found", false), "knowledge granted", failures)
	before = s.duplicate(true)
	_check(not Director.apply_event(s, "main.act1.waymarker", first)["accepted"], "duplicate rejected", failures)
	_check(s == before, "duplicate side-effect free", failures)
	_check(Director.apply_event(s, "main.act1.route", second)["accepted"], "dependent event accepted", failures)
	_check(not Director.advance_act(s, 1, "main.act1.not_done"), "unearned act gate", failures)
	_check(Director.advance_act(s, 1, "main.act1.route"), "act transition", failures)
	_check(s["current_act"] == 2, "new act stored", failures)
	before = s.duplicate(true)
	_check(not Director.apply_event(s, "main.act1.third", first)["accepted"], "wrong act rejected", failures)
	_check(s == before, "wrong act side-effect free", failures)
	_check(not Director.advance_act(s, 1, "main.act1.route"), "transition cannot repeat", failures)
	var malformed: Dictionary = first.duplicate(true)
	malformed["grants_knowledge"] = ["not_namespaced"]
	_check(not Director.apply_event(s, "main.act2.bad", malformed)["accepted"], "invalid definition rejected", failures)
	_check(person["story"]["chapter1"]["evidence"]["legacy"], "legacy content untouched", failures)
	_check(Contract.valid_state(s), "final state valid", failures)
	_check(Contract.valid_state(JSON.parse_string(JSON.stringify(s))), "JSON round trip", failures)
	if failures.is_empty():
		print("MAIN STORY DIRECTOR: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(ok: bool, description: String, failures: Array[String]) -> void:
	if not ok:
		failures.append(description)
