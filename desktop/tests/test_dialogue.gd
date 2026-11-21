extends SceneTree
const Rules=preload("res://world.gd")
const D=preload("res://dialogue.gd")
var failed:=0
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failed+=1
		push_error(label)
func _initialize() -> void:
	var w:=Rules.fresh()
	Rules.born(w,"a","여행자")
	Rules.born(w,"b","다른 주민")
	var p: Dictionary=w.people.a
	check(D.talk(w,"a","bran").is_empty(),"out-of-range conversation denied")
	for id in D.NPCS:
		var n: Dictionary=D.NPCS[id]
		p.x=n.x
		p.y=n.y
		check(Rules.walkable(Rules.pos(n)) and D.nearby(p)==id,"NPC reachable: "+id)
		check(D.talk(w,"a",id).text==n.first,"first greeting: "+id)
		check(D.talk(w,"a",id).text==n["return"],"return greeting: "+id)
	check(not p.story.iren_missing_rumor,"greeting does not grant rumor")
	check(D.talk(w,"a","sera","rumor").is_empty(),"choice requires server session")
	check(D.talk(w,"a","sera","forged","sera").is_empty(),"unknown choice denied")
	D.talk(w,"a","sera","rumor","sera")
	check(p.story.iren_missing_rumor and p.events[-1].contains("확인되지"),"rumor records uncertainty in today's notes")
	var count: int=p.events.size()
	D.talk(w,"a","sera","rumor","sera")
	check(p.events.size()==count,"repeated rumor is idempotent")
	check(D.talk(w,"a","sera").text.contains(D.NPCS.sera.known),"known-rumor branch")
	check(not w.people.b.story.iren_missing_rumor and not w.people.b.story.visits.sera,"state isolated per player")
	p.offline=true
	check(D.talk(w,"a","sera").is_empty(),"offline conversation denied")
	p.offline=false
	p.x=D.NPCS.sera.x+D.RADIUS
	check(D.talk(w,"a","sera").is_empty(),"radius boundary denied")
	p.x=D.NPCS.sera.x
	Rules.advance(w,Rules.DAY)
	check(p.journal[-1].text.contains("소문"),"rumor rolls into daily journal")
	var path: String="/tmp/vestige-dialogue-%d.json" % OS.get_process_id()
	Rules.save_world(w,path)
	var loaded:=Rules.load_world(path)
	check(loaded.version==1 and loaded.people.a.story==p.story,"version 1 story save/load roundtrip")
	loaded.people.a.offline=false
	check(D.talk(loaded,"a","sera").text.contains(D.NPCS.sera["return"]),"return branch after reload")
	p.erase("story")
	Rules.save_world(w,path)
	loaded=Rules.load_world(path)
	check(not loaded.people.a.story.iren_missing_rumor and not loaded.people.a.story.visits.bran,"legacy save gets defaults")
	p.x=7
	p.y=7.5
	D.talk(w,"a","bran","rumor","bran")
	Rules.die(w,"a","시험")
	check(D.talk(w,"a","bran").is_empty(),"dead conversation denied")
	Rules.born(w,"a","다음 생애")
	check(not w.people.a.story.iren_missing_rumor and not w.people.a.story.visits.bran,"new life resets knowledge")
	check(w.books[-1].last.contains("소문"),"old life preserves notes in book")
	for place in Rules.PLACES:
		if place.kind in ["forge","library"]:
			var at: Dictionary={"x":place.x,"y":place.y+1}
			check(D.nearby(at).is_empty() and Rules.nearby(at).kind==place.kind,"facility entrance remains accessible: "+place.kind)
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".bak")
	quit(1 if failed else 0)
