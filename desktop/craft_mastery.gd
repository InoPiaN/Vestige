extends RefCounted
const FIELDS={"smithing":"대장 기술","handicraft":"생활 공예","herbalism":"약초 조제"}
const STAGES=["입문","견습","숙련","장인"]
const THRESHOLDS=[0,100,400,1000]
const RATES=[{"common":70,"fine":20,"great":10},{"common":65,"fine":23,"great":12},{"common":57,"fine":27,"great":16},{"common":45,"fine":30,"great":25}]
const RECIPES={"leather":{"field":"handicraft","xp":14,"difficulty":1},"iron_armor":{"field":"smithing","xp":18,"difficulty":2},"iron_sword":{"field":"smithing","xp":12,"difficulty":1},"repair_kit":{"field":"handicraft","xp":10,"difficulty":1},"mug":{"field":"handicraft","xp":8,"difficulty":0},"bandage":{"field":"herbalism","xp":8,"difficulty":0},"herbal_tea":{"field":"herbalism","xp":10,"difficulty":1}}
static func prepare(p: Dictionary) -> void:
	if not p.has("craft_xp"): p.craft_xp={"smithing":0,"handicraft":0,"herbalism":0}
static func xp(p: Dictionary,field: String) -> int:
	return int(p.get("craft_xp",{}).get(field,0))
static func stage(p: Dictionary,field: String) -> int:
	var value:=xp(p,field)
	for i in range(3,-1,-1):
		if value>=THRESHOLDS[i]: return i
	return 0
static func rates(p: Dictionary,field: String,bonus: int=0) -> Dictionary:
	var result: Dictionary=RATES[stage(p,field)].duplicate()
	var extra:=clampi(bonus,0,result.common)
	result.common-=extra
	result.great+=extra
	return result
static func gain(p: Dictionary,recipe: String) -> int:
	if not RECIPES.has(recipe): return 0
	var rule: Dictionary=RECIPES[recipe]
	var reduction:=1+maxi(0,stage(p,rule.field)-int(rule.difficulty))
	return mini(1000-xp(p,rule.field),maxi(1,int(float(rule.xp)/reduction)))
static func award(p: Dictionary,recipe: String) -> String:
	prepare(p)
	if not RECIPES.has(recipe): return ""
	var field: String=RECIPES[recipe].field
	var before:=stage(p,field)
	var amount:=gain(p,recipe)
	p.craft_xp[field]+=amount
	var after:=stage(p,field)
	if after>before: p.events.append("%s의 %s 단계에 올랐다. 손에 익은 기술이 한층 깊어졌다." % [FIELDS[field],STAGES[after]])
	return "%s 경험치 +%d%s" % [FIELDS[field],amount," · "+STAGES[after]+" 달성" if after>before else ""] if amount>0 else FIELDS[field]+" · 장인"
static func progress(p: Dictionary,field: String) -> String:
	var rank:=stage(p,field)
	return "%s · %s · %d / %d XP%s" % [FIELDS[field],STAGES[rank],xp(p,field),THRESHOLDS[rank+1] if rank<3 else 1000," → "+STAGES[rank+1] if rank<3 else " (최고 단계)"]
static func rate_text(p: Dictionary,field: String,bonus: int=0) -> String:
	var chance:=rates(p,field,bonus)
	return "일반 %d%% · 양품 %d%% · 대성공 %d%%" % [chance.common,chance.fine,chance.great]
static func valid(p: Dictionary) -> bool:
	if not p.get("craft_xp") is Dictionary or p.craft_xp.size()!=FIELDS.size(): return false
	for field in FIELDS:
		var value=p.craft_xp.get(field)
		if not (value is int or value is float) or not is_finite(float(value)) or value<0 or value>1000 or value!=floor(value): return false
	return true
