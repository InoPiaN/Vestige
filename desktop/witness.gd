extends RefCounted
# Mira tends the lantern beside the village crates. All positions are in world tiles.
const STATION:=Vector2(13,13.125)
const NAME:="등불지기 미라"
const REACH:=1.5
const SIGHT:=4.5

static func can_see(observer: Vector2,point: Vector2,places: Array) -> bool:
	if observer.distance_to(point)>SIGHT: return false
	for place in places:
		if place.kind not in ["home","forge","library","inn"]: continue
		var wall:=Rect2(place.x-1,place.y-1.5,2,1.9)
		if wall.has_point(observer) or wall.has_point(point): return false
		var corners: Array[Vector2]=[wall.position,Vector2(wall.end.x,wall.position.y),wall.end,Vector2(wall.position.x,wall.end.y)]
		for side in range(4):
			if Geometry2D.segment_intersects_segment(observer,point,corners[side],corners[(side+1)%4])!=null: return false
	return true

# The record contains only what the observer could see at the time of the blow.
static func observe(observer: Vector2,attacker: Vector2,victim: Vector2,mark: String,places: Array,day: int) -> Dictionary:
	if not can_see(observer,attacker,places) or not can_see(observer,victim,places): return {}
	return {"day":day,"mark":mark}

static func testify(c: Dictionary) -> String:
	if c.observation.is_empty(): return NAME+"는 그 장면을 보지 못했다."
	var seen: Dictionary=c.observation
	return "%s의 제 %d일 증언 · “한 사람이 칼을 휘둘렀어. 소매에는 %s가 달려 있었지. 얼굴은 보지 못했어.”" % [NAME,seen.day,seen.mark]

static func candidates(c: Dictionary) -> String:
	return "장부에 적힌 두 사람 중 지목할 이를 고르세요.\n1 · %s     2 · %s" % [c.roster[0].name,c.roster[1].name]

static func identify(w: Dictionary,p: Dictionary,choice: String) -> String:
	if Vector2(p.x,p.y).distance_to(Vector2(4,14))>=2: return "묘지에서 증거를 대조하세요."
	var c: Dictionary=w.cases.get(w.estate.owner,{})
	if not c.has("roster") or choice not in ["1","2"]: return "지목할 사건이 없습니다."
	var notes: Dictionary=p.notebook.get(w.estate.owner,{})
	if not notes.has("home") or not notes.has("scene") or not notes.has("witness") or c.observation.is_empty():
		return "집 장부·현장 단서·목격 증언을 먼저 확보하세요."
	var suspect: Dictionary=c.roster[int(choice)-1]
	if suspect.mark!=c.trace_mark or suspect.mark!=c.observation.mark or suspect.name!=c.attacker:
		return "조사 기록\n장부의 장식과 증언·현장의 흔적이 일치하지 않는다. 수첩을 다시 살펴보자."
	notes.finding="%s의 죽음 · %s의 칼에 의한 살해. 장부, 현장의 장식 조각, 미라의 증언이 일치한다." % [c.name,suspect.name]
	if not c.resolved:
		c.resolved=true
		for grave in w.graves:
			if grave.get("case_id","")==w.estate.owner: grave.cause="살해 · "+suspect.name
		p.events.append(notes.finding)
	return "조사 기록\n"+notes.finding
