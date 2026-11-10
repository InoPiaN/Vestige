extends SceneTree
const R=preload("res://world.gd")
const Items=preload("res://items.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func at(p: Dictionary,x: float,y: float) -> void:
	p.x=x
	p.y=y
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var w:=preload("res://investigation_demo.gd").home()
	w.craft_rng=19 # Keep baseline recipe effects deterministic; quality has separate coverage.
	var p: Dictionary=w.people.local
	p.belongings.cloth=10
	p.belongings.bent_nail=4
	p.belongings.broken_cup=1
	p.herb=5
	R.act(w,"local","craft_home","bandage")
	check(Items.quantity(p,"bandage")==0 and p.herb==5,"Distant crafting does not consume resources")
	at(p,15,12)
	R.act(w,"local","craft_home","bandage")
	check(Items.quantity(p,"bandage")==1 and p.herb==4 and p.belongings.cloth==9,"Bandage consumes exact recipe")
	p.hp=100
	R.act(w,"local","use_crafted","bandage")
	check(Items.quantity(p,"bandage")==1,"Full health preserves bandage")
	p.hp=30
	R.act(w,"local","use_crafted","bandage")
	check(p.hp==75 and Items.quantity(p,"bandage")==0,"Bandage restores 45 health once")
	R.act(w,"local","craft_home","mug")
	check(Items.quantity(p,"mug")==1 and Items.quantity(p,"broken_cup")==0,"Broken cup repaired into reusable tool")
	R.act(w,"local","craft_home","herbal_tea")
	check(Items.quantity(p,"herbal_tea")==0 and p.herb==4,"Unlit hearth prevents brewing without consuming herb")
	w.estate.interior.fire=true
	R.act(w,"local","craft_home","herbal_tea")
	check(Items.quantity(p,"herbal_tea")==1 and Items.quantity(p,"mug")==1 and p.herb==3,"Brewing retains cup and consumes one herb")
	p.hp=100
	p.stamina=40
	R.act(w,"local","use_crafted","herbal_tea")
	check(p.stamina==80 and Items.quantity(p,"herbal_tea")==0,"Tea can restore energy at full health")
	p.belongings.bandage=10
	var cloth: int=p.belongings.cloth
	R.act(w,"local","craft_home","bandage")
	check(p.belongings.cloth==cloth and p.herb==3,"Output cap rejects craft atomically")
	p.offline=true
	R.act(w,"local","craft_home","repair_kit")
	check(Items.quantity(p,"repair_kit")==0,"Offline crafting rejected")
	p.offline=false
	R.act(w,"local","craft_home","repair_kit")
	R.act(w,"local","craft_home","repair_kit")
	R.act(w,"local","craft_home","repair_kit")
	check(Items.quantity(p,"repair_kit")==2 and p.belongings.bent_nail==0,"Repeated crafts stop exactly when materials run out")
	p.sword=2
	R.outfit(p)
	var swords: Array=[]
	for id in p.gear_instances:
		if p.gear_instances[id]=="iron_sword": swords.append(id)
	R.act(w,"local","equip_instance",swords[0])
	p.room="village"
	at(p,25,10)
	w.wolf.hp=1000
	for i in range(20):
		p.attack=0
		p.stamina=100
		R.act(w,"local","attack")
	check(p.gear_condition[swords[0]]==0 and p.gear_condition[swords[1]]==100,"Only the striking sword wears on successful hits")
	check(R.weapon_damage(p)==9 and p.sword==2,"Worn sword loses effectiveness without disappearing")
	R.act(w,"local","repair_gear",swords[0])
	check(p.gear_condition[swords[0]]==0 and Items.quantity(p,"repair_kit")==2,"Remote repair rejected")
	p.room="home"
	at(p,15,12)
	R.act(w,"local","repair_gear",swords[0])
	check(p.gear_condition[swords[0]]==40 and R.weapon_damage(p)==22 and Items.quantity(p,"repair_kit")==1,"Exact worn sword repaired with one kit")
	R.act(w,"local","repair_gear",swords[1])
	R.act(w,"local","repair_gear","fake")
	check(Items.quantity(p,"repair_kit")==1,"Full condition and unowned repair targets consume nothing")
	at(p,22,13)
	R.act(w,"local","store_item",swords[0])
	check(w.estate.storage.gear_condition[swords[0]]==40 and not p.gear_condition.has(swords[0]),"Storage moves durability with exact item")
	R.act(w,"local","take_item",swords[0])
	R.die(w,"local","노환")
	var life: String=p.life
	check(w.remains[life].contents.gear_condition[swords[0]]==40 and p.gear_condition.is_empty(),"Death preserves durability in remains only")
	R.born(w,"local","후계자")
	p=w.people.local
	p.room="home"
	at(p,22,13)
	R.act(w,"local","take_remains",life+"|"+swords[0])
	check(p.gear_condition[swords[0]]==40,"Successor inherits wear rather than a restored copy")
	var game:=preload("res://main.gd").new()
	root.add_child(game)
	game.mode="single"
	game.world=w
	game.me="local"
	game.save_path=OS.get_temp_dir()+"/vestige-craft-"+str(OS.get_process_id())+".json"
	at(p,15,12)
	p.belongings.repair_kit=1
	game.interact()
	check(game.bench.visible and not game.bench.repair_button.disabled,"E opens usable repair workbench")
	game.bench.repair_button.pressed.emit()
	check(p.gear_condition[swords[0]]==80 and Items.quantity(p,"repair_kit")==0,"Workbench UI repairs selected sword")
	var now: float=w.time
	game._physics_process(1)
	check(w.time==now,"Single player workbench pauses world")
	check(R.save_world(w,game.save_path),"Crafted items and durability save")
	var loaded:=R.load_world(game.save_path,false)
	check(not loaded.is_empty() and loaded.people.local.gear_condition[swords[0]]==80,"Durability persists on reload")
	var invalid:=w.duplicate(true)
	invalid.people.local.gear_condition[swords[0]]=101
	check(not R.Store.valid(invalid),"Out-of-range durability rejected")
	var old:=w.duplicate(true)
	old.version=6
	var containers: Array=old.people.values()
	containers.append(old.estate.storage)
	for row in old.remains.values(): containers.append(row.contents)
	for holder in containers: holder.erase("gear_condition")
	var legacy_path: String=game.save_path+".legacy"
	var file:=FileAccess.open(legacy_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var migrated:=R.load_world(legacy_path,false)
	check(not migrated.is_empty() and migrated.version==8 and migrated.people.local.gear_condition[swords[0]]==100,"Legacy gear in all containers starts with full durability")
	for ext in ["",".bak"]: DirAccess.remove_absolute(legacy_path+ext)
	game.queue_free()
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	quit(1 if failures else 0)
