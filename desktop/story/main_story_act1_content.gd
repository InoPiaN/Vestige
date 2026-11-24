extends RefCounted
## Main Story ACT I content only. No coordinates or physical scene are assigned
## until waypoint placement and movement collision are verified in Godot.
## This is NOT legacy Chapter I/Iren content.
const WAYMARKER_EVENT := "main.act1.old_waymarker"
const WAYMARKER_KNOWLEDGE := "main.waymarker_found"
const WAYMARKER_EVIDENCE := "main.act1.waymarker_evidence"

static func waymarker_definition() -> Dictionary:
	return {
		"act": 1,
		"requires_events": [],
		"requires_knowledge": [],
		"grants_knowledge": [WAYMARKER_KNOWLEDGE]
	}

## Template, not a claim that the player collected evidence.
static func waymarker_evidence() -> Dictionary:
	return {
		"id": WAYMARKER_EVIDENCE,
		"title": "오래된 조사단 이정표",
		"source": "잿빛 마을 외곽 · 오래된 길 (위치 확정 전)",
		"fact": "이정표에 새겨진 표식이 과거 탐사 수첩의 기호와 일치한다.",
		"inference": "과거 주인공이 이 경로를 이용했을 가능성이 있다. 경로 및 보급 기록과의 추가 대조가 필요하다."
	}

static func sera_response(waymarker_confirmed: bool, current_name: String) -> String:
	if waymarker_confirmed:
		return "%s, 그 표식이 네 오래된 수첩과 일치한다고? 마을 기록도 함께 확인해 보자." % current_name
	return "%s, 오늘 오래된 길을 살펴볼 거야? 비가 지나간 뒤라 조심해." % current_name
