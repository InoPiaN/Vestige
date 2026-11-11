extends SceneTree
const R=preload("res://world.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var w:=preload("res://investigation_demo.gd").legacy()
	var p: Dictionary=w.people.local
	var ids: Array=[]
	for id in p.gear_instances:
		if p.gear_instances[id]=="iron_sword": ids.append(id)
	check(ids.size()==3,"Successor recovers three individually crafted swords")
	var id: String=ids[0]
	var record: Dictionary=p.gear_records[id]
	check(record.maker.name=="은결" and record.maker.life!=p.life and record.maker.stage=="숙련" and record.maker.day==23,"Original maker identity date and pre-craft mastery survive death")
	check(record.events.size()==2 and record.events[1].actor==p.life and record.events[1].kind=="recovered","Recovery records successor identity")
	R.act(w,"local","take_remains",record.maker.life+"|"+id)
	check(record.events.size()==2,"Repeated recovery cannot duplicate history")
	for sword in ids:
		R.act(w,"local","equip_weapon",sword)
		check(p.equipped_ids.weapon==sword and R.weapon_damage(p)==p.gear_quality[sword].attack,"Exact equipment selection applies selected sword stats")
	R.act(w,"local","equip_weapon",ids[2])
	check(p.equipped_ids.weapon==ids[2],"Repeated selection keeps sword equipped")
	R.act(w,"local","equip_weapon","forged-id")
	check(p.equipped_ids.weapon==ids[2],"Unowned ID cannot replace worn sword")
	R.act(w,"local","equip_weapon","none")
	check(not p.equipped_ids.has("weapon") and R.weapon_damage(p)==9,"Explicit bare hand selection removes weapon")
	p.room="home"
	p.x=15
	p.y=12
	p.gear_condition[id]=20
	p.belongings.repair_kit=1
	R.act(w,"local","repair_gear",id)
	check(record.events.size()==3 and record.events[2].kind=="repaired" and p.gear_condition[id]>20,"Successful repair appends history")
	R.act(w,"local","repair_gear",id)
	check(record.events.size()==3,"Failed repair does not invent history")
	p.room="village"
	p.x=7
	p.y=14
	R.act(w,"local","interact")
	R.act(w,"local","store_item",id)
	check(w.estate.storage.gear_records[id].events.size()==3 and not p.gear_records.has(id),"House storage carries exact history without move event")
	R.act(w,"local","equip_weapon",id)
	check(p.equipment.weapon=="none","Stored sword cannot be remotely equipped")
	R.act(w,"local","take_item",id)
	check(p.gear_records[id].maker.life==record.maker.life and record.events.size()==3,"Withdrawal retains provenance")
	R.born(w,"other","은결")
	var view:=w.duplicate(true)
	R.Investigation.redact(view,"local")
	check(not view.people.other.has("gear_records") and view.people.local.gear_records.has(id),"Snapshot protects others private inventory records")
	var path:="/tmp/vestige-records-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Version thirteen world saves")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and loaded.people.local.gear_records[id].events.size()==3 and loaded.people.local.gear_records[id].maker.life==record.maker.life,"Save reload preserves provenance and history")
	var bad:=w.duplicate(true)
	bad.people.local.gear_records[id].maker.day=99999
	check(not R.Store.valid(bad),"Future maker dates rejected")
	bad=w.duplicate(true)
	bad.people.local.gear_records[id].events[0].kind="invented"
	check(not R.Store.valid(bad),"Malformed history event rejected")
	var old:=w.duplicate(true)
	old.version=12
	var holders: Array=old.people.values()
	holders.append(old.estate.storage)
	for row in old.remains.values(): holders.append(row.contents)
	for holder in holders: holder.erase("gear_records")
	var file:=FileAccess.open(path+".legacy",FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var migrated:=R.load_world(path+".legacy",false)
	check(not migrated.is_empty() and migrated.version==13 and migrated.people.local.gear_records[id].maker.is_empty(),"Legacy save receives unknown provenance without invented makers")
	var offline:=R.fresh()
	R.born(offline,"worker","대장장이")
	var worker: Dictionary=offline.people.worker
	worker.offline=true
	worker.policy="work"
	worker.ore=6
	R.advance(offline,R.DAY*3)
	var days: Array=[]
	for item in worker.gear_records:
		if not worker.gear_records[item].maker.is_empty(): days.append(worker.gear_records[item].maker.day)
	check(days==[1,2,3],"Catch-up records each workday instead of final day for every sword")
	for entry in [path,path+".legacy"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(entry+ext)
	quit(1 if failures else 0)
