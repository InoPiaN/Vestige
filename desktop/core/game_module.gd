extends RefCounted
## Pure state reducer contract. Hooks own only module-local resources.
func module_id() -> String: return ""
func dependencies() -> PackedStringArray: return []
func state_version() -> int: return 1
func initial_state() -> Dictionary: return {}
func valid_state(_state: Dictionary) -> bool: return true
func reduce(_state: Dictionary, _event: Dictionary) -> Dictionary: return {"accepted":false}
func on_enable() -> bool: return true
func on_disable() -> void: pass
