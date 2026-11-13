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
	for kind in ["leather","iron_armor"]:
		var w:=preload("res://investigation_demo.gd").armor()
		var p: Dictionary=w.people.local
		p.gold=40
		p.ore=20
		p.belongings.hide=20
		p.belongings.cloth=20
		var id:=""
		for key in p.gear_instances:
			if p.gear_instances[key]==kind and not p.gear_records[key].maker.is_empty(): id=key
		R.act(w,"local","equip_body",id)
		p.gear_condition[id]=60
		var base: int=p.gear_quality[id].defense
		var original: Dictionary=p.gear_quality[id].duplicate(true)
		var maker: Dictionary=p.gear_records[id].maker.duplicate(true)
		var xp: Dictionary=p.craft_xp.duplicate(true)
		var seed: int=w.craft_rng
		var cost: Dictionary=R.ArmorUpgrade.COSTS[kind][0]
		R.act(w,"local","upgrade_armor",id+"|0")
		check(R.Armor.defense(p)==base+1 and p.gold==36,"Actual worn armor gains one defense: "+kind)
		for material in cost: check(I.quantity(p,material)==20-cost[material],"Exact armor upgrade material: "+kind+"/"+material)
		check(p.gear_condition[id]==60 and p.gear_quality[id].defense==base and p.gear_quality[id].tier==original.tier and p.craft_xp==xp and w.craft_rng==seed,"Quality durability mastery and RNG unchanged: "+kind)
		check(p.gear_records[id].maker==maker and p.gear_records[id].events.back().kind=="upgraded" and p.gear_records[id].events.back().actor==p.life,"Maker and upgrader retained: "+kind)
		var gold: int=p.gold
		R.act(w,"local","upgrade_armor",id+"|0")
		check(p.gold==gold and R.ArmorUpgrade.level(p,id)==1,"Duplicate request cannot double spend: "+kind)
		for invalid in ["fake|0",id+"|bad",id+"|1|extra"]: R.act(w,"local","upgrade_armor",invalid)
		p.x=10
		R.act(w,"local","upgrade_armor",id+"|1")
		p.x=5
		p.room="home"
		R.act(w,"local","upgrade_armor",id+"|1")
		p.room="village"
		p.offline=true
		R.act(w,"local","upgrade_armor",id+"|1")
		p.offline=false
		check(p.gold==gold and R.ArmorUpgrade.level(p,id)==1,"Invalid IDs location and offline rejected: "+kind)
		for material in R.ArmorUpgrade.COSTS[kind][1]:
			var amount:=I.quantity(p,material)
			R.Storage.change(p,material,-amount)
			R.act(w,"local","upgrade_armor",id+"|1")
			check(p.gold==gold and R.ArmorUpgrade.level(p,id)==1,"Missing material rejects atomically: "+kind+"/"+material)
			R.Storage.change(p,material,amount)
		p.gold=0
		R.act(w,"local","upgrade_armor",id+"|1")
		check(R.ArmorUpgrade.level(p,id)==1,"Missing money rejects: "+kind)
		p.gold=gold
		R.act(w,"local","upgrade_armor",id+"|1")
		R.act(w,"local","upgrade_armor",id+"|2")
		check(R.Armor.defense(p)==base+3 and p.gold==16 and R.Armor.dodge_cost(p)==(32 if kind=="leather" else 38),"Maximum defense and unchanged dodge cost: "+kind)
		check(I.definition(p,id).name.contains("+3") and I.definition(p,id).description.contains("감소 %d" % (base+3)),"Inventory exposes actual upgraded rating: "+kind)
		var history: int=p.gear_records[id].events.size()
		R.act(w,"local","upgrade_armor",id+"|3")
		check(p.gold==16 and p.gear_records[id].events.size()==history,"Maximum upgrade no mutation: "+kind)
		p.hp=100
		check(R.Armor.hit(p,18)==18-base-3 and p.gear_condition[id]==55,"Upgraded armor reduces real damage and wears: "+kind)
		p.gear_condition[id]=0
		check(R.Armor.defense(p)==0 and R.Armor.hit(p,18)==18,"Broken upgraded armor grants no protection: "+kind)
		p.room="home"
		p.x=15
		p.y=12
		R.Crafting.repair(p,id)
		check(R.Armor.defense(p)==base+3 and p.gear_condition[id]>0 and R.ArmorUpgrade.level(p,id)==3,"Repair restores enhanced defense without losing grade: "+kind)
		p.room="village"
		p.x=7
		p.y=14
		R.act(w,"local","interact")
		R.act(w,"local","store_item",id)
		check(w.estate.storage.gear_quality[id].upgrade==3 and R.Armor.defense(p)==0,"Storing upgraded armor removes worn effect and preserves level: "+kind)
		R.act(w,"local","take_item",id)
		R.die(w,"local","노환")
		var life: String=p.life
		R.born(w,"local","후계자")
		p=w.people.local
		p.x=7
		p.y=14
		R.act(w,"local","take_remains",life+"|"+id)
		check(R.ArmorUpgrade.level(p,id)==3 and p.gear_records[id].maker==maker,"Successor receives enhancement and original maker: "+kind)
		var path: String="/tmp/vestige-armor-up-"+str(OS.get_process_id())+kind+".json"
		check(R.save_world(w,path),"Upgraded armor saves: "+kind)
		var loaded:=R.load_world(path,false)
		check(not loaded.is_empty() and R.ArmorUpgrade.level(loaded.people.local,id)==3,"Reload preserves enhancement: "+kind)
		var bad:=w.duplicate(true)
		bad.people.local.gear_quality[id].upgrade=4
		check(not R.Store.valid(bad),"Out of range armor enhancement rejected: "+kind)
		bad.people.local.gear_quality[id].upgrade=1.5
		check(not R.Store.valid(bad),"Fractional enhancement rejected: "+kind)
		for ext in ["",".bak"]: DirAccess.remove_absolute(path+ext)
	var old:=preload("res://investigation_demo.gd").armor()
	old.version=16
	var expected: Dictionary=old.people.local.gear_quality.duplicate(true)
	var path: String="/tmp/vestige-armor-up-old-"+str(OS.get_process_id())+".json"
	var f:=FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify(old))
	f.close()
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and loaded.version==18 and JSON.parse_string(JSON.stringify(loaded.people.local.gear_quality))==JSON.parse_string(JSON.stringify(expected)),"Version sixteen armor stats and unenhanced state migrate unchanged")
	for ext in ["",".bak"]: DirAccess.remove_absolute(path+ext)
	quit(1 if failures else 0)
