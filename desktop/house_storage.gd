extends RefCounted
const Record=preload("res://gear_record.gd")
const Items=preload("res://items.gd")
const HOME=Vector2(7,13)
const CAPACITY=40
static func empty() -> Dictionary:
	return {"ore":0,"herb":0,"sword":0,"relic":0,"belongings":{},"equipment":{},"gear_instances":{},"equipped_ids":{},"gear_condition":{},"gear_quality":{},"gear_records":{}}
# Counts remain compatible with gathering/crafting; IDs distinguish individual gear.
static func reconcile(p: Dictionary) -> void:
	if not p.has("gear_instances"): p.gear_instances={}
	if not p.has("equipped_ids"): p.equipped_ids={}
	if not p.has("gear_condition"): p.gear_condition={}
	if not p.has("gear_quality"): p.gear_quality={}
	if not p.has("gear_records"): p.gear_records={}
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
	# Resolve each slot once: multiple body kinds must not erase each other.
	for slot in ["body","head","cloak","weapon"]:
		var kind: String=p.get("equipment",{}).get(slot,"none")
		var ids: Array=[]
		for id in p.gear_instances:
			if p.gear_instances[id]==kind: ids.append(id)
		if ids.is_empty(): p.equipped_ids.erase(slot)
		elif not ids.has(p.equipped_ids.get(slot,"")): p.equipped_ids[slot]=ids[0]
	for id in p.gear_instances:
		if not p.gear_records.has(id): p.gear_records[id]=Record.empty()
		if not p.gear_condition.has(id): p.gear_condition[id]=100
		if not p.gear_quality.has(id): p.gear_quality[id]={"tier":"common","attack":22 if p.gear_instances[id]=="iron_sword" else 0}
		if not p.gear_quality[id].has("upgrade"): p.gear_quality[id].upgrade=0
		if not p.gear_quality[id].has("defense"): p.gear_quality[id].defense=3 if p.gear_instances[id]=="leather" else (6 if p.gear_instances[id]=="iron_armor" else 0)
	for id in p.gear_condition.keys():
		if not p.gear_instances.has(id): p.gear_condition.erase(id)
	for id in p.gear_records.keys():
		if not p.gear_instances.has(id): p.gear_records.erase(id)
	for id in p.gear_quality.keys():
		if not p.gear_instances.has(id): p.gear_quality.erase(id)
static func prepare(w: Dictionary) -> void:
	if not w.has("estate"): return # Version 1 fixture; history is added on load.
	if not w.estate.has("storage"): w.estate.storage=empty()
	for p in w.people.values(): reconcile(p)
	reconcile(w.estate.storage)
	for row in w.get("remains",{}).values(): reconcile(row.contents)
static func allowed(w: Dictionary,p: Dictionary) -> bool:
	return p.alive and not p.offline and (preload("res://house_interior.gd").near(p,"chest") if p.get("room","village")=="home" else Vector2(p.x,p.y).distance_to(HOME)<2) and (w.estate.owner==p.life or w.get("cases",{}).has(w.estate.owner) or w.get("storage_access",false))
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
	if take and Items.family_quantity(p,kind)>=int(def.limit): return "소지품의 해당 물품 한도에 도달했습니다."
	if kind=="relic" and not take: p.relic_found=true
	change(source,kind,-1)
	change(target,kind,1)
	if def.has("slot"):
		source.gear_instances.erase(id)
		target.gear_instances[id]=kind
		target.gear_condition[id]=source.gear_condition[id]
		source.gear_condition.erase(id)
		target.gear_quality[id]=source.gear_quality[id]
		source.gear_quality.erase(id)
		target.gear_records[id]=source.gear_records[id]
		source.gear_records.erase(id)
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
	if not w.get("remains",{}) is Dictionary: return false
	for row in w.get("remains",{}).values():
		if not row is Dictionary or not row.get("contents") is Dictionary: return false
		containers.append(row.contents)
	var seen: Dictionary={}
	for p in containers:
		if not p.get("gear_instances") is Dictionary or not p.get("equipped_ids") is Dictionary: return false
		if not p.get("belongings") is Dictionary or not p.get("equipment") is Dictionary: return false
		for kind in Items.CATALOG:
			var def: Dictionary=Items.CATALOG[kind]
			var value=p.get(def.field) if def.has("field") else p.belongings.get(kind,0)
			if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value!=floor(value): return false
			if def.has("slot") and p.gear_instances.values().count(kind)!=int(value): return false
		if w.version>=7:
			if not p.get("gear_condition") is Dictionary or p.gear_condition.size()!=p.gear_instances.size(): return false
			for id in p.gear_instances:
				var n=p.gear_condition.get(id)
				if not (n is int or n is float) or not is_finite(float(n)) or n<0 or n>100 or n!=floor(n): return false
		if w.version>=13:
			if not p.get("gear_records") is Dictionary or p.gear_records.size()!=p.gear_instances.size(): return false
			for id in p.gear_instances:
				if not Record.valid(p.gear_records.get(id),int(w.time/2880)+1): return false
		if w.version>=8:
			if not p.get("gear_quality") is Dictionary or p.gear_quality.size()!=p.gear_instances.size(): return false
			for id in p.gear_instances:
				var q=p.gear_quality.get(id)
				if not q is Dictionary or q.get("tier") not in ["common","fine","great"]: return false
				if w.version>=14:
					var upgrade=q.get("upgrade")
					if not (upgrade is int or upgrade is float) or not is_finite(float(upgrade)) or upgrade!=floor(upgrade) or upgrade<0 or upgrade>3: return false
					if p.gear_instances[id]!="iron_sword" and upgrade!=0: return false
				if w.version>=15:
					var d=q.get("defense")
					if not (d is int or d is float) or not is_finite(float(d)) or d!=floor(d): return false
					if p.gear_instances[id] in ["leather","iron_armor"]:
						var bounds: Array=preload("res://armor_stats.gd").DEFENSE[p.gear_instances[id]][q.tier]
						if d<bounds[0] or d>bounds[1]: return false
					elif d!=0: return false
				var n=q.get("attack")
				if not (n is int or n is float) or not is_finite(float(n)) or n!=floor(n): return false
				if p.gear_instances[id]=="iron_sword":
					var low: int=20 if q.tier=="common" else (24 if q.tier=="fine" else 27)
					var high: int=24 if q.tier=="common" else (26 if q.tier=="fine" else 29)
					if n<low or n>high: return false
				elif n!=0: return false
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
