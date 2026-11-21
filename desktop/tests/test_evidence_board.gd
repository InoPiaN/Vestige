extends SceneTree
const R=preload("res://world.gd")
const I=preload("res://investigation.gd")
const Rules=preload("res://story/evidence_board_rules.gd")
const Main=preload("res://main.gd")
var failed:=0

func check(value: bool, label: String) -> void:
	if value:
		print("PASS: ", label)
	else:
		failed+=1
		push_error(label)

func at(p: Dictionary, clue: String) -> void:
	p.x=I.EVIDENCE[clue].x
	p.y=I.EVIDENCE[clue].y

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var w:=R.fresh()
	R.born(w,"a","조사자")
	R.born(w,"b","다른 조사자")
	var p: Dictionary=w.people["a"]
	check(Rules.available_records(p).is_empty(),"board empty before inspection")
	check(not Rules.evaluate(p,"E05","E07").accepted,"unearned inference denied")
	check(not Rules.evaluate(p,"E07","E07").accepted,"duplicate selection denied")
	w.wolf.hp=0
	w.wolf.respawn=R.DAY*10
	at(p,"chapel_traces")
	R.act(w,"a","inspect","chapel_traces")
	at(p,"device_log")
	R.act(w,"a","inspect","device_log")
	var items: Array=Rules.available_records(p)
	check(items.size()==2 and items[0].id=="E05" and items[1].id=="E07","board lists found clues in discovery order")
	check(not Rules.evaluate(p,"E05","E13").accepted,"unowned E13 rejected")
	check(not Rules.evaluate(p,"E05","E06").accepted,"unmatched pair returns uncertainty")
	var valid: Dictionary=Rules.evaluate(p,"E07","E05")
	check(valid.accepted and valid.inference_id=="I03","reverse pair verifies limited inference")
	check(p.story.chapter1.inferences.get("I03")=="verified","verification persisted in personal story")
	check(not Rules.evaluate(p,"E05","E07").accepted,"repeat does not duplicate confirmation")
	check(not p.story.chapter1.inferences.has("I06"),"operator inference remains locked")
	check(w.people["b"].story.chapter1.inferences.is_empty(),"other player does not gain inference")
	p.offline=true
	check(not Rules.evaluate(p,"E05","E07").accepted,"offline investigator denied")
	p.offline=false
	var path: String="/tmp/vestige-board-state-%d.json" % OS.get_process_id()
	R.save_world(w,path)
	var restored:=R.load_world(path)
	check(restored.people["a"].story.chapter1.inferences.get("I03")=="verified","board inference survives save/load")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".bak")

	var g:=Main.new()
	root.add_child(g)
	g.set_physics_process(false)
	g.save_path="/tmp/vestige-board-ui-%d.json" % OS.get_process_id()
	g.start_single()
	var player: Dictionary=g.world.people["local"]
	at(player,"chapel_traces")
	g.world.wolf.hp=0
	g.world.wolf.respawn=R.DAY*10
	R.act(g.world,"local","inspect","chapel_traces")
	at(player,"device_log")
	R.act(g.world,"local","inspect","device_log")
	g.open_notebook()
	check(g.panel.visible and not g.evidence_board.visible,"N notebook remains default")
	g.open_evidence_board()
	check(g.evidence_board.visible and not g.panel.visible,"board can be opened from notebook")
	g.evidence_board.select_evidence("E05")
	g.evidence_board.select_evidence("E07")
	g.evidence_board._verify()
	check(player.story.chapter1.inferences.get("I03")=="verified","UI selection reaches authoritative local evaluator")
	check(g.evidence_board.feedback.text.contains("I03"),"board displays verification feedback")
	g.close_evidence_board()
	check(g.panel.visible and not g.evidence_board.visible,"board closes back into notebook")
	check(g.panel_text.text.contains("검증 완료"),"notebook reflects reconstruction")
	DirAccess.remove_absolute(g.save_path)
	DirAccess.remove_absolute(g.save_path+".bak")
	g.queue_free()
	quit(1 if failed else 0)
