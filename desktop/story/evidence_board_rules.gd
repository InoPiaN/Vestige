extends RefCounted
## Server-authoritative pair matching. Each selected clue is a logical ID, not a fact claim.
const Chapter = preload("res://story/chapter1_rules.gd")
const PAIRS := {
	"I03": ["E05", "E07"],
	"I04": ["E06", "E08"],
	"I07": ["E07", "E13"]
}

static func available_records(p: Dictionary) -> Array:
	var result: Array = []
	var story: Dictionary = p.get("story", {})
	var evidence: Dictionary = story.get("evidence", {})
	for id in Chapter.LEGACY_TO_LOGICAL:
		if not evidence.has(id):
			continue
		var item: Dictionary = evidence[id]
		result.append({
			"id": Chapter.LEGACY_TO_LOGICAL[id],
			"title": str(item.get("title", id)),
			"order": int(item.get("order", 0)),
			"source": str(item.get("source", ""))
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary): return a.order < b.order)
	return result

static func evaluate(p: Dictionary, first: String, second: String) -> Dictionary:
	if not p.get("alive", false) or p.get("offline", false):
		return {"accepted": false, "text": "직접 조종 중인 살아 있는 인물만 기록을 검토할 수 있습니다."}
	if first == second or first.is_empty() or second.is_empty():
		return {"accepted": false, "text": "서로 다른 증거 두 개를 선택해야 합니다."}
	Chapter.ensure(p)
	var state: Dictionary = p["story"]["chapter1"]
	if not Chapter.has_evidence(state, first) or not Chapter.has_evidence(state, second):
		return {"accepted": false, "text": "직접 수집하지 않은 증거는 조합할 수 없습니다."}
	var expected: Array = [first, second]
	expected.sort()
	for inference_id in PAIRS:
		var pair: Array = PAIRS[inference_id].duplicate()
		pair.sort()
		if expected != pair:
			continue
		if not Chapter.inference_supported(state, inference_id):
			return {"accepted": false, "text": "현재 확인된 자료로는 이 판단을 검증할 수 없습니다."}
		if state["inferences"].get(inference_id, "") == "verified":
			return {"accepted": false, "text": "이미 기록한 연결입니다. 기존 결과는 유지됩니다."}
		if not Chapter.verify_inference(state, inference_id):
			return {"accepted": false, "text": "추론을 검증할 수 없습니다."}
		return {"accepted": true, "inference_id": inference_id, "text": "연결을 기록했습니다: %s. 이 결과만으로 사건의 책임이나 사망 경위는 확정되지 않습니다." % inference_id}
	return {"accepted": false, "text": "두 자료 사이의 직접적인 연결을 아직 확인할 수 없습니다. 더 조사해 보세요."}
