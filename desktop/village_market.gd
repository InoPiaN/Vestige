extends RefCounted
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const LOCATION=Vector2(14,14)
const GEAR_FIELDS=["gear_instances","gear_condition","gear_quality","gear_records"]
const DAY=2880.0
const GOODS={"hide":{"price":3,"stock":10},"cloth":{"price":3,"stock":8},"bent_nail":{"price":2,"stock":12},"broken_cup":{"price":3,"stock":3},"herb":{"price":3,"stock":8},"ore":{"price":4,"stock":8}}
const SELL={"cloth":1,"bent_nail":1,"broken_cup":1,"herb":1,"ore":2,"bandage":3,"repair_kit":4,"mug":3,"herbal_tea":2}
static func prepare_person(p: Dictionary) -> void:
	if not p.has("buyback"): p.buyback=Storage.empty()
	if not p.has("buyback_orders"): p.buyback_orders=[]
static func move_gear(source: Dictionary,target: Dictionary,id: String) -> void:
	var kind: String=source.gear_instances[id]
	Storage.change(source,kind,-1)
	Storage.change(target,kind,1)
	for field in GEAR_FIELDS:
		target[field][id]=source[field][id]
		source[field].erase(id)
static func order(p: Dictionary,token: String) -> Dictionary:
	for row in p.get("buyback_orders",[]):
		if row.token==token: return row
	return {}
static func repurchase(w: Dictionary,p: Dictionary,token: String) -> String:
	if not allowed(p): return "직접 조종 중인 인물로 잿불 장터 가까이에 오세요."
	var row:=order(p,token)
	if row.is_empty(): return "되살 장비가 목록에 없습니다."
	var id: String=row.id
	var kind: String=p.buyback.gear_instances[id]
	if p.gold<row.price: return "은화가 부족합니다."
	if Items.quantity(p,kind)>=Items.CATALOG[kind].limit: return "해당 장비의 소지 한도에 도달했습니다."
	var name: String=Items.definition(p.buyback,id).name
	p.gold-=int(row.price)
	move_gear(p.buyback,p,id)
	p.buyback_orders.erase(row)
	Storage.Record.append(p,id,"repurchased",int(w.time/DAY)+1,"잿불 장터에서 은화 %d에 되샀다." % row.price)
	var text: String=name+" 되사기 · 은화 -%d" % row.price
	p.events.append(text)
	return text
static func prepare(w: Dictionary) -> void:
	var day:=int(w.time/DAY)
	if not w.has("market"): w.market={"day":day,"stock":{}}
	if w.market.stock.is_empty() or day>int(w.market.day):
		w.market.day=day
		for id in GOODS: w.market.stock[id]=GOODS[id].stock
	if not w.market.stock.has("hide"): w.market.stock.hide=GOODS.hide.stock
static func valid(w: Dictionary) -> bool:
	var market=w.get("market")
	if not market is Dictionary or not market.get("stock") is Dictionary: return false
	var day=market.get("day")
	if not (day is int or day is float) or not is_finite(day) or day<0 or day!=floor(day) or day>int(w.time/DAY): return false
	if market.stock.size()!=(GOODS.size() if w.version>=15 or market.stock.has("hide") else GOODS.size()-1): return false
	for id in GOODS:
		if id=="hide" and w.version<15 and not market.stock.has(id): continue
		var n=market.stock.get(id)
		if not (n is int or n is float) or not is_finite(n) or n<0 or n>GOODS[id].stock or n!=floor(n): return false
	if w.version>=18:
		for p in w.people.values():
			if not p.get("buyback") is Dictionary or not p.get("buyback_orders") is Array: return false
			if not p.buyback.get("gear_instances") is Dictionary or p.buyback_orders.size()>10 or p.buyback_orders.size()!=p.buyback.gear_instances.size(): return false
			var ids: Array=[]
			var tokens: Array=[]
			for row in p.buyback_orders:
				if not row is Dictionary or not row.get("id") is String or not row.get("token") is String: return false
				if row.id in ids or row.token in tokens or not row.token.begins_with("sale-"): return false
				if p.buyback.gear_instances.get(row.id) not in ["iron_sword","leather","iron_armor"]: return false
				var coins=row.get("price")
				if not (coins is int or coins is float) or not is_finite(float(coins)) or coins!=floor(coins) or coins<1 or coins>26: return false
				ids.append(row.id)
				tokens.append(row.token)
	return true
static func allowed(p: Dictionary) -> bool:
	return p.alive and not p.offline and p.get("room","village")=="village" and Vector2(p.x,p.y).distance_to(LOCATION)<2
static func price(p: Dictionary,id: String) -> int:
	var kind: String=p.get("gear_instances",{}).get(id,"")
	if kind in ["iron_sword","leather","iron_armor"]:
		if kind!="iron_sword" and p.gear_records[id].maker.is_empty(): return 0
		var q: Dictionary=p.gear_quality[id]
		var prices: Dictionary={"iron_sword":{"common":4,"fine":5,"great":6},"leather":{"common":8,"fine":10,"great":12},"iron_armor":{"common":14,"fine":17,"great":20}}
		var base: int=prices[kind][q.tier]+2*int(q.get("upgrade",0))
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
		if id in p.equipped_ids.values(): return "착용한 장비는 외형·장비에서 먼저 해제하세요."
		if p.gear_instances.has(id):
			prepare_person(p)
			Storage.Record.append(p,id,"sold",int(w.time/DAY)+1,"잿불 장터에서 은화 %d에 판매했다." % coins)
			move_gear(p,p.buyback,id)
			p.buyback_orders.append({"id":id,"price":coins,"token":"sale-"+Crypto.new().generate_random_bytes(12).hex_encode()})
			if p.buyback_orders.size()>10:
				var oldest: Dictionary=p.buyback_orders.pop_front()
				Storage.change(p.buyback,p.buyback.gear_instances[oldest.id],-1)
				for field in GEAR_FIELDS: p.buyback[field].erase(oldest.id)
		else: Storage.change(p,id,-1)
		p.gold+=coins
	var text: String="%s 1개 %s · 은화 %s%d" % [name,"구매" if buy else "판매","-" if buy else "+",coins]
	p.events.append(text)
	return text
