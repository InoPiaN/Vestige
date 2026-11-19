extends RefCounted
const NAMES={"village":"잿불 마을","road":"안개 숲길","harbor":"안개나루"}
const PLACES={"village":[{"kind":"mail","name":"전령 유나 · 안개나루 서신","x":3.0,"y":9.0},{"kind":"coach","name":"마차 정류장 · M으로 노선 보기","x":9.0,"y":16.0},{"kind":"gate","name":"안개 숲길로 출발","x":29.0,"y":9.0,"to":"road"}],"road":[{"kind":"gate","name":"잿불 마을로 돌아가기","x":1.0,"y":9.0,"to":"village"},{"kind":"gate","name":"안개나루로 들어가기","x":29.0,"y":9.0,"to":"harbor"}],"harbor":[{"kind":"gate","name":"안개 숲길로 돌아가기","x":1.0,"y":9.0,"to":"road"},{"kind":"mail","name":"나루지기 도윤 · 서신 전달","x":12.0,"y":9.0},{"kind":"harbor_shop","name":"나루 상인 소하 · 물자 구매","x":18.0,"y":10.0},{"kind":"harbor_rest","name":"물안개 여관 · 휴식","x":9.0,"y":5.0},{"kind":"coach","name":"마차 정류장 · M으로 노선 보기","x":5.0,"y":14.0}]}
const GOODS={"wood":{"price":2,"stock":10},"cloth":{"price":3,"stock":8},"herb":{"price":3,"stock":8}}
static func region(p: Dictionary) -> String:
	var room: String=p.get("room","village")
	return "village" if room=="home" else room
static func prepare_person(p: Dictionary) -> void:
	if not p.has("discovered"): p.discovered=["village"]
	if not p.has("mail_quest"): p.mail_quest="new"
static func prepare(w: Dictionary) -> void:
	if not w.has("harbor_market"): w.harbor_market={"day":-1,"stock":{}}
	var day:=int(w.time/2880)
	if day>w.harbor_market.day:
		w.harbor_market.day=day
		for id in GOODS: w.harbor_market.stock[id]=GOODS[id].stock
static func near(p: Dictionary,t: Dictionary) -> bool:
	return p.alive and not p.offline and p.get("room","village")!="home" and Vector2(p.x,p.y).distance_to(Vector2(t.x,t.y))<1.9
static func nearby(p: Dictionary) -> Dictionary:
	if p.get("room","village")=="home": return {}
	var best: Dictionary={}
	var distance:=1.9
	for t in PLACES.get(region(p),[]):
		var d:=Vector2(p.x,p.y).distance_to(Vector2(t.x,t.y))
		if d<distance:
			distance=d
			best=t
	return best
static func arrive(p: Dictionary,to: String,x: float,y: float) -> String:
	p.room=to
	p.x=x
	p.y=y
	p.target_enemy=""
	p.attack=0.0
	p.dodge=0.0
	p.motion=0.0
	p.guard_time=0.0
	p.shot_time=0.0
	var text: String=NAMES[to]+"에 도착했다."
	if to not in p.discovered:
		p.discovered.append(to)
		text+=" 지도의 새로운 지역을 발견했다."
	p.events.append(text)
	return text
static func walkable(p: Dictionary,at: Vector2) -> bool:
	if at.x<1 or at.x>29 or at.y<1 or at.y>18: return false
	if region(p)=="road": return at.y>=6 and at.y<=12
	if at.x>23 and at.y<12: return false # Water; southern pier is walkable.
	for center in [Vector2(9,4),Vector2(18,8)]:
		if Rect2(center-Vector2(1,1.5),Vector2(2,1.9)).has_point(at): return false
	return true
static func coach_reason(p: Dictionary) -> String:
	if not p.alive or p.offline or p.get("room","village")=="home": return "직접 조종 중인 인물로 마차 정류장에 오세요."
	var here:=region(p)
	if here not in ["village","harbor"]: return "마을의 마차 정류장에서만 탈 수 있습니다."
	if "harbor" not in p.discovered: return "먼저 숲길을 걸어 안개나루를 발견하세요."
	var close:=false
	for t in PLACES[here]:
		if t.kind=="coach" and near(p,t): close=true
	if not close: return "마차 정류장 가까이에 오세요."
	if p.gold<5: return "운임 은화 5개가 필요합니다. 걸어서도 왕복할 수 있습니다."
	return ""
static func coach(p: Dictionary) -> String:
	var why:=coach_reason(p)
	if not why.is_empty(): return why
	p.gold-=5
	var to: String="harbor" if region(p)=="village" else "village"
	var text:=arrive(p,to,5 if to=="harbor" else 9,14 if to=="harbor" else 16)
	p.events.append("마차 운임으로 은화 5개를 지불했다.")
	return text+" · 운임 은화 -5"
static func interact(w: Dictionary,p: Dictionary,t: Dictionary) -> String:
	if t.is_empty() or not near(p,t): return "시설 가까이에서 E를 누르세요."
	match t.kind:
		"gate":
			var to: String=t.to
			var x:=2.5 if (region(p)=="village" or to=="harbor") else 27.5
			return arrive(p,to,x,9)
		"coach": return "지역 지도"
		"harbor_shop": return "나루 물자"
		"harbor_rest":
			p.hp=100
			p.stamina=100.0
			p.events.append("안개나루 여관에서 몸을 쉬었다.")
			return "물안개 여관 · 체력과 기력을 회복했습니다."
		"mail":
			if region(p)=="village":
				if p.mail_quest=="new":
					p.mail_quest="outbound"
					p.events.append("전령 유나에게 안개나루로 전할 서신을 받았다.")
					return "동쪽 출구 → 안개 숲길 → 안개나루의 도윤에게 서신을 전하세요."
				if p.mail_quest=="reply":
					p.mail_quest="done"
					p.gold+=12
					p.events.append("안개나루의 답신을 유나에게 전달했다. 보상 은화 +12.")
					return "답신 전달 완료 · 은화 +12"
				return "서신 의뢰를 완료했습니다." if p.mail_quest=="done" else "안개나루의 나루지기 도윤을 찾아가세요."
			if p.mail_quest=="outbound":
				p.mail_quest="reply"
				p.events.append("안개나루의 도윤에게 서신을 전하고 답신을 받았다.")
				return "도윤: 잿불 마을의 유나에게 이 답신을 전해 주세요."
			return "도윤: 물안개 여관에서 쉬고, 소하에게 여행 물자를 구할 수 있습니다."
	return ""
static func buy(w: Dictionary,p: Dictionary,id: String) -> String:
	var t:=nearby(p)
	if region(p)!="harbor" or t.get("kind")!="harbor_shop" or not near(p,t) or not GOODS.has(id): return "나루 상인 소하 가까이에서 물품을 선택하세요."
	prepare(w)
	var items=preload("res://items.gd")
	var rule: Dictionary=GOODS[id]
	if w.harbor_market.stock[id]<=0: return "오늘의 재고가 소진되었습니다."
	if p.gold<rule.price: return "은화가 부족합니다."
	if items.quantity(p,id)>=items.CATALOG[id].limit: return "소지 한도에 도달했습니다."
	preload("res://house_storage.gd").change(p,id,1)
	p.gold-=rule.price
	w.harbor_market.stock[id]-=1
	var text: String="안개나루에서 "+items.CATALOG[id].name+" 구입 · 은화 -%d" % rule.price
	p.events.append(text)
	return text
static func valid(w: Dictionary) -> bool:
	var market=w.get("harbor_market")
	if not market is Dictionary or not market.get("stock") is Dictionary or market.stock.size()!=GOODS.size(): return false
	if not number(market.get("day"),0,int(w.time/2880)): return false
	for id in GOODS:
		if not number(market.stock.get(id),0,GOODS[id].stock): return false
	for p in w.people.values():
		if not p is Dictionary or p.get("room","village") not in ["village","home","road","harbor"]: return false
		if not p.get("discovered") is Array or p.discovered.size()>3 or "village" not in p.discovered: return false
		var seen: Array=[]
		for id in p.discovered:
			if not NAMES.has(id) or id in seen: return false
			seen.append(id)
		if p.get("mail_quest") not in ["new","outbound","reply","done"]: return false
	return true
static func number(n: Variant,low: int,high: int) -> bool:
	return (n is int or n is float) and is_finite(n) and n==floor(n) and n>=low and n<=high
