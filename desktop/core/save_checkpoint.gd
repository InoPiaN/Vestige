extends RefCounted
## Runtime-only status, keyed by save path. Writer owns validation and file I/O.
var _pending: Dictionary = {}
func pending(path: String) -> bool: return _pending.get(path, false)
func attempt(world: Dictionary, path: String, role: String, writer: Callable) -> bool:
	if role not in ["single", "server"] or world.is_empty() or path.is_empty(): return false
	var ok: bool = writer.call(world, path)
	_pending[path] = not ok
	return ok
