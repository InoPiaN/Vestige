extends RefCounted
const KINDS=["iron_sword","leather","iron_armor"]
static func price(p: Dictionary,id: String) -> int:
	if p.get("gear_instances",{}).get(id) not in KINDS: return 0
	return ceili((100-int(p.gear_condition[id]))/20.0)*(1+int(p.gear_quality[id].get("upgrade",0)))
static func reason(p: Dictionary,id: String) -> String:
	if not p.alive or p.offline or p.get("room","village")!="village" or Vector2(p.x,p.y).distance_to(Vector2(5,7))>=2: return "직접 조종 중인 인물로 대장간 가까이에 오세요."
	if p.gear_instances.get(id) not in KINDS: return "수리할 소지 철검 또는 갑옷을 선택하세요."
	if p.gear_condition[id]>=100: return "이미 온전한 장비입니다."
	if p.gold<price(p,id): return "수리할 은화가 부족합니다."
	return ""
static func apply(w: Dictionary,p: Dictionary,value: String) -> String:
	var parts:=value.split("|")
	if parts.size()!=3 or not parts[1].is_valid_int() or not parts[2].is_valid_int(): return "수리 선택이 올바르지 않습니다."
	var id: String=parts[0]
	if p.get("gear_condition",{}).get(id,-1)!=int(parts[1]) or price(p,id)!=int(parts[2]): return "장비 상태가 변경되었습니다. 수리 비용을 다시 확인하세요."
	var why:=reason(p,id)
	if not why.is_empty(): return why
	var coins:=price(p,id)
	var before: int=p.gear_condition[id]
	p.gold-=coins
	p.gear_condition[id]=100
	var text: String=preload("res://items.gd").definition(p,id).name+" · 대장간 수리 · 내구도 %d → 100 · 은화 -%d" % [before,coins]
	preload("res://gear_record.gd").append(p,id,"repaired",int(w.time/2880)+1,text)
	p.events.append(text)
	return text
