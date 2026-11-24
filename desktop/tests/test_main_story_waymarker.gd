extends SceneTree
## Run: godot --headless --path desktop --script res://tests/test_main_story_waymarker.gd
const Waymarker = preload("res://story/main_story_waymarker.gd")
const Content = preload("res://story/main_story_act1_content.gd")
const Contract = preload("res://story/main_story_contract.gd")
const Rules = preload("res://world.gd")
const Store = preload("res://world_store.gd")

func _initialize() -> void:
	var failures: Array[String] = []
	var world: Dictionary = Rules.fresh()
	Rules.born(world, "owner", "현 이름")
	Rules.born(world, "other", "다른 인물")
	var p: Dictionary = world.people["owner"]
	var had_legacy_story: bool = p.has("story")
	var original_legacy: Dictionary = p.get("story", {}).duplicate(true)
	p["room"] = "village"
	p["x"] = Waymarker.LOCATION.x
	p["y"] = Waymarker.LOCATION.y
	p["offline"] = false
	_check(Waymarker.nearby(p), "target reachable", failures)
	_check(Rules.walkable(Waymarker.LOCATION), "waymarker does not block movement", failures)
	_check(Rules.walkable(Waymarker.LOCATION + Vector2(0.5, 0.5)), "surrounding approach walkable", failures)
	var life_id: String = str(p.get("life", ""))
	_check(not life_id.is_empty(), "character life available", failures)
	var before: Dictionary = p.duplicate(true)
	_check(not Waymarker.execute(world, "owner", Content.WAYMARKER_EVIDENCE, "client", life_id).recorded, "client rejected", failures)
	_check(p == before, "client rejection side-effect free", failures)
	_check(not Waymarker.execute(world, "owner", "other.target", "single", life_id).recorded, "arbitrary target rejected", failures)
	_check(not Waymarker.execute(world, "owner", Content.WAYMARKER_EVIDENCE, "single", "old-life").recorded, "wrong life rejected", failures)
	p.x = 11.0
	_check(not Waymarker.execute(world, "owner", Content.WAYMARKER_EVIDENCE, "single", life_id).recorded, "distance rejected", failures)
	p.x = Waymarker.LOCATION.x
	_check(not p.has("main_story"), "invalid requests created no state", failures)
	var recorded: Dictionary = Waymarker.execute(world, "owner", Content.WAYMARKER_EVIDENCE, "single", life_id)
	_check(recorded.get("recorded", false), "first discovery accepted", failures)
	_check(Contract.valid_person(p), "story validated", failures)
	_check(Store.valid(world), "world save schema accepts story", failures)
	_check(p.has("story") == had_legacy_story, "legacy story presence unchanged", failures)
	_check(p.get("story", {}) == original_legacy, "legacy story contents unchanged", failures)
	_check(not world.people["other"].has("main_story"), "other character unchanged", failures)
	_check(p.main_story.completed_events.get(Content.WAYMARKER_EVENT, false), "event marked", failures)
	_check(p.main_story.knowledge.get(Content.WAYMARKER_KNOWLEDGE, false), "knowledge marked", failures)
	_check(Waymarker.notebook(p).contains("추정"), "N notebook has uncertainty", failures)
	var snapshot: Dictionary = p.duplicate(true)
	_check(not Waymarker.execute(world, "owner", Content.WAYMARKER_EVIDENCE, "single", life_id).recorded, "repeat blocked", failures)
	_check(snapshot == p, "repeat no mutation", failures)
	_check(Store.valid(JSON.parse_string(JSON.stringify(world))), "world JSON round trip", failures)
	if failures.is_empty():
		print("MAIN STORY WAYMARKER: PASS")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _check(value: bool, description: String, failures: Array[String]) -> void:
	if not value:
		failures.append(description)
