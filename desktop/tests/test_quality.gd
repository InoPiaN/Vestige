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
	var w:=preload("res://investigation_demo.gd").quality()
	var p: Dictionary=w.people.local
	var tiers: Array=[]
	var swords: Array=[]
	for id in p.gear_instances:
		if p.gear_instances[id]!="iron_sword": continue
		swords.append(id)
		tiers.append(p.gear_quality[id].tier)
	check(tiers.has("common") and tiers.has("fine") and tiers.has("great") and p.sword==3,"Actual forge production creates all three quality tiers")
	var great: String=swords[2]
	var attack: int=p.gear_quality[great].attack
	check(attack>=27 and attack<=29,"Great success sword has bounded improved attack")
	R.act(w,"local","equip_instance",great) # Toggle off if demo equipped it.
	R.act(w,"local","equip_instance",great)
	check(R.weapon_damage(p)==attack,"Combat uses rolled attack, not a fixed template")
	var text:=Items.definition(p,great)
	check(text.name.contains("대성공") and text.description.contains(str(attack)),"Inventory exposes item's quality and real attack")
	p.gear_condition[great]=0
	check(R.weapon_damage(p)==9,"Zero durability still reduces quality weapon effectiveness")
	p.belongings.repair_kit_great=1
	var seed: int=w.craft_rng
	R.act(w,"local","repair_gear",great)
	check(p.gear_condition[great]==50 and p.gear_quality[great].attack==attack and w.craft_rng==seed,"Great kit restores 50 without rerolling sword quality")
	at(p,22,13)
	R.act(w,"local","store_item",great)
	check(w.estate.storage.gear_quality[great].attack==attack and not p.gear_quality.has(great),"Storage moves quality with unique gear")
	R.act(w,"local","take_item",great)
	R.die(w,"local","노환")
	var dead: String=p.life
	R.born(w,"local","후계자")
	p=w.people.local
	p.room="home"
	at(p,22,13)
	R.act(w,"local","take_remains",dead+"|"+great)
	check(p.gear_quality[great].tier=="great" and p.gear_quality[great].attack==attack,"Successor recovers unchanged quality")
	p.belongings.bandage_great=1
	p.hp=20
	R.act(w,"local","use_crafted","bandage_great")
	check(p.hp==74 and Items.quantity(p,"bandage_great")==0,"Great bandage restores 54 once")
	p.belongings.herbal_tea_fine=1
	p.hp=20
	p.stamina=10
	R.act(w,"local","use_crafted","herbal_tea_fine")
	check(p.hp==42 and p.stamina==54,"Fine tea has distinct health and energy effects")
	at(p,15,12)
	p.belongings.cloth=4
	p.herb=3
	p.belongings.bandage=9
	p.belongings.bandage_fine=1
	seed=w.craft_rng
	R.act(w,"local","craft_home","bandage")
	check(p.herb==3 and p.belongings.cloth==4 and w.craft_rng==seed,"Combined family cap rejects craft without consuming materials or RNG")
	w.estate.storage.belongings.bandage_great=1
	at(p,22,13)
	R.act(w,"local","take_item","bandage_great")
	check(Items.quantity(p,"bandage_great")==0 and w.estate.storage.belongings.bandage_great==1,"Withdrawal cannot bypass family limit using another quality")
	at(p,15,12)
	p.belongings.bandage=0
	p.belongings.bandage_fine=0
	R.act(w,"local","craft_home","forged_recipe")
	check(w.craft_rng==seed,"Invalid recipe cannot advance quality randomness")
	var path:=OS.get_temp_dir()+"/vestige-quality-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Quality and RNG save")
	var copy:=R.load_world(path,false)
	check(not copy.is_empty() and copy.people.local.gear_quality[great].attack==attack,"Reload preserves exact rolled stats")
	R.act(copy,"local","resume")
	R.act(w,"local","craft_home","bandage")
	R.act(copy,"local","craft_home","bandage")
	check(w.craft_rng==copy.craft_rng and Items.quantity(p,"bandage")==Items.quantity(copy.people.local,"bandage") and Items.quantity(p,"bandage_fine")==Items.quantity(copy.people.local,"bandage_fine") and Items.quantity(p,"bandage_great")==Items.quantity(copy.people.local,"bandage_great"),"Reload before production yields same result rather than a reroll")
	var view:=w.duplicate(true)
	R.Investigation.redact(view,"local")
	check(not view.has("craft_rng"),"Random state is absent from client snapshot")
	var invalid:=w.duplicate(true)
	invalid.people.local.gear_quality[great].attack=999
	check(not R.Store.valid(invalid),"Out-of-range quality stats rejected")
	# Same saved roll shows reusable quality cup improves great-success threshold.
	var base: Dictionary={"craft_rng":1}
	var boosted: Dictionary={"craft_rng":1}
	var found:=false
	for i in range(100):
		var normal:=R.Quality.roll(base)
		var improved:=R.Quality.roll(boosted,5)
		if normal.tier!="great" and improved.tier=="great": found=true
	check(found and base.craft_rng==boosted.craft_rng,"Cup bonus improves great-success chance without extra rolls")
	# Legacy gear retains baseline attack rather than receiving random upgrades.
	var old:=w.duplicate(true)
	old.version=7
	old.erase("craft_rng")
	var holders: Array=old.people.values()
	holders.append(old.estate.storage)
	for row in old.remains.values(): holders.append(row.contents)
	for holder in holders: holder.erase("gear_quality")
	var legacy_path:=path+".legacy"
	var file:=FileAccess.open(legacy_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var migrated:=R.load_world(legacy_path,false)
	check(not migrated.is_empty() and migrated.people.local.gear_quality[great].attack==22 and migrated.people.local.gear_condition[great]==50,"Legacy gear migrates to ordinary 22 and preserves wear")
	var offline:=R.fresh()
	offline.craft_rng=685
	R.born(offline,"worker","대장장이")
	offline.people.worker.ore=2
	offline.people.worker.offline=true
	offline.people.worker.policy="work"
	R.advance(offline,R.DAY)
	var made: Dictionary=offline.people.worker
	var great_count:=0
	for id in made.gear_instances:
		if made.gear_instances[id]=="iron_sword" and made.gear_quality[id].tier=="great": great_count+=1
	check(great_count==1 and made.ore==0 and made.journal[0].text.contains("대성공"),"Offline blacksmith uses same quality rules and records result")
	for entry in [path,legacy_path]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(entry+ext)
	quit(1 if failures else 0)
