extends SceneTree
const World = preload("res://world.gd")
const Evidence = preload("res://investigation.gd")
const Dialogue = preload("res://dialogue.gd")
const Chapter = preload("res://story/chapter1_rules.gd")
var failures := 0

func check(condition: bool, label: String) -> void:
	if condition:
		print("PASS: ", label)
	else:
		failures += 1
		push_error(label)

func locate(p: Dictionary, evidence_id: String) -> void:
	p.x = Evidence.EVIDENCE[evidence_id].x
	p.y = Evidence.EVIDENCE[evidence_id].y

func _initialize() -> void:
	var w := World.fresh()
	World.born(w,"a","조사자")
	World.born(w,"b","두 번째 조사자")
	var p: Dictionary = w.people["a"]
	locate(p,"device_log")
	check(World.walkable(World.pos(p)),"E07 record site is accessible")
	check(World.act(w,"a","inspect","device_log").contains("늑대"),"wolf blocks E07 investigation")
	w.wolf.hp=0
	w.wolf.respawn=World.DAY*10
	check(World.act(w,"a","inspect","device_log").contains("증거 기록"),"E07 discovered without a fixed order")
	check(Chapter.has_evidence(p.story.chapter1,"E07"),"logical E07 registered")
	check(not Chapter.inference_supported(p.story.chapter1,"I03"),"E07 alone does not prove accident correlation")
	check(not Chapter.inference_supported(p.story.chapter1,"I06"),"E07 alone does not prove operator")
	var original: Dictionary=p.story.evidence["device_log"].duplicate(true)
	w.time=890.0
	World.act(w,"a","inspect","device_log")
	check(original==p.story.evidence["device_log"],"E07 duplicate retains provenance")
	check(w.people["b"].story.evidence.is_empty(),"E07 is private to the investigator")
	locate(p,"chapel_traces")
	World.act(w,"a","inspect","chapel_traces")
	check(Chapter.inference_supported(p.story.chapter1,"I03"),"E05 plus E07 support limited operation correlation")
	check(Chapter.verify_inference(p.story.chapter1,"I03"),"supported I03 can be verified by story rules")
	check(not Chapter.can_resolve(p.story.chapter1),"operation correlation never opens the ending")
	locate(p,"kael_token")
	World.act(w,"a","inspect","kael_token")
	check(Chapter.has_evidence(p.story.chapter1,"E06"),"token E06 collected")
	var kael: Dictionary=Dialogue.NPCS["kael"]
	p.x=kael.x
	p.y=kael.y
	check(Dialogue.talk(w,"a","kael","kael_compare","kael").is_empty(),"cannot compare without recorded testimony")
	var a:=Dialogue.talk(w,"a","kael","kael_token","kael")
	check(not a.is_empty(),"authorized token presentation available")
	check(Evidence.has_evidence(p,"kael_statement"),"Kael's original claim recorded as E08")
	check(Chapter.has_evidence(p.story.chapter1,"E08"),"E08 linked to story")
	check(p.story.evidence["kael_statement"].fact.contains("진술했다"),"E08 is clearly attributed testimony")
	check(Chapter.inference_supported(p.story.chapter1,"I04"),"E06 and E08 allow testimony comparison")
	check(not Chapter.inference_supported(p.story.chapter1,"I06"),"E07 and testimony do not establish guilt without E13")
	var record: Dictionary = p.story.evidence["kael_statement"].duplicate(true)
	Dialogue.talk(w,"a","kael","kael_token","kael")
	check(record==p.story.evidence["kael_statement"],"repeat conversation does not duplicate E08")
	var options: Dictionary=Dialogue.talk(w,"a","kael")
	check(options.choices.any(func(item): return item.id=="kael_compare"),"comparison unlocked after two sources")
	var compared:=Dialogue.talk(w,"a","kael","kael_compare","kael")
	check(compared.text.contains("별개의 문제"),"comparison does not assert guilt")
	check("kael_device_record_compared" in p.story.chapter1.dialogue_events,"comparison event persisted")
	check(Dialogue.talk(w,"a","bran","kael_compare","bran").is_empty(),"cross-NPC comparison forged choice rejected")
	p.x=5
	p.y=8
	check(Dialogue.talk(w,"a","kael","kael_compare","kael").is_empty(),"remote comparison rejected")
	var notebook:=Evidence.notebook(p)
	check(notebook.contains("진술 대조 가능"),"notebook explains available comparison")
	check(notebook.contains("조작자를 입증하지 않는다"),"notebook keeps inference limited")
	var path: String="/tmp/vestige-device-log-%d.json" % OS.get_process_id()
	World.save_world(w,path)
	var reloaded:=World.load_world(path)
	check(reloaded.people["a"].story.evidence.has("device_log"),"E07 survives save/load")
	check(reloaded.people["a"].story.evidence.has("kael_statement"),"E08 survives save/load")
	check(reloaded.people["a"].story.chapter1.inferences.get("I03")=="verified","I03 survives save/load")
	check(reloaded.people["b"].story.evidence.is_empty(),"other player has no E07/E08")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".bak")
	quit(1 if failures else 0)
