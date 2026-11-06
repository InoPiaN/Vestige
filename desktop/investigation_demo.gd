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
