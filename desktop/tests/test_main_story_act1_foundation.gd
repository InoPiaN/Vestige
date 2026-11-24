extends SceneTree
## Run: godot --headless --path desktop --script res://tests/test_main_story_act1_foundation.gd
const Contract = preload("res://story/main_story_contract.gd")
const Director = preload("res://story/main_story_director.gd")
const Act1 = preload("res://story/main_story_act1_content.gd")
const Snapshot = preload("res://story/main_story_snapshot.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var actor: Dictionary = {"name": "현재 이름", "story": {"chapter1": {"preserve": true}}}
	_check(Contract.ensure_person(actor), "main story state created", failures)
	var state: Dictionary = actor["main_story"]
	var evidence: Dictionary = Act1.waymarker_evidence()
	_check(evidence.id.begins_with("main."), "evidence ID isolated", failures)
	_check(evidence.fact != evidence.inference, "fact and inference separated", failures)
	_check(not Act1.sera_response(false, actor.name).contains("표식이 네 오래된"), "before discovery line", failures)
	var result: Dictionary = Director.apply_event(state, Act1.WAYMARKER_EVENT, Act1.waymarker_definition())
	_check(result.get("accepted", false), "waymarker event registered", failures)
	_check(state.knowledge.get(Act1.WAYMARKER_KNOWLEDGE, false), "waymarker knowledge recorded", failures)
	_check(Act1.sera_response(true, actor.name).contains("표식이 네 오래된"), "after discovery line", failures)
	var existing := state.duplicate(true)
	_check(not Director.apply_event(state, Act1.WAYMARKER_EVENT, Act1.waymarker_definition()).get("accepted", false), "repeat prevented", failures)
	_check(state == existing, "repeat no mutation", failures)
	_check(actor.story.chapter1.preserve, "legacy chapter preserved", failures)
	var others: Dictionary = {"other": {"name": "다른 여행자", "main_story": Contract.initial_state(), "story": {"chapter1": {}}}, "me": actor}
	var snapshot: Dictionary = {"people": others.duplicate(true)}
	Snapshot.redact_other_players(snapshot, "me")
	_check(snapshot.people.me.has("main_story"), "owner keeps personal story", failures)
	_check(not snapshot.people.other.has("main_story"), "other player's story redacted", failures)
	_check(snapshot.people.other.has("story"), "existing redaction is independent", failures)
	_check(others.other.has("main_story"), "authoritative source not modified", failures)
	if failures.is_empty():
		print("MAIN STORY ACT1 FOUNDATION: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(ok: bool, name: String, failures: Array[String]) -> void:
	if not ok:
		failures.append(name)
