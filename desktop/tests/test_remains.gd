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
	R.born(w,"local","옛 주인")
	var p: Dictionary=w.people.local
	place(p,7,14)
	p.herb=3
	p.sword=1
	R.act(w,"local","interact")
	R.act(w,"local","store_item","herb")
	var life: String=p.life
	var sword: String=""
	for id in p.gear_instances:
		if p.gear_instances[id]=="iron_sword": sword=id
	R.act(w,"local","equip_instance",sword)
	place(p,18,14)
	var gold: int=p.gold
	R.die(w,"local","늑대와의 전투")
	var box: Dictionary=w.remains[life].contents
	check(box.herb==2 and box.gold==gold and box.gear_instances.has(sword),"Death transfers materials, money and exact equipped sword")
	check(p.herb==0 and p.gold==0 and p.sword==0 and p.gear_instances.is_empty() and p.equipment.weapon=="none","Dead inventory is emptied without copies")
	check(w.estate.storage.herb==1 and w.remains[life].x==18,"House contents stay separate from actual death site")
	R.die(w,"local","노환")
	check(w.remains.size()==1 and box.sword==1,"Repeated death does not create another cache")
	R.born(w,"local","새 여행자")
	p=w.people.local
	check(w.remains.has(life) and p.life!=life,"New life preserves predecessor cache")
	var view:=w.duplicate(true)
	R.Investigation.redact(view,"local")
	check(view.remains.is_empty(),"Distant remains contents and coordinates are not sent")
	R.act(w,"local","take_remains",life+"|"+sword)
	check(box.gear_instances.has(sword),"Distant recovery rejected")
	place(p,18,14)
	p.offline=true
	R.act(w,"local","take_remains",life+"|"+sword)
	check(box.gear_instances.has(sword),"Offline recovery rejected")
	p.offline=false
	p.herb=20
	R.act(w,"local","take_remains",life+"|herb")
	check(box.herb==2 and p.herb==20,"Inventory cap rejects recovery without loss")
	R.born(w,"other","경쟁 조사자")
	place(w.people.other,18,14)
	R.act(w,"local","take_remains",life+"|"+sword)
	R.act(w,"other","take_remains",life+"|"+sword)
	check(p.gear_instances.has(sword) and not w.people.other.gear_instances.has(sword),"Competing recovery yields only one exact sword")
	check(not p.equipped_ids.values().has(sword),"Recovered gear is not silently equipped")
	var wallet: int=p.gold
	R.act(w,"local","take_remains",life+"|gold")
	check(p.gold==wallet+1 and box.gold==gold-1,"Coin recovery conserves total money")
	R.act(w,"local","take_remains","bad|gold")
	R.act(w,"local","take_remains",life+"|iron_sword")
	check(p.sword==1 and p.gold==wallet+1,"Forged cache and generic gear requests rejected")
	R.die(w,"other","노환")
	var game:=preload("res://main.gd").new()
	root.add_child(game)
	game.mode="single"
	game.world=w
	game.me="local"
	game.save_path=OS.get_temp_dir()+"/vestige-remains-"+str(OS.get_process_id())+".json"
	var event:=InputEventKey.new()
	event.physical_keycode=KEY_G
	event.pressed=true
	game._unhandled_key_input(event)
	check(game.chest.visible and game.chest.remains_mode and game.chest.chooser.item_count==2,"G shows multiple nearby death caches")
	game.chest.chooser.select(1)
	game.chest.chooser.item_selected.emit(1)
	check(game.chest.remains_id==w.people.other.life,"Cache selector refreshes while single world is paused")
	for i in range(game.chest.stored.item_count):
		if game.chest.stored.get_item_metadata(i)=="gold": game.chest.stored.select(i)
	game.chest.take_button.pressed.emit()
	check(p.gold==wallet+2 and game.chest.stored.get_selected_items().size()==1,"Recovery UI transfers coin and retains selection")
	check(R.save_world(w,game.save_path),"Remains save with unique identity graph")
	var loaded:=R.load_world(game.save_path,false)
	check(not loaded.is_empty() and loaded.remains[life].contents.herb==2 and loaded.people.local.gear_instances.has(sword),"Reload preserves unclaimed items and claimed gear")
	var bad:=w.duplicate(true)
	bad.remains[life].contents.gear_instances[sword]="iron_sword"
	bad.remains[life].contents.sword+=1
	check(not R.Store.valid(bad),"Duplicate identity across cache and living inventory rejected")
	bad=w.duplicate(true)
	bad.remains[life].contents.gold=-1
	check(not R.Store.valid(bad),"Invalid cached wallet rejected")
	bad=w.duplicate(true)
	bad.version=4
	bad.remains={"bad":1}
	check(not R.Store.valid(bad),"Malformed optional legacy cache rejected without crashing")
	# Offline natural death goes through the same cache path.
	var offline:=R.fresh()
	R.born(offline,"a","주민")
	offline.people.a.age=offline.people.a.limit-1
	offline.people.a.offline=true
	R.advance(offline,R.DAY*2)
	check(offline.remains.size()==1 and offline.remains.values()[0].day==1,"Offline old-age death leaves one cache on actual day")
	# Empty caches remain as an idempotency record, but vanish from discovery.
	w.remains[life].contents=R.Storage.empty()
	w.remains[life].contents.gold=0
	check(not R.Remains.visible(w,p).has(life),"Fully recovered cache is not offered again")
	var legacy:=w.duplicate(true)
	legacy.version=4
	legacy.erase("remains")
	var path: String=game.save_path+".legacy"
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var migrated:=R.load_world(path,false)
	check(not migrated.is_empty() and migrated.version==9 and migrated.remains.is_empty(),"Older save migrates without inventing historical loot")
	for entry in [game.save_path,path]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(entry+ext)
	game.queue_free()
	quit(1 if failures else 0)
