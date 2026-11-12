extends RefCounted

const CharacterMotion=preload("res://animation.gd")
const Store=preload("res://world_store.gd")
const Remains=preload("res://death_belongings.gd")
const Supply=preload("res://craft_supply.gd")
const Plan=preload("res://craft_plan.gd")
const Mastery=preload("res://craft_mastery.gd")
const Armor=preload("res://armor_stats.gd")
const ArmorCraft=preload("res://armor_crafting.gd")
const Upgrade=preload("res://sword_upgrade.gd")
const Quality=preload("res://craft_quality.gd")
const Market=preload("res://village_market.gd")
const Crafting=preload("res://home_crafting.gd")
const Interior=preload("res://house_interior.gd")
const Storage=preload("res://house_storage.gd")
const Investigation=preload("res://investigation.gd")
const DAY := 2880.0
const PLACES := [
	{"kind":"market","name":"잿불 장터 · 재료 구매 / 물품 판매","x":14,"y":14},
	{"kind":"forge","name":"잿불 대장간","x":5,"y":7},
	{"kind":"library","name":"기억의 서재","x":10,"y":4},
	{"kind":"inn","name":"등불 여관","x":11,"y":11},
	{"kind":"home","name":"언덕집 · 매입 8은화 / 일지 보관","x":7,"y":13},
	{"kind":"grave","name":"이름의 묘지","x":4,"y":14},
	{"kind":"ore","name":"철광맥","x":21,"y":5},
	{"kind":"herb","name":"달빛 약초","x":22,"y":14},
	{"kind":"ruin","name":"잊힌 예배당","x":27,"y":9}
]

const LOOK_OPTIONS := {"hair":3,"hair_color":4,"skin":3,"cloth":4}
const GEAR := {"body":["none","leather","iron_armor"],"head":["none","hood"],"cloak":["none","traveler"],"weapon":["none","iron_sword"]}

static func clean_look(value: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for key in LOOK_OPTIONS:
		var v=value.get(key,0)
		result[key]=clampi(int(v),0,LOOK_OPTIONS[key]-1) if (v is int or v is float) else 0
	return result

static func outfit(p: Dictionary) -> void:
	Mastery.prepare(p)
	Plan.prepare(p)
	Supply.prepare(p)
	p.look=clean_look(p.get("look",{}))
	if not p.has("belongings"): p.belongings={"leather":1,"hood":1,"traveler":1}
	if not p.has("equipment"):
		p.equipment={"body":"none","head":"none","cloak":"none","weapon":"iron_sword" if p.sword>0 else "none"}
	for slot in GEAR:
		if not p.equipment.get(slot,"none") in GEAR[slot]: p.equipment[slot]="none"
	if p.sword<=0: p.equipment.weapon="none"
	if not p.has("hide_helmet"): p.hide_helmet=false
	if not p.has("direction"): p.direction="left" if p.get("facing",1)<0 else "down"
	if not p.has("motion"): p.motion=0.0
	if not p.has("hurt"): p.hurt=0.0
	if not p.has("action"): p.action="idle"
	Storage.reconcile(p)

static func fresh() -> Dictionary:
	var w: Dictionary={"version":16,"time":0.0,"saved":Time.get_unix_time_from_system(),"people":{},"graves":[],"books":[],"wolf":{"x":25.0,"y":10.0,"hp":50,"cooldown":0.0,"warning":0.0,"respawn":0.0}}

	Investigation.prepare(w)
	Storage.prepare(w)
	Remains.prepare(w)
	Interior.prepare(w)
	Quality.prepare(w)
	Market.prepare(w)
	return w

static func born(w: Dictionary, id: String, title: String, look: Dictionary={}) -> void:
	if w.people.has(id) and w.people[id].alive:
		return
	w.people[id] = {"name":title.left(20),"x":9.0,"y":9.0,"hp":100,"stamina":100.0,"age":7200,"limit":21600,"alive":true,"offline":false,"policy":"rest","ore":0,"herb":0,"sword":0,"relic":0,"skill":0,"gold":12,"journal":[],"events":["잿불 마을에 도착했다."],"attack":0.0,"dodge":0.0,"facing":1,"steps":0.0,"quest":0}

	w.people[id].look=clean_look(look)
	outfit(w.people[id])
	Investigation.prepare_person(w.people[id])

static func die(w: Dictionary, id: String, cause: String, day: int=0) -> void:
	var p: Dictionary = w.people[id]
	if not p.alive:
		return
	outfit(p)
	p.alive=false
	p.offline=true
	p.hp=0
	Remains.leave(w,p,day if day>0 else int(w.time/DAY)+1)
	w.graves.append({"name":p.name,"cause":cause,"day":day if day>0 else int(w.time/DAY)+1,"x":p.x,"y":p.y})
	w.books.append({"author":p.name,"pages":p.journal.duplicate(true),"last":" ".join(p.events)})
	Investigation.Objects.drop(w,p)
	Investigation.record_death(w,p,w.graves.back(),w.books.back())
	p.events.append(cause+"으로 삶을 마쳤다.")

# Scripted NPC encounter. Clients cannot invoke it through the command API.
static func npc_strike(w: Dictionary,id: String,attacker: Dictionary,observer: Vector2,roster: Array,damage: int) -> bool:
	if not w.people.has(id) or damage<=0: return false
	var victim: Dictionary=w.people[id]
	if not victim.alive or w.estate.owner!=victim.life: return false
	if Interior.inside(victim): return false
	if pos(victim).distance_to(pos(attacker))>Investigation.Witness.REACH: return false
	Armor.hit(victim,damage)
	victim.hurt=0.22
	if victim.hp>0: return false
	var observation:=Investigation.Witness.observe(observer,pos(attacker),pos(victim),attacker.mark,PLACES,int(w.time/DAY)+1)
	die(w,id,"칼에 의한 살해")
	var c: Dictionary=w.cases[victim.life]
	c.roster=roster.duplicate(true)
	c.attacker=attacker.name
	c.trace_mark=attacker.mark
	c.observation=observation
	Investigation.Objects.prepare(w)
	return true

static func advance(w: Dictionary, seconds: float) -> void:
	var old_day := int(w.time / DAY)
	w.time += maxf(0, seconds)
	Market.prepare(w)
	var days := int(w.time / DAY) - old_day
	for id in w.people:
		var p: Dictionary = w.people[id]
		if not p.alive:
			continue
		var count := mini(days, int(p.limit-p.age))
		for i in range(count):
			if p.offline:
				if p.hp < 40 or p.policy == "rest":
					if p.policy=="plan":
						Plan.recovery(p)
						p.events.append("부재 제작 · 몸 상태가 나빠 회복을 먼저 했다.")
					p.hp=mini(100,p.hp+25)
					p.events.append("여관에서 쉬며 몸을 추슬렀다.")
				elif p.policy == "plan":
					Plan.day(w,p,forge_sword,old_day+i+1)
				elif p.policy == "gather":
					var amount := mini(2,20-int(p.herb))
					p.herb+=amount
					p.events.append("근교에서 약초 %d개를 모았다." % amount if amount > 0 else "약초 보관함이 가득 차 채집을 쉬었다.")
				elif p.policy == "work":
					if p.ore>=2 and p.sword<5:
						p.ore-=2
						var result:=forge_sword(w,p,false,old_day+i+1)
						p.skill+=1
						p.events.append(result)
					else:
						p.events.append("제작할 재료나 보관 공간이 부족해 작업장을 정리했다.")
				else:
					if p.skill<20:
						p.skill+=1
					p.events.append("훈련장에서 기본기를 연습했다.")
			p.age+=1
			p.journal.append({"day":old_day+i+1,"text":" ".join(p.events) if not p.events.is_empty() else "별다른 일 없이 평온한 하루를 보냈다."})
			p.events=[]
			if p.age>=p.limit:
				die(w,id,"노환",old_day+i+1)
				break
	if w.wolf.hp<=0 and w.time>=w.wolf.respawn:
		w.wolf.hp=50
		w.wolf.x=25.0
		w.wolf.y=10.0
		w.wolf.warning=0.0
		w.wolf.cooldown=0.0

static func forge_sword(w: Dictionary,p: Dictionary,equip: bool,day: int=-1) -> String:
	if day<0: day=int(w.time/DAY)+1
	var previous: Array=p.gear_instances.keys()
	p.sword+=1
	Storage.reconcile(p)
	for id in p.gear_instances:
		if previous.has(id): continue
		p.gear_quality[id]=Quality.roll(w,0,Mastery.rates(p,"smithing"))
		if equip:
			p.equipment.weapon="iron_sword"
			p.equipped_ids.weapon=id
		Storage.Record.create(p,id,day,Mastery.stage(p,"smithing"))
		if p.gear_quality[id].tier=="great": p.events.append("작품 기록 · 대성공 철검 · "+id.right(6)+". 내 이름을 남겼다.")
		var growth:=Mastery.award(p,"iron_sword")
		return "철검 제작 · %s · 공격력 %d · %s" % [Quality.LABELS[p.gear_quality[id].tier],p.gear_quality[id].attack,growth]
	return ""

static func weapon_damage(p: Dictionary) -> int:
	if p.equipment.get("weapon")!="iron_sword": return 9
	var id: String=p.get("equipped_ids",{}).get("weapon","")
	return Quality.attack(p,id) if p.get("gear_condition",{}).get(id,100)>0 else 9

static func pos(p: Dictionary) -> Vector2:
	return Vector2(p.x,p.y)

static func walkable(v: Vector2) -> bool:
	if v.x<1 or v.y<1 or v.x>29 or v.y>18:
		return false
	for t in PLACES:
		if t.kind in ["forge","library","inn","home"]:
			if Rect2(t.x-1,t.y-1.5,2,1.9).has_point(v):
				return false
	return true

static func move(w: Dictionary, id: String, direction: Vector2, dt: float) -> void:
	if not w.people.has(id):
		return
	var p: Dictionary=w.people[id]
	if not p.alive or p.offline:
		return
	var d:=direction.limit_length()*dt*(5.8 if p.dodge>0 else 3.2)
	var old:=pos(p)
	var next:=old+Vector2(d.x,0)
	if (Interior.walkable(next) if Interior.inside(p) else walkable(next)):
		p.x=next.x
	next=pos(p)+Vector2(0,d.y)
	if (Interior.walkable(next) if Interior.inside(p) else walkable(next)):
		p.y=next.y
	if d.length()>0:
		p.direction=CharacterMotion.direction(d)
		p.facing=1 if d.x>=0 else -1
	if pos(p).distance_to(old)>0.001:
		p.steps+=pos(p).distance_to(old)*2.5
		p.motion=0.12

static func tick(w: Dictionary, dt: float) -> void:
	advance(w,dt)
	for p in w.people.values():
		p.attack=maxf(0,p.attack-dt)
		p.motion=maxf(0,p.get("motion",0.0)-dt)
		p.hurt=maxf(0,p.get("hurt",0.0)-dt)
		p.dodge=maxf(0,p.dodge-dt)
		p.stamina=minf(100,p.stamina+dt*16)
		if p.alive and p.offline:
			if p.policy=="plan" and not p.craft_plan.is_empty() and Plan.next_recipe(w,p) not in Plan.FORGE and not Plan.next_recipe(w,p).is_empty() and w.estate.owner==p.life:
				if Interior.inside(p):
					var next:=pos(p).move_toward(Vector2(15,12),dt*1.1)
					if Interior.walkable(next):
						p.x=next.x
						p.y=next.y
					continue
				if pos(p).distance_to(Vector2(7,14))<1:
					p.room="home"
					p.x=15.0
					p.y=16.0
					continue
			if Interior.inside(p):
				if p.policy=="rest": continue
				p.room="village"
				p.x=7.0
				p.y=14.0
			var destination:=Vector2(11,12)
			if p.policy=="work": destination=Vector2(5,8)
			if p.policy=="plan": destination=Vector2(5,8) if Plan.next_recipe(w,p) in Plan.FORGE else (Vector2(11,12) if Plan.next_recipe(w,p).is_empty() else Vector2(7,14))
			if p.policy=="gather": destination=Vector2(15,13)
			if p.policy=="train": destination=Vector2(9,9)
			var previous:=pos(p)
			var v:=previous.move_toward(destination,dt*1.1)
			if walkable(v) and v.distance_to(previous)>0.001:
				p.x=v.x
				p.y=v.y
				p.steps+=v.distance_to(previous)*2.5
				p.motion=0.12
				p.direction=CharacterMotion.direction(v-previous)
	var e: Dictionary=w.wolf
	if e.hp<=0:
		return
	e.cooldown=maxf(0,e.cooldown-dt)
	var target_id: String=""
	var nearest:=4.5
	for id in w.people:
		var p: Dictionary=w.people[id]
		var dist:=pos(e).distance_to(pos(p))
		if p.alive and not Interior.inside(p) and p.x>18 and dist<nearest:
			nearest=dist
			target_id=id
	if target_id.is_empty():
		e.warning=0.0
		return
	var target: Dictionary=w.people[target_id]
	if e.warning>0:
		e.warning-=dt
		if e.warning<=0:
			if nearest<1.6 and target.dodge<=0:
				Armor.hit(target,18)
				target.hurt=0.22
				if target.hp<=0: die(w,target_id,"늑대와의 전투")
			e.cooldown=1.3
	elif nearest<1.2 and e.cooldown<=0:
		e.warning=0.65
	elif nearest>1.0:
		var v:=pos(e).move_toward(pos(target),dt*1.7)
		e.x=v.x
		e.y=v.y

static func nearby(p: Dictionary) -> Dictionary:
	for t in PLACES:
		if pos(p).distance_to(pos(t))<2.0:
			return t
	return {}

static func act(w: Dictionary, id: String, kind: String, value: String="") -> String:
	if not w.people.has(id): return "먼저 인물을 생성하세요."
	var p: Dictionary=w.people[id]
	if not p.alive: return "삶을 마쳤습니다. 새 인물로 세계를 이어가세요."
	outfit(p)
	if kind=="equip_body":
		if value=="none":
			p.equipment.body="none"
			p.equipped_ids.erase("body")
		elif p.gear_instances.get(value) in Armor.KINDS:
			p.equipment.body=p.gear_instances[value]
			p.equipped_ids.body=value
		else: return "현재 소지한 갑옷을 선택하세요."
		return "착용 갑옷을 변경했습니다."
	if kind=="equip_weapon":
		if value=="none":
			p.equipment.weapon="none"
			p.equipped_ids.erase("weapon")
		elif p.gear_instances.get(value)=="iron_sword":
			p.equipment.weapon="iron_sword"
			p.equipped_ids.weapon=value
		else: return "현재 소지한 철검을 선택하세요."
		return "착용 무기를 변경했습니다."
	if kind=="equip":
		var parts:=value.split(":")
		if parts.size()!=2 or not GEAR.has(parts[0]) or not parts[1] in GEAR[parts[0]]: return "장비 선택이 올바르지 않습니다."
		if parts[1]!="none" and preload("res://items.gd").quantity(p,parts[1])<=0: return "먼저 대장간에서 철검을 제작하세요."
		p.equipment[parts[0]]=parts[1]
		Storage.reconcile(p)
		return "장비를 변경했습니다."
	if kind=="helmet":
		p.hide_helmet=value=="hide"
		return "투구 표시를 변경했습니다."
	if kind=="craft_supply": return Supply.configure(p,value)
	if kind in ["plan_save","plan_start"]: return Plan.configure(p,value,kind=="plan_start")
	if kind in ["plan_pause","plan_delete","plan_up","plan_down"]: return Plan.manage(p,kind,value)
	if kind=="plan_cancel":
		p.craft_plan={}
		p.craft_queue=[]
		p.policy="rest"
		return "제작 계획을 취소하고 휴식합니다."
	if kind=="policy":
		if value=="plan" and not p.craft_plan.is_empty(): p.policy="plan"
		if value in ["rest","work","gather","train"]: p.policy=value
		return "생활 방침을 저장했습니다."
	if kind=="leave":
		p.offline=true
		return "생활을 맡겼습니다. 세계가 흐르는 동안 주민으로 살아갑니다."
	if kind=="resume":
		p.offline=false
		return "직접 조종을 시작합니다."
	if p.offline: return "직접 조종을 먼저 선택하세요."
	if kind=="armor_menu": return "방어구 제작"
	if kind=="craft_armor": return ArmorCraft.craft(w,p,value)
	if kind=="upgrade_sword": return Upgrade.apply(w,p,value)
	if kind=="market_buy": return Market.trade(w,p,value,true)
	if kind=="market_sell": return Market.trade(w,p,value,false)
	if kind=="craft_home": return Crafting.craft(w,p,value)
	if kind=="repair_gear": return Crafting.repair(p,value,int(w.time/DAY)+1)
	if kind=="use_crafted": return Crafting.use(p,value)
	if kind=="enter_home":
		if not Interior.inside(p) and Vector2(p.x,p.y).distance_to(Vector2(7,13))<2 and w.estate.owner=="": Investigation.visit_house(w,p)
		return Interior.enter(w,p)
	if Interior.inside(p) and kind in ["interact","investigate"]:
		if Interior.nearby(p)=="shelf":
			if w.estate.owner==p.life:
				Investigation.visit_house(w,p)
				return "조사 기록\n"+w.estate.shelf
			return Investigation.investigate(w,p)
		if kind=="interact": return Interior.interact(w,p)
		return Investigation.investigate(w,p)
	if Interior.inside(p) and kind in ["attack","identify"]: return "집 안에서는 사용할 수 없습니다."
	if kind=="take_remains": return Remains.take(w,p,value)
	if kind=="equip_instance": return Storage.equip(p,value)
	if kind in ["store_item","take_item"]: return Storage.transfer(w,p,value,kind=="take_item")
	if kind=="store_evidence": return Investigation.Objects.deposit(w,p,value)
	if kind=="identify": return Investigation.Witness.identify(w,p,value)
	if kind=="investigate": return Investigation.investigate(w,p)
	if kind=="dodge":
		if p.stamina>=Armor.dodge_cost(p) and p.dodge<=0:
			p.stamina-=Armor.dodge_cost(p)
			p.dodge=0.4
		return ""
	if kind=="heal":
		if p.herb<=0: return "약초가 없습니다."
		if p.hp>=100: return "이미 체력이 가득 찼습니다."
		p.herb-=1
		p.hp=mini(100,p.hp+30)
		return "달빛 약초로 체력 30을 회복했습니다."
	if kind=="attack":
		if p.attack>0 or p.stamina<12: return ""
		p.attack=0.5
		p.action="attack"
		p.stamina-=12
		if w.wolf.hp>0 and pos(p).distance_to(pos(w.wolf))<2:
			if pos(p).distance_to(pos(w.wolf))>0.1: p.direction=CharacterMotion.direction(pos(w.wolf)-pos(p))
			w.wolf.hp-=weapon_damage(p)
			var weapon: String=p.equipped_ids.get("weapon","")
			if p.gear_instances.get(weapon)=="iron_sword": p.gear_condition[weapon]=maxi(0,int(p.gear_condition[weapon])-5)
			if w.wolf.hp<=0:
				w.wolf.hp=0
				w.wolf.respawn=w.time+DAY
				p.gold+=8
				p.events.append("예배당의 길목에서 늑대를 물리쳤다.")
				return "늑대를 물리쳤습니다. 은화 +8"
		return ""
	if kind!="interact": return ""
	var t:=nearby(p)
	if t.is_empty(): return "시설이나 자원 가까이에서 E를 누르세요."
	match t.kind:
		"market":
			Market.prepare(w)
			return "장터"
		"home": return Investigation.visit_house(w,p)
		"ore":
			if p.attack>0: return ""
			if p.ore>=20: return "철광석 보관함이 가득 찼습니다."
			p.attack=0.6
			p.action="work"
			p.ore+=1
			p.events.append("북쪽 광맥에서 철광석을 채굴했다.")
			return "철광석 +1 · 2개를 모아 대장간으로 돌아가세요."
		"herb":
			if p.attack>0: return ""
			if p.herb>=20: return "약초 보관함이 가득 찼습니다."
			p.attack=0.6
			p.action="work"
			p.herb+=1
			p.events.append("숲 가장자리에서 달빛 약초를 채집했다.")
			return "달빛 약초 +1 · Q로 치료할 수 있습니다."
		"forge":
			if p.ore<2: return "철광석 2개가 필요합니다. 동쪽 광맥을 찾아보세요."
			if p.sword>=5: return "철검 보관 한도에 도달했습니다."
			p.ore-=2
			var result:=forge_sword(w,p,true)
			p.skill+=1
			p.events.append(result)
			return result
		"inn":
			p.hp=100
			p.events.append("등불 여관에서 따뜻한 식사를 하고 쉬었다.")
			return "체력을 모두 회복했습니다."
		"ruin":
			if p.relic>0 or p.get("relic_found",false): return "이미 조사한 장소입니다. 서재에서 발견한 기록을 읽어보세요."
			if w.wolf.hp>0: return "예배당을 지키는 늑대를 먼저 물리쳐야 합니다."
			p.relic=1
			p.relic_found=true
			p.events.append("예배당에서 약초사 이렌의 마지막 일기와 낡은 유물을 찾았다.")
			return "유물과 이렌의 기록을 발견했습니다. 서재에 돌아가 보세요."
		"library": return "서재"
		"grave": return "묘지"
	return ""

static func save_world(w: Dictionary, path: String, now: float=-1.0) -> bool:
	return checkpoint(w,path,now,Store.read(path))

static func checkpoint(w: Dictionary, path: String, now: float, previous: Dictionary) -> bool:
	if w.is_empty(): return false
	if now<0: now=Time.get_unix_time_from_system()
	Storage.prepare(w)
	Interior.prepare(w)
	Quality.prepare(w)
	Market.prepare(w)
	var snapshot:=w.duplicate(false)
	snapshot.saved=maxf(w.saved,now)
	if not Store.replace(snapshot,path,previous):
		push_error("월드 저장 실패: "+path)
		return false
	w.saved=snapshot.saved
	return true

static func load_world(path: String, simulate_absence: bool=true, now: float=-1.0) -> Dictionary:
	if not FileAccess.file_exists(path) and not FileAccess.file_exists(path+".bak"): return fresh()
	var primary:=Store.read(path)
	if Store.unsupported(primary): return {}
	var w:=primary.duplicate(true)
	if not Store.valid(w):
		w=Store.read(path+".bak")
		if not Store.valid(w): return {}
	if now<0: now=Time.get_unix_time_from_system()
	Investigation.prepare(w)
	w.version=16
	Quality.prepare(w)
	Market.prepare(w)
	Interior.prepare(w)
	Remains.prepare(w)
	for p in w.people.values():
		Investigation.prepare_person(p)
		outfit(p)
		p.offline=true
	Storage.prepare(w)
	if simulate_absence: advance(w,maxf(0,now-float(w.saved)))
	# Commit both rewards and the processed timestamp before allowing play.
	if not checkpoint(w,path,now,primary): return {}
	return w
