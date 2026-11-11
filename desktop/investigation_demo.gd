extends RefCounted
const Rules=preload("res://world.gd")
# Build a fictional starting point with the same purchase, journal and combat rules as play.
static func create() -> Dictionary:
	var w:=Rules.fresh()
	Rules.born(w,"local","약초꾼 소율")
	var owner: Dictionary=w.people.local
	owner.x=7
	owner.y=14
	owner.events.append("내일은 동쪽 예배당 길목으로 약초를 가져갈 생각이다.")
	Rules.advance(w,Rules.DAY)
	Rules.act(w,"local","interact")
	owner.x=25
	owner.y=10
	owner.events.append("예배당 근처까지 왔다. 수풀에서 발소리가 들린다.")
	for frame in range(1200):
		Rules.tick(w,1.0/60.0)
		if not owner.alive: break
	Rules.born(w,"local","기록을 좇는 여행자")
	return w

static func murder() -> Dictionary:
	var w:=Rules.fresh()
	Rules.born(w,"local","장부지기 은결")
	var owner: Dictionary=w.people.local
	owner.x=7
	owner.y=14
	var roster: Array=[{"name":"로운","mark":"둥근 고리"},{"name":"하렌","mark":"갈라진 고리"}]
	owner.events.append("내일 장터 동쪽에서 운송인 두 사람에게 장부를 보여줄 예정이다.")
	for carrier in roster: owner.events.append("운송 조합 명부 · %s의 소매 표식은 %s." % [carrier.name,carrier.mark])
	Rules.advance(w,Rules.DAY)
	Rules.act(w,"local","interact")
	owner.x=16
	owner.y=13
	var attacker: Dictionary=roster[1].duplicate()
	attacker.x=16.5
	attacker.y=13
	Rules.npc_strike(w,"local",attacker,Rules.Investigation.Witness.STATION,roster,100)
	Rules.born(w,"local","기록을 좇는 여행자")
	return w

# Independent recovery tutorial; existing investigation saves are never reset.
static func remains() -> Dictionary:
	var w:=Rules.fresh()
	Rules.born(w,"local","떠난 여행자")
	var owner: Dictionary=w.people.local
	owner.x=7
	owner.y=14
	owner.herb=3
	owner.ore=2
	Rules.act(w,"local","interact")
	Rules.act(w,"local","store_item","herb")
	owner.x=5
	owner.y=8
	Rules.act(w,"local","interact")
	owner.x=16
	owner.y=13
	owner.events.append("장터 동쪽에 도착했다. 남은 짐은 누군가에게 도움이 되기를.")
	Rules.die(w,"local","여행 중 사고")
	Rules.born(w,"local","유품을 찾는 여행자")
	w.people.local.x=15
	w.people.local.y=13
	return w

static func home() -> Dictionary:
	var w:=Rules.fresh()
	Rules.born(w,"local","언덕집의 여행자")
	var p: Dictionary=w.people.local
	p.x=7
	p.y=14
	p.hp=65
	p.events.append("오래된 언덕집을 마련했다. 책장에 앞으로의 날들을 남기려 한다.")
	Rules.act(w,"local","interact")
	Rules.act(w,"local","enter_home")
	return w

static func craft() -> Dictionary:
	var w:=home()
	var p: Dictionary=w.people.local
	p.x=15
	p.y=12
	p.belongings.cloth=5
	p.belongings.bent_nail=4
	p.belongings.broken_cup=1
	p.herb=3
	p.sword=1
	Rules.outfit(p)
	for id in p.gear_instances:
		if p.gear_instances[id]=="iron_sword": p.gear_condition[id]=35
	p.events.append("작업대에 수선할 검과 작은 재료 꾸러미를 준비했다.")
	return w

static func quality() -> Dictionary:
	var w:=home()
	var p: Dictionary=w.people.local
	p.room="village"
	p.x=5
	p.y=8
	p.ore=6
	w.craft_rng=8 # Tutorial creates one example of each tier using real crafting.
	for i in range(3): Rules.act(w,"local","interact")
	p.room="home"
	p.x=15
	p.y=12
	p.belongings.cloth=6
	p.belongings.bent_nail=4
	p.belongings.broken_cup=1
	p.herb=6
	return w

static func market() -> Dictionary:
	var w:=quality()
	var p: Dictionary=w.people.local
	p.room="village"
	p.x=14
	p.y=15
	p.gold=30
	return w

static func mastery() -> Dictionary:
	var w:=craft()
	var p: Dictionary=w.people.local
	p.craft_xp={"smithing":400,"handicraft":1000,"herbalism":96}
	p.events.append("체험용 인물: 대장 기술 숙련, 생활 공예 장인, 약초 조제 견습까지 경험치 4를 남겨 두었다.")
	return w

static func plan() -> Dictionary:
	var w:=craft()
	w.people.local.hp=100
	return w

static func supply() -> Dictionary:
	var w:=plan()
	var p: Dictionary=w.people.local
	w.estate.storage.belongings.cloth=6
	w.estate.storage.herb=6
	p.belongings.cloth=0
	p.herb=0
	p.craft_supply={"source":"home","destination":"home"}
	return w
