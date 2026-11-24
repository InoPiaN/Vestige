extends RefCounted
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const Life=preload("res://npc_life.gd")
const BOARDS={"village":Vector2(12,8),"harbor":Vector2(15,14)}
const REGIONS={"village":"잿불 마을","harbor":"안개나루"}
const JOBS={
	"herbs":{"title":"소하의 약재 보충","region":"harbor","npc":"soha","name":"소하","needs":{"forest_mushroom":1,"harbor_reed":1},"reward":8,"story":"여행자에게 나눠 줄 약재가 부족합니다. 숲 버섯과 나루 갈대를 한 묶음씩 구해주세요."},
	"salve":{"title":"도윤의 구급 연고","region":"harbor","npc":"doyun","name":"도윤","needs":{"healing_salve":1},"reward":10,"story":"부두에서 일하다 다친 사람들을 위해 회복 연고를 구합니다. 직접 만든 것이 아니어도 좋습니다."},
	"tusk":{"title":"잿불 경비대의 엄니 수집","region":"village","npc":"raon","name":"교관 라온","needs":{"boar_tusk":1},"reward":6,"story":"북쪽 숲 멧돼지의 엄니를 수집하고 있습니다. 손질하지 않은 엄니 한 개를 가져오세요."}}
static func prepare(p: Dictionary) -> void:
	if not p.has("requests"):
		p.requests={}
		for id in JOBS: p.requests[id]={"state":"new","accepted_day":-1,"completed_day":-1}
static func near_board(p: Dictionary,region: String="") -> bool:
	var room: String=p.get("room","village")
	return p.alive and not p.offline and BOARDS.has(room) and (region.is_empty() or room==region) and Vector2(p.x,p.y).distance_to(BOARDS[room])<1.9
static func actor(w: Dictionary,id: String) -> Dictionary:
	if JOBS[id].npc=="raon": return {"x":8.0,"y":6.0,"awake":true,"activity":"경비대 훈련"}
	return Life.state(JOBS[id].npc,w.time)
static func accept_reason(w: Dictionary,p: Dictionary,id: String) -> String:
	if not JOBS.has(id): return "없는 의뢰입니다."
	if not near_board(p,JOBS[id].region): return REGIONS[JOBS[id].region]+" 게시판 가까이에서 수락하세요."
	var row: Dictionary=p.requests[id]
	if row.state=="active": return "이미 진행 중입니다. 의뢰인에게 물품을 전달하세요."
	if row.state=="done" and int(w.time/2880)<=row.completed_day: return "완료한 의뢰는 다음 월드 날부터 다시 받을 수 있습니다."
	return ""
static func accept(w: Dictionary,p: Dictionary,id: String) -> String:
	var why:=accept_reason(w,p,id)
	if not why.is_empty(): return why
	p.requests[id].state="active"
	p.requests[id].accepted_day=int(w.time/2880)
	var text: String="의뢰 수락 · "+JOBS[id].title+". 기한 없이 의뢰인에게 직접 납품하기로 했다."
	p.events.append(text)
	return text
static func deliver_reason(w: Dictionary,p: Dictionary,id: String) -> String:
	if not JOBS.has(id): return "없는 의뢰입니다."
	if not p.alive or p.offline: return "직접 조종 중인 살아 있는 인물로 납품하세요."
	if p.requests[id].state!="active": return "먼저 게시판에서 의뢰를 수락하세요."
	var job: Dictionary=JOBS[id]
	var npc:=actor(w,id)
	if p.get("room","village")!=job.region or Vector2(p.x,p.y).distance_to(Vector2(npc.x,npc.y))>=1.9: return REGIONS[job.region]+"의 "+job.name+" 가까이에서 납품하세요."
	if not npc.awake: return job.name+"이 잠들어 있습니다. 깨어 있을 때 찾아오세요."
	for kind in job.needs:
		if Items.family_quantity(p,kind)<job.needs[kind]: return Items.CATALOG[kind].name+"의 소지 수량이 부족합니다."
	return ""
static func delivery_items(p: Dictionary,id: String) -> Dictionary:
	var result: Dictionary={}
	for base in JOBS[id].needs:
		var left: int=JOBS[id].needs[base]
		for kind in [base,base+"_fine",base+"_great"]:
			var count:=mini(left,Items.quantity(p,kind))
			if count>0: result[kind]=count
			left-=count
	return result
static func deliver(w: Dictionary,p: Dictionary,id: String) -> String:
	var why:=deliver_reason(w,p,id)
	if not why.is_empty(): return why
	var selected:=delivery_items(p,id)
	var names: PackedStringArray=[]
	for kind in selected:
		Storage.change(p,kind,-selected[kind])
		names.append(Items.CATALOG[kind].name+" %d개" % selected[kind])
	var job: Dictionary=JOBS[id]
	p.requests[id].state="done"
	p.requests[id].completed_day=int(w.time/2880)
	p.gold+=job.reward
	var text: String="의뢰 완료 · "+job.title+" · "+", ".join(names)+" 납품 · 은화 +%d" % job.reward
	p.events.append(text)
	return text
static func status(w: Dictionary,p: Dictionary,id: String) -> String:
	var row: Dictionary=p.requests[id]
	if row.state=="active": return "진행 중"
	if row.state=="done": return "다시 수락 가능" if int(w.time/2880)>row.completed_day else "오늘 완료"
	return "미수락"
static func valid(w: Dictionary) -> bool:
	for p in w.people.values():
		if not p is Dictionary or not p.get("requests") is Dictionary or p.requests.size()!=JOBS.size(): return false
		for id in JOBS:
			var row=p.requests.get(id)
			if not row is Dictionary or row.get("state") not in ["new","active","done"]: return false
			for key in ["accepted_day","completed_day"]:
				var n=row.get(key)
				if not (n is int or n is float) or not is_finite(float(n)) or n!=floor(n) or n< -1 or n>int(w.time/2880): return false
			if row.state=="new" and (row.accepted_day!=-1 or row.completed_day!=-1): return false
			if row.state=="active" and (row.accepted_day<0 or row.completed_day>=row.accepted_day): return false
			if row.state=="done" and (row.accepted_day<0 or row.completed_day<row.accepted_day): return false
	return true
static func draw(canvas: Node,region: String) -> void:
	if not BOARDS.has(region): return
	var at: Vector2=BOARDS[region]*16
	canvas.box(at.x-12,at.y-20,24,18,"725338")
	canvas.box(at.x-14,at.y-22,28,4,"ac8b59")
	canvas.box(at.x-10,at.y-2,3,10,"9a7850")
	canvas.box(at.x+7,at.y-2,3,10,"9a7850")
	for x in [-8,1]:
		canvas.box(at.x+x,at.y-17,7,10,"d2c195")
		canvas.box(at.x+x+1,at.y-14,5,1,"80704f")
		canvas.box(at.x+x+1,at.y-11,4,1,"80704f")
