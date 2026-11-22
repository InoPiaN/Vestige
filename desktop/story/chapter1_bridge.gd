extends RefCounted
## Deliberately isolated Chapter I adapter for the 0.5.19 gameplay world.
## Not wired to world.act/main.command yet. Caller must own the authorization boundary.
const Investigation = preload("res://story/chapter1_investigation.gd")
const Dialogue = preload("res://story/chapter1_dialogue.gd")
const Board = preload("res://story/evidence_board_rules.gd")
const Chapter = preload("res://story/chapter1_rules.gd")

static func prepare_person(p: Dictionary) -> void:
	Investigation.ensure(p)
	Dialogue.ensure(p)

static func allowed(w: Dictionary, player_id: String) -> bool:
	if not w.get("people", {}).has(player_id):
		return false
	var p: Dictionary = w.people[player_id]
	return p.get("alive", false) and not p.get("offline", true) and p.get("room", "village") == "village"

static func inspect(w: Dictionary, player_id: String, evidence_id: String) -> String:
	if not allowed(w, player_id):
		return "잿불 마을에서 살아 있는 인물만 제1장 현장을 조사할 수 있습니다."
	prepare_person(w.people[player_id])
	return Investigation.inspect(w, player_id, evidence_id)

static func nearby_npc(w: Dictionary, player_id: String) -> String:
	if not allowed(w, player_id):
		return ""
	return Dialogue.nearby(w.people[player_id])

## For local tests only. Network caller MUST enforce a server-owned active dialogue session.
## Do not expose this method as an arbitrary client command.
static func talk(w: Dictionary, player_id: String, npc_id: String, choice: String="", server_active_npc: String="") -> Dictionary:
	if not allowed(w, player_id):
		return {}
	prepare_person(w.people[player_id])
	return Dialogue.talk(w, player_id, npc_id, choice, server_active_npc)

static func reconstruct(w: Dictionary, player_id: String, first: String, second: String) -> Dictionary:
	if not allowed(w, player_id):
		return {"accepted":false, "text":"현재 지역에서 조사 기록을 검토할 수 없습니다."}
	prepare_person(w.people[player_id])
	return Board.evaluate(w.people[player_id], first, second)

static func notebook(w: Dictionary, player_id: String) -> String:
	if not w.get("people", {}).has(player_id):
		return ""
	prepare_person(w.people[player_id])
	return Investigation.notebook(w.people[player_id])
