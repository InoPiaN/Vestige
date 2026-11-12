extends RefCounted
const Stats=preload("res://armor_stats.gd")
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const Quality=preload("res://craft_quality.gd")
const Mastery=preload("res://craft_mastery.gd")
const RECIPES={"leather":{"cost":{"hide":3,"cloth":2},"field":"handicraft"},"iron_armor":{"cost":{"ore":6,"hide":1,"cloth":2},"field":"smithing"}}
static func reason(p: Dictionary,kind: String) -> String:
	if not p.alive or p.offline or p.get("room","village")!="village" or Vector2(p.x,p.y).distance_to(Vector2(5,7))>=2: return "직접 조종 중인 인물로 대장간 가까이에 오세요."
	if not RECIPES.has(kind): return "없는 방어구 제작법입니다."
	if Items.quantity(p,kind)>=Items.CATALOG[kind].limit: return "해당 갑옷의 소지 한도에 도달했습니다."
	for material in RECIPES[kind].cost:
		if Items.quantity(p,material)<RECIPES[kind].cost[material]: return Items.CATALOG[material].name+" 재료가 부족합니다."
	return ""
static func craft(w: Dictionary,p: Dictionary,kind: String) -> String:
	var why:=reason(p,kind)
	if not why.is_empty(): return why
	var recipe: Dictionary=RECIPES[kind]
	var previous: Array=p.gear_instances.keys()
	for material in recipe.cost: Storage.change(p,material,-int(recipe.cost[material]))
	Storage.change(p,kind,1)
	Storage.reconcile(p)
	var id:=""
	for key in p.gear_instances:
		if not previous.has(key): id=key
	var roll:=Quality.roll(w,0,Mastery.rates(p,recipe.field))
	var bounds: Array=Stats.DEFENSE[kind][roll.tier]
	# Same two-draw quality RNG; reuse spread for the armor stat, no reroll.
	var defense: int=bounds[0]+int(roll.attack)% (int(bounds[1])-int(bounds[0])+1)
	p.gear_quality[id]={"tier":roll.tier,"attack":0,"upgrade":0,"defense":defense}
	Storage.Record.create(p,id,int(w.time/2880)+1,Mastery.stage(p,recipe.field),Mastery.FIELDS[recipe.field])
	var text: String="제작 · "+Items.definition(p,id).name+" · 피해 감소 %d · " % defense+Mastery.award(p,kind)
	p.events.append(text)
	return text
