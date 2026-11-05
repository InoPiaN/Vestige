extends RefCounted

const DAY := 2880.0
const PLACES := [
	{"kind":"forge","name":"잿불 대장간","x":5,"y":7},
	{"kind":"library","name":"기억의 서재","x":10,"y":4},
	{"kind":"inn","name":"등불 여관","x":11,"y":11},
	{"kind":"grave","name":"이름의 묘지","x":4,"y":14},
	{"kind":"ore","name":"철광맥","x":21,"y":5},
	{"kind":"herb","name":"달빛 약초","x":22,"y":14},
	{"kind":"ruin","name":"잊힌 예배당","x":27,"y":9}
]

const LOOK_OPTIONS := {"hair":3,"hair_color":4,"skin":3,"cloth":4}
const GEAR := {"body":["none","leather"],"head":["none","hood"],"cloak":["none","traveler"],"weapon":["none","iron_sword"]}

static func clean_look(value: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for key in LOOK_OPTIONS:
		var v=value.get(key,0)
		result[key]=clampi(int(v),0,LOOK_OPTIONS[key]-1) if (v is int or v is float) else 0
	return result

static func outfit(p: Dictionary) -> void:
	p.look=clean_look(p.get("look",{}))
	if not p.has("belongings"): p.belongings={"leather":1,"hood":1,"traveler":1}
	if not p.has("equipment"):
		p.equipment={"body":"none","head":"none","cloak":"none","weapon":"iron_sword" if p.sword>0 else "none"}
	for slot in GEAR:
		if not p.equipment.get(slot,"none") in GEAR[slot]: p.equipment[slot]="none"
	if p.sword<=0: p.equipment.weapon="none"
	if not p.has("hide_helmet"): p.hide_helmet=false

static func fresh() -> Dictionary:
	return {"version":1,"time":0.0,"saved":Time.get_unix_time_from_system(),"people":{},"graves":[],"books":[],"wolf":{"x":25.0,"y":10.0,"hp":50,"cooldown":0.0,"warning":0.0,"respawn":0.0}}

static func born(w: Dictionary, id: String, title: String, look: Dictionary={}) -> void:
	if w.people.has(id) and w.people[id].alive:
		return
	w.people[id] = {"name":title.left(20),"x":9.0,"y":9.0,"hp":100,"stamina":100.0,"age":7200,"limit":21600,"alive":true,"offline":false,"policy":"rest","ore":0,"herb":0,"sword":0,"relic":0,"skill":0,"gold":12,"journal":[],"events":["잿불 마을에 도착했다."],"attack":0.0,"dodge":0.0,"facing":1,"steps":0.0,"quest":0}

	w.people[id].look=clean_look(look)
	outfit(w.people[id])

static func die(w: Dictionary, id: String, cause: String) -> void:
	var p: Dictionary = w.people[id]
	if not p.alive:
		return
	p.alive=false
	p.offline=true
	p.hp=0
	w.graves.append({"name":p.name,"cause":cause,"day":int(w.time/DAY)+1,"x":p.x,"y":p.y})
	w.books.append({"author":p.name,"pages":p.journal.duplicate(true),"last":" ".join(p.events)})
	p.events.append(cause+"으로 삶을 마쳤다.")

static func advance(w: Dictionary, seconds: float) -> void:
	var old_day := int(w.time / DAY)
	w.time += maxf(0, seconds)
	var days := int(w.time / DAY) - old_day
	for id in w.people:
		var p: Dictionary = w.people[id]
		if not p.alive:
			continue
		var count := mini(days, int(p.limit-p.age))
		for i in range(count):
			if p.offline:
				if p.hp < 40 or p.policy == "rest":
					p.hp=mini(100,p.hp+25)
					p.events.append("여관에서 쉬며 몸을 추슬렀다.")
				elif p.policy == "gather":
					var amount := mini(2,20-int(p.herb))
					p.herb+=amount
					p.events.append("근교에서 약초 %d개를 모았다." % amount if amount > 0 else "약초 보관함이 가득 차 채집을 쉬었다.")
				elif p.policy == "work":
					if p.ore>=2 and p.sword<5:
						p.ore-=2
						p.sword+=1
						p.skill+=1
						p.events.append("대장간에서 철검을 완성했다.")
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
				die(w,id,"노환")
				break
	if w.wolf.hp<=0 and w.time>=w.wolf.respawn:
		w.wolf.hp=50
		w.wolf.x=25.0
		w.wolf.y=10.0

static func pos(p: Dictionary) -> Vector2:
	return Vector2(p.x,p.y)

static func walkable(v: Vector2) -> bool:
	if v.x<1 or v.y<1 or v.x>29 or v.y>18:
		return false
	for t in PLACES:
		if t.kind in ["forge","library","inn"]:
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
	if walkable(next):
		p.x=next.x
	next=pos(p)+Vector2(0,d.y)
	if walkable(next):
		p.y=next.y
	if d.length()>0:
		p.steps+=dt*8
		p.facing=1 if d.x>=0 else -1

static func tick(w: Dictionary, dt: float) -> void:
	advance(w,dt)
	for p in w.people.values():
		p.attack=maxf(0,p.attack-dt)
		p.dodge=maxf(0,p.dodge-dt)
		p.stamina=minf(100,p.stamina+dt*16)
		if p.alive and p.offline:
			var destination:=Vector2(11,12)
			if p.policy=="work": destination=Vector2(5,8)
			if p.policy=="gather": destination=Vector2(15,13)
			if p.policy=="train": destination=Vector2(9,9)
			var v:=pos(p).move_toward(destination,dt*1.1)
			if walkable(v):
				p.x=v.x
				p.y=v.y
			p.steps+=dt*3
	var e: Dictionary=w.wolf
	if e.hp<=0:
		return
	e.cooldown=maxf(0,e.cooldown-dt)
	var target_id: String=""
	var nearest:=4.5
	for id in w.people:
		var p: Dictionary=w.people[id]
		var dist:=pos(e).distance_to(pos(p))
		if p.alive and p.x>18 and dist<nearest:
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
				target.hp-=18
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
	if kind=="equip":
		var parts:=value.split(":")
		if parts.size()!=2 or not GEAR.has(parts[0]) or not parts[1] in GEAR[parts[0]]: return "장비 선택이 올바르지 않습니다."
		if parts[1]!="none" and preload("res://items.gd").quantity(p,parts[1])<=0: return "먼저 대장간에서 철검을 제작하세요."
		p.equipment[parts[0]]=parts[1]
		return "장비를 변경했습니다."
	if kind=="helmet":
		p.hide_helmet=value=="hide"
		return "투구 표시를 변경했습니다."
	if kind=="policy":
		if value in ["rest","work","gather","train"]: p.policy=value
		return "생활 방침을 저장했습니다."
	if kind=="leave":
		p.offline=true
		return "생활을 맡겼습니다. 세계가 흐르는 동안 주민으로 살아갑니다."
	if kind=="resume":
		p.offline=false
		return "직접 조종을 시작합니다."
	if p.offline: return "직접 조종을 먼저 선택하세요."
	if kind=="dodge":
		if p.stamina>=30 and p.dodge<=0:
			p.stamina-=30
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
		p.stamina-=12
		if w.wolf.hp>0 and pos(p).distance_to(pos(w.wolf))<2:
			w.wolf.hp-=22 if p.equipment.weapon=="iron_sword" else 9
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
		"ore":
			if p.attack>0: return ""
			if p.ore>=20: return "철광석 보관함이 가득 찼습니다."
			p.attack=0.6
			p.ore+=1
			p.events.append("북쪽 광맥에서 철광석을 채굴했다.")
			return "철광석 +1 · 2개를 모아 대장간으로 돌아가세요."
		"herb":
			if p.attack>0: return ""
			if p.herb>=20: return "약초 보관함이 가득 찼습니다."
			p.attack=0.6
			p.herb+=1
			p.events.append("숲 가장자리에서 달빛 약초를 채집했다.")
			return "달빛 약초 +1 · Q로 치료할 수 있습니다."
		"forge":
			if p.ore<2: return "철광석 2개가 필요합니다. 동쪽 광맥을 찾아보세요."
			if p.sword>=5: return "철검 보관 한도에 도달했습니다."
			p.ore-=2
			p.sword+=1
			p.equipment.weapon="iron_sword"
			p.skill+=1
			p.events.append("잿불 대장간에서 첫 여정을 위한 철검을 만들었다.")
			return "철검을 만들었습니다. 공격력 9 → 22"
		"inn":
			p.hp=100
			p.events.append("등불 여관에서 따뜻한 식사를 하고 쉬었다.")
			return "체력을 모두 회복했습니다."
		"ruin":
			if w.wolf.hp>0: return "예배당을 지키는 늑대를 먼저 물리쳐야 합니다."
			if p.relic>0: return "이미 조사한 장소입니다. 서재에서 발견한 기록을 읽어보세요."
			p.relic=1
			p.events.append("예배당에서 약초사 이렌의 마지막 일기와 낡은 유물을 찾았다.")
			return "유물과 이렌의 기록을 발견했습니다. 서재에 돌아가 보세요."
		"library": return "서재"
		"grave": return "묘지"
	return ""

static func save_world(w: Dictionary, path: String) -> void:
	w.saved=Time.get_unix_time_from_system()
	var f:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if f==null: return
	f.store_string(JSON.stringify(w))
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(path,path+".bak")
	DirAccess.rename_absolute(path+".tmp",path)

static func load_world(path: String) -> Dictionary:
	var w:=fresh()
	if FileAccess.file_exists(path):
		var data=JSON.parse_string(FileAccess.get_file_as_string(path))
		if data is Dictionary and data.get("version",0)==1:
			w=data
			for p in w.people.values():
				outfit(p)
				p.offline=true
			advance(w,maxf(0,Time.get_unix_time_from_system()-float(w.saved)))
	return w
