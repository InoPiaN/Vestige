extends SceneTree
const R=preload("res://world.gd")
const I=preload("res://investigation.gd")
const D=preload("res://dialogue.gd")
const Story=preload("res://story/chapter1_rules.gd")
var failures:=0

func check(ok: bool, message: String) -> void:
	if ok:
		print("PASS: ",message)
	else:
		failures+=1
		push_error(message)

func at_evidence(p: Dictionary, id: String) -> void:
	p.x=I.EVIDENCE[id].x
	p.y=I.EVIDENCE[id].y

func at_npc(p: Dictionary, id: String) -> void:
	p.x=D.NPCS[id].x
	p.y=D.NPCS[id].y

func _initialize() -> void:
	var w:=R.fresh()
	R.born(w,"a","조사자")
	R.born(w,"b","다른 조사자")
	var p: Dictionary=w.people["a"]
	at_evidence(p,"device_key")
	check(R.walkable(R.pos(p)),"E13 position walkable")
	check(R.act(w,"a","inspect","device_key").contains("늑대"),"wolf guards E13")
	w.wolf.hp=0
	w.wolf.respawn=R.DAY*10
	var result: String=R.act(w,"a","inspect","device_key")
	check(result.contains("증거 기록"),"E13 inspect available")
	check(Story.has_evidence(p.story.chapter1,"E13"),"E13 linked to logical evidence")
	check(not Story.inference_supported(p.story.chapter1,"I07"),"E13 alone does not justify tool inference")
	check(not Story.inference_supported(p.story.chapter1,"I06"),"E13 alone does not establish operator")
	var found: Dictionary=p.story.evidence["device_key"].duplicate(true)
	R.act(w,"a","inspect","device_key")
	check(p.story.evidence["device_key"]==found,"E13 repeat preserves provenance")
	check(w.people["b"].story.evidence.is_empty(),"E13 remains private to one life")
	at_npc(p,"sera")
	check(D.talk(w,"a","sera","verify_I07","sera").is_empty(),"unearned I07 verification rejected")
	at_evidence(p,"device_log")
	R.act(w,"a","inspect","device_log")
	check(Story.inference_supported(p.story.chapter1,"I07"),"E07+E13 enable limited I07")
	check(not Story.inference_supported(p.story.chapter1,"I06"),"E07+E13 cannot prove Kael's responsibility")
	at_npc(p,"sera")
	var options: Dictionary=D.talk(w,"a","sera")
	check(options.choices.any(func(x): return x.id=="verify_I07"),"Sera exposes supported reconstruction option")
	check(D.talk(w,"a","kael","verify_I07","kael").is_empty(),"Kael cannot verify Sera-only inference")
	check(D.talk(w,"a","sera","verify_I07","bran").is_empty(),"wrong active dialogue session rejected")
	var checked: Dictionary=D.talk(w,"a","sera","verify_I07","sera")
	check(checked.text.contains("단정"),"Sera preserves incomplete truth")
	check(p.story.chapter1.inferences.get("I07","")=="verified","I07 verified in authoritative story state")
	check(not D.talk(w,"a","sera").choices.any(func(x): return x.id=="verify_I07"),"verified option no longer repeats")
	var notebook:=I.notebook(p)
	check(notebook.contains("I07"),"N notebook includes reconstruction summary")
	check(notebook.contains("검증 완료"),"N notebook shows verified result")
	check(notebook.contains("이렌의 사망을 확정하지"),"N notebook does not confirm final outcome")
	check(not Story.can_resolve(p.story.chapter1),"final choices still locked")
	var path: String="/tmp/vestige-reconstruct-%d.json" % OS.get_process_id()
	R.save_world(w,path)
	var restored:=R.load_world(path)
	check(restored.people["a"].story.evidence.has("device_key"),"E13 survives save/load")
	check(restored.people["a"].story.chapter1.inferences.get("I07","")=="verified","I07 survives save/load")
	check(restored.people["b"].story.chapter1.evidence_links.is_empty(),"other player lacks reconstruction findings")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".bak")
	quit(1 if failures else 0)
