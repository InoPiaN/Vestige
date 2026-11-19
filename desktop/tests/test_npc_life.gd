extends SceneTree
const R=preload("res://world.gd")
const L=preload("res://npc_life.gd")
var failed:=false
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failed=true
		push_error(text)
func at_hour(h: float) -> float: return fposmod(h-8,24)*120
func _initialize() -> void:
	var w:=preload("res://investigation_demo.gd").travel()
	var p: Dictionary=w.people.local
	p.room="harbor"
	p.x=18
	p.y=10
	check(L.hour(0)==8 and L.hour(2880)==8,"World day remains 48 minutes with morning start")
	check(L.phase(at_hour(6))=="새벽" and L.phase(at_hour(12))=="낮" and L.phase(at_hour(18))=="노을" and L.phase(at_hour(23))=="밤","Four visual sky phases agree with world time")
	check(L.shop_open(0) and not L.shop_open(at_hour(7.99)) and not L.shop_open(at_hour(18)),"Shop hours have exact opening and closing boundaries")
	var safe:=true
	var continuous:=true
	for id in L.NAMES:
		var prev:=L.state(id,0)
		for t in range(2881):
			var npc:=L.state(id,t)
			safe=safe and R.Travel.walkable(p,Vector2(npc.x,npc.y))
			continuous=continuous and Vector2(npc.x,npc.y).distance_to(Vector2(prev.x,prev.y))<0.3
			prev=npc
	check(safe,"Both daily routes avoid water and building collisions")
	check(continuous,"NPC motion remains continuous across all schedule boundaries and midnight")
	R.act(w,"local","harbor_buy","wood")
	check(p.belongings.get("wood",0)==1,"Open shop sells at actual merchant position")
	R.advance(w,at_hour(18.25))
	var gold: int=p.gold
	R.act(w,"local","harbor_buy","wood")
	check(p.gold==gold,"Old shop coordinates cannot buy after closing")
	var soha:=L.state("soha",w.time)
	p.x=soha.x
	p.y=soha.y
	var response:=R.act(w,"local","interact")
	check(response.contains("귀가 중"),"Moving merchant can be addressed at actual position")
	R.act(w,"local","harbor_buy","wood")
	check(p.gold==gold,"Following closed merchant cannot bypass hours")
	w.time=at_hour(14)
	p.mail_quest="outbound"
	p.x=12
	p.y=9
	R.act(w,"local","interact")
	check(p.mail_quest=="outbound","Absent guide cannot receive letter at old coordinates")
	var guide:=L.state("doyun",w.time)
	p.x=guide.x
	p.y=guide.y
	R.act(w,"local","interact")
	check(p.mail_quest=="reply","Patrolling guide accepts letter at pier")
	w.time=at_hour(23)
	p.mail_quest="outbound"
	guide=L.state("doyun",w.time)
	p.x=guide.x
	p.y=guide.y
	R.act(w,"local","interact")
	check(p.mail_quest=="outbound","Sleeping guide does not receive letter")
	# Independent chronological fixture for persistence/history assertions.
	w=preload("res://investigation_demo.gd").travel()
	R.advance(w,1500)
	check(not w.npc_activity.is_empty() and L.valid(w),"Major timed activities recorded with valid locations")
	var count: int=w.npc_activity.size()
	R.advance(w,0)
	check(w.npc_activity.size()==count,"Zero elapsed time cannot duplicate activity history")
	var path: String="/tmp/vestige-npc-rules-"+str(OS.get_process_id())+".json"
	w.saved=10000
	check(R.save_world(w,path,10000),"World with activity history saves")
	var loaded:=R.load_world(path,false,10000)
	check(JSON.stringify(loaded.npc_activity)==JSON.stringify(w.npc_activity) and is_equal_approx(loaded.time,w.time),"Reload preserves history and exact NPC location")
	var resumed:=R.load_world(path,true,10000+900)
	check(is_equal_approx(resumed.time,w.time+900) and L.state("doyun",resumed.time).activity==L.state("doyun",w.time+900).activity,"Offline elapsed time restores the correct schedule")
	var again:=R.load_world(path,true,10900)
	check(again.npc_activity==resumed.npc_activity,"Same reconnect timestamp does not duplicate activities")
	R.advance(loaded,2880*500)
	check(loaded.npc_activity.size()<=96 and L.valid(loaded),"Long absence keeps bounded chronological history")
	var redacted:=loaded.duplicate(true)
	R.Investigation.redact(redacted,"local")
	check(not redacted.has("npc_activity"),"Internal activity history not exposed as unearned witness knowledge")
	loaded.npc_activity[0].time=-1
	check(not R.Store.valid(loaded),"Malformed activity timestamps rejected by save validation")
	for ext in ["",".bak"]: DirAccess.remove_absolute(path+ext)
	quit(1 if failed else 0)
