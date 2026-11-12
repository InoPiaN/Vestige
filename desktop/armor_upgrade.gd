extends RefCounted
const Stats=preload("res://armor_stats.gd")
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const COSTS={"leather":[{"hide":1,"cloth":1},{"hide":2,"cloth":2},{"hide":3,"cloth":3}],"iron_armor":[{"ore":2,"hide":1},{"ore":4,"hide":1},{"ore":6,"hide":2}]}
const GOLD=[4,8,12]
static func level(p: Dictionary,id: String) -> int:
	return int(p.get("gear_quality",{}).get(id,{}).get("upgrade",0))
static func reason(p: Dictionary,id: String) -> String:
	if not p.alive or p.offline: return "직접 조종 중인 살아 있는 인물이 필요합니다."
	if p.get("room","village")!="village" or Vector2(p.x,p.y).distance_to(Vector2(5,7))>=2: return "잿불 마을 대장간 가까이에서 강화하세요."
	var kind: String=p.gear_instances.get(id,"")
	if kind not in Stats.KINDS: return "소지한 가죽 또는 철제 갑옷을 선택하세요."
	var n:=level(p,id)
	if n>=3: return "최대 강화 +3에 도달했습니다."
	for material in COSTS[kind][n]:
		if Items.quantity(p,material)<COSTS[kind][n][material]: return Items.CATALOG[material].name+" 재료가 부족합니다."
	if p.gold<GOLD[n]: return "은화가 부족합니다."
	return ""
static func apply(w: Dictionary,p: Dictionary,value: String) -> String:
	var parts:=value.split("|")
	if parts.size()!=2 or not parts[1].is_valid_int(): return "강화 선택이 올바르지 않습니다."
	var id: String=parts[0]
	if int(parts[1])!=level(p,id): return "강화 단계가 변경되었습니다. 비용을 다시 확인하세요."
	var why:=reason(p,id)
	if not why.is_empty(): return why
	var n:=level(p,id)
	var kind: String=p.gear_instances[id]
	for material in COSTS[kind][n]: Storage.change(p,material,-int(COSTS[kind][n][material]))
	p.gold-=GOLD[n]
	p.gear_quality[id].upgrade=n+1
	var text: String=Items.CATALOG[kind].name+" · %s · +%d → +%d 강화 · 피해 감소 +1" % [id.right(4),n,n+1]
	Storage.Record.append(p,id,"upgraded",int(w.time/2880)+1,text)
	p.events.append(text)
	return text
