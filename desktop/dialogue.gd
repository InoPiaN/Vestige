extends RefCounted

# Fixed prototype residents. The short radius leaves facility entrances usable.
const RADIUS := 1.125
const NPCS := {
	"bran": {"name":"브란", "role":"대장장이", "x":7.0, "y":7.5,
		"first":"처음 보는 얼굴이군. 나는 브란, 이 대장간을 맡고 있네. 철광석 두 개를 모으면 대장간에서 검을 만들 수 있어.",
		"return":"다시 왔군. 불은 아직 따뜻하네. 필요한 일이 있나?",
		"known":"이렌 이야기가 마음에 걸리나? 돌아오지 않았다는 말만으로 무슨 일이 있었는지 단정할 수는 없네.",
		"rumor":"약초사 이렌이 돌아오지 않았다는 소문이 돌고 있네. 내 장갑도 고쳐 주던 사람이야. 늑대 때문이라는 말도 있지만, 나는 직접 본 게 없어."},
	"sera": {"name":"세라", "role":"서재 관리인", "x":12.0, "y":4.5,
		"first":"기억의 서재에 오신 걸 환영해요. 저는 세라예요. 누군가 남긴 기록을 돌보고 있어요.",
		"return":"다시 오셨군요. 오늘은 어떤 이야기를 찾고 계세요?",
		"known":"이렌의 소문을 들으셨군요. 들은 말과 확인한 사실은 나누어 기록해 주세요.",
		"rumor":"이렌이 돌아오지 않았다고들 해요. 빌려 간 책이 아직 돌아오지 않았어요. 하지만 그것만으로 실종의 이유나 지금 어디에 있는지는 알 수 없어요."}
}
const CHOICES := [{"id":"rumor", "text":"이렌의 실종 소문을 묻는다"}, {"id":"leave", "text":"대화를 마친다"}]

static func ensure(p: Dictionary) -> void:
	if not p.get("story", null) is Dictionary: p.story={}
	var s: Dictionary=p.story
	if not s.get("visits", null) is Dictionary: s.visits={}
	for id in NPCS:
		if not s.visits.get(id, null) is bool: s.visits[id]=false
	if not s.get("iren_missing_rumor", null) is bool: s.iren_missing_rumor=false
	if not s.get("kael_encountered", null) is bool: s.kael_encountered=false

static func nearby(p: Dictionary) -> String:
	var nearest := RADIUS
	var found := ""
	for id in NPCS:
		var n: Dictionary=NPCS[id]
		var distance := Vector2(p.x,p.y).distance_to(Vector2(n.x,n.y))
		if distance < nearest:
			nearest=distance
			found=id
	return found

# The server owns active_npc; a client cannot submit an arbitrary conversation result.
static func talk(w: Dictionary, id: String, npc_id: String, choice: String="", active_npc: String="") -> Dictionary:
	if not w.people.has(id) or not NPCS.has(npc_id): return {}
	var p: Dictionary=w.people[id]
	var n: Dictionary=NPCS[npc_id]
	if not p.alive or p.offline: return {}
	if Vector2(p.x,p.y).distance_to(Vector2(n.x,n.y))>=RADIUS: return {}
	if choice!="" and (active_npc!=npc_id or choice!="rumor"): return {}
	ensure(p)
	var s: Dictionary=p.story
	var text: String
	if choice=="rumor":
		text=n.rumor
		if not s.iren_missing_rumor:
			s.iren_missing_rumor=true
			p.events.append("%s에게 이렌이 돌아오지 않았다는 소문을 들었다. 실종 이유와 행방은 확인되지 않았다." % n.name)
	else:
		text=n["return"] if s.visits[npc_id] else n.first
		if s.iren_missing_rumor: text+="\n\n"+n.known
		if not s.visits[npc_id]:
			s.visits[npc_id]=true
			p.events.append("%s %s와 처음 인사를 나누었다." % [n.role,n.name])
	return {"npc_id":npc_id, "name":n.name, "text":text, "choices":CHOICES.duplicate(true)}
