extends SceneTree
const R=preload("res://world.gd")
const I=preload("res://items.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w:=preload("res://investigation_demo.gd").supply()
	var p: Dictionary=w.people.local
	var box: Dictionary=w.estate.storage
	R.act(w,"local","craft_home","bandage")
	check(box.belongings.cloth==5 and box.herb==5 and I.family_quantity(box,"bandage")==1 and I.family_quantity(p,"bandage")==0,"Chest materials become chest output without backpack detour")
	check(p.craft_xp.herbalism==8,"Chest output grants experience to crafter")
	R.act(w,"local","craft_supply","invalid|home")
	check(p.craft_supply.source=="home","Invalid source cannot mutate preferences")
	R.act(w,"local","craft_supply","home|bag")
	p.belongings.cloth=3
	p.belongings.bent_nail=1
	box.belongings.bent_nail=1
	R.act(w,"local","craft_home","repair_kit")
	check(box.belongings.bent_nail==0 and p.belongings.bent_nail==0 and box.belongings.cloth==4 and p.belongings.cloth==3 and I.family_quantity(p,"repair_kit")==1,"Split costs use chest first then backpack")
	R.act(w,"local","craft_supply","bag|bag")
	p.herb=0
	var seed: int=w.craft_rng
	var xp: int=p.craft_xp.herbalism
	R.act(w,"local","craft_home","bandage")
	check(w.craft_rng==seed and p.craft_xp.herbalism==xp and box.herb==5,"Bag-only mode ignores available chest materials")
	R.act(w,"local","craft_supply","home|bag")
	p.belongings.bandage=10
	R.act(w,"local","craft_home","bandage")
	check(box.herb==5 and w.craft_rng==seed,"Full backpack family blocks before chest withdrawal or RNG")
	p.belongings.bandage=0
	var saved_box:=box.duplicate(true)
	w.estate.storage=R.Storage.empty()
	box=w.estate.storage
	box.belongings.cloth=39
	box.herb=1
	R.act(w,"local","craft_supply","home|home")
	R.act(w,"local","craft_home","bandage")
	check(R.Storage.total(box)==39 and I.family_quantity(box,"bandage")==1,"Full chest allows production when ingredient consumption frees space")
	w.estate.storage=R.Storage.empty()
	box=w.estate.storage
	box.ore=40
	p.herb=1
	p.belongings.cloth=1
	seed=w.craft_rng
	xp=p.craft_xp.herbalism
	R.act(w,"local","craft_home","bandage")
	check(p.herb==1 and p.belongings.cloth==1 and box.ore==40 and w.craft_rng==seed and p.craft_xp.herbalism==xp,"Full destination with no chest ingredients changes nothing")
	box.ore=39
	R.act(w,"local","craft_home","bandage")
	check(R.Storage.total(box)==40 and I.family_quantity(box,"bandage")==1 and p.herb==0,"Exact final capacity accepts one output")
	w.estate.storage=saved_box
	box=w.estate.storage
	var owner: String=w.estate.owner
	w.estate.owner="departed"
	p.herb=1
	seed=w.craft_rng
	R.act(w,"local","craft_home","bandage")
	check(box.herb==5 and p.herb==1 and w.craft_rng==seed,"Former or foreign house cannot supply or receive automatic crafting")
	w.estate.owner=owner
	p.room="village"
	R.act(w,"local","craft_home","bandage")
	check(w.craft_rng==seed,"Remote crafting cannot use owned storage")
	p.room="home"
	box.belongings.mug_great=1
	p.belongings.mug=1
	w.estate.interior.fire=true
	var tool:=R.Supply.tool(w,p,"mug",p.craft_supply)
	check(tool=="mug_great","Best enabled cup may come from chest")
	var control:=w.duplicate(true)
	var expected:=R.Quality.roll(control,0,R.Mastery.rates(p,"herbalism",5))
	R.act(w,"local","craft_home","herbal_tea")
	var result: String="herbal_tea"+("" if expected.tier=="common" else "_"+expected.tier)
	check(I.quantity(box,result)==1 and box.belongings.mug_great==1 and w.craft_rng==control.craft_rng,"Chest cup adds correct bonus without being consumed")
	R.act(w,"local","plan_start","bandage|target|3|home|home")
	p.hp=100
	var before:=I.family_quantity(p,"bandage")+I.family_quantity(box,"bandage")
	R.advance(w,R.DAY)
	check(R.Supply.target_count(w,p,"bandage",p.craft_plan)==before+1,"Offline plan uses same storage routing")
	R.advance(w,R.DAY*4)
	check(R.Supply.target_count(w,p,"bandage",p.craft_plan)==3,"Target includes inventory and chest and stops at combined count")
	R.act(w,"local","resume")
	p.x=22
	p.y=13
	var taken:=I.best(box,"bandage")
	R.act(w,"local","take_item",taken)
	R.act(w,"local","leave")
	seed=w.craft_rng
	R.advance(w,R.DAY)
	check(R.Supply.target_count(w,p,"bandage",p.craft_plan)==3 and w.craft_rng==seed,"Moving finished product from chest to bag does not trigger replacement")
	R.act(w,"local","plan_start","bandage|count|2|home|home")
	R.advance(w,R.DAY)
	R.act(w,"local","plan_save","bandage|count|2|bag|bag")
	check(p.craft_plan.remaining==1,"Changing routing alone preserves remaining repetitions")
	R.act(w,"local","plan_start","iron_sword|count|2|home|home")
	check(p.craft_plan.recipe=="bandage","Forge refuses chest routing")
	R.act(w,"local","plan_save","bandage|count|2|home|home")
	var path:=OS.get_temp_dir()+"/vestige-supply-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Storage preferences and plan save")
	var copy:=R.load_world(path,false)
	check(not copy.is_empty() and copy.people.local.craft_supply.destination=="home" and copy.people.local.craft_plan.source=="home" and copy.people.local.craft_plan.remaining==1,"Reload preserves routing and progress")
	var old:=w.duplicate(true)
	old.version=11
	old.people.local.erase("craft_supply")
	old.people.local.craft_plan.erase("source")
	old.people.local.craft_plan.erase("destination")
	var f:=FileAccess.open(path+".old",FileAccess.WRITE)
	f.store_string(JSON.stringify(old));f.close()
	var migrated:=R.load_world(path+".old",false)
	check(not migrated.is_empty() and migrated.version==13 and migrated.people.local.craft_supply.source=="bag" and migrated.people.local.craft_plan.destination=="bag" and migrated.people.local.craft_plan.remaining==1,"Legacy saves default to bag-only without resetting plan")
	var bad:=w.duplicate(true)
	bad.people.local.craft_supply.source="other_player"
	check(not R.Store.valid(bad),"Invalid saved routing rejected")
	var view:=w.duplicate(true)
	view.people.local.room="home"
	view.people.local.x=15
	view.people.local.y=12
	R.Investigation.redact(view,"local")
	check(view.estate.has("storage") and not view.storage_access,"Owner can inspect crafting supply without chest transfer permission")
	R.born(w,"visitor","방문자")
	view=w.duplicate(true)
	R.Investigation.redact(view,"visitor")
	check(not view.estate.has("storage") and not view.people.local.has("craft_supply"),"Foreign storage and crafting preferences remain private")
	for entry in [path,path+".old"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(entry+ext)
	quit(1 if failures else 0)
