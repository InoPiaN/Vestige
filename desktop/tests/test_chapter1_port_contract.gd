extends SceneTree
## Standalone G-branch compatibility contract. Does not depend on main.gd or UI.
const World = preload("res://world.gd")
const Bridge = preload("res://story/chapter1_bridge.gd")
const Investigation = preload("res://story/chapter1_investigation.gd")
var failures := 0

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func _initialize() -> void:
	var w: Dictionary = World.fresh()
	World.born(w, "a", "조사자")
	World.born(w, "b", "다른 조사자")
	var p: Dictionary = w.people["a"]
	p.offline = false
	check(not p.has("story"), "gameplay spawn does not have Chapter I fields by default")
	Bridge.prepare_person(p)
	check(p.story.chapter1.evidence_links.is_empty(), "bridge creates empty Chapter I state")
	check(w.version == 23, "gameplay save version stays 23")
	var first := Bridge.inspect(w, "a", "last_promise")
	check(first.contains("가까이"), "remote E01 inspection rejected")
	p.room = "harbor"
	p.x = Investigation.EVIDENCE["last_promise"].x
	p.y = Investigation.EVIDENCE["last_promise"].y
	check(not Bridge.inspect(w, "a", "last_promise").contains("증거 기록"), "wrong region cannot collect E01")
	p.room = "village"
	check(Bridge.inspect(w, "a", "last_promise").contains("증거 기록"), "village E01 discovery recorded")
	check(p.story.chapter1.evidence_links.has("E01"), "legacy physical clue maps to E01")
	check(w.people["b"].get("story", {}).is_empty(), "other life does not gain evidence")
	var before: Dictionary = p.story.evidence["last_promise"].duplicate(true)
	Bridge.inspect(w, "a", "last_promise")
	check(p.story.evidence["last_promise"] == before, "repeat inspection is idempotent")
	check(not Bridge.reconstruct(w, "a", "E01", "E07").accepted, "missing evidence cannot prove an inference")
	check(not p.story.chapter1.chapter_completed, "chapter ending remains locked")
	check(not p.story.chapter1.identity_confirmed, "identity is not invented")
	var path := "/tmp/vestige-ch1-bridge-%d.json" % OS.get_process_id()
	check(World.save_world(w, path), "v23 safe-save accepts isolated Chapter I fields")
	var restored: Dictionary = World.load_world(path, false)
	check(restored.version == 23, "load retains gameplay save format")
	check(restored.people["a"].get("story", {}).get("evidence", {}).has("last_promise"), "evidence survives save/reload")
	check(restored.people["a"].story.chapter1.evidence_links.has("E01"), "logical E01 survives save/reload")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path + ".bak")
	DirAccess.remove_absolute(path + ".tmp")
	print("CHAPTER1_PORT: ", ("PASS" if failures == 0 else "FAIL"), " failures=", failures)
	quit(0 if failures == 0 else 1)
