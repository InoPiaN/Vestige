extends RefCounted
const C=preload("res://home_crafting.gd")
const Items=preload("res://items.gd")
const RECIPES=["iron_sword","repair_kit","mug","bandage","herbal_tea"]
static func prepare(p: Dictionary) -> void:
	if not p.has("craft_plan"): p.craft_plan={}
static func valid(p: Dictionary) -> bool:
	var plan=p.get("craft_plan")
	if not plan is Dictionary: return false
	if plan.is_empty(): return p.policy!="plan"
	if plan.get("recipe") not in RECIPES or plan.get("mode") not in ["count","target"] or not plan.get("status") is String: return false
	for key in ["amount","remaining"]:
		var n=plan.get(key)
		if not (n is int or n is float) or not is_finite(float(n)) or n!=floor(n): return false
	return plan.amount>=1 and plan.amount<=Items.CATALOG[plan.recipe].limit and plan.remaining>=0 and plan.remaining<=plan.amount
static func configure(p: Dictionary,value: String,start: bool) -> String:
	var parts:=value.split("|")
	if parts.size()!=3 or parts[0] not in RECIPES or parts[1] not in ["count","target"] or not parts[2].is_valid_int(): return "제작 계획 설정이 올바르지 않습니다."
	var amount:=int(parts[2])
	if amount<1 or amount>int(Items.CATALOG[parts[0]].limit): return "목표 수량은 1개부터 소지 한도까지 지정하세요."
	# Re-saving an unchanged plan does not restart its completed count.
	var old: Dictionary=p.get("craft_plan",{})
	if old.get("recipe")!=parts[0] or old.get("mode")!=parts[1] or old.get("amount")!=amount:
		p.craft_plan={"recipe":parts[0],"mode":parts[1],"amount":amount,"remaining":amount,"status":"제작 대기"}
	p.policy="plan"
	if start: p.offline=true
	return "제작 계획을 저장하고 생활을 맡겼습니다." if start else "제작 계획을 저장했습니다. 생활 맡기기 또는 종료 후 적용됩니다."
static func summary(p: Dictionary) -> String:
	var plan: Dictionary=p.get("craft_plan",{})
	if plan.is_empty(): return "제작 계획 없음"
	return "%s · %s · %s" % [Items.CATALOG[plan.recipe].name,"남은 제작 %d / %d개" % [plan.remaining,plan.amount] if plan.mode=="count" else "목표 소지 %d개" % plan.amount,plan.status]
static func rest(p: Dictionary,text: String) -> void:
	p.craft_plan.status=text
	p.hp=mini(100,p.hp+25)
	p.events.append("부재 제작 · "+text+". 쉬며 몸을 추슬렀다.")
static func day(w: Dictionary,p: Dictionary,forge: Callable) -> void:
	var plan: Dictionary=p.craft_plan
	if plan.is_empty(): return
	var id: String=plan.recipe
	if plan.mode=="count" and plan.remaining==0:
		rest(p,"지정 수량 제작 완료")
		return
	if plan.mode=="target" and Items.family_quantity(p,id)>=int(plan.amount):
		rest(p,"목표 소지 수량 충족")
		return
	var why:=""
	if id=="iron_sword":
		if p.sword>=5: why="철검 소지 한도 도달"
		elif p.ore<2: why="철광석 재료 부족"
	else:
		if w.estate.owner!=p.life: why="본인 소유의 집이 필요함"
		else: why=C.reason(w,p,id,true)
	if not why.is_empty():
		rest(p,why)
		return
	if id=="iron_sword":
		p.room="village"
		p.x=5.0
		p.y=8.0
		p.ore-=2
		p.events.append(forge.call(w,p,false))
		p.skill+=1
	else:
		p.room="home"
		p.x=15.0
		p.y=12.0
		C.craft(w,p,id,true)
	if plan.mode=="count": plan.remaining-=1
	plan.status="지정 수량 제작 완료" if plan.mode=="count" and plan.remaining==0 else "오늘 1개 제작"
	if plan.mode=="target" and Items.family_quantity(p,id)>=int(plan.amount): plan.status="목표 소지 수량 충족"
	p.events.append("부재 제작 · "+summary(p))
