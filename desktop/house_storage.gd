extends RefCounted
const Items=preload("res://items.gd")
const HOME=Vector2(7,13)
const CAPACITY=40
static func empty() -> Dictionary:
	return {"ore":0,"herb":0,"sword":0,"relic":0,"belongings":{},"equipment":{},"gear_instances":{},"equipped_ids":{}}
# Counts remain compatible with gathering/crafting; IDs distinguish individual gear.
static func reconcile(p: Dictionary) -> void:
	if not p.has("gear_instances"): p.gear_instances={}
	if not p.has("equipped_ids"): p.equipped_ids={}
	for kind in Items.CATALOG:
		if not Items.CATALOG[kind].has("slot"): continue
		var ids: Array=[]
		for id in p.gear_instances:
			if p.gear_instances[id]==kind: ids.append(id)
		var count:=Items.quantity(p,kind)
		while ids.size()>count:
			p.gear_instances.erase(ids.pop_back())
		while ids.size()<count:
			var id: String="gear-"+Crypto.new().generate_random_bytes(12).hex_encode()
			p.gear_instances[id]=kind
			ids.append(id)
		var slot: String=Items.CATALOG[kind].slot
		if p.get("equipment",{}).get(slot,"none")!=kind or ids.is_empty(): p.equipped_ids.erase(slot)
		elif not ids.has(p.equipped_ids.get(slot,"")): p.equipped_ids[slot]=ids[0]
static func prepare(w: Dictionary) -> void:
	if not w.has("estate"): return # Version 1 fixture; history is added on load.
	if not w.estate.has("storage"): w.estate.storage=empty()
	for p in w.people.values(): reconcile(p)
static func allowed(w: Dictionary,p: Dictionary) -> bool:
	return p.alive and not p.offline and Vector2(p.x,p.y).distance_to(HOME)<2 and (w.estate.owner==p.life or w.get("cases",{}).has(w.estate.owner) or w.get("storage_access",false))
static func total(p: Dictionary) -> int:
	var result:=0
	for kind in Items.CATALOG: result+=Items.quantity(p,kind)
	return result
static func change(p: Dictionary,kind: String,amount: int) -> void:
	var def: Dictionary=Items.CATALOG[kind]
	if def.has("field"): p[def.field]=int(p.get(def.field,0))+amount
	else: p.belongings[kind]=int(p.belongings.get(kind,0))+amount
static func transfer(w: Dictionary,p: Dictionary,id: String,take: bool) -> String:
	if not allowed(w,p): return "소유한 집이나 주인이 떠난 집 가까이에서 보관함을 이용하세요."
	var box: Dictionary=w.estate.storage
	var source: Dictionary=box if take else p
	var target: Dictionary=p if take else box
	var kind: String=source.gear_instances.get(id,id)
	if not Items.CATALOG.has(kind) or Items.quantity(source,id)<=0: return "옮길 물품이 없습니다."
	var def: Dictionary=Items.CATALOG[kind]
	if def.has("slot") and not source.gear_instances.has(id): return "개별 장비를 선택하세요."
	if not take and total(box)>=CAPACITY: return "집 보관함이 가득 찼습니다. (40개)"
	if take and Items.quantity(p,kind)>=int(def.limit): return "소지품의 해당 물품 한도에 도달했습니다."
	if kind=="relic" and not take: p.relic_found=true
	change(source,kind,-1)
	change(target,kind,1)
	if def.has("slot"):
		source.gear_instances.erase(id)
		target.gear_instances[id]=kind
		if source.equipped_ids.get(def.slot,"")==id:
			source.equipped_ids.erase(def.slot)
			source.equipment[def.slot]="none"
	reconcile(p)
	var text: String=def.name+" 1개를 "+("집에서 꺼냈다." if take else "집에 보관했다.")
	p.events.append(text)
	return text
static func equip(p: Dictionary,id: String) -> String:
	if not p.gear_instances.has(id): return "소지하지 않은 장비입니다."
	var kind: String=p.gear_instances[id]
	var slot: String=Items.CATALOG[kind].slot
	if p.equipped_ids.get(slot,"")==id:
		p.equipment[slot]="none"
		p.equipped_ids.erase(slot)
	else:
		p.equipment[slot]=kind
		p.equipped_ids[slot]=id
	return "장비를 변경했습니다."
static func valid(w: Dictionary) -> bool:
	if not w.estate.get("storage") is Dictionary: return false
	var containers: Array=w.people.values()
	containers.append(w.estate.storage)
	var seen: Dictionary={}
	for p in containers:
		if not p.get("gear_instances") is Dictionary or not p.get("equipped_ids") is Dictionary: return false
		if not p.get("belongings") is Dictionary or not p.get("equipment") is Dictionary: return false
		for kind in Items.CATALOG:
			var def: Dictionary=Items.CATALOG[kind]
			var value=p.get(def.field) if def.has("field") else p.belongings.get(kind,0)
			if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value!=floor(value): return false
			if def.has("slot") and p.gear_instances.values().count(kind)!=int(value): return false
		for id in p.gear_instances:
			if not id is String or not id.begins_with("gear-") or seen.has(id): return false
			var kind=p.gear_instances[id]
			if not Items.CATALOG.has(kind) or not Items.CATALOG[kind].has("slot"): return false
			seen[id]=true
		for slot in p.equipped_ids:
			var id=p.equipped_ids[slot]
			if not p.gear_instances.has(id): return false
			var kind: String=p.gear_instances[id]
			if Items.CATALOG[kind].slot!=slot or p.equipment.get(slot)!=kind: return false
	return total(w.estate.storage)<=CAPACITY
