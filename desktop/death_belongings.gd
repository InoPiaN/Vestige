extends RefCounted
const Storage=preload("res://house_storage.gd")
const Items=preload("res://items.gd")
static func prepare(w: Dictionary) -> void:
	if not w.has("remains"): w.remains={}
static func leave(w: Dictionary,p: Dictionary,day: int) -> void:
	prepare(w)
	if w.remains.has(p.life): return
	Storage.reconcile(p)
	var contents:=Storage.empty()
	for key in contents: contents[key]=p.get(key,contents[key]).duplicate(true) if p.get(key) is Dictionary else p.get(key,contents[key])
	contents.equipment={}
	contents.equipped_ids={}
	contents.gold=p.gold
	w.remains[p.life]={"name":p.name,"x":p.x,"y":p.y,"day":day,"contents":contents,"room":p.get("room","village")}
	for kind in Items.CATALOG: Storage.change(p,kind,-Items.quantity(p,kind))
	p.gold=0
	p.gear_instances={}
	p.equipped_ids={}
	for slot in p.equipment: p.equipment[slot]="none"
static func visible(w: Dictionary,p: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for id in w.get("remains",{}):
		var row: Dictionary=w.remains[id]
		if p.get("room","village")==row.get("room","village") and Vector2(p.x,p.y).distance_to(Vector2(row.x,row.y))<2 and (Storage.total(row.contents)>0 or row.contents.gold>0): result[id]=row
	return result
static func take(w: Dictionary,p: Dictionary,value: String) -> String:
	var parts:=value.split("|")
	if parts.size()!=2 or not p.alive or p.offline: return "회수할 유품을 선택하세요."
	var near:=visible(w,p)
	if not near.has(parts[0]): return "유품 가까이에서 회수하세요."
	var row: Dictionary=near[parts[0]]
	var box: Dictionary=row.contents
	var id: String=parts[1]
	var name: String="은화"
	if id=="gold":
		if box.gold<=0: return "남아 있는 은화가 없습니다."
		box.gold-=1
		p.gold+=1
	else:
		var kind: String=box.gear_instances.get(id,id)
		if not Items.CATALOG.has(kind) or Items.quantity(box,id)<=0: return "이미 회수된 물품입니다."
		var def: Dictionary=Items.CATALOG[kind]
		if def.has("slot") and not box.gear_instances.has(id): return "개별 장비를 선택하세요."
		if Items.quantity(p,kind)>=int(def.limit): return "소지품 한도에 도달했습니다. 집에 보관한 뒤 돌아오세요."
		Storage.change(box,kind,-1)
		Storage.change(p,kind,1)
		if def.has("slot"):
			box.gear_instances.erase(id)
			p.gear_instances[id]=kind
		if kind=="relic": p.relic_found=true
		Storage.reconcile(p)
		name=def.name
	var text: String=row.name+"의 유품에서 "+name+" 1개를 회수했다."
	p.events.append(text)
	return text
static func valid(w: Dictionary) -> bool:
	if not w.get("remains") is Dictionary: return false
	for id in w.remains:
		var row=w.remains[id]
		if not id is String or id.is_empty() or not row is Dictionary: return false
		if row.get("room","village") not in ["home","village"]: return false
		if not row.get("name") is String or not row.get("contents") is Dictionary: return false
		for key in ["x","y","day"]:
			if not (row.get(key) is int or row.get(key) is float) or not is_finite(float(row[key])): return false
		if row.day<1 or row.day!=floor(row.day): return false
		var gold=row.contents.get("gold")
		if not (gold is int or gold is float) or not is_finite(float(gold)) or gold<0 or gold!=floor(gold): return false
		if not row.contents.get("equipment") is Dictionary or not row.contents.equipment.is_empty(): return false
		if not row.contents.get("equipped_ids") is Dictionary or not row.contents.equipped_ids.is_empty(): return false
		if w.people.values().any(func(p): return p.life==id and p.alive): return false
	return true
