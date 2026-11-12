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
	var w:=R.fresh()
	R.born(w,"local","갑옷 장인")
	var p: Dictionary=w.people.local
	p.x=5
	p.y=8
	p.ore=20
	p.belongings.hide=12
	p.belongings.cloth=12
	var seed: int=w.craft_rng
	R.act(w,"local","craft_armor","invalid")
	check(w.craft_rng==seed and p.ore==20,"Invalid armor recipe consumes no resources or RNG")
	p.x=10
	R.act(w,"local","craft_armor","iron_armor")
	check(p.ore==20,"Remote armor craft rejected")
	p.x=5
	p.belongings.hide=0
	R.act(w,"local","craft_armor","iron_armor")
	check(p.ore==20 and w.craft_rng==seed,"Missing hide rejects atomically")
	p.belongings.hide=12
	p.offline=true
	R.act(w,"local","craft_armor","leather")
	check(p.belongings.hide==12,"Offline direct craft rejected")
	p.offline=false
	R.act(w,"local","craft_armor","leather")
	R.act(w,"local","craft_armor","iron_armor")
	check(p.ore==14 and p.belongings.hide==8 and p.belongings.cloth==8,"Armor consumes exact recipe materials")
	check(p.craft_xp.handicraft==14 and p.craft_xp.smithing==18,"Armor awards correct profession XP")
	var leather:=""
	var iron:=""
	for id in p.gear_instances:
		if p.gear_instances[id]=="leather" and not p.gear_records[id].maker.is_empty(): leather=id
		if p.gear_instances[id]=="iron_armor": iron=id
	check(p.gear_records[leather].maker.field=="생활 공예" and p.gear_records[iron].maker.field=="대장 기술","Armor maker records correct profession")
	var bounds: Array=R.Armor.DEFENSE.iron_armor[p.gear_quality[iron].tier]
	check(p.gear_quality[iron].defense>=bounds[0] and p.gear_quality[iron].defense<=bounds[1],"Armor defense matches rolled quality")
	R.act(w,"local","craft_armor","leather")
	var cap_seed: int=w.craft_rng
	var cap_hide: int=p.belongings.hide
	var cap_xp: int=p.craft_xp.handicraft
	R.act(w,"local","craft_armor","leather")
	check(p.belongings.leather==3 and p.belongings.hide==cap_hide and w.craft_rng==cap_seed and p.craft_xp.handicraft==cap_xp,"Armor capacity rejects without resource RNG or XP changes")
	R.act(w,"local","equip_body",leather)
	R.outfit(p)
	check(p.equipped_ids.body==leather,"Reconciliation preserves leather when iron armor is also owned")
	check(R.Armor.dodge_cost(p)==32,"Leather dodge costs 32 stamina")
	p.stamina=31
	R.act(w,"local","dodge")
	check(p.dodge==0 and p.stamina==31,"Insufficient armor dodge stamina is preserved")
	p.stamina=100
	R.act(w,"local","dodge")
	check(p.stamina==68 and p.dodge>0,"Leather dodge consumes actual cost")
	R.act(w,"local","equip_body",iron)
	R.act(w,"local","equip_body",iron)
	R.outfit(p)
	check(p.equipped_ids.body==iron and R.Armor.dodge_cost(p)==38,"Exact iron choice persists and costs 38 stamina")
	p.dodge=0
	p.hp=100
	p.x=25
	p.y=10
	w.wolf.x=25
	w.wolf.y=10
	w.wolf.warning=0.01
	var reduction: int=p.gear_quality[iron].defense
	R.tick(w,0.02)
	check(p.hp==100-(18-reduction) and p.gear_condition[iron]==95,"Real wolf hit applies armor defense and one wear event")
	p.dodge=0.4
	w.wolf.warning=0.01
	R.tick(w,0.02)
	check(p.gear_condition[iron]==95,"Dodged hit does not wear armor")
	p.gear_condition[iron]=0
	p.hp=100
	R.Armor.hit(p,18)
	check(p.hp==82 and R.Armor.defense(p)==0 and R.Armor.dodge_cost(p)==38,"Broken armor loses protection but retains weight")
	p.gear_condition[iron]=100
	p.hp=100
	check(R.Armor.hit(p,1)==1,"Minimum physical damage remains one")
	p.room="home"
	p.x=15
	p.y=12
	p.belongings.repair_kit=1
	p.gear_condition[iron]=0
	R.act(w,"local","repair_gear",iron)
	check(p.gear_condition[iron]==40 and R.Armor.defense(p)==reduction and p.gear_records[iron].events.back().kind=="repaired","Armor repair restores defense and records history")
	p.room="village"
	p.x=7
	p.y=14
	R.act(w,"local","interact")
	R.act(w,"local","store_item",iron)
	check(p.equipment.body=="none" and R.Armor.defense(p)==0 and w.estate.storage.gear_quality[iron].defense==reduction,"Storing worn armor removes protection and preserves stats")
	R.act(w,"local","equip_body",iron)
	check(p.equipment.body=="none","Stored armor cannot be equipped remotely")
	R.act(w,"local","take_item",iron)
	var life: String=p.life
	R.die(w,"local","노환")
	R.born(w,"local","후계자")
	p=w.people.local
	p.x=7
	p.y=14
	R.act(w,"local","take_remains",life+"|"+iron)
	R.act(w,"local","equip_body",iron)
	check(R.Armor.defense(p)==reduction and p.gear_records[iron].maker.life==life and p.gear_records[iron].events.back().kind=="recovered","Successor recovers exact armor stats and history")
	var path:="/tmp/vestige-armor-test-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Armor world saves")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and R.Armor.defense(loaded.people.local)==reduction,"Reload preserves worn armor and defense")
	var bad:=w.duplicate(true)
	bad.people.local.gear_quality[iron].defense=99
	check(not R.Store.valid(bad),"Forged defense value rejected")
	# Genuine old-style save: no new items, defense fields or hide stock.
	var old:=R.fresh()
	R.born(old,"local","기존 여행자")
	old.version=14
	old.market.stock.erase("hide")
	old.market.stock.cloth=1
	for holder in [old.people.local,old.estate.storage]:
		for id in holder.gear_quality: holder.gear_quality[id].erase("defense")
	var file:=FileAccess.open(path+".old",FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	loaded=R.load_world(path+".old",false)
	check(not loaded.is_empty() and loaded.version==17 and loaded.market.stock.cloth==1 and loaded.market.stock.hide==10,"Legacy market gains hide without resetting existing stock")
	for id in loaded.people.local.gear_instances:
		if loaded.people.local.gear_instances[id]=="leather": check(loaded.people.local.gear_quality[id].defense==3 and loaded.people.local.gear_records[id].maker.is_empty(),"Legacy starter armor gets baseline defense without invented maker")
	var shop:=R.fresh()
	R.born(shop,"local","손님")
	shop.people.local.x=14
	shop.people.local.y=15
	R.act(shop,"local","market_buy","hide")
	check(shop.people.local.belongings.hide==1 and shop.people.local.gold==9 and shop.market.stock.hide==9,"Hide can be bought from real shared market stock")
	for kind in ["leather","iron_armor"]:
		var tiers: Array=[]
		for n in [1,4,685]:
			var trial:=R.fresh()
			R.born(trial,"local","품질 장인")
			trial.craft_rng=n
			var crafter: Dictionary=trial.people.local
			crafter.x=5
			crafter.y=8
			crafter.ore=10
			crafter.belongings.hide=10
			crafter.belongings.cloth=10
			R.act(trial,"local","craft_armor",kind)
			for key in crafter.gear_records:
				if not crafter.gear_records[key].maker.is_empty() and not tiers.has(crafter.gear_quality[key].tier): tiers.append(crafter.gear_quality[key].tier)
		check(tiers.size()==3,"Actual armor production reaches all quality tiers: "+kind)
	for entry in [path,path+".old"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(entry+ext)
	quit(1 if failures else 0)
