extends SceneTree
const R=preload("res://world.gd")
const Items=preload("res://items.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func place(p: Dictionary,x: float,y: float) -> void:
	p.x=x
	p.y=y
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var w:=R.fresh()
	R.born(w,"local","주인")
	var p: Dictionary=w.people.local
	p.ore=4
	place(p,5,8)
	R.act(w,"local","interact")
	R.act(w,"local","interact")
	var swords: Array=[]
	for id in p.gear_instances:
		if p.gear_instances[id]=="iron_sword": swords.append(id)
	check(swords.size()==2 and swords[0]!=swords[1],"Crafted swords have separate identities")
	R.act(w,"local","equip_instance",swords[1])
	check(p.equipped_ids.weapon==swords[1],"Select exact sword to wear")
	p.herb=3
	R.act(w,"local","store_item","herb")
	check(p.herb==3,"Remote storage rejected")
	place(p,7,14)
	R.act(w,"local","store_item","herb")
	check(p.herb==3,"Unowned plot storage rejected")
	R.act(w,"local","interact")
	R.act(w,"local","store_item",swords[0])
	check(p.equipped_ids.weapon==swords[1] and p.sword==1,"Storing spare keeps worn sword")
	R.act(w,"local","store_item",swords[1])
	check(p.equipment.weapon=="none" and p.sword==0,"Storing worn gear removes equipment")
	R.act(w,"local","store_item",swords[1])
	check(w.estate.storage.sword==2,"Repeated gear deposit cannot duplicate")
	R.act(w,"local","take_item",swords[0])
	check(p.gear_instances.has(swords[0]) and not w.estate.storage.gear_instances.has(swords[0]),"Withdrawal preserves gear identity")
	R.born(w,"other","방문자")
	place(w.people.other,7,14)
	R.act(w,"other","take_item",swords[1])
	check(w.estate.storage.gear_instances.has(swords[1]),"Living owner blocks visitors")
	var view:=w.duplicate(true)
	R.Investigation.redact(view,"other")
	check(not view.estate.has("storage") and not view.people.local.has("gear_instances"),"Private storage and individual gear hidden in snapshot")
	var game:=preload("res://main.gd").new()
	root.add_child(game)
	game.mode="single"
	game.world=w
	game.me="local"
	game.save_path=OS.get_temp_dir()+"/vestige-storage-"+str(OS.get_process_id())+".json"
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_B
	key.pressed=true
	game._unhandled_key_input(key)
	check(game.chest.visible and not game.chest.put_button.disabled,"B opens accessible house storage")
	for i in range(game.chest.carried.item_count):
		if game.chest.carried.get_item_metadata(i)=="herb": game.chest.carried.select(i)
	game.chest.put_button.pressed.emit()
	check(p.herb==2 and w.estate.storage.herb==1,"Storage UI transfers exactly one material")
	var before: float=w.time
	game._physics_process(1.0)
	check(w.time==before,"Single player storage pauses world")
	w.estate.storage.ore=39
	R.act(w,"local","store_item","herb")
	check(p.herb==2,"Full storage rejects without consuming item")
	w.estate.storage.ore=0
	p.herb=20
	R.act(w,"local","take_item","herb")
	check(p.herb==20 and w.estate.storage.herb==1,"Full inventory rejects withdrawal atomically")
	p.relic=1
	R.act(w,"local","store_item","relic")
	place(p,27,9)
	w.wolf.hp=0
	R.act(w,"local","interact")
	check(p.relic==0 and w.estate.storage.relic==1,"Stored relic cannot be collected again from ruin")
	place(p,7,14)
	p.offline=true
	R.act(w,"local","take_item",swords[1])
	check(w.estate.storage.gear_instances.has(swords[1]),"Offline resident cannot transfer")
	p.offline=false
	R.die(w,"local","노환")
	R.born(w,"local","후계자")
	p=w.people.local
	place(p,7,14)
	R.act(w,"local","take_item",swords[1])
	R.act(w,"other","take_item",swords[1])
	check(p.gear_instances.has(swords[1]) and not w.people.other.gear_instances.has(swords[1]),"Successor recovers same sword and competing withdrawal cannot duplicate")
	check(R.save_world(w,game.save_path),"Storage saves valid identity graph")
	var loaded:=R.load_world(game.save_path,false)
	check(not loaded.is_empty() and loaded.people.local.gear_instances.has(swords[1]) and loaded.estate.storage.herb==1,"Save reload preserves house contents and item identity")
	var bad:=w.duplicate(true)
	bad.estate.storage.gear_instances[swords[1]]="iron_sword"
	bad.estate.storage.sword+=1
	check(not R.Store.valid(bad),"Duplicate gear identity rejected in save")
	var legacy:=w.duplicate(true)
	legacy.version=3
	legacy.estate.erase("storage")
	for person in legacy.people.values():
		person.erase("gear_instances")
		person.erase("equipped_ids")
	var legacy_path:=game.save_path+".legacy"
	var f:=FileAccess.open(legacy_path,FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy))
	f.close()
	var migrated:=R.load_world(legacy_path,false)
	check(not migrated.is_empty() and migrated.version==4 and migrated.people.local.gear_instances.size()==4,"Legacy counters migrate to stable individual gear")
	game.queue_free()
	for path in [game.save_path,legacy_path]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(path+ext)
	quit(1 if failures else 0)
