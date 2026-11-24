extends "res://core/game_module.gd"
var identity := "test.observation"
var needs: PackedStringArray = []
var enables := 0
var disables := 0
func module_id() -> String: return identity
func dependencies() -> PackedStringArray: return needs
func initial_state() -> Dictionary: return {"observed":[]}
func valid_state(state: Dictionary) -> bool:
	if not state.get("observed") is Array: return false
	for target in state.observed:
		if not target is String or target.is_empty(): return false
	return true
func reduce(state: Dictionary, event: Dictionary) -> Dictionary:
	if event.type != "observation.record" or not event.payload.get("target") is String: return {"accepted":false}
	state.observed.append(event.payload.target)
	return {"accepted":true,"state":state}
func on_enable() -> bool:
	enables += 1
	return true
func on_disable() -> void: disables += 1
