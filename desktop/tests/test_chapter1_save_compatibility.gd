extends SceneTree
## P1-D fixture-only persistence regression. No real user://world is ever opened.
const World=preload("res://world.gd")
const Store=preload("res://world_store.gd")
const StoryContract=preload("res://story/chapter1_save_contract.gd")
const Bridge=preload("res://story/chapter1_bridge.gd")
const Clues=preload("res://story/chapter1_investigation.gd")
var failures:=0

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: ",label)
	else:
		failures+=1
		push_error("FAIL: "+label)

func file_bytes(path: String) -> String:
	return FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""

func _initialize() -> void:
	var path: String="/tmp/vestige-story-save-%d.json" % OS.get_process_id()
	var w: Dictionary=World.fresh()
	World.born(w,"a","첫 조사자")
	World.born(w,"b","둘째 조사자")
	check(Store.valid(w), "story-free v23 gameplay world remains valid")
	check(World.save_world(w,path), "old-style v23 fixture saves without story")
	var before: String=file_bytes(path)
	var old_loaded: Dictionary=World.load_world(path,false)
	check(not old_loaded.is_empty() and old_loaded.version==23, "existing story-free v23 fixture still loads")
	check(not old_loaded.people["a"].has("story"), "load does not invent Chapter I evidence")
	check(file_bytes(path)!="", "load checkpoint did not delete save")
	var previous_version: Dictionary=World.fresh()
	previous_version.version=22
	World.born(previous_version,"old","이전 저장 주민")
	var old_path: String="/tmp/vestige-story-v22-%d.json" % OS.get_process_id()
	check(World.save_world(previous_version,old_path), "v22 fixture saves without Chapter I story")
	var migrated: Dictionary=World.load_world(old_path,false)
	check(not migrated.is_empty() and migrated.version==23, "v22 gameplay fixture continues loading as v23")
	check(not migrated.people["old"].has("story"), "v22 migration does not invent Chapter I events")
	DirAccess.remove_absolute(old_path)
	DirAccess.remove_absolute(old_path+".bak")
	DirAccess.remove_absolute(old_path+".tmp")
	w=old_loaded
	var p: Dictionary=w.people["a"]
	p.offline=false
	p.room="village"
	p.x=Clues.EVIDENCE.last_promise.x
	p.y=Clues.EVIDENCE.last_promise.y
	check(Bridge.inspect(w,"a","last_promise").contains("증거 기록"), "record E01 in isolated life")
	check(Store.valid(w), "valid E01 story accepted by G store")
	check(World.save_world(w,path), "valid Chapter I story checkpoint")
	var good: String=file_bytes(path)
	var backup_path: String=path+".bak"
	check(DirAccess.copy_absolute(path,backup_path)==OK, "create known good .bak fixture")
	var malformed: Dictionary=w.duplicate(true)
	malformed.people["a"].story.evidence.last_promise.order="broken"
	check(not StoryContract.valid_person(malformed.people["a"]), "invalid evidence order rejected")
	check(not Store.valid(malformed), "G store rejects malformed story before save")
	check(not World.save_world(malformed,path), "malformed story cannot overwrite checkpoint")
	check(file_bytes(path)==good, "malformed save attempt leaves primary bytes unchanged")
	# Simulate a syntactically valid JSON primary with malformed Chapter I; backup is known good.
	var writer:=FileAccess.open(path,FileAccess.WRITE)
	check(writer!=null, "open isolated corrupt primary fixture")
	if writer!=null:
		writer.store_string(JSON.stringify(malformed))
		writer.close()
	var recovered: Dictionary=World.load_world(path,false)
	check(not recovered.is_empty() and recovered.people["a"].story.evidence.last_promise.order==1, "falls back to valid backup story")
	check(recovered.people["a"].story.chapter1.evidence_links.has("E01"), "backup preserves logical provenance")
	check(not recovered.people["b"].has("story"), "other player life remains untouched")
	var bad_link: Dictionary=recovered.duplicate(true)
	bad_link.people["a"].story.chapter1.evidence_links.E01.original_id="device_log"
	check(not Store.valid(bad_link), "fabricated E01 logical link rejected")
	var fake_inference: Dictionary=recovered.duplicate(true)
	fake_inference.people["a"].story.chapter1.inferences.I06="verified"
	check(not Store.valid(fake_inference), "unsupported operator inference rejected")
	var invalid_schema: Dictionary=recovered.duplicate(true)
	invalid_schema.people["a"].story.chapter1.schema_version=999
	check(not Store.valid(invalid_schema), "unknown Chapter I schema rejected")
	var invalid_type: Dictionary=recovered.duplicate(true)
	invalid_type.people["a"].story="not-a-dictionary"
	check(not Store.valid(invalid_type), "broken story type rejected")
	# Both copies invalid: load must fail closed and keep the exact primary/backup bytes.
	var bad_path: String="/tmp/vestige-story-both-bad-%d.json" % OS.get_process_id()
	var bad_bytes: String=JSON.stringify(malformed)
	var bad_primary:=FileAccess.open(bad_path,FileAccess.WRITE)
	check(bad_primary!=null, "write isolated malformed primary")
	if bad_primary!=null:
		bad_primary.store_string(bad_bytes)
		bad_primary.close()
	var bad_backup:=FileAccess.open(bad_path+".bak",FileAccess.WRITE)
	check(bad_backup!=null, "write isolated malformed backup")
	if bad_backup!=null:
		bad_backup.store_string(bad_bytes)
		bad_backup.close()
	check(World.load_world(bad_path,false).is_empty(), "invalid primary and backup never create fresh world")
	check(file_bytes(bad_path)==bad_bytes and file_bytes(bad_path+".bak")==bad_bytes, "both damaged files are preserved for recovery")
	DirAccess.remove_absolute(bad_path)
	DirAccess.remove_absolute(bad_path+".bak")
	DirAccess.remove_absolute(bad_path+".tmp")
	var future: Dictionary=recovered.duplicate(true)
	future.version=24
	check(not Store.valid(future), "future v24 still refused")
	check(not StoryContract.valid_world(bad_link), "standalone validator rejects forged evidence")
	check(World.save_world(recovered,path), "valid recovered story can be saved")
	var again: Dictionary=World.load_world(path,false)
	check(again.people["a"].story.evidence.last_promise.order==1, "record persists on repeated load")
	check(again.people["a"].story.chapter1.evidence_links.E01.original_id=="last_promise", "evidence source unchanged")
	check(again.people["a"].story.chapter1.inferences.is_empty(), "recovery creates no fictional deductions")
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".bak")
	DirAccess.remove_absolute(path+".tmp")
	DirAccess.remove_absolute(path+".bak.tmp")
	print("CHAPTER1_SAVE_COMPATIBILITY: ", "PASS" if failures==0 else "FAIL", " failures=",failures)
	quit(0 if failures==0 else 1)
