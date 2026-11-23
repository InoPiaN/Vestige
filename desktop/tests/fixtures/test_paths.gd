extends RefCounted
## Test-only paths. Never use a production user:// save directory.
static var _directory := ""

static func path(filename: String) -> String:
	if _directory.is_empty():
		var parent := OS.get_environment("VESTIGE_TEST_ROOT")
		if parent.is_empty(): parent = OS.get_temp_dir()
		_directory = parent.path_join("vestige-fixture-%s-%s" % [OS.get_process_id(), Time.get_ticks_usec()])
		var error := DirAccess.make_dir_recursive_absolute(_directory)
		assert(error == OK, "Cannot create isolated test directory")
	assert(not filename.is_absolute_path() and not ".." in filename, "Fixture name must be local")
	return _directory.path_join(filename)
