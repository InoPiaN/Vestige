extends RefCounted

const Chapter1 = preload("res://story/chapter1_rules.gd")

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
		"inference":"여러 원인이 흔적을 남겼을 수 있다. 야수나 사람의 개입, 발생 시점과 이렌의 행방을 이 흔적만으로 판단할 수 없다."},
	"kael_token": {
		"title":"낡은 금속 표식", "source":"잊힌 예배당 · 바깥길", "x":26.0,"y":14.0,
		"fact":"낡은 금속 표식에 마모된 글자와 균열이 남아 있다. 누구의 물건인지는 확인되지 않았다.",
		"inference":"예배당을 방문한 사람이 떨어뜨렸을 가능성이 있다. 소유자와 사고 관련성은 아직 밝혀지지 않았다."},
	"device_log": {
		"title":"장치 작동 기록 조각", "source":"잊힌 예배당 · 동쪽 기록판", "x":28.0,"y":11.0,
		"fact":"기록판에는 장치의 수동 가동과 직후의 비정상적인 진동이 표시되어 있다. 일부 기록은 훼손되어 조작자의 신원은 남아 있지 않다.",
		"inference":"장치가 실제로 가동된 정황이다. 기록만으로 누가 조작했는지, 이렌에게 무슨 일이 일어났는지는 알 수 없다."},
	"device_key": {
		"title":"장치 조작 도구 파편", "source":"잊힌 예배당 · 파손된 연결부", "x":24.0,"y":13.0,
		"fact":"장치 연결부에 부러진 도구 조각이 끼어 있다. 파손 단면과 맞물리는 홈이 남아 있다. 사용자의 신원 표식은 없다.",
		"inference":"장치에 도구가 사용되었을 정황이다. 조각의 제작자·사용자는 확인되지 않는다."}
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
	Chapter1.ensure(p)

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
	if evidence_id in ["chapel_traces","kael_token","device_log","device_key"] and w.wolf.hp>0: return "예배당을 지키는 늑대를 먼저 물리쳐야 현장을 조사할 수 있습니다."
	var order:=1
	for record in p.story.evidence.values(): order=maxi(order,int(record.order)+1)
	var record: Dictionary={"id":evidence_id,"title":e.title,"source":e.source,"order":order,
		"discovered_at":float(w.time),"day":int(w.time/DAY)+1,"fact":e.fact,"inference":e.inference}
	p.story.evidence[evidence_id]=record
	Chapter1.sync_legacy(p)
	p.events.append("%s에서 증거를 기록했다: %s. [확인된 사실] %s [추정 · 미확인] %s" % [e.source,e.title,e.fact,e.inference])
	return "증거 기록 · %s — N으로 조사 수첩을 확인하세요." % e.title

# Dialogue-owned evidence can only originate from an authenticated NPC conversation.
# This function must not be exposed as a client-command without session and range checks.
static func record_kael_statement(w: Dictionary, player_id: String) -> bool:
	if not w.people.has(player_id): return false
	var p: Dictionary = w.people[player_id]
	if not p.alive or p.offline or not has_evidence(p,"kael_token"): return false
	ensure(p)
	if has_evidence(p,"kael_statement"): return false
	var order := 1
	for record in p.story.evidence.values(): order=maxi(order,int(record.order)+1)
	var fact := "카엘은 금속 표식이 자신의 것이라고 인정하고 예배당에 갔으나 장치가 작동했는지는 모른다고 진술했다."
	var hypothesis := "이는 카엘의 진술이며 장치 조작자나 사고 책임을 입증하는 독립 물증이 아니다."
	p.story.evidence["kael_statement"] = {
		"id":"kael_statement","title":"카엘의 최초 진술","source":"카엘 · 직접 대화",
		"order":order,"discovered_at":float(w.time),"day":int(w.time/DAY)+1,
		"fact":fact,"inference":hypothesis
	}
	Chapter1.sync_legacy(p)
	p.events.append("카엘의 최초 진술을 기록했다. 확인되지 않은 사건 책임은 단정하지 않았다.")
	return true

static func reconstruction_summary(p: Dictionary) -> String:
	var state: Dictionary = p.get("story", {}).get("chapter1", {})
	var text := "사건 재구성 · 임시 조사 기록\\n────────────────────\\n"
	for inference_id in ["I03","I04","I07"]:
		var label: String = {"I03":"봉인 손상과 장치 가동 기록","I04":"카엘의 방문과 직접 진술","I07":"장치 연결부와 도구 파편"}.get(inference_id,inference_id)
		var status := "검증 완료" if state.get("inferences", {}).get(inference_id, "")=="verified" else ("검증 가능 · 세라에게 확인" if Chapter1.inference_supported(state,inference_id) else "증거 부족")
		text += "%s · %s: %s\\n" % [inference_id,label,status]
	text += "\\n주의: 이 판단은 카엘이 장치를 작동했다는 사실이나 이렌의 사망을 확정하지 않습니다.\\n"
	return text

static func notebook(p: Dictionary) -> String:
	var text: String="조사 수첩 · 마지막 약속\n────────────────────\n발견 시각은 월드 경과 시간입니다. 추정은 확인된 사실이 아닙니다.\n\n"
	var records: Array=p.get("story",{}).get("evidence",{}).values()
	records.sort_custom(func(a,b): return a.order<b.order)
	if records.is_empty():
		return text+"아직 발견한 증거가 없습니다. 마을 북동쪽 이렌의 집 입구나 예배당 남쪽 석판 가까이에서 E로 조사하세요. 소문을 먼저 들을 필요는 없습니다."
	for e in records:
		text+="#%d · %s [%s]\n출처: %s\n발견: 제 %d일 · 월드 경과 %.1f초\n\n확인된 사실\n%s\n\n추정 · 미확인\n%s\n\n" % [e.order,e.title,e.id,e.source,e.day,e.discovered_at,e.fact,e.inference]
	if has_evidence(p,"device_log") and has_evidence(p,"chapel_traces"):
		text+="연결 가능한 사실: 석판 손상과 장치 가동 기록이 함께 발견되었다. 원인·시점·조작자의 관계는 추가 검증이 필요하다.\n\n"
	if has_evidence(p,"kael_statement") and has_evidence(p,"device_log"):
		text+="진술 대조 가능: 카엘의 기억과 장치 기록을 다시 비교할 수 있다. 어느 쪽도 단독으로 조작자를 입증하지 않는다.\n\n"
	text+="\\n"+reconstruction_summary(p)+"\\n"
	text+="기록한 증거를 브란, 세라, 카엘에게 물어볼 수 있습니다. 사건의 원인과 약속 상대는 아직 확인되지 않았습니다."
	return text

static func testimony(p: Dictionary, npc_id: String) -> String:
	var token:=has_evidence(p,"kael_token")
	var log_found:=has_evidence(p,"device_log")
	if log_found and npc_id=="sera": return "예배당에서 장치가 실제로 가동된 기록을 발견하셨군요. 다만 기록이 훼손됐으니 누가 조작했는지는 아직 판단할 수 없어요."
	if npc_id=="kael":
		if token: return "이 표식이… 왜 거기에 있었지? 예배당에 갔다는 사실까지는 부인하지 않겠어. 하지만 거기서 무슨 일이 있었는지는 말하지 않았어."
		if has_evidence(p,"last_promise"): return "이렌이 누군가와 약속했다는 글인가. 내가 그 상대였는지는 아직 모르잖아."
		if has_evidence(p,"chapel_traces"): return "석판이 파손됐다는 얘기는 들었어. 그 흔적만으로 누구의 행동인지 알 수는 없겠지."
		if log_found: return "장치가 작동했다는 기록이 있어도 누가 그 기록을 남긴 건지는 모르는 일이야."
		return ""
	if log_found and npc_id=="bran": return "장치의 기록이 발견됐다고 해도 그날 누구에게 무슨 일이 있었는지 알 수는 없네."
	if token: return "금속 표식의 주인을 직접 확인해야겠네. 소지품만으로 현장 행동을 단정할 수는 없어." if npc_id=="bran" else "표식의 표면을 확인했군요. 주인을 밝히더라도 작동자를 확인하려면 다른 증거가 필요해요."
	var diary:=has_evidence(p,"last_promise")
	var traces:=has_evidence(p,"chapel_traces")
	if diary and traces:
		return "약속의 글과 현장 흔적을 모두 찾았군. 그래도 누가 왔는지, 언제 무슨 일이 있었는지는 아직 모르네." if npc_id=="bran" else "약속 일기와 석판 흔적은 각각 기록해 두세요. 두 증거가 같은 사건에서 비롯됐는지도 아직 확인해야 해요."
	if diary:
		return "예배당에서 만나기로 했다는 글인가. 나는 약속 상대가 누구인지 몰라. 약속과 실제 만남은 다를 수 있네." if npc_id=="bran" else "일기에 약속이 적혀 있다는 건 확인했군요. 실제로 만났는지 알아보려면 예배당 현장도 살펴봐야겠어요."
	if traces:
		return "긁힌 석판만으로 늑대 탓이라고 할 수는 없네. 내가 그 현장을 본 것도 아니야." if npc_id=="bran" else "흔적의 모양과 해석을 나누어 적으세요. 이렌의 집에 남은 기록과 비교할 수 있겠지만, 원인은 아직 몰라요."
	return ""
