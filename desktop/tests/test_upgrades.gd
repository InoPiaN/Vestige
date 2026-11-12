extends SceneTree
const R=preload("res://world.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w:=preload("res://investigation_demo.gd").upgrade()
	var p: Dictionary=w.people.local
	var id:=""
	for key in p.gear_instances:
		if p.gear_instances[key]=="iron_sword": id=key
	var base: int=p.gear_quality[id].attack
	var maker: String=p.gear_records[id].maker.life
	var seed: int=w.craft_rng
	var xp: int=p.craft_xp.smithing
	R.act(w,"local","equip_weapon",id)
	p.gear_condition[id]=60
	R.act(w,"local","upgrade_sword",id+"|0")
	check(R.weapon_damage(p)==base+2 and p.ore==18 and p.gold==36,"Upgrade applies exact attack and resource costs")
	check(p.gear_quality[id].attack==base and p.gear_condition[id]==60 and w.craft_rng==seed and p.craft_xp.smithing==xp,"Upgrade retains base quality durability RNG and crafting mastery")
	check(p.gear_records[id].maker.life==maker and p.gear_records[id].events.back().kind=="upgraded" and p.gear_records[id].events.back().actor==p.life,"Original maker preserved and upgrader recorded")
	R.act(w,"local","upgrade_sword",id+"|0")
	check(p.ore==18 and R.Upgrade.level(p,id)==1,"Duplicate stale request does not double spend")
	p.x=10
	R.act(w,"local","upgrade_sword",id+"|1")
	check(p.ore==18,"Remote forge action rejected")
	p.x=5
	p.room="home"
	R.act(w,"local","upgrade_sword",id+"|1")
	check(p.ore==18,"Matching coordinates inside house cannot upgrade")
	p.room="village"
	p.offline=true
	R.act(w,"local","upgrade_sword",id+"|1")
	check(p.ore==18,"Offline upgrade rejected")
	p.offline=false
	p.gold=0
	R.act(w,"local","upgrade_sword",id+"|1")
	check(p.ore==18 and R.Upgrade.level(p,id)==1,"Missing gold consumes nothing")
	p.gold=36
	p.ore=0
	R.act(w,"local","upgrade_sword",id+"|1")
	check(p.gold==36,"Missing ore consumes nothing")
	p.ore=18
	R.act(w,"local","upgrade_sword","fake|0")
	check(p.ore==18,"Foreign gear ID rejected")
	R.act(w,"local","upgrade_sword",id+"|1")
	R.act(w,"local","upgrade_sword",id+"|2")
	check(R.weapon_damage(p)==base+6 and p.ore==8 and p.gold==16,"Three levels use increasing costs and total six attack")
	var events: int=p.gear_records[id].events.size()
	R.act(w,"local","upgrade_sword",id+"|3")
	check(p.ore==8 and p.gear_records[id].events.size()==events,"Maximum level blocks costs and history")
	check(preload("res://items.gd").definition(p,id).name.contains("+3"),"Inventory exposes upgrade level")
	p.gear_condition[id]=0
	check(R.weapon_damage(p)==9,"Broken upgraded sword still deals nine")
	p.x=7
	p.y=14
	R.act(w,"local","interact")
	R.act(w,"local","store_item",id)
	check(w.estate.storage.gear_quality[id].upgrade==3,"Storage preserves level")
	R.act(w,"local","take_item",id)
	R.die(w,"local","노환")
	var life: String=p.life
	R.born(w,"local","후계자")
	p=w.people.local
	p.x=7
	p.y=14
	R.act(w,"local","take_remains",life+"|"+id)
	check(R.Upgrade.level(p,id)==3 and p.gear_records[id].maker.life==maker,"Death and successor recovery preserve upgrade and original maker")
	var path:="/tmp/vestige-upgrade-test-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Upgrade world saves")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and R.Upgrade.level(loaded.people.local,id)==3,"Reload retains upgrade")
	var bad:=w.duplicate(true)
	bad.people.local.gear_quality[id].upgrade=4
	check(not R.Store.valid(bad),"Out of range upgrade rejected")
	bad.people.local.gear_quality[id].upgrade=1.5
	check(not R.Store.valid(bad),"Fractional upgrade rejected")
	var old:=w.duplicate(true)
	old.version=13
	var holders: Array=old.people.values()
	holders.append(old.estate.storage)
	for row in old.remains.values(): holders.append(row.contents)
	for holder in holders:
		for gear_id in holder.gear_quality: holder.gear_quality[gear_id].erase("upgrade")
	var file:=FileAccess.open(path+".old",FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	loaded=R.load_world(path+".old",false)
	check(not loaded.is_empty() and loaded.version==15 and R.Upgrade.level(loaded.people.local,id)==0 and loaded.people.local.gear_quality[id].attack==base,"Version thirteen migrates to unenhanced without rerolling base")
	for entry in [path,path+".old"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(entry+ext)
	quit(1 if failures else 0)
