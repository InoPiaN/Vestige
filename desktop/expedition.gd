extends RefCounted
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
const Armor=preload("res://armor_stats.gd")
const DEFS={"boar":{"name":"잿빛 들멧돼지","x":26.0,"y":3.0,"hp":95,"damage":24,"loot":{"hide":2,"boar_tusk":1}},"wraith":{"name":"망령 궁수","x":27.0,"y":16.0,"hp":75,"damage":18,"loot":{"spectral_ash":2}}}
const QUESTS={"warrior":{"name":"북쪽 숲길의 위협","enemy":"boar","x":8.0,"y":6.0,"reward":14,"hint":"북동쪽 숲의 들멧돼지를 처치하세요. 돌진 예고선을 보고 옆으로 피하세요."},"hunter":{"name":"남쪽 숲의 잿빛 화살","enemy":"wraith","x":16.0,"y":8.0,"reward":16,"hint":"남동쪽 숲의 망령 궁수를 처치하세요. 조준선을 피하고 거리를 좁히세요."}}
static func spawn(id: String) -> Dictionary:
	var d: Dictionary=DEFS[id]
	return {"x":d.x,"y":d.y,"hp":d.hp,"warning":0.0,"cooldown":0.0,"slow":0.0,"respawn":0.0,"aim_x":d.x,"aim_y":d.y,"flash":0.0,"trail_x":d.x,"trail_y":d.y}
static func prepare(w: Dictionary) -> void:
	if not w.has("enemies"):
		w.enemies={}
		for id in DEFS: w.enemies[id]=spawn(id)
	if not w.has("field_loot"): w.field_loot={}
static func person(p: Dictionary) -> void:
	if not p.has("target_enemy"): p.target_enemy=""
	if not p.has("expeditions"): p.expeditions={"warrior":"new","hunter":"new"}
static func available(p: Dictionary) -> bool:
	return p.alive and not p.offline and p.get("room","village")=="village"
static func position(row: Dictionary) -> Vector2: return Vector2(row.x,row.y)
static func all(w: Dictionary) -> Dictionary:
	var result: Dictionary={"wolf":w.wolf}
	result.merge(w.get("enemies",{}))
	return result
static func title(id: String) -> String:
	return "예배당 늑대" if id=="wolf" else DEFS.get(id,{}).get("name","")
static func candidates(w: Dictionary,p: Dictionary) -> Array:
	var ids: Array=[]
	if not available(p): return ids
	var enemies:=all(w)
	for id in enemies:
		if enemies[id].hp>0 and position(p).distance_to(position(enemies[id]))<8: ids.append(id)
	ids.sort_custom(func(a,b): return position(p).distance_squared_to(position(enemies[a]))<position(p).distance_squared_to(position(enemies[b])))
	return ids
static func selected(w: Dictionary,p: Dictionary) -> String:
	var ids:=candidates(w,p)
	if p.get("target_enemy","") in ids: return p.target_enemy
	return str(ids[0]) if not ids.is_empty() else ""
static func cycle(w: Dictionary,p: Dictionary) -> String:
	var ids:=candidates(w,p)
	if ids.is_empty():
		p.target_enemy=""
		return "근처에 선택할 적이 없습니다."
	var current:=selected(w,p)
	p.target_enemy=ids[(ids.find(current)+1)%ids.size()]
	return "공격 대상 · "+title(p.target_enemy)
static func quest(p: Dictionary,field: String) -> String:
	if not QUESTS.has(field) or not available(p): return "직접 조종 중인 인물로 스승에게 돌아오세요."
	var q: Dictionary=QUESTS[field]
	if position(p).distance_to(position(q))>=2: return "의뢰를 준 스승 가까이에서 대화하세요."
	if p.professions[field].state!="learned": return "해당 스승의 입문 과제를 먼저 마치세요."
	var state: String=p.expeditions[field]
	if state=="new":
		p.expeditions[field]="active"
		p.events.append("원정 의뢰 수락 · "+q.name)
		return q.hint+" 처치 후 스승에게 보고하면 은화 %d." % q.reward
	if state=="active": return q.hint
	if state=="ready":
		p.expeditions[field]="done"
		p.gold+=q.reward
		var text: String="원정 귀환 보고 · "+q.name+" · 은화 +%d" % q.reward
		p.events.append(text)
		return text
	return "이미 보상을 받은 의뢰입니다."
static func defeated(w: Dictionary,p: Dictionary,id: String) -> String:
	var e: Dictionary=w.enemies[id]
	e.warning=0.0
	e.respawn=w.time+2880.0
	var token: String="loot-"+Crypto.new().generate_random_bytes(12).hex_encode()
	w.field_loot[token]={"x":e.x,"y":e.y,"contents":DEFS[id].loot.duplicate()}
	for field in QUESTS:
		if QUESTS[field].enemy==id and p.expeditions[field]=="active": p.expeditions[field]="ready"
	var text: String=title(id)+" 처치 · R로 현장 전리품 회수. 의뢰는 스승에게 돌아가 보고하세요."
	p.events.append(text)
	return text
static func nearby_loot(w: Dictionary,p: Dictionary) -> String:
	if not available(p): return ""
	var nearest:=2.0
	var found:=""
	for id in w.get("field_loot",{}):
		var distance:=position(p).distance_to(position(w.field_loot[id]))
		if distance<nearest:
			nearest=distance
			found=id
	return found
static func collect(w: Dictionary,p: Dictionary) -> String:
	var id:=nearby_loot(w,p)
	if id.is_empty(): return "전리품 가까이에서 R을 누르세요."
	var box: Dictionary=w.field_loot[id].contents
	var taken: Array[String]=[]
	for kind in box.keys():
		var amount:=mini(int(box[kind]),int(Items.CATALOG[kind].limit)-Items.quantity(p,kind))
		if amount<=0: continue
		Storage.change(p,kind,amount)
		box[kind]-=amount
		taken.append(Items.CATALOG[kind].name+" +%d" % amount)
		if box[kind]==0: box.erase(kind)
	if box.is_empty(): w.field_loot.erase(id)
	if taken.is_empty(): return "소지 한도에 도달했습니다. 전리품은 현장에 남습니다."
	var text: String="원정 전리품 · "+" / ".join(taken)
	p.events.append(text)
	return text
static func advance(w: Dictionary,dt: float) -> void:
	for id in w.enemies:
		var e: Dictionary=w.enemies[id]
		e.slow=maxf(0,e.slow-dt)
		e.flash=maxf(0,e.flash-dt)
		if e.hp<=0 and w.time>=e.respawn: w.enemies[id]=spawn(id)
static func segment_distance(point: Vector2,a: Vector2,b: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point,a,b))
static func tick(w: Dictionary,dt: float,die: Callable) -> void:
	for id in w.enemies:
		var e: Dictionary=w.enemies[id]
		if e.hp<=0: continue
		var home:=Vector2(DEFS[id].x,DEFS[id].y)
		e.cooldown=maxf(0,e.cooldown-dt)
		var target:=""
		var nearest:=5.0 if e.warning>0 else 3.8
		for pid in w.people:
			var p: Dictionary=w.people[pid]
			var dist:=position(p).distance_to(position(e))
			if p.alive and not p.offline and p.get("room","village")=="village" and p.x>18 and position(p).distance_to(home)<6 and dist<nearest:
				target=pid
				nearest=dist
		if target.is_empty():
			e.warning=0.0
			var back:=position(e).move_toward(home,dt*1.2)
			e.x=back.x
			e.y=back.y
			continue
		var p: Dictionary=w.people[target]
		if e.warning>0:
			e.warning=maxf(0,e.warning-dt)
			if e.warning==0:
				var origin:=position(e)
				var aim:=Vector2(e.aim_x,e.aim_y)
				e.flash=0.18
				e.trail_x=origin.x
				e.trail_y=origin.y
				# Aim is locked when the warning starts; moving sideways avoids it.
				for pid in w.people:
					var victim: Dictionary=w.people[pid]
					if not available(victim) or victim.x<=18 or victim.dodge>0: continue
					if segment_distance(position(victim),origin,aim)>(0.7 if id=="boar" else 0.35): continue
					Armor.hit(victim,DEFS[id].damage)
					victim.hurt=0.22
					if victim.hp<=0: die.call(w,pid,title(id)+"와의 전투")
				if id=="boar":
					e.x=aim.x
					e.y=aim.y
				e.cooldown=2.2
		elif e.cooldown<=0 and nearest<(3.2 if id=="boar" else 5.0):
			var aim:=position(p)
			if id=="boar": aim=position(e)+(aim-position(e)).normalized()*3.2
			e.aim_x=clampf(aim.x,18.5,29)
			e.aim_y=clampf(aim.y,1.5,18)
			e.warning=1.0 if id=="boar" else 1.2
		else:
			var destination:=position(p)
			if id=="wraith" and nearest<2.7: destination=position(e)+(position(e)-position(p)).normalized()*2
			elif id=="wraith": continue
			var next:=position(e).move_toward(destination,dt*1.35*(0.5 if e.slow>0 else 1.0))
			if next.distance_to(home)<4:
				e.x=clampf(next.x,18.5,29)
				e.y=clampf(next.y,1.5,18)
static func number(n: Variant,low: float,high: float,integer: bool=false) -> bool:
	return (n is int or n is float) and is_finite(n) and n>=low and n<=high and (not integer or n==floor(n))
static func valid(w: Dictionary) -> bool:
	if not w.get("enemies") is Dictionary or w.enemies.size()!=2 or not w.get("field_loot") is Dictionary: return false
	for id in DEFS:
		var e=w.enemies.get(id)
		if not e is Dictionary: return false
		for key in ["x","aim_x","trail_x"]:
			if not number(e.get(key),18.5,29): return false
		for key in ["y","aim_y","trail_y"]:
			if not number(e.get(key),1.5,18): return false
		for key in ["warning","cooldown","slow","flash"]:
			if not number(e.get(key),0,3): return false
		if not number(e.get("hp"),0,DEFS[id].hp,true) or not number(e.get("respawn"),0,1e15): return false
	for p in w.people.values():
		if not p is Dictionary: return false
		if not p.get("target_enemy") is String or p.target_enemy not in ["","wolf","boar","wraith"]: return false
		if not p.get("expeditions") is Dictionary or p.expeditions.size()!=2: return false
		for field in QUESTS:
			if p.expeditions.get(field) not in ["new","active","ready","done"]: return false
	for id in w.field_loot:
		var row=w.field_loot[id]
		if not id is String or not id.begins_with("loot-") or not row is Dictionary: return false
		if not number(row.get("x"),18.5,29) or not number(row.get("y"),1.5,18): return false
		if not row.get("contents") is Dictionary or row.contents.is_empty(): return false
		for kind in row.contents:
			if kind not in ["hide","boar_tusk","spectral_ash"] or not number(row.contents[kind],1,2,true): return false
	return true
