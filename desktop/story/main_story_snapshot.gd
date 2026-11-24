extends RefCounted
## Remove private main-story state for non-owner participants in world snapshots.
## Caller should pass an already copied snapshot, not live authoritative world.
static func redact_other_players(snapshot: Dictionary, owner_id: String) -> void:
	if not snapshot.get("people") is Dictionary:
		return
	for player_id in snapshot["people"]:
		if str(player_id) == owner_id:
			continue
		var player: Variant = snapshot["people"][player_id]
		if player is Dictionary:
			player.erase("main_story")
