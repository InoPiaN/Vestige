extends RefCounted
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
static func reason(w: Dictionary,p: Dictionary,id: String) -> String:
	if not allowed(p): return "직접 조종 중인 인물로 집 작업대 가까이에 오세요."
	if not RECIPES.has(id): return "없는 제작법입니다."
	var recipe: Dictionary=RECIPES[id]
	if Items.quantity(p,recipe.result)>=int(Items.CATALOG[recipe.result].limit): return "완성품 소지 한도에 도달했습니다."
	for material in recipe.cost:
		if Items.quantity(p,material)<int(recipe.cost[material]): return Items.CATALOG[material].name+" 재료가 부족합니다."
	if recipe.has("tool") and Items.quantity(p,recipe.tool)<1: return "고친 찻잔이 필요합니다. 찻잔은 소비하지 않습니다."
	if recipe.get("fire",false) and not w.estate.get("interior",{}).get("fire",false): return "먼저 벽난로에 불을 켜세요."
	return ""
static func craft(w: Dictionary,p: Dictionary,id: String) -> String:
	var why:=reason(w,p,id)
	if not why.is_empty(): return why
	var recipe: Dictionary=RECIPES[id]
	for material in recipe.cost: Storage.change(p,material,-int(recipe.cost[material]))
	Storage.change(p,recipe.result,1)
	var text: String="작업대에서 "+Items.CATALOG[recipe.result].name+" 1개를 만들었다."
	p.events.append(text)
	return text
static func repair(p: Dictionary,id: String) -> String:
	if not allowed(p): return "집 작업대 가까이에서 수선하세요."
	if p.gear_instances.get(id,"")!="iron_sword": return "소지한 철검 하나를 선택하세요."
	var condition: int=p.gear_condition[id]
	if condition>=100: return "이미 온전한 철검입니다."
	if Items.quantity(p,"repair_kit")<1: return "간이 수선 도구 1개가 필요합니다."
	Storage.change(p,"repair_kit",-1)
	p.gear_condition[id]=mini(100,condition+40)
	var text: String="철검 · "+id.right(4)+"을 수선했다. 내구도 %d → %d." % [condition,p.gear_condition[id]]
	p.events.append(text)
	return text
static func use(p: Dictionary,id: String) -> String:
	if id not in ["bandage","herbal_tea"] or Items.quantity(p,id)<1: return "사용할 물품이 없습니다."
	var heal: int=45 if id=="bandage" else 20
	var energy: int=0 if id=="bandage" else 40
	if p.hp>=100 and (energy==0 or p.stamina>=100): return "이미 충분히 회복했습니다."
	Storage.change(p,id,-1)
	p.hp=mini(100,p.hp+heal)
	p.stamina=minf(100,p.stamina+energy)
	return Items.CATALOG[id].name+"을 사용했습니다."
