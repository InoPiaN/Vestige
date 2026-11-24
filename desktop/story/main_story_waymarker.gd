extends RefCounted
## Server/single-authorized ACT I waymarker examination.
## A client never submits an event ID or coordinates as a fact.
const Contract = preload("res://story/main_story_contract.gd")
const Director = preload("res://story/main_story_director.gd")
const Content = preload("res://story/main_story_act1_content.gd")
const RADIUS := 1.25
const LOCATION := Vector2(3.0, 16.0)
const REGION := "village"
const DAY := 2880.0

static func nearby(person: Dictionary) -> bool:
	return person.get("alive", false) and not person.get("offline", true) and person.get("room", "village") == REGION and Vector2(float(person.get("x", -100)), float(person.get("y", -100))).distance_to(LOCATION) < RADIUS

static func execute(world: Dictionary, actor_id: String, target: String, role: String, life_id: String) -> Dictionary:
	if role not in ["single", "server"]:
		return {"recorded": false, "message": "권한이 없는 조사 요청입니다."}
	if target != Content.WAYMARKER_EVIDENCE:
		return {"recorded": false, "message": "알 수 없는 조사 대상입니다."}
	if not world.get("people") is Dictionary or not world["people"].has(actor_id):
		return {"recorded": false, "message": "조사할 인물을 찾을 수 없습니다."}
	var person: Dictionary = world["people"][actor_id]
	if life_id.is_empty() or str(person.get("life", "")) != life_id:
		return {"recorded": false, "message": "생애가 변경되어 조사할 수 없습니다."}
	if not nearby(person):
		return {"recorded": false, "message": "마을 외곽 이정표 가까이에서 E를 누르세요."}
	# No mutation before authorization, presence, and life/target checks.
	if not Contract.ensure_person(person):
		return {"recorded": false, "message": "기록 상태를 확인할 수 없습니다."}
	var state: Dictionary = person["main_story"]
	var result: Dictionary = Director.apply_event(state, Content.WAYMARKER_EVENT, Content.waymarker_definition())
	if not result.get("accepted", false):
		return {"recorded": false, "message": "이미 조사한 이정표입니다. N 수첩을 확인하세요." if result.get("reason") == "already_completed" else "현재 이 표식을 조사할 수 없습니다."}
	var evidence: Dictionary = Content.waymarker_evidence().duplicate(true)
	evidence["discovered_at"] = float(world.get("time", 0.0))
	evidence["day"] = int(evidence["discovered_at"] / DAY) + 1
	if not state.has("evidence"):
		state["evidence"] = {}
	state["evidence"][Content.WAYMARKER_EVIDENCE] = evidence
	return {"recorded": true, "message": "옛 조사단 이정표의 표식을 기록했습니다. N 수첩에서 사실과 추정을 확인하세요."}

static func notebook(person: Dictionary) -> String:
	var state: Dictionary = person.get("main_story", {})
	if not state is Dictionary or not state.get("evidence", {}) is Dictionary:
		return ""
	var evidence: Dictionary = state.get("evidence", {})
	if not evidence.has(Content.WAYMARKER_EVIDENCE):
		return ""
	var record: Dictionary = evidence[Content.WAYMARKER_EVIDENCE]
	return "메인 스토리 · 돌아온 길\n────────────────────\n%s\n출처: %s\n제 %d일 발견\n\n[확인된 사실]\n%s\n\n[추정 · 추가 검증 필요]\n%s\n\n" % [record.title, record.source, int(record.day), record.fact, record.inference]
