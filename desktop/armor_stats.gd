extends RefCounted
const KINDS=["leather","iron_armor"]
const DEFENSE={"leather":{"common":[3,4],"fine":[5,5],"great":[6,7]},"iron_armor":{"common":[6,7],"fine":[8,8],"great":[9,10]}}
static func worn(p: Dictionary) -> String:
	var id: String=p.get("equipped_ids",{}).get("body","")
	return id if p.get("gear_instances",{}).get(id) in KINDS else ""
static func defense(p: Dictionary) -> int:
	var id:=worn(p)
	if id.is_empty() or p.get("gear_condition",{}).get(id,0)<=0: return 0
	return int(p.get("gear_quality",{}).get(id,{}).get("defense",3 if p.gear_instances[id]=="leather" else 6))
static func dodge_cost(p: Dictionary) -> int:
	var id:=worn(p)
	return 30+(8 if p.gear_instances.get(id)=="iron_armor" else (2 if p.gear_instances.get(id)=="leather" else 0))
static func hit(p: Dictionary,raw: int) -> int:
	if raw<=0: return 0
	var amount:=maxi(1,raw-defense(p))
	var id:=worn(p)
	if not id.is_empty(): p.gear_condition[id]=maxi(0,int(p.gear_condition[id])-5)
	p.hp=maxi(0,int(p.hp)-amount)
	return amount
