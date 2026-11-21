extends RefCounted

# Fixed prototype residents. The short radius leaves facility entrances usable.
const Investigation=preload("res://investigation.gd")

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
		"rumor":"이렌이 돌아오지 않았다고들 해요. 빌려 간 책이 아직 돌아오지 않았어요. 하지만 그것만으로 실종의 이유나 지금 어디에 있는지는 알 수 없어요."},
	"kael": {"name":"카엘", "role":"떠돌이", "x":17.0, "y":14.0,
		"first":"낯선 얼굴이군. 이 마을 사람은 아닌 것 같은데. 무슨 일이지?",
		"return":"다시 왔군. 아직 이곳을 떠나지 않았어.",
		"known":"이렌 이야기가 들리는군. 내가 그 사람의 행방을 안다고 생각하지는 마.",
		"rumor":"이렌이 사라졌다고? 내게 묻는다고 그 사람의 행방이 밝혀지지는 않을 거야."}
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
	if choice!="" and (active_npc!=npc_id or not choice in ["rumor","evidence","kael_irene","kael_chapel","kael_token"]): return {}
	var testimony:=Investigation.testimony(p,npc_id)
	if choice=="evidence" and testimony.is_empty(): return {}
	if choice.begins_with("kael_") and npc_id!="kael": return {}
	if choice=="kael_chapel" and not Investigation.has_evidence(p,"chapel_traces"): return {}
	if choice=="kael_token" and not Investigation.has_evidence(p,"kael_token"): return {}
	ensure(p)
	var s: Dictionary=p.story
	var text: String
	if choice=="evidence":
		text=testimony
	elif choice=="kael_irene":
		text="이렌을 알고 있었어. 예전에 나를 도와준 사람이었지. 그렇지만 실종됐다는 소문만으로 내가 무엇을 알 거라고 단정하지는 마."
	elif choice=="kael_chapel":
		text="예배당에 흔적이 있었다고? 나도 오래된 건물이라는 얘기는 들었어. 그 흔적이 언제 생긴 건지는 모르잖아."
	elif choice=="kael_token":
		text="…그 표식은 내 물건이야. 예배당에 간 적도 있어. 하지만 그곳에서 장치가 작동했다거나 누가 다쳤다는 것은 몰라."
		Investigation.Chapter1.dialogue_once(s.chapter1,"kael_token_owner_admitted")
	elif choice=="rumor":
		text=n.rumor
		if not s.iren_missing_rumor:
			s.iren_missing_rumor=true
			p.events.append("%s에게 이렌이 돌아오지 않았다는 소문을 들었다. 실종 이유와 행방은 확인되지 않았다." % n.name)
	else:
		text=n["return"] if s.visits[npc_id] else n.first
		if s.iren_missing_rumor: text+="\n\n"+n.known
		if not s.visits[npc_id]:
			s.visits[npc_id]=true
			if npc_id=="kael":
				s.kael_encountered=true
				Investigation.Chapter1.dialogue_once(s.chapter1,"KAEL_01")
			p.events.append("%s %s와 처음 인사를 나누었다." % [n.role,n.name])
	var choices:=CHOICES.duplicate(true)
	if not testimony.is_empty(): choices.insert(1,{"id":"evidence","text":"발견한 증거에 관해 묻는다"})
	if npc_id=="kael":
		choices.insert(0,{"id":"kael_irene","text":"이렌과 어떤 관계였는지 묻는다"})
		if Investigation.has_evidence(p,"chapel_traces"):
			choices.insert(1,{"id":"kael_chapel","text":"예배당의 흔적을 묻는다"})
		if Investigation.has_evidence(p,"kael_token"):
			choices.insert(1,{"id":"kael_token","text":"발견한 금속 표식을 보여준다"})
	return {"npc_id":npc_id, "name":n.name, "text":text, "choices":choices}
