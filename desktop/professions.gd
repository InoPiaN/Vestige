extends RefCounted
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const Quality=preload("res://craft_quality.gd")
const Mentors={"warrior":{"name":"경비대 교관 라온","x":8.0,"y":6.0,"weapon":"iron_sword","material":"ore","title":"전사"},"hunter":{"name":"사냥꾼 스승 세린","x":16.0,"y":8.0,"weapon":"shortbow","material":"herb","title":"사냥꾼"}}
const SKILLS={"heavy":{"name":"강타","field":"warrior","cost":24,"cooldown":4.0,"description":"철검으로 강한 일격 · 기본 공격력 ×1.6"},"guard":{"name":"방어 자세","field":"warrior","cost":18,"cooldown":6.0,"description":"철검을 들고 2초간 받는 물리 피해 절반"},"aim":{"name":"조준 사격","field":"hunter","cost":22,"cooldown":4.0,"description":"단궁으로 7칸 사격 · 기본 공격력 ×1.5"},"slow":{"name":"둔화 사격","field":"hunter","cost":18,"cooldown":5.0,"description":"단궁으로 6칸 사격 · 3초간 적 이동속도 절반"}}
static func prepare(p: Dictionary) -> void:
	if not p.has("professions"): p.professions={"warrior":{"state":"new","xp":0},"hunter":{"state":"new","xp":0}}
	if not p.has("skill_slots"): p.skill_slots=["",""]
	if not p.has("skill_cooldowns"): p.skill_cooldowns={"heavy":0.0,"guard":0.0,"aim":0.0,"slow":0.0}
	if not p.has("guard_time"): p.guard_time=0.0
	if not p.has("shot_time"): p.shot_time=0.0
	if not p.has("shot_x"): p.shot_x=p.x
	if not p.has("shot_y"): p.shot_y=p.y
static func valid(p: Dictionary) -> bool:
	if not p.get("professions") is Dictionary or p.professions.size()!=2 or not p.get("skill_slots") is Array or p.skill_slots.size()!=2: return false
	for field in Mentors:
		var row=p.professions.get(field)
		if not row is Dictionary or row.get("state") not in ["new","active","learned"]: return false
		var xp=row.get("xp")
		if not (xp is int or xp is float) or not is_finite(xp) or xp!=floor(xp) or xp<0 or xp>1000: return false
	for id in p.skill_slots:
		if id!="" and (not SKILLS.has(id) or p.professions[SKILLS[id].field].state!="learned"): return false
	if p.skill_slots[0]!="" and p.skill_slots[0]==p.skill_slots[1]: return false
	if not p.get("skill_cooldowns") is Dictionary or p.skill_cooldowns.size()!=4: return false
	for id in SKILLS:
		var n=p.skill_cooldowns.get(id)
		if not (n is int or n is float) or not is_finite(n) or n<0 or n>SKILLS[id].cooldown: return false
	for key in ["guard_time","shot_time","shot_x","shot_y"]:
		var n=p.get(key)
		if not (n is int or n is float) or not is_finite(n): return false
	return p.guard_time>=0 and p.guard_time<=2 and p.shot_time>=0 and p.shot_time<=0.2
static func near(p: Dictionary,field: String) -> bool:
	return Mentors.has(field) and p.alive and not p.offline and p.get("room","village")=="village" and Vector2(p.x,p.y).distance_to(Vector2(Mentors[field].x,Mentors[field].y))<2
static func lesson(p: Dictionary,field: String) -> String:
	if not near(p,field): return "직접 조종 중인 인물로 해당 스승 가까이에 오세요."
	var row: Dictionary=p.professions[field]
	var mentor: Dictionary=Mentors[field]
	if row.state=="learned": return "이미 입문 과제를 마쳤습니다. 실제 전투 명중으로 숙련을 쌓으세요."
	if row.state=="new":
		row.state="active"
		var text: String=mentor.name+"의 입문 과제: "+Items.CATALOG[mentor.weapon].name+"을 착용하고 "+Items.CATALOG[mentor.material].name+" 2개를 가져오세요."
		p.events.append(text)
		return text
	if p.equipment.get("weapon")!=mentor.weapon: return Items.CATALOG[mentor.weapon].name+"을 착용해 준비된 모습을 보여주세요."
	if Items.quantity(p,mentor.material)<2: return Items.CATALOG[mentor.material].name+" 2개가 필요합니다."
	Storage.change(p,mentor.material,-2)
	row.state="learned"
	p.gold+=4
	for id in SKILLS:
		if SKILLS[id].field==field:
			for slot in range(2):
				if p.skill_slots[slot]=="":
					p.skill_slots[slot]=id
					break
	var text: String=mentor.name+"에게 "+mentor.title+"의 두 기술을 배웠다. 입문 보상 은화 +4."
	p.events.append(text)
	return text
static func assign(p: Dictionary,value: String) -> String:
	var parts:=value.split("|")
	if parts.size()!=2 or parts[0] not in ["0","1"]: return "기술 슬롯을 확인하세요."
	var id: String=parts[1]
	if id!="" and (not SKILLS.has(id) or p.professions[SKILLS[id].field].state!="learned"): return "스승에게 먼저 배워야 하는 기술입니다."
	var slot:=int(parts[0])
	if id!="" and p.skill_slots[1-slot]==id: return "이미 다른 슬롯에 준비한 기술입니다."
	p.skill_slots[slot]=id
	return "준비할 기술을 변경했습니다. 재사용 시간은 유지됩니다."
static func rank(p: Dictionary,field: String) -> String:
	var xp: int=p.professions[field].xp
	return "장인" if xp>=1000 else ("숙련" if xp>=400 else ("견습" if xp>=100 else "입문"))
static func tick(p: Dictionary,dt: float) -> void:
	for id in SKILLS: p.skill_cooldowns[id]=maxf(0,p.skill_cooldowns[id]-dt)
	p.guard_time=maxf(0,p.guard_time-dt)
	p.shot_time=maxf(0,p.shot_time-dt)
static func clear_line(a: Vector2,b: Vector2) -> bool:
	for center in [Vector2(5,7),Vector2(10,4),Vector2(11,11),Vector2(7,13)]:
		var rect:=Rect2(center-Vector2(1,1.5),Vector2(2,1.9))
		for i in range(1,33):
			if rect.has_point(a.lerp(b,i/32.0)): return false
	return true
static func strike(w: Dictionary,p: Dictionary,id: String="") -> String:
	if not p.alive or p.offline or p.get("room","village")!="village": return "직접 조종 중인 인물로 마을 밖 전투를 준비하세요."
	var kind: String=p.equipment.get("weapon","none")
	var weapon: String=p.equipped_ids.get("weapon","")
	if not id.is_empty():
		if not SKILLS.has(id) or p.professions[SKILLS[id].field].state!="learned": return "아직 배우지 않은 기술입니다."
		if kind!=Mentors[SKILLS[id].field].weapon: return "이 기술에 맞는 무기를 착용하세요."
		if p.skill_cooldowns[id]>0: return "기술 재사용 시간이 남았습니다."
	var cost: int=SKILLS[id].cost if not id.is_empty() else 12
	if p.attack>0 or p.stamina<cost: return "공격 준비 또는 기력이 부족합니다."
	var reach:=7.0 if id=="aim" else (6.0 if kind=="shortbow" else 2.0)
	var target:=Vector2(w.wolf.x,w.wolf.y)
	var origin:=Vector2(p.x,p.y)
	var hit: bool=w.wolf.hp>0 and origin.distance_to(target)<reach and clear_line(origin,target)
	if not id.is_empty() and id!="guard" and not hit: return "공격 가능한 거리와 시야에 적이 없습니다."
	p.stamina-=cost
	p.attack=0.7 if kind=="shortbow" else 0.5
	p.action="attack"
	if not id.is_empty(): p.skill_cooldowns[id]=SKILLS[id].cooldown
	if id=="guard":
		p.guard_time=2.0
		return "방어 자세 · 2초간 물리 피해 절반"
	if not hit: return ""
	p.direction=preload("res://animation.gd").direction(target-origin)
	var damage: int=Quality.attack(p,weapon) if kind in ["iron_sword","shortbow"] and p.gear_condition.get(weapon,0)>0 else 9
	if id=="heavy": damage=roundi(damage*1.6)
	if id=="aim": damage=roundi(damage*1.5)
	w.wolf.hp=maxi(0,int(w.wolf.hp)-damage)
	if id=="slow": w.wolf.slow=3.0
	if kind in ["iron_sword","shortbow"]:
		p.gear_condition[weapon]=maxi(0,int(p.gear_condition[weapon])-5)
		var field: String="warrior" if kind=="iron_sword" else "hunter"
		if p.professions[field].state=="learned":
			var before:=rank(p,field)
			p.professions[field].xp=mini(1000,int(p.professions[field].xp)+5)
			if rank(p,field)!=before: p.events.append(Mentors[field].title+" 숙련이 "+rank(p,field)+" 단계에 올랐다.")
	if kind=="shortbow":
		p.shot_time=0.2
		p.shot_x=target.x
		p.shot_y=target.y
	if w.wolf.hp==0:
		w.wolf.respawn=w.time+2880.0
		p.gold+=8
		p.events.append("예배당의 길목에서 늑대를 물리쳤다.")
		return "늑대를 물리쳤습니다. 은화 +8"
	return (SKILLS[id].name+" · " if not id.is_empty() else "")+"피해 %d" % damage
static func bow_reason(p: Dictionary) -> String:
	if not p.alive or p.offline or p.get("room","village")!="village" or Vector2(p.x,p.y).distance_to(Vector2(5,7))>=2: return "대장간 가까이에서 직접 제작하세요."
	if Items.quantity(p,"shortbow")>=3: return "단궁 소지 한도에 도달했습니다."
	if Items.quantity(p,"wood")<3 or Items.quantity(p,"cloth")<2: return "목재 3개와 천 2개가 필요합니다. 장터에서 구입할 수 있습니다."
	return ""
static func craft_bow(w: Dictionary,p: Dictionary) -> String:
	var why:=bow_reason(p)
	if not why.is_empty(): return why
	var previous: Array=p.gear_instances.keys()
	Storage.change(p,"wood",-3)
	Storage.change(p,"cloth",-2)
	Storage.change(p,"shortbow",1)
	Storage.reconcile(p)
	var id:=""
	for key in p.gear_instances:
		if not previous.has(key): id=key
	var mastery=preload("res://craft_mastery.gd")
	var q:=Quality.roll(w,0,mastery.rates(p,"handicraft"))
	q.attack-=6
	p.gear_quality[id]=q
	Storage.Record.create(p,id,int(w.time/2880)+1,mastery.stage(p,"handicraft"),"생활 공예")
	var text: String="단궁 제작 · "+Items.definition(p,id).name+" · "+mastery.award(p,"shortbow")
	p.events.append(text)
	return text
