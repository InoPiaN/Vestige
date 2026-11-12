extends RefCounted
const C=preload("res://home_crafting.gd")
const Supply=preload("res://craft_supply.gd")
const Items=preload("res://items.gd")
const Armor=preload("res://armor_crafting.gd")
const FORGE=["iron_sword","leather","iron_armor"]
const RECIPES=["leather","iron_armor","iron_sword","repair_kit","mug","bandage","herbal_tea"]
# Keep the first plan in its legacy field; following plans retain independent progress.
static func plans(p: Dictionary) -> Array:
	var result: Array=[]
	if not p.get("craft_plan",{}).is_empty(): result.append(p.craft_plan)
	result.append_array(p.get("craft_queue",[]))
	return result
static func store(p: Dictionary,rows: Array) -> void:
	p.craft_plan=rows[0] if not rows.is_empty() else {}
	p.craft_queue=rows.slice(1)
static func prepare(p: Dictionary) -> void:
	if not p.has("craft_plan"): p.craft_plan={}
	if not p.has("craft_queue"): p.craft_queue=[]
	for row in plans(p):
		if not row.has("paused"): row.paused=false
static func valid_row(plan: Dictionary) -> bool:
	if plan.get("recipe") not in RECIPES or plan.get("mode") not in ["count","target"] or not plan.get("status") is String: return false
	if not plan.get("paused",false) is bool: return false
	for key in ["amount","remaining"]:
		var n=plan.get(key)
		if not (n is int or n is float) or not is_finite(float(n)) or n!=floor(n): return false
	if plan.has("source") or plan.has("destination"):
		if not Supply.valid_settings(plan): return false
		if plan.recipe in FORGE and Supply.linked(plan): return false
	return plan.amount>=1 and plan.amount<=Items.CATALOG[plan.recipe].limit and plan.remaining>=0 and plan.remaining<=plan.amount
static func valid(p: Dictionary,strict: bool=false) -> bool:
	if not p.get("craft_plan") is Dictionary or not p.get("craft_queue",[]) is Array: return false
	if p.get("craft_queue",[]).size()>2: return false
	if p.craft_plan.is_empty(): return p.policy!="plan" and p.get("craft_queue",[]).is_empty()
	for row in plans(p):
		if not row is Dictionary or not valid_row(row): return false
		if strict and (not Supply.valid_settings(row) or not row.get("paused") is bool): return false
	return true
static func manage(p: Dictionary,kind: String,value: String) -> String:
	if not value.is_valid_int(): return "계획 번호가 올바르지 않습니다."
	var index:=int(value)
	var rows:=plans(p)
	if index<0 or index>=rows.size(): return "해당 계획이 없습니다."
	match kind:
		"plan_pause":
			rows[index].paused=not rows[index].get("paused",false)
			rows[index].status="일시정지" if rows[index].paused else "제작 대기"
		"plan_delete": rows.remove_at(index)
		"plan_up", "plan_down":
			var next:=index+(-1 if kind=="plan_up" else 1)
			if next<0 or next>=rows.size(): return "더 이동할 수 없습니다."
			var row: Dictionary=rows[index]
			rows[index]=rows[next]
			rows[next]=row
	store(p,rows)
	if rows.is_empty(): p.policy="rest"
	return "제작 계획을 변경했습니다."
static func configure(p: Dictionary,value: String,start: bool) -> String:
	var parts:=value.split("|")
	var index:=0
	if parts.size()==6:
		if not parts[0].is_valid_int(): return "계획 번호가 올바르지 않습니다."
		index=int(parts[0])
		parts.remove_at(0)
	var rows:=plans(p)
	if index<0 or index>rows.size() or index>=3: return "제작 계획은 최대 3개입니다."
	if parts.size() not in [3,5] or parts[0] not in RECIPES or parts[1] not in ["count","target"] or not parts[2].is_valid_int(): return "제작 계획 설정이 올바르지 않습니다."
	var source: String=parts[3] if parts.size()==5 else "bag"
	var destination: String=parts[4] if parts.size()==5 else "bag"
	if not Supply.valid_settings({"source":source,"destination":destination}): return "재료와 보관 장소가 올바르지 않습니다."
	if parts[0] in FORGE and (source!="bag" or destination!="bag"): return "마을 대장간은 소지품만 사용합니다."
	var amount:=int(parts[2])
	if amount<1 or amount>int(Items.CATALOG[parts[0]].limit): return "목표 수량은 1개부터 소지 한도까지 지정하세요."
	# Re-saving an unchanged plan does not restart its completed count.
	var old: Dictionary=rows[index] if index<rows.size() else {}
	if old.get("recipe")!=parts[0] or old.get("mode")!=parts[1] or old.get("amount")!=amount:
		old={"recipe":parts[0],"mode":parts[1],"amount":amount,"remaining":amount,"status":"제작 대기","paused":false}
	old.source=source
	old.destination=destination
	if index==rows.size(): rows.append(old)
	else: rows[index]=old
	store(p,rows)
	p.policy="plan"
	if start: p.offline=true
	return "제작 계획을 저장하고 생활을 맡겼습니다." if start else "제작 계획을 저장했습니다. 생활 맡기기 또는 종료 후 적용됩니다."
static func row_summary(plan: Dictionary) -> String:
	return "%s · %s · %s" % [Items.CATALOG[plan.recipe].name,"남은 %d / %d개" % [plan.remaining,plan.amount] if plan.mode=="count" else "목표 %d개" % plan.amount,"일시정지" if plan.get("paused",false) else plan.status]
static func summary(p: Dictionary) -> String:
	var lines: PackedStringArray=[]
	for row in plans(p): lines.append("%d. %s" % [lines.size()+1,row_summary(row)])
	return "제작 계획 없음" if lines.is_empty() else "\n".join(lines)
static func reason(w: Dictionary,p: Dictionary,plan: Dictionary) -> String:
	if plan.get("paused",false): return "일시정지"
	if plan.mode=="count" and plan.remaining==0: return "지정 수량 제작 완료"
	if plan.mode=="target" and Supply.target_count(w,p,plan.recipe,plan)>=int(plan.amount): return "목표 소지 수량 충족"
	if plan.recipe=="iron_sword":
		if p.sword>=5: return "철검 소지 한도 도달"
		return "철광석 재료 부족" if p.ore<2 else ""
	if plan.recipe in Armor.RECIPES: return Armor.reason(p,plan.recipe,true)
	if w.estate.owner!=p.life: return "본인 소유의 집이 필요함"
	return C.reason(w,p,plan.recipe,true,plan)
static func next_recipe(w: Dictionary,p: Dictionary) -> String:
	if p.hp<40: return ""
	for row in plans(p):
		if reason(w,p,row).is_empty(): return row.recipe
	return ""
static func recovery(p: Dictionary) -> void:
	for row in plans(p):
		if not row.get("paused",false): row.status="몸 상태가 나빠 회복 우선"
static func day(w: Dictionary,p: Dictionary,forge: Callable,day_number: int=-1) -> void:
	var selected: Dictionary={}
	for row in plans(p):
		var why:=reason(w,p,row)
		if not why.is_empty(): row.status=why
		elif selected.is_empty(): selected=row
		else: row.status="우선순위 대기"
	if selected.is_empty():
		p.hp=mini(100,p.hp+25)
		p.events.append("부재 제작 · "+summary(p)+". 쉬며 몸을 추슬렀다.")
		return
	var plan: Dictionary=selected
	var id: String=plan.recipe
	if id=="iron_sword":
		p.room="village"
		p.x=5.0
		p.y=8.0
		p.ore-=2
		p.events.append(forge.call(w,p,false,day_number))
		p.skill+=1
	elif id in Armor.RECIPES:
		p.room="village"
		p.x=5.0
		p.y=8.0
		Armor.craft(w,p,id,true,day_number)
	else:
		p.room="home"
		p.x=15.0
		p.y=12.0
		C.craft(w,p,id,true,plan)
	if plan.mode=="count": plan.remaining-=1
	plan.status="지정 수량 제작 완료" if plan.mode=="count" and plan.remaining==0 else "오늘 1개 제작"
	if plan.mode=="target" and Supply.target_count(w,p,id,plan)>=int(plan.amount): plan.status="목표 소지 수량 충족"
	p.events.append("부재 제작 · "+summary(p))
