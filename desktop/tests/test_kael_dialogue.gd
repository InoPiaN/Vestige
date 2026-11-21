extends SceneTree
const R = preload("res://world.gd")
const D = preload("res://dialogue.gd")
const I = preload("res://investigation.gd")
const C = preload("res://story/chapter1_rules.gd")
var failed := 0

func check(ok: bool, description: String) -> void:
	if ok:
		print("PASS: ", description)
	else:
		failed += 1
		push_error(description)

func _initialize() -> void:
	var w := R.fresh()
	R.born(w, "a", "여행자")
	R.born(w, "b", "다른 여행자")
	var p: Dictionary = w.people["a"]
	var n: Dictionary = D.NPCS["kael"]
	check(R.walkable(Vector2(n.x,n.y)), "Kael stands on walkable ground")
	check(D.nearby(p) != "kael", "Kael is not near spawn")
	check(D.talk(w,"a","kael").is_empty(), "remote Kael dialogue rejected")
	p.x = n.x
	p.y = n.y
	check(D.nearby(p) == "kael", "Kael can be targeted")
	check(D.talk(w,"a","kael").text == n.first, "Kael first greeting")
	check(p.story.kael_encountered, "first encounter stored")
	check(D.talk(w,"a","kael").text == n["return"], "Kael return greeting")
	check(D.talk(w,"a","kael","kael_token","kael").is_empty(), "token dialogue locked without evidence")
	check(D.talk(w,"a","bran","kael_irene","bran").is_empty(), "Kael-only choice denied for Bran")
	check(D.talk(w,"a","kael","kael_irene").is_empty(), "unsessioned question rejected")
	var question: Dictionary = D.talk(w,"a","kael","kael_irene","kael")
	check(question.text.contains("이렌"), "Kael answers relationship question")
	check(not question.choices.is_empty(), "Kael question keeps dialogue choices")
	check(not D.talk(w,"a","kael","kael_chapel","kael").size() > 0, "chapel branch requires clue")
	p.x = I.EVIDENCE["kael_token"].x
	p.y = I.EVIDENCE["kael_token"].y
	check(R.walkable(R.pos(p)), "token site walkable")
	check(R.act(w,"a","inspect","kael_token").contains("늑대"), "wolf protects chapel token")
	w.wolf.hp=0
	w.wolf.respawn=R.DAY*10
	w.time=321
	check(R.act(w,"a","inspect","kael_token").contains("증거 기록"), "token can be discovered")
	check(C.has_evidence(p.story.chapter1,"E06"), "physical token mapped to E06")
	check(not C.inference_supported(p.story.chapter1,"I06"), "token does not prove guilt")
	var original: Dictionary = p.story.evidence["kael_token"].duplicate(true)
	R.act(w,"a","inspect","kael_token")
	check(original == p.story.evidence["kael_token"], "token repeated inspection is idempotent")
	p.x=n.x
	p.y=n.y
	var response: Dictionary = D.talk(w,"a","kael")
	check(response.choices.any(func(v): return v.id == "kael_token"), "token choice unlocked by server evidence")
	check(not D.talk(w,"a","kael","kael_token","bran").size() > 0, "wrong active session rejected")
	response=D.talk(w,"a","kael","kael_token","kael")
	check(response.text.contains("내 물건"), "Kael recognizes ownership but not cause")
	check("kael_token_owner_admitted" in p.story.chapter1.dialogue_events, "acknowledgement stored")
	check(not C.can_resolve(p.story.chapter1), "no ending unlocked from admission")
	check(w.people["b"].story.evidence.is_empty(), "other player cannot inherit token")
	var path := "/tmp/vestige-kael-%d.json" % OS.get_process_id()
	R.save_world(w,path)
	var loaded:=R.load_world(path)
	check(loaded.people["a"].story.evidence.has("kael_token"),"token saved and loaded")
	check("kael_token_owner_admitted" in loaded.people["a"].story.chapter1.dialogue_events,"Kael dialogue event survives save")
	check(not loaded.people["b"].story.chapter1.evidence_links.has("E06"),"other player has no logical E06")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".bak")
	quit(1 if failed else 0)
