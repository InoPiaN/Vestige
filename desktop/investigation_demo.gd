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
