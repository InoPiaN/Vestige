extends SceneTree
const Rules=preload("res://world.gd")
const Store=preload("res://world_store.gd")
const START=1000000.0
var failures:=0
func check(condition: bool, message: String) -> void:
	if condition: print("PASS: ",message)
	else:
		failures+=1
		push_error(message)
func write(path: String, value: String) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(value)
	file.close()
func _initialize() -> void:
	var dir:=OS.get_temp_dir()+"/vestige-recovery-%s-%s" % [OS.get_process_id(),Time.get_ticks_usec()]
	DirAccess.make_dir_absolute(dir)
	var path:=dir+"/world.json"
	var w:=Rules.fresh()
	w.saved=START
	Rules.born(w,"a","선대")
	Rules.die(w,"a","늑대")
	Rules.born(w,"a","후임")
	w.people.a.policy="gather"
	check(Rules.save_world(w,path,START) and FileAccess.file_exists(path+".bak"),"first save seeds a readable backup")
	var end:=START+Rules.DAY*2
	w=Rules.load_world(path,true,end)
	check(w.people.a.herb==4 and w.people.a.journal.size()==2 and w.saved==end,"two absent days committed before play")
	w=Rules.load_world(path,true,end)
	check(w.people.a.herb==4 and w.people.a.journal.size()==2,"instant reconnect does not repeat a day")
	w=Rules.load_world(path,true,end-Rules.DAY)
	check(w.saved==end and w.people.a.herb==4,"clock rollback preserves processed timestamp")
	w=Rules.load_world(path,true,end+Rules.DAY)
	check(w.people.a.herb==6 and w.people.a.journal.size()==3,"only the next new day is credited")
	var backup:=FileAccess.get_file_as_string(path+".bak")
	write(path,"{incomplete")
	w=Rules.load_world(path,true,end+Rules.DAY)
	check(w.people.a.herb==6 and w.people.a.journal.size()==3 and w.graves.size()==1 and w.books.size()==1,"broken JSON restores history and catches up from backup")
	check(FileAccess.get_file_as_string(path+".bak")==backup and Store.valid(Store.read(path)),"recovery preserves known-good backup and repairs primary")
	var incomplete:=Store.read(path)
	incomplete.people.a.erase("journal")
	write(path,JSON.stringify(incomplete))
	w=Rules.load_world(path,true,end+Rules.DAY)
	check(w.people.a.journal.size()==3,"incomplete character record falls back to backup")
	DirAccess.remove_absolute(path)
	w=Rules.load_world(path,true,end+Rules.DAY)
	check(w.people.a.herb==6 and FileAccess.file_exists(path),"missing primary restored")
	w=Rules.load_world(path,false,end+Rules.DAY*20)
	check(w.people.a.herb==6 and w.people.a.journal.size()==3,"server downtime does not simulate residents")
	w.people.a.age=w.people.a.limit-1
	Rules.save_world(w,path,end+Rules.DAY*20)
	w=Rules.load_world(path,true,end+Rules.DAY*25)
	check(not w.people.a.alive and w.graves.back().day==w.people.a.journal.back().day and w.graves.size()==2,"old age records the actual last day during a long absence")
	w=Rules.load_world(path,true,end+Rules.DAY*25)
	check(w.books.size()==2 and w.graves.size()==2,"reload does not duplicate deaths or books")
	var original:=FileAccess.get_file_as_string(path)
	var old_backup:=FileAccess.get_file_as_string(path+".bak")
	DirAccess.make_dir_absolute(path+".tmp")
	check(Rules.load_world(path,true,end+Rules.DAY*26).is_empty(),"uncommitted catch-up is never returned to play")
	check(FileAccess.get_file_as_string(path)==original and FileAccess.get_file_as_string(path+".bak")==old_backup,"failed checkpoint preserves both files")
	DirAccess.remove_absolute(path+".tmp")
	var future:=Store.read(path)
	future.version=12
	var raw:=JSON.stringify(future)
	write(path,raw)
	check(Rules.load_world(path).is_empty() and FileAccess.get_file_as_string(path)==raw,"newer save version is preserved")
	write(path,"broken-primary")
	write(path+".bak","broken-backup")
	check(Rules.load_world(path).is_empty() and FileAccess.get_file_as_string(path)=="broken-primary" and FileAccess.get_file_as_string(path+".bak")=="broken-backup","unrecoverable files remain intact")
	for filename in DirAccess.get_files_at(dir): DirAccess.remove_absolute(dir+"/"+filename)
	DirAccess.remove_absolute(dir)
	quit(1 if failures else 0)
