extends SceneTree
const R=preload("res://world.gd")
const Q=preload("res://village_requests.gd")
const I=preload("res://items.gd")
var failures:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failures+=1
		push_error(text)
func board(p: Dictionary,region: String) -> void:
	p.room=region
	p.x=Q.BOARDS[region].x
	p.y=Q.BOARDS[region].y
func npc(w: Dictionary,p: Dictionary,id: String) -> void:
	var at:=Q.actor(w,id)
	p.room=Q.JOBS[id].region
	p.x=at.x
	p.y=at.y
func run() -> void:
	var w:=preload("res://investigation_demo.gd").travel()
	var p: Dictionary=w.people.local
	check(Q.valid(w) and p.requests.size()==3,"Fresh life has three unaccepted board requests")
	var safe:=true
	for region in Q.BOARDS:
		board(p,region)
		safe=safe and (R.walkable(Vector2(p.x,p.y)) if region=="village" else R.Travel.walkable(p,Vector2(p.x,p.y)))
	check(safe,"Both notice boards have reachable interaction tiles")
	board(p,"harbor")
	check(R.act(w,"local","interact")=="마을 의뢰","E at board opens request UI route")
	R.act(w,"local","request_accept","tusk")
	check(p.requests.tusk.state=="new","Other town request cannot be accepted at wrong board")
	p.x=1
	R.act(w,"local","request_accept","herbs")
	check(p.requests.herbs.state=="new","Remote acceptance rejected")
	board(p,"harbor")
	p.offline=true
	R.act(w,"local","request_accept","herbs")
	check(p.requests.herbs.state=="new","Offline acceptance rejected")
	p.offline=false
	R.act(w,"local","request_accept","herbs")
	check(p.requests.herbs.state=="active" and p.requests.herbs.accepted_day==0,"Local board accepts without taking materials")
	var accepted: Dictionary=p.requests.herbs.duplicate()
	R.act(w,"local","request_accept","herbs")
	check(p.requests.herbs==accepted,"Repeated acceptance preserves current progress")
	p.belongings.forest_mushroom=2
	p.belongings.harbor_reed=2
	var gold: int=p.gold
	R.act(w,"local","request_deliver","herbs")
	check(p.gold==gold and I.quantity(p,"forest_mushroom")==2,"Board is not a remote delivery counter")
	npc(w,p,"herbs")
	p.room="village"
	R.act(w,"local","request_deliver","herbs")
	check(p.gold==gold,"Matching coordinates in wrong region cannot deliver")
	npc(w,p,"herbs")
	p.belongings.harbor_reed=0
	R.act(w,"local","request_deliver","herbs")
	check(I.quantity(p,"forest_mushroom")==2 and p.gold==gold,"Missing second material does not partially consume first")
	p.belongings.harbor_reed=2
	R.act(w,"local","request_deliver","herbs")
	check(p.gold==gold+8 and I.quantity(p,"forest_mushroom")==1 and I.quantity(p,"harbor_reed")==1,"Actual client consumes exact quantities and pays advertised reward")
	check(p.requests.herbs.state=="done" and p.requests.herbs.completed_day==0,"Completion stores world day")
	R.act(w,"local","request_deliver","herbs")
	check(p.gold==gold+8 and I.quantity(p,"forest_mushroom")==1,"Repeated delivery cannot duplicate reward or consumption")
	board(p,"harbor")
	R.act(w,"local","request_accept","herbs")
	check(p.requests.herbs.state=="done","Same-day repeat acceptance denied")
	R.advance(w,2879)
	R.act(w,"local","request_accept","herbs")
	check(p.requests.herbs.state=="done","Cooldown holds until world day boundary")
	R.advance(w,1)
	R.act(w,"local","request_accept","herbs")
	check(p.requests.herbs.state=="active" and p.requests.herbs.accepted_day==1,"Next world day permits new acceptance")
	R.advance(w,2880*5)
	check(p.requests.herbs.state=="active","Accepted request has no time limit across days of absence")
	npc(w,p,"herbs")
	R.act(w,"local","request_deliver","herbs")
	check(p.gold==gold+16 and p.requests.herbs.completed_day==6,"Late delivery pays once and cooldown starts on completion day")
	board(p,"harbor")
	R.act(w,"local","request_accept","salve")
	p.belongings.healing_salve=1
	p.belongings.healing_salve_fine=1
	p.belongings.healing_salve_great=1
	npc(w,p,"salve")
	check(Q.delivery_items(p,"salve")=={"healing_salve":1},"Preview explicitly chooses lowest available quality first")
	R.act(w,"local","request_deliver","salve")
	check(I.quantity(p,"healing_salve")==0 and I.quantity(p,"healing_salve_fine")==1 and I.quantity(p,"healing_salve_great")==1 and p.gold==gold+26,"Ordinary salve delivered without spending higher grades")
	R.advance(w,2880)
	board(p,"harbor")
	R.act(w,"local","request_accept","salve")
	w.estate.storage.belongings.healing_salve=1
	p.belongings.healing_salve_fine=0
	p.belongings.healing_salve_great=0
	npc(w,p,"salve")
	R.act(w,"local","request_deliver","salve")
	check(p.requests.salve.state=="active" and I.quantity(w.estate.storage,"healing_salve")==1,"Delivery uses carried items only, never remote home storage")
	p.belongings.healing_salve_great=1
	R.advance(w,1440) # 20:00; guide returning home, awake.
	npc(w,p,"salve")
	p.offline=true
	R.act(w,"local","request_deliver","salve")
	check(p.requests.salve.state=="active","Offline delivery rejected")
	p.offline=false
	R.advance(w,240) # 22:00, both sleeping.
	npc(w,p,"salve")
	R.act(w,"local","request_deliver","salve")
	check(p.requests.salve.state=="active" and I.quantity(p,"healing_salve_great")==1,"Sleeping client cannot receive deliveries")
	R.advance(w,1200) # Next 08:00.
	npc(w,p,"salve")
	R.act(w,"local","request_deliver","salve")
	check(p.gold==gold+36 and I.quantity(p,"healing_salve_great")==0,"Great salve satisfies minimum quality without unadvertised bonus")
	board(p,"village")
	R.act(w,"local","request_accept","tusk")
	p.belongings.boar_tusk=1
	npc(w,p,"tusk")
	R.act(w,"local","request_deliver","tusk")
	check(p.gold==gold+42 and I.quantity(p,"boar_tusk")==0,"Raon receives tusk at existing mentor location")
	var snapshot:=JSON.stringify(p.requests)
	R.act(w,"local","request_accept","forged")
	R.act(w,"local","request_deliver","forged")
	check(JSON.stringify(p.requests)==snapshot and p.gold==gold+42,"Forged request IDs cannot mutate state")
	R.advance(w,2880)
	check(JSON.stringify(p.journal).contains("의뢰 수락") and JSON.stringify(p.journal).contains("의뢰 완료"),"Accepted and delivered requests appear in daily journal")
	R.born(w,"other","함께 사는 사람")
	var other: Dictionary=w.people.other
	board(other,"harbor")
	R.act(w,"other","request_accept","herbs")
	check(other.requests.herbs.state=="active" and p.requests.herbs.state=="done","Players have independent contracts")
	var view:=w.duplicate(true)
	R.Investigation.redact(view,"local")
	check(not view.people.other.has("requests") and view.people.local.has("requests"),"Only viewer's private request progress reaches snapshot")
	var path: String="/tmp/vestige-requests-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Request progress and cooldown save")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and loaded.people.local.requests.herbs.completed_day==6 and loaded.people.other.requests.herbs.state=="active","Reload preserves active progress and completed day")
	R.act(loaded,"local","resume")
	npc(loaded,loaded.people.local,"tusk")
	var before: int=loaded.people.local.gold
	R.act(loaded,"local","request_deliver","tusk")
	check(loaded.people.local.gold==before,"Reload cannot repay a completed contract")
	var legacy:=w.duplicate(true)
	legacy.version=22
	for person in legacy.people.values(): person.erase("requests")
	var legacy_path:=path+".legacy"
	var file:=FileAccess.open(legacy_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var migrated:=R.load_world(legacy_path,false)
	check(not migrated.is_empty() and migrated.version==23 and migrated.people.local.requests.herbs.state=="new","Version22 migration starts contracts without invented completion")
	for field in ["state","accepted_day","completed_day"]:
		var bad:=w.duplicate(true)
		bad.people.local.requests.herbs[field]="invalid"
		check(not R.Store.valid(bad),"Malformed contract state rejected: "+field)
	var bad:=w.duplicate(true)
	bad.people.local.requests.herbs.completed_day=99999
	check(not R.Store.valid(bad),"Future completion date rejected")
	R.die(w,"local","노환")
	R.born(w,"local","다음 삶")
	check(w.people.local.requests.herbs.state=="new" and w.people.local.requests.herbs.completed_day== -1,"New life starts fresh personal contracts")
	for base in [path,legacy_path]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(base+ext)
	quit(1 if failures else 0)
