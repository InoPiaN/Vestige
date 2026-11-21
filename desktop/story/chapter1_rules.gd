extends RefCounted
## Chapter I: per-life story progression. The existing investigation records remain authoritative.
## The server calls ensure/sync from investigation.gd; never trust client-supplied facts.

const LEGACY_TO_LOGICAL := {"last_promise": "E01", "chapel_traces": "E05", "kael_token": "E06", "device_log": "E07", "kael_statement": "E08"}
const ALLOWED_INFERENCES := ["I01", "I02", "I03", "I04", "I05", "I06"]
const RESOLUTIONS := ["public", "archive", "testimony"]
const NPCS := ["bran", "sera", "kael"]

static func initial_state() -> Dictionary:
	var relationships := {}
	for npc in NPCS:
		relationships[npc] = {"trust": 0, "events": []}
	return {
		"schema_version": 1,
		"evidence_links": {},
		"inferences": {},
		"dialogue_events": [],
		"relationships": relationships,
		"decisions": {
			"kael_confrontation": "",
			"kael_confession": "unknown",
			"chapter1_resolution": "",
			"bran_farewell": ""
		},
		"identity_confirmed": false,
		"chapter_completed": false,
		"chapter2_letter_received": false
	}

static func ensure(p: Dictionary) -> void:
	if not p.get("story", null) is Dictionary:
		p["story"] = {}
	if not p["story"].get("chapter1", null) is Dictionary:
		p["story"]["chapter1"] = initial_state()
	var state: Dictionary = p["story"]["chapter1"]
	var defaults := initial_state()
	for key in defaults:
		if not state.has(key) or typeof(state[key]) != typeof(defaults[key]):
			state[key] = defaults[key].duplicate(true) if defaults[key] is Dictionary or defaults[key] is Array else defaults[key]
	for npc in NPCS:
		if not state["relationships"].get(npc, null) is Dictionary:
			state["relationships"][npc] = {"trust": 0, "events": []}
		var r: Dictionary = state["relationships"][npc]
		r["trust"] = clampi(int(r.get("trust", 0)), -2, 2)
		if not r.get("events", null) is Array:
			r["events"] = []
	for key in defaults["decisions"]:
		if not state["decisions"].has(key):
			state["decisions"][key] = defaults["decisions"][key]
	sync_legacy(p)

static func sync_legacy(p: Dictionary) -> void:
	if not p.get("story", null) is Dictionary:
		return
	var state: Dictionary = p["story"].get("chapter1", {})
	var records: Dictionary = p["story"].get("evidence", {})
	if state.is_empty() or not records is Dictionary:
		return
	for original_id in LEGACY_TO_LOGICAL:
		if not records.has(original_id):
			continue
		var logical_id: String = LEGACY_TO_LOGICAL[original_id]
		# Refer to original evidence, including its world time and order.
		# Do not copy text or pretend later-story evidence was obtained.
		var old_record: Dictionary = records[original_id]
		state["evidence_links"][logical_id] = {
			"original_id": original_id,
			"order": int(old_record.get("order", 0)),
			"discovered_at": float(old_record.get("discovered_at", 0.0))
		}

static func has_evidence(state: Dictionary, logical_id: String) -> bool:
	return state.get("evidence_links", {}).has(logical_id)

static func inference_supported(state: Dictionary, inference_id: String) -> bool:
	# Future story evidence IDs must be registered by server-side interaction rules
	# before any corresponding inference can unlock. Existing 2 clues do NOT prove guilt.
	if not inference_id in ALLOWED_INFERENCES:
		return false
	var requirements := {
		"I01": ["E01", "E04"],
		"I02": ["E03", "E05"],
		"I03": ["E05", "E07"],
		"I04": ["E06", "E08"],
		"I05": ["E07", "E09", "E10"],
		"I06": ["E06", "E07", "E08", "E13"]
	}
	for id in requirements[inference_id]:
		if not has_evidence(state, id):
			return false
	if inference_id == "I05" and not state.get("identity_confirmed", false):
		return false
	return true

static func verify_inference(state: Dictionary, inference_id: String) -> bool:
	if not inference_supported(state, inference_id):
		return false
	state["inferences"][inference_id] = "verified"
	return true

static func can_resolve(state: Dictionary) -> bool:
	if not state.get("identity_confirmed", false):
		return false
	for id in ["I03", "I05", "I06"]:
		if state.get("inferences", {}).get(id, "") != "verified":
			return false
	return true

static func resolve(state: Dictionary, resolution: String) -> bool:
	if not resolution in RESOLUTIONS or not can_resolve(state):
		return false
	if state["decisions"].get("chapter1_resolution", "") != "":
		return false
	state["decisions"]["chapter1_resolution"] = resolution
	return true

static func relationship_event(state: Dictionary, npc: String, event_id: String, delta: int) -> bool:
	if not npc in NPCS or event_id.is_empty():
		return false
	var relationship: Dictionary = state["relationships"][npc]
	if event_id in relationship["events"]:
		return false
	relationship["events"].append(event_id)
	relationship["trust"] = clampi(int(relationship["trust"]) + delta, -2, 2)
	return true

static func dialogue_once(state: Dictionary, event_id: String) -> bool:
	if event_id.is_empty() or event_id in state["dialogue_events"]:
		return false
	state["dialogue_events"].append(event_id)
	return true

static func finish_epilogue(state: Dictionary, farewell: String) -> bool:
	if state["decisions"].get("chapter1_resolution", "") == "" or state["chapter_completed"]:
		return false
	if not farewell in ["comfort", "pragmatic", "silence"]:
		return false
	state["decisions"]["bran_farewell"] = farewell
	state["chapter2_letter_received"] = true
	state["chapter_completed"] = true
	return true
