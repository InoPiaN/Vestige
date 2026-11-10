extends RefCounted
const Items=preload("res://items.gd")
const OBJECTS={
	"door":{"name":"마을로 나가기","x":15.0,"y":17.0},
	"drawer":{"name":"낡은 서랍 뒤지기","x":7.0,"y":6.0},
	"shelf":{"name":"책장 · 일지 읽고 보관","x":11.0,"y":6.0},
	"curtain":{"name":"창문 커튼 여닫기","x":16.0,"y":5.0},
	"bed":{"name":"침대에서 휴식","x":22.0,"y":6.0},
	"cupboard":{"name":"찬장 살피기","x":7.0,"y":10.0},
	"hearth":{"name":"벽난로 불 켜고 끄기","x":7.0,"y":14.0},
	"table":{"name":"식탁의 흔적 살피기","x":15.0,"y":11.0},
	"chest":{"name":"물품 보관함","x":22.0,"y":12.0}}
static func inside(p: Dictionary) -> bool:
	return p.get("room","village")=="home"
static func near(p: Dictionary,key: String) -> bool:
	var o: Dictionary=OBJECTS[key]
	return inside(p) and Vector2(p.x,p.y).distance_to(Vector2(o.x,o.y))<1.9
static func nearby(p: Dictionary) -> String:
	if not inside(p): return ""
	var best:=""
	var distance:=1.9
	for key in OBJECTS:
		var o: Dictionary=OBJECTS[key]
		var d:=Vector2(p.x,p.y).distance_to(Vector2(o.x,o.y))
		if d<distance:
			distance=d
			best=key
	return best
static func walkable(at: Vector2) -> bool:
	if at.x<5 or at.x>25 or at.y<4 or at.y>17: return false
	for key in OBJECTS:
		if key in ["door","curtain"]: continue
		var o: Dictionary=OBJECTS[key]
		if Rect2(o.x-0.85,o.y-1.0,1.7,1.5).has_point(at): return false
	return true
static func prepare(w: Dictionary) -> void:
	if not w.has("estate") or w.estate.has("interior"): return
	var rng:=RandomNumberGenerator.new()
	rng.randomize()
	w.estate.interior={"fire":false,"curtain":false,"searched":{},"drawers":{
		"drawer":{"cloth":rng.randi_range(1,3),"bent_nail":rng.randi_range(0,3)},
		"cupboard":{"broken_cup":rng.randi_range(1,2),"herb":rng.randi_range(0,1)}}}
static func enter(w: Dictionary,p: Dictionary) -> String:
	if inside(p) or Vector2(p.x,p.y).distance_to(Vector2(7,13))>=2: return "집 문 가까이에서 들어가세요."
	if w.estate.owner!=p.life and not w.cases.has(w.estate.owner): return "다른 주민이 사는 집입니다."
	p.room="home"
	p.x=15.0
	p.y=16.0
	p.motion=0.0
	return "언덕집에 들어왔습니다. 가구 가까이에서 E로 상호작용하세요."
static func interact(w: Dictionary,p: Dictionary) -> String:
	var key:=nearby(p)
	if key.is_empty(): return "가구 가까이에서 E를 누르세요."
	var state: Dictionary=w.estate.interior
	match key:
		"door":
			p.room="village"
			p.x=7.0
			p.y=14.0
			return "마을로 나왔습니다."
		"chest": return "보관함"
		"drawer","cupboard":
			var contents: Dictionary=state.drawers[key]
			state.searched[key]=true
			for id in ["cloth","bent_nail","broken_cup","herb"]:
				if not contents.has(id) or contents[id]<=0: continue
				var def: Dictionary=Items.CATALOG[id]
				if Items.quantity(p,id)>=int(def.limit): return "소지 한도가 찼습니다. 물건은 가구 안에 그대로 남아 있습니다."
				if def.has("field"): p[def.field]+=1
				else: p.belongings[id]=int(p.belongings.get(id,0))+1
				contents[id]-=1
				var text: String=OBJECTS[key].name+" · "+def.name+" 1개를 찾았다."
				p.events.append(text)
				return text
			return "먼지만 남아 있습니다. 이미 살펴본 가구의 물건은 다시 생기지 않습니다."
		"curtain":
			state.curtain=not state.curtain
			return "커튼을 닫았습니다." if state.curtain else "커튼을 열었습니다."
		"hearth":
			state.fire=not state.fire
			return "벽난로에 불을 밝혔습니다." if state.fire else "벽난로의 불을 껐습니다."
		"bed":
			if w.time-float(p.get("home_rest_at",-60.0))<60: return "아직 충분히 쉬었습니다. 잠시 뒤 다시 누우세요."
			if p.hp>=100 and p.stamina>=100: return "지금은 충분히 쉬었습니다."
			p.home_rest_at=w.time
			p.hp=mini(100,p.hp+25)
			p.stamina=100.0
			p.events.append("언덕집 침대에서 몸을 추슬렀다.")
			return "잠시 쉬었습니다. 체력 +25 · 기력 회복. 세계의 시간을 건너뛰지는 않습니다."
		"table": return "조사 기록\n식탁 모서리에 컵 자국이 겹쳐 있고, 다리 하나는 낡은 천으로 감싸 수선해 두었다."
	return ""
static func valid(w: Dictionary) -> bool:
	var state=w.estate.get("interior")
	if not state is Dictionary or not state.get("fire") is bool or not state.get("curtain") is bool: return false
	if not state.get("drawers") is Dictionary or not state.get("searched") is Dictionary: return false
	for key in ["drawer","cupboard"]:
		if not state.drawers.get(key) is Dictionary: return false
		for id in state.drawers[key]:
			if not id in ["cloth","bent_nail","broken_cup","herb"]: return false
			var n=state.drawers[key][id]
			if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>3 or n!=floor(n): return false
	for value in state.searched.values():
		if not value is bool: return false
	for p in w.people.values():
		if p.get("room","village") not in ["village","home"]: return false
		if p.has("home_rest_at") and (not (p.home_rest_at is float or p.home_rest_at is int) or not is_finite(float(p.home_rest_at))): return false
		if inside(p) and not walkable(Vector2(p.x,p.y)): return false
	return true
