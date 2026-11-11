extends RefCounted
const Supply=preload("res://craft_supply.gd")
const Mastery=preload("res://craft_mastery.gd")
const Quality=preload("res://craft_quality.gd")
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const Interior=preload("res://house_interior.gd")
const RECIPES={
	"bandage":{"name":"약초 붕대","cost":{"cloth":1,"herb":1},"result":"bandage","description":"체력 45 회복. 소지품에서 사용합니다."},
	"repair_kit":{"name":"간이 수선 도구","cost":{"cloth":1,"bent_nail":2},"result":"repair_kit","description":"작업대에서 철검 내구도를 40 복원합니다."},
	"mug":{"name":"찻잔 고치기","cost":{"broken_cup":1,"cloth":1},"result":"mug","description":"약초차를 만들 때 계속 사용하는 도구입니다."},
	"herbal_tea":{"name":"약초차 달이기","cost":{"herb":1},"result":"herbal_tea","tool":"mug","fire":true,"description":"체력 20 · 기력 40 회복. 찻잔은 소비하지 않습니다."}}
static func allowed(p: Dictionary) -> bool:
	return p.alive and not p.offline and Interior.near(p,"table")
static func reason(w: Dictionary,p: Dictionary,id: String,automated: bool=false,settings: Dictionary={}) -> String:
	if not automated and not allowed(p): return "직접 조종 중인 인물로 집 작업대 가까이에 오세요."
	if not RECIPES.has(id): return "없는 제작법입니다."
	var recipe: Dictionary=RECIPES[id]
	var supply:=Supply.options(p,settings)
	var capacity:=Supply.capacity_reason(w,p,recipe,supply)
	if not capacity.is_empty(): return capacity
	for material in recipe.cost:
		if Supply.available(w,p,material,supply)<int(recipe.cost[material]): return Items.CATALOG[material].name+" 재료가 부족합니다."
	if recipe.has("tool") and Supply.tool(w,p,recipe.tool,supply).is_empty(): return "고친 찻잔이 필요합니다. 찻잔은 소비하지 않습니다."
	if recipe.get("fire",false) and not w.estate.get("interior",{}).get("fire",false): return "먼저 벽난로에 불을 켜세요."
	return ""
static func craft(w: Dictionary,p: Dictionary,id: String,automated: bool=false,settings: Dictionary={}) -> String:
	var why:=reason(w,p,id,automated,settings)
	if not why.is_empty(): return why
	var recipe: Dictionary=RECIPES[id]
	var supply:=Supply.options(p,settings)
	Supply.consume(w,p,recipe.cost,supply)
	var bonus:=0
	if recipe.has("tool"):
		var tool:=Supply.tool(w,p,recipe.tool,supply)
		bonus=5 if tool.ends_with("_great") else (2 if tool.ends_with("_fine") else 0)
	var roll:=Quality.roll(w,0,Mastery.rates(p,Mastery.RECIPES[id].field,bonus))
	var output: String=recipe.result+("" if roll.tier=="common" else "_"+roll.tier)
	Storage.change(w.estate.storage if supply.destination=="home" else p,output,1)
	var text: String="제작 · "+Quality.LABELS[roll.tier]+" · "+Items.CATALOG[output].name+" 1개를 만들었다."
	if supply.destination=="home": text+=" 집 보관함에 보관했다."
	text+=" · "+Mastery.award(p,id)
	p.events.append(text)
	return text
static func repair(p: Dictionary,id: String,day: int=1) -> String:
	if not allowed(p): return "집 작업대 가까이에서 수선하세요."
	if p.gear_instances.get(id,"")!="iron_sword": return "소지한 철검 하나를 선택하세요."
	var condition: int=p.gear_condition[id]
	if condition>=100: return "이미 온전한 철검입니다."
	var kit:=Items.best(p,"repair_kit")
	if kit.is_empty(): return "간이 수선 도구 1개가 필요합니다."
	Storage.change(p,kit,-1)
	var restore: int=50 if kit.ends_with("_great") else (44 if kit.ends_with("_fine") else 40)
	p.gear_condition[id]=mini(100,condition+restore)
	var text: String="철검 · "+id.right(4)+"을 수선했다. 내구도 %d → %d." % [condition,p.gear_condition[id]]
	Storage.Record.append(p,id,"repaired",day,"내구도 %d → %d 수선" % [condition,p.gear_condition[id]])
	p.events.append(text)
	return text
static func use(p: Dictionary,id: String) -> String:
	var base:=Items.base_id(id)
	if base not in ["bandage","herbal_tea"] or Items.quantity(p,id)<1: return "사용할 물품이 없습니다."
	var grade: int=2 if id.ends_with("_great") else (1 if id.ends_with("_fine") else 0)
	var heal: int=[45,48,54][grade] if base=="bandage" else [20,22,25][grade]
	var energy: int=0 if base=="bandage" else [40,44,50][grade]
	if p.hp>=100 and (energy==0 or p.stamina>=100): return "이미 충분히 회복했습니다."
	Storage.change(p,id,-1)
	p.hp=mini(100,p.hp+heal)
	p.stamina=minf(100,p.stamina+energy)
	return Items.CATALOG[id].name+"을 사용했습니다."
