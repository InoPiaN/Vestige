extends RefCounted
## Optional Chapter I data contract for G's version 23 world saves.
## This validator is read-only: it NEVER repairs/normalizes a damaged save.
## Story-free v1..v23 gameplay saves remain valid and migrate through G's existing path.
const Chapter = preload("res://story/chapter1_rules.gd")

static func whole_nonnegative(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0.0 and floor(float(value))==float(value)

static func finite_nonnegative(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)>=0.0

static func string_list(value: Variant) -> bool:
	if not value is Array: return false
	for item in value:
		if not item is String: return false
	return true

static func valid_record(id: String, record: Variant) -> bool:
	if not record is Dictionary: return false
	if record.get("id") != id or not Chapter.LEGACY_TO_LOGICAL.has(id): return false
	for key in ["title","source","fact","inference"]:
		if not record.get(key) is String: return false
	if not whole_nonnegative(record.get("order")) or int(record.order)<1: return false
	if not whole_nonnegative(record.get("day")) or int(record.day)<1: return false
	return finite_nonnegative(record.get("discovered_at"))

static func valid_chapter(chapter: Variant, evidence: Dictionary) -> bool:
	if not chapter is Dictionary: return false
	if not whole_nonnegative(chapter.get("schema_version")) or int(chapter.schema_version)!=1: return false
	for key in ["evidence_links","inferences","relationships","decisions"]:
		if not chapter.get(key) is Dictionary: return false
	if not string_list(chapter.get("dialogue_events")): return false
	for key in ["identity_confirmed","chapter_completed","chapter2_letter_received"]:
		if not chapter.get(key) is bool: return false
	for logical_id in chapter.evidence_links:
		if not Chapter.LEGACY_TO_LOGICAL.values().has(logical_id): return false
		var link: Variant=chapter.evidence_links[logical_id]
		if not link is Dictionary: return false
		var legacy: Variant=link.get("original_id")
		if not legacy is String or not evidence.has(legacy) or Chapter.LEGACY_TO_LOGICAL[legacy]!=logical_id: return false
		if not whole_nonnegative(link.get("order")) or int(link.order)!=int(evidence[legacy].order): return false
		if not finite_nonnegative(link.get("discovered_at")) or not is_equal_approx(float(link.discovered_at),float(evidence[legacy].discovered_at)): return false
	for legacy_id in evidence:
		if not chapter.evidence_links.has(Chapter.LEGACY_TO_LOGICAL[legacy_id]): return false
	for inference_id in chapter.inferences:
		if not Chapter.ALLOWED_INFERENCES.has(inference_id) or chapter.inferences[inference_id]!="verified": return false
		if not Chapter.inference_supported(chapter,inference_id): return false
	for npc in Chapter.NPCS:
		var relation: Variant=chapter.relationships.get(npc)
		if not relation is Dictionary: return false
		var trust: Variant=relation.get("trust")
		if not (trust is int or trust is float) or not is_finite(float(trust)): return false
		if floor(float(trust))!=float(trust) or absf(float(trust))>2: return false
		if not string_list(relation.get("events")): return false
	for event_id in chapter.dialogue_events:
		if event_id.is_empty(): return false
	var decisions: Dictionary=chapter.decisions
	for key in ["kael_confrontation","kael_confession","chapter1_resolution","bran_farewell"]:
		if not decisions.get(key) is String: return false
	if not decisions.chapter1_resolution in ["","public","archive","testimony"]: return false
	if chapter.chapter_completed and (decisions.chapter1_resolution=="" or not chapter.chapter2_letter_received): return false
	return true

static func valid_person(person: Dictionary) -> bool:
	if not person.has("story"): return true
	var story: Variant=person.story
	if not story is Dictionary: return false
	var evidence: Variant=story.get("evidence",{})
	if not evidence is Dictionary: return false
	var used_order: Dictionary={}
	for id in evidence:
		if not id is String or not valid_record(id,evidence[id]): return false
		var order: int=int(evidence[id].order)
		if used_order.has(order): return false
		used_order[order]=true
	if story.has("visits"):
		if not story.visits is Dictionary: return false
		for id in story.visits:
			if not Chapter.NPCS.has(id) or not story.visits[id] is bool: return false
	for key in ["iren_missing_rumor","kael_encountered"]:
		if story.has(key) and not story[key] is bool: return false
	if story.has("chapter1") and not valid_chapter(story.chapter1,evidence): return false
	if not evidence.is_empty() and not story.has("chapter1"): return false
	return true

static func valid_world(world: Dictionary) -> bool:
	if not world.get("people") is Dictionary: return false
	for person in world.people.values():
		if not person is Dictionary or not valid_person(person): return false
	return true
