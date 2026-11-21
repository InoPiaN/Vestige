extends RefCounted

const RADIUS := 1.125
const DAY := 2880.0
# Observation text is intentionally narrower than the unresolved story hypothesis.
const EVIDENCE := {
	"last_promise": {
		"title":"마지막 약속 일기", "source":"이렌의 집 · 입구 책장", "x":16.0,"y":7.0,
		"fact":"이렌의 일기에 ‘해 질 무렵 예배당에서 누군가를 만나기로 했다’고 적혀 있다. 상대의 이름은 적혀 있지 않다.",
		"inference":"예배당에 약속 상대가 왔을 가능성이 있다. 실제 만남 여부와 상대의 신원은 확인되지 않았다."},
	"chapel_traces": {
		"title":"예배당 현장 흔적", "source":"잊힌 예배당 · 남쪽 석판", "x":27.0,"y":12.0,
		"fact":"석판의 문양 일부가 깨져 있고 가장자리에 길게 긁힌 자국이 남아 있다. 주변 흙에는 윤곽이 흐린 눌린 흔적이 겹쳐 있다.",
		"inference":"여러 원인이 흔적을 남겼을 수 있다. 야수나 사람의 개입, 발생 시점과 이렌의 행방을 이 흔적만으로 판단할 수 없다."}
}

static func ensure(p: Dictionary) -> void:
	if not p.get("story",null) is Dictionary: p.story={}
	if not p.story.get("evidence",null) is Dictionary: p.story.evidence={}
	# JSON parses numbers as floats; restore the declared record types on load.
	for id in p.story.evidence:
		var record: Dictionary=p.story.evidence[id]
		record.order=int(record.order)
		record.day=int(record.day)
		record.discovered_at=float(record.discovered_at)

static func has_evidence(p: Dictionary, id: String) -> bool:
	return p.get("story",{}).get("evidence",{}).has(id)

static func nearby(p: Dictionary) -> String:
	for id in EVIDENCE:
		var e: Dictionary=EVIDENCE[id]
		if Vector2(p.x,p.y).distance_to(Vector2(e.x,e.y))<RADIUS: return id
	return ""

static func inspect(w: Dictionary, player_id: String, evidence_id: String) -> String:
	if not w.people.has(player_id): return "먼저 인물을 생성하세요."
	var p: Dictionary=w.people[player_id]
	if not p.alive or p.offline: return "살아 있는 인물을 직접 조종할 때 조사할 수 있습니다."
	if not EVIDENCE.has(evidence_id): return "알 수 없는 조사 대상입니다."
	var e: Dictionary=EVIDENCE[evidence_id]
	if Vector2(p.x,p.y).distance_to(Vector2(e.x,e.y))>=RADIUS: return "조사 대상 가까이에서 E를 누르세요."
	ensure(p)
	if has_evidence(p,evidence_id): return "이미 기록한 증거입니다. N으로 조사 수첩을 확인하세요."
	if evidence_id=="chapel_traces" and w.wolf.hp>0: return "예배당을 지키는 늑대를 먼저 물리쳐야 현장을 조사할 수 있습니다."
	var order:=1
	for record in p.story.evidence.values(): order=maxi(order,int(record.order)+1)
	var record: Dictionary={"id":evidence_id,"title":e.title,"source":e.source,"order":order,
		"discovered_at":float(w.time),"day":int(w.time/DAY)+1,"fact":e.fact,"inference":e.inference}
	p.story.evidence[evidence_id]=record
	p.events.append("%s에서 증거를 기록했다: %s. [확인된 사실] %s [추정 · 미확인] %s" % [e.source,e.title,e.fact,e.inference])
	return "증거 기록 · %s — N으로 조사 수첩을 확인하세요." % e.title

static func notebook(p: Dictionary) -> String:
	var text: String="조사 수첩 · 마지막 약속\n────────────────────\n발견 시각은 월드 경과 시간입니다. 추정은 확인된 사실이 아닙니다.\n\n"
	var records: Array=p.get("story",{}).get("evidence",{}).values()
	records.sort_custom(func(a,b): return a.order<b.order)
	if records.is_empty():
		return text+"아직 발견한 증거가 없습니다. 마을 북동쪽 이렌의 집 입구나 예배당 남쪽 석판 가까이에서 E로 조사하세요. 소문을 먼저 들을 필요는 없습니다."
	for e in records:
		text+="#%d · %s [%s]\n출처: %s\n발견: 제 %d일 · 월드 경과 %.1f초\n\n확인된 사실\n%s\n\n추정 · 미확인\n%s\n\n" % [e.order,e.title,e.id,e.source,e.day,e.discovered_at,e.fact,e.inference]
	text+="기록한 증거를 브란과 세라에게 물어볼 수 있습니다. 사건의 원인과 약속 상대는 아직 확인되지 않았습니다."
	return text

static func testimony(p: Dictionary, npc_id: String) -> String:
	var diary:=has_evidence(p,"last_promise")
	var traces:=has_evidence(p,"chapel_traces")
	if diary and traces:
		return "약속의 글과 현장 흔적을 모두 찾았군. 그래도 누가 왔는지, 언제 무슨 일이 있었는지는 아직 모르네." if npc_id=="bran" else "약속 일기와 석판 흔적은 각각 기록해 두세요. 두 증거가 같은 사건에서 비롯됐는지도 아직 확인해야 해요."
	if diary:
		return "예배당에서 만나기로 했다는 글인가. 나는 약속 상대가 누구인지 몰라. 약속과 실제 만남은 다를 수 있네." if npc_id=="bran" else "일기에 약속이 적혀 있다는 건 확인했군요. 실제로 만났는지 알아보려면 예배당 현장도 살펴봐야겠어요."
	if traces:
		return "긁힌 석판만으로 늑대 탓이라고 할 수는 없네. 내가 그 현장을 본 것도 아니야." if npc_id=="bran" else "흔적의 모양과 해석을 나누어 적으세요. 이렌의 집에 남은 기록과 비교할 수 있겠지만, 원인은 아직 몰라요."
	return ""
