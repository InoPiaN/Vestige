extends RefCounted
const STAGES=["입문","견습","숙련","장인"]
static func empty() -> Dictionary:
	return {"maker":{},"events":[]}
static func create(p: Dictionary,id: String,day: int,stage: int,field: String="대장 기술") -> void:
	p.gear_records[id]={"maker":{"life":p.life,"name":p.name,"day":day,"place":"잿불 마을 대장간","stage":STAGES[stage],"field":field},"events":[]}
	append(p,id,"crafted",day,"잿불 마을 대장간에서 제작")
static func append(p: Dictionary,id: String,kind: String,day: int,detail: String) -> void:
	if p.gear_instances.get(id) not in ["iron_sword","leather","iron_armor"]: return
	p.gear_records[id].events.append({"kind":kind,"day":day,"actor":p.life,"name":p.name,"detail":detail})
static func describe(p: Dictionary,id: String) -> String:
	var record: Dictionary=p.get("gear_records",{}).get(id,empty())
	var maker: Dictionary=record.maker
	var text:="제작자 기록 없음 · 과거를 확인할 수 없습니다."
	if not maker.is_empty(): text="제작자 %s · 제%d일\n%s · 당시 %s %s" % [maker.name,maker.day,maker.place,maker.get("field","대장 기술"),maker.stage]
	if not record.events.is_empty():
		text+="\n\n장비 이력"
		for event in record.events: text+="\n제%d일 · %s · %s" % [event.day,event.name,event.detail]
	return text
static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value>=1 and value==floor(value)
static func valid(record: Variant,day: int) -> bool:
	if not record is Dictionary or not record.get("maker") is Dictionary or not record.get("events") is Array: return false
	var maker: Dictionary=record.maker
	if not maker.is_empty():
		if not maker.get("life") is String or maker.life.is_empty() or not maker.get("name") is String or not maker.get("place") is String or maker.get("stage") not in STAGES: return false
		if maker.has("field") and maker.field not in ["대장 기술","생활 공예","약초 조제"]: return false
		if not number(maker.get("day")) or maker.day>day: return false
	for event in record.events:
		if not event is Dictionary or event.get("kind") not in ["crafted","repaired","recovered","upgraded"]: return false
		if not number(event.get("day")) or event.day>day: return false
		if not event.get("actor") is String or event.actor.is_empty() or not event.get("name") is String or not event.get("detail") is String: return false
	return true
