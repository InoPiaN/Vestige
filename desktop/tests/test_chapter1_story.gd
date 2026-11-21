extends SceneTree
const World = preload("res://world.gd")
const Investigation = preload("res://investigation.gd")
const Chapter1 = preload("res://story/chapter1_rules.gd")
var failures := 0

func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		failures += 1
		push_error("FAIL: " + description)

func _initialize() -> void:
	var w := World.fresh()
	World.born(w, "a", "첫 조사자")
	World.born(w, "b", "다른 조사자")
	var p: Dictionary = w.people["a"]
	var other: Dictionary = w.people["b"]
	check(p.story.has("chapter1"), "new life has chapter1 state")
	check(p.story.chapter1.evidence_links.is_empty(), "no invented clues on spawn")
	check(not Chapter1.can_resolve(p.story.chapter1), "ending locked initially")
	p.x = Investigation.EVIDENCE["last_promise"].x
	p.y = Investigation.EVIDENCE["last_promise"].y
	w.time = 127.5
	check(World.act(w,"a","inspect","last_promise").contains("증거 기록"),"existing E interaction discovers diary")
	check(p.story.chapter1.evidence_links.has("E01"),"diary mirrored to logical E01")
	check(p.story.chapter1.evidence_links["E01"].original_id=="last_promise","old evidence ID preserved")
	check(p.story.chapter1.evidence_links["E01"].discovered_at==127.5,"original world discovery time preserved")
	check(p.story.evidence["last_promise"].order==1,"old notebook order preserved")
	check(other.story.chapter1.evidence_links.is_empty(),"evidence not shared with other player")
	World.act(w,"a","inspect","last_promise")
	check(p.story.chapter1.evidence_links.size()==1,"duplicate inspection not duplicated in chapter")
	check(not Chapter1.verify_inference(p.story.chapter1,"I06"),"diary cannot prove Kael's culpability")
	check(not Chapter1.can_resolve(p.story.chapter1),"no premature resolution")
	check(Chapter1.relationship_event(p.story.chapter1,"bran","first_notice",1),"relationship event applied")
	check(not Chapter1.relationship_event(p.story.chapter1,"bran","first_notice",1),"relationship event idempotent")
	check(p.story.chapter1.relationships.bran.trust==1,"trust not applied twice")
	check(Chapter1.dialogue_once(p.story.chapter1,"BRAN_01"),"first conversation tracked")
	check(not Chapter1.dialogue_once(p.story.chapter1,"BRAN_01"),"conversation event not repeated")
	var path := "/tmp/vestige-chapter1-%d.json" % OS.get_process_id()
	World.save_world(w,path)
	var loaded := World.load_world(path)
	var restored: Dictionary = loaded.people["a"]
	check(restored.story.evidence.has("last_promise"),"original notebook survived save/load")
	check(restored.story.chapter1.evidence_links.has("E01"),"chapter1 link survived save/load")
	check(restored.story.chapter1.relationships.bran.trust==1,"relationship survived save/load")
	restored.story.erase("chapter1")
	World.save_world(loaded,path)
	loaded=World.load_world(path)
	check(loaded.people["a"].story.chapter1.evidence_links.has("E01"),"migrate legacy save with no chapter1")
	World.die(loaded,"a","시험")
	World.born(loaded,"a","후계자")
	check(loaded.people["a"].story.chapter1.evidence_links.is_empty(),"new life does not inherit discovery")
	check(loaded.people["b"].story.chapter1.evidence_links.is_empty(),"unrelated player remains isolated")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".bak")
	quit(1 if failures else 0)
