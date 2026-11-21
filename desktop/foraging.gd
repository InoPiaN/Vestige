extends RefCounted
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const Life=preload("res://npc_life.gd")
const NODES={
	"mushroom_west":{"room":"road","x":9.0,"y":7.0,"item":"forest_mushroom"},
	"mushroom_east":{"room":"road","x":20.0,"y":11.0,"item":"forest_mushroom"},
	"reed_bank":{"room":"harbor","x":22.0,"y":12.0,"item":"harbor_reed"},
	"reed_pier":{"room":"harbor","x":25.0,"y":15.0,"item":"harbor_reed"},
	"flower_west":{"room":"road","x":15.0,"y":7.0,"item":"night_blossom"},
	"flower_east":{"room":"road","x":25.0,"y":7.0,"item":"night_blossom"}}
const REQUEST={"forest_mushroom":1,"harbor_reed":1,"night_blossom":1}
const RECIPES=["healing_salve","vigor_tea"]
const REGEN=2880.0
static func prepare(w: Dictionary) -> void:
	if not w.has("forage_ready"):
		w.forage_ready={}
		for id in NODES: w.forage_ready[id]=0.0
static func person(p: Dictionary) -> void:
	if not p.has("herbal_quest"): p.herbal_quest="new"
	if not p.has("forage_xp"): p.forage_xp=0
static func blooming(time: float) -> bool:
	var hour:=Life.hour(time)
	return hour>=20 or hour<5
static func stage(p: Dictionary) -> String:
	return "숙련" if p.get("forage_xp",0)>=150 else ("견습" if p.get("forage_xp",0)>=50 else "입문")
static func nearby(p: Dictionary) -> String:
	var best:=""
	var distance:=1.5
	for id in NODES:
		var n: Dictionary=NODES[id]
		if p.get("room","village")!=n.room: continue
		var d:=Vector2(p.x,p.y).distance_to(Vector2(n.x,n.y))
		if d<distance:
			distance=d
			best=id
	return best
static func reason(w: Dictionary,p: Dictionary,id: String) -> String:
	if not p.alive or p.offline: return "직접 조종 중인 살아 있는 인물로 채집하세요."
	if not NODES.has(id) or nearby(p)!=id: return "해당 지역의 채집 지점 가까이에서 E를 누르세요."
	var n: Dictionary=NODES[id]
	if w.time<float(w.get("forage_ready",{}).get(id,0)): return "채집한 자원이 다시 자라고 있습니다. 채집 후 월드 하루가 필요합니다."
	if n.item=="night_blossom" and not blooming(w.time): return "밤안개꽃은 밤8시~새벽5시에 핍니다. 상단 하늘의 달을 확인하세요."
	if Items.quantity(p,n.item)>=Items.CATALOG[n.item].limit: return "해당 재료의 소지 한도에 도달했습니다."
	if p.stamina<6: return "채집할 기력이 부족합니다. (필요 6)"
	return ""
static func harvest(w: Dictionary,p: Dictionary,id: String) -> String:
	var why:=reason(w,p,id)
	if not why.is_empty(): return why
	prepare(w)
	person(p)
	var item: String=NODES[id].item
	var amount:=mini(2 if p.forage_xp>=150 else 1,Items.CATALOG[item].limit-Items.quantity(p,item))
	Storage.change(p,item,amount)
	p.stamina-=6
	w.forage_ready[id]=w.time+REGEN
	var before:=stage(p)
	p.forage_xp=mini(1000,p.forage_xp+5)
	var text: String=Items.CATALOG[item].name+" %d개 채집 · 채집 %s (%d XP)" % [amount,stage(p),p.forage_xp]
	p.events.append(text)
	if before!=stage(p): p.events.append("채집 숙련이 "+stage(p)+" 단계에 올랐다.")
	return text
static func mentor_reason(w: Dictionary,p: Dictionary) -> String:
	if not p.alive or p.offline or p.get("room","village")!="harbor": return "직접 조종 중인 인물로 안개나루의 소하를 찾아가세요."
	var npc:=Life.state("soha",w.time)
	if not npc.awake: return "소하가 잠들어 있습니다. 아침에 다시 찾아오세요."
	if Vector2(p.x,p.y).distance_to(Vector2(npc.x,npc.y))>=1.9: return "소하 가까이에서 입문 의뢰를 진행하세요. M에서 생활 일정을 확인할 수 있습니다."
	return ""
static func quest(w: Dictionary,p: Dictionary) -> String:
	var why:=mentor_reason(w,p)
	if not why.is_empty(): return why
	person(p)
	if p.herbal_quest=="done": return "약초꾼 입문 완료 · 집 작업대에서 회복 연고와 기력 차를 만들 수 있습니다."
	if p.herbal_quest=="new":
		p.herbal_quest="active"
		p.events.append("소하에게 약초꾼 입문 의뢰를 받았다. 숲 버섯1, 나루 갈대1, 밤안개꽃1을 모으기로 했다.")
		return "숲 버섯1 · 나루 갈대1 · 밤안개꽃1을 가져오세요. 밤안개꽃은 밤8시~새벽5시에 핍니다."
	for id in REQUEST:
		if Items.quantity(p,id)<REQUEST[id]: return "납품 재료가 부족합니다. 숲 버섯1 · 나루 갈대1 · 밤안개꽃1을 소지하세요."
	for id in REQUEST: Storage.change(p,id,-REQUEST[id])
	p.herbal_quest="done"
	p.gold+=8
	var text:="약초꾼 입문 완료 · 재료를 납품하고 회복 연고·기력 차 조제법을 배웠다. 은화 +8."
	p.events.append(text)
	return text
static func summary(p: Dictionary) -> String:
	var text:="약초꾼 입문 · "
	match p.get("herbal_quest","new"):
		"new": text+="소하에게 의뢰 받기"
		"active": text+="납품 · 버섯%d/1 갈대%d/1 밤꽃%d/1" % [Items.quantity(p,"forest_mushroom"),Items.quantity(p,"harbor_reed"),Items.quantity(p,"night_blossom")]
		"done": text+="조제법2종 습득"
	return text+"  |  채집 %s · %d XP" % [stage(p),p.get("forage_xp",0)]
static func valid(w: Dictionary) -> bool:
	var ready=w.get("forage_ready")
	if not ready is Dictionary or ready.size()!=NODES.size(): return false
	for id in NODES:
		var value=ready.get(id)
		if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>w.time+REGEN: return false
	for p in w.people.values():
		if not p is Dictionary or p.get("herbal_quest") not in ["new","active","done"]: return false
		var xp=p.get("forage_xp")
		if not (xp is int or xp is float) or not is_finite(float(xp)) or xp<0 or xp>1000 or xp!=floor(xp): return false
	return true
