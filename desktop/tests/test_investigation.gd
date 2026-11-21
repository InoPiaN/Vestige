extends SceneTree
const R=preload("res://world.gd")
const I=preload("res://investigation.gd")
var failed:=0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failed+=1
		push_error(label)
func at(p: Dictionary, id: String) -> void:
	p.x=I.EVIDENCE[id].x
	p.y=I.EVIDENCE[id].y
func _initialize() -> void:
	for sequence in [["last_promise","chapel_traces"],["chapel_traces","last_promise"]]:
		var w:=R.fresh()
		R.born(w,"a","조사자")
		R.born(w,"b","다른 인물")
		var p: Dictionary=w.people.a
		check(R.act(w,"a","inspect","last_promise").contains("가까이"),"remote inspection denied")
		check(R.act(w,"a","inspect","forged").contains("알 수 없는"),"unknown evidence denied")
		at(p,"chapel_traces")
		R.act(w,"a","inspect","chapel_traces")
		check(p.story.evidence.is_empty(),"living wolf gates chapel investigation")
		w.wolf.hp=0
		w.wolf.respawn=R.DAY*10
		for index in range(sequence.size()):
			var id: String=sequence[index]
			at(p,id)
			check(R.walkable(R.pos(p)),"site is reachable: "+id)
			w.time=100+index*10
			check(R.act(w,"a","inspect",id).contains("증거 기록"),"discovery without rumor or prior evidence: "+id)
			var e: Dictionary=p.story.evidence[id]
			check(e.id==id and e.order==index+1 and e.discovered_at==w.time and e.source==I.EVIDENCE[id].source,"server evidence provenance and sequence")
			check(e.fact!=e.inference and not e.fact.contains("카엘"),"observation separate from hypothesis")
			var count: int=p.events.size()
			var before:=e.duplicate(true)
			w.time+=1
			R.act(w,"a","inspect",id)
			check(p.events.size()==count and p.story.evidence[id]==before,"duplicates preserve original timestamp and journal")
		check(w.people.b.story.evidence.is_empty(),"evidence isolated per player")
		check(p.relic==0 and p.sword==0 and p.ore==0,"investigation does not change inventory or relic")
		var notebook:=I.notebook(p)
		check(notebook.contains("확인된 사실") and notebook.contains("추정 · 미확인") and notebook.find(sequence[0])<notebook.find(sequence[1]),"notebook displays facts, hypotheses and discovery order")
		for npc in R.Dialogue.NPCS:
			p.x=R.Dialogue.NPCS[npc].x
			p.y=R.Dialogue.NPCS[npc].y
			check(not R.Dialogue.talk(w,"a",npc,"evidence",npc).is_empty(),"both-evidence dialogue: "+npc)
		R.advance(w,R.DAY)
		check(p.journal[-1].text.contains("확인된 사실"),"investigation rolls into daily journal")
		var path: String="/tmp/vestige-investigation-%d.json" % OS.get_process_id()
		R.save_world(w,path)
		var restored:=R.load_world(path)
		check(restored.people.a.story.evidence==p.story.evidence,"evidence save roundtrip including timestamps")
		p.story.erase("evidence")
		p.story.iren_missing_rumor=true
		p.relic=1
		R.save_world(w,path)
		restored=R.load_world(path)
		check(restored.people.a.story.evidence.is_empty() and restored.people.a.story.iren_missing_rumor and restored.people.a.relic==1,"dialogue-era save keeps rumor and relic without invented evidence")
		var old: Dictionary=restored.people.a
		old.offline=false
		at(old,"chapel_traces")
		R.act(restored,"a","inspect","chapel_traces")
		check(I.has_evidence(old,"chapel_traces"),"legacy relic owner can still investigate")
		old.erase("story")
		R.save_world(restored,path)
		restored=R.load_world(path)
		check(restored.people.a.story.evidence.is_empty(),"pre-dialogue version 1 migration")
		at(p,"last_promise")
		p.offline=true
		R.act(w,"a","inspect","last_promise")
		check(p.story.get("evidence",{}).is_empty(),"offline investigation denied")
		p.offline=false
		R.act(w,"a","inspect","last_promise")
		R.die(w,"a","시험")
		check(R.act(w,"a","inspect","chapel_traces").contains("삶을 마쳤"),"dead investigation denied")
		R.born(w,"a","후계자")
		check(w.people.a.story.evidence.is_empty() and w.books[-1].last.contains("마지막 약속"),"new life resets knowledge while predecessor journal remains")
		DirAccess.remove_absolute(path)
		DirAccess.remove_absolute(path+".bak")
	var w:=R.fresh()
	R.born(w,"a","분기 검사")
	var p: Dictionary=w.people.a
	for npc in R.Dialogue.NPCS:
		p.x=R.Dialogue.NPCS[npc].x
		p.y=R.Dialogue.NPCS[npc].y
		check(R.Dialogue.talk(w,"a",npc,"evidence",npc).is_empty(),"unearned evidence dialogue rejected")
	for id in I.EVIDENCE:
		p.story.evidence={}
		at(p,id)
		p.x+=I.RADIUS
		R.act(w,"a","inspect",id)
		check(p.story.evidence.is_empty(),"exact radius boundary rejected")
		at(p,id)
		w.wolf.hp=0
		R.act(w,"a","inspect",id)
		for npc in R.Dialogue.NPCS:
			check(not I.testimony(p,npc).is_empty(),"single evidence branch: "+id+" / "+npc)
	quit(1 if failed else 0)
