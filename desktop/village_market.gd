extends RefCounted
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const LOCATION=Vector2(14,14)
const DAY=2880.0
const GOODS={"cloth":{"price":3,"stock":8},"bent_nail":{"price":2,"stock":12},"broken_cup":{"price":3,"stock":3},"herb":{"price":3,"stock":8},"ore":{"price":4,"stock":8}}
const SELL={"cloth":1,"bent_nail":1,"broken_cup":1,"herb":1,"ore":2,"bandage":3,"repair_kit":4,"mug":3,"herbal_tea":2}
static func prepare(w: Dictionary) -> void:
	var day:=int(w.time/DAY)
	if not w.has("market"): w.market={"day":day,"stock":{}}
	if w.market.stock.is_empty() or day>int(w.market.day):
		w.market.day=day
		for id in GOODS: w.market.stock[id]=GOODS[id].stock
static func valid(w: Dictionary) -> bool:
	var market=w.get("market")
	if not market is Dictionary or not market.get("stock") is Dictionary: return false
	var day=market.get("day")
	if not (day is int or day is float) or not is_finite(day) or day<0 or day!=floor(day) or day>int(w.time/DAY): return false
	if market.stock.size()!=GOODS.size(): return false
	for id in GOODS:
		var n=market.stock.get(id)
		if not (n is int or n is float) or not is_finite(n) or n<0 or n>GOODS[id].stock or n!=floor(n): return false
	return true
static func allowed(p: Dictionary) -> bool:
	return p.alive and not p.offline and p.get("room","village")=="village" and Vector2(p.x,p.y).distance_to(LOCATION)<2
static func price(p: Dictionary,id: String) -> int:
	if p.get("gear_instances",{}).get(id,"")=="iron_sword":
		var q: Dictionary=p.gear_quality[id]
		var base: int={"common":4,"fine":5,"great":6}[q.tier]
		return maxi(1,int(base*float(p.gear_condition[id])/100.0))
	var base:=Items.base_id(id)
	if not SELL.has(base) or not Items.CATALOG.has(id): return 0
	return int(SELL[base])+(2 if id.ends_with("_great") else (1 if id.ends_with("_fine") else 0))
static func trade(w: Dictionary,p: Dictionary,id: String,buy: bool) -> String:
	if not allowed(p): return "직접 조종 중인 인물로 잿불 장터 가까이에 오세요."
	prepare(w)
	var name: String=Items.definition(p,id).get("name",id)
	var coins:=0
	if buy:
		if not GOODS.has(id): return "판매하지 않는 물품입니다."
		coins=GOODS[id].price
		if w.market.stock[id]<=0: return "오늘 준비한 재고가 소진되었습니다. 다음 월드 날짜에 보충됩니다."
		if p.gold<coins: return "은화가 부족합니다."
		if Items.family_quantity(p,id)>=Items.CATALOG[id].limit: return "소지 한도에 도달했습니다."
		Storage.change(p,id,1)
		p.gold-=coins
		w.market.stock[id]-=1
	else:
		coins=price(p,id)
		if coins<=0 or Items.quantity(p,id)<1: return "판매할 수 없는 물품입니다."
		if id in p.equipped_ids.values(): return "착용한 장비는 먼저 소지품에서 해제하세요."
		if p.gear_instances.has(id):
			Storage.change(p,p.gear_instances[id],-1)
			p.gear_instances.erase(id)
			p.gear_condition.erase(id)
			p.gear_quality.erase(id)
			p.gear_records.erase(id)
		else: Storage.change(p,id,-1)
		p.gold+=coins
	var text: String="%s 1개 %s · 은화 %s%d" % [name,"구매" if buy else "판매","-" if buy else "+",coins]
	p.events.append(text)
	return text
