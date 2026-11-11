extends RefCounted
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const DEFAULT={"source":"bag","destination":"bag"}
static func prepare(p: Dictionary) -> void:
	if not p.has("craft_supply"): p.craft_supply=DEFAULT.duplicate()
	var plan: Dictionary=p.get("craft_plan",{})
	if not plan.is_empty():
		if not plan.has("source"): plan.source="bag"
		if not plan.has("destination"): plan.destination="bag"
static func valid_settings(s: Dictionary) -> bool:
	return s.get("source") in ["bag","home"] and s.get("destination") in ["bag","home"]
static func valid(p: Dictionary) -> bool:
	return p.get("craft_supply") is Dictionary and valid_settings(p.craft_supply) and (p.get("craft_plan",{}).is_empty() or valid_settings(p.craft_plan))
static func configure(p: Dictionary,value: String) -> String:
	var parts:=value.split("|")
	if parts.size()!=2 or parts[0] not in ["bag","home"] or parts[1] not in ["bag","home"]: return "재료와 보관 장소 설정이 올바르지 않습니다."
	p.craft_supply={"source":parts[0],"destination":parts[1]}
	return "제작 재료와 완성품 보관 장소를 저장했습니다."
static func options(p: Dictionary,override: Dictionary={}) -> Dictionary:
	return override if not override.is_empty() else p.get("craft_supply",DEFAULT)
static func linked(s: Dictionary) -> bool:
	return s.source=="home" or s.destination=="home"
static func owns(w: Dictionary,p: Dictionary) -> bool:
	return w.estate.owner==p.life and p.alive
static func box(w: Dictionary,p: Dictionary) -> Dictionary:
	return w.estate.get("storage",{}) if owns(w,p) else {}
static func available(w: Dictionary,p: Dictionary,id: String,s: Dictionary) -> int:
	return Items.quantity(p,id)+(Items.quantity(box(w,p),id) if s.source=="home" else 0)
static func tool(w: Dictionary,p: Dictionary,base: String,s: Dictionary) -> String:
	for id in [base+"_great",base+"_fine",base]:
		if available(w,p,id,s)>0: return id
	return ""
static func allocation(w: Dictionary,p: Dictionary,cost: Dictionary,s: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for id in cost: result[id]=mini(int(cost[id]),Items.quantity(box(w,p),id)) if s.source=="home" else 0
	return result
static func capacity_reason(w: Dictionary,p: Dictionary,recipe: Dictionary,s: Dictionary) -> String:
	if linked(s) and not owns(w,p): return "본인 소유의 집에서만 보관함을 연동할 수 있습니다."
	if s.destination=="bag":
		if Items.family_quantity(p,recipe.result)>=int(Items.CATALOG[recipe.result].limit): return "완성품 소지 한도에 도달했습니다."
	else:
		var removed:=0
		for n in allocation(w,p,recipe.cost,s).values(): removed+=int(n)
		if Storage.total(box(w,p))-removed+1>Storage.CAPACITY: return "집 보관함 공간이 부족합니다. 재료 소비 후에도 완성품을 넣을 수 없습니다."
	return ""
static func consume(w: Dictionary,p: Dictionary,cost: Dictionary,s: Dictionary) -> void:
	var from_home:=allocation(w,p,cost,s)
	for id in cost:
		if from_home[id]>0: Storage.change(w.estate.storage,id,-int(from_home[id]))
		Storage.change(p,id,-(int(cost[id])-int(from_home[id])))
static func target_count(w: Dictionary,p: Dictionary,id: String,s: Dictionary) -> int:
	return Items.family_quantity(p,id)+(Items.family_quantity(box(w,p),id) if linked(s) else 0)
