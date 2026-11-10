extends SceneTree
const R=preload("res://world.gd")
const M=preload("res://village_market.gd")
const Items=preload("res://items.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w:=preload("res://investigation_demo.gd").market()
	var p: Dictionary=w.people.local
	check(R.act(w,"local","interact")=="장터","Market reached through village interaction")
	var cloth:=Items.quantity(p,"cloth")
	R.act(w,"local","market_buy","cloth")
	check(p.gold==27 and Items.quantity(p,"cloth")==cloth+1 and w.market.stock.cloth==7,"Purchase changes wallet, inventory and shared stock once")
	p.gold=0
	R.act(w,"local","market_buy","cloth")
	check(w.market.stock.cloth==7 and Items.quantity(p,"cloth")==cloth+1,"Insufficient funds consume no stock")
	p.gold=100
	p.belongings.cloth=20
	R.act(w,"local","market_buy","cloth")
	check(p.gold==100 and w.market.stock.cloth==7,"Carry limit rejects purchase atomically")
	R.act(w,"local","market_sell","cloth")
	check(p.gold==101 and p.belongings.cloth==19 and w.market.stock.cloth==7,"Sale removes one unit without creating buyback stock")
	check(M.price(p,"bandage")<M.price(p,"bandage_fine") and M.price(p,"bandage_fine")<M.price(p,"bandage_great"),"Quality increases crafted sale value")
	p.belongings.bandage_great=1
	R.act(w,"local","market_sell","bandage_great")
	var coins: int=p.gold
	R.act(w,"local","market_sell","bandage_great")
	check(p.gold==coins and p.belongings.bandage_great==0,"Repeated sale cannot sell consumed item")
	for id in ["relic","leather","invalid","iron_sword"]: R.act(w,"local","market_sell",id)
	check(p.gold==coins,"Evidence, starter clothes, invalid IDs and aggregate sword IDs are excluded")
	var sword: String=p.equipped_ids.weapon
	R.act(w,"local","market_sell",sword)
	check(p.gear_instances.has(sword) and p.gold==coins,"Equipped sword protected")
	R.act(w,"local","equip_instance",sword)
	var original:=M.price(p,sword)
	p.gear_condition[sword]=25
	check(M.price(p,sword)<original,"Sword wear lowers value")
	var quote:=M.price(p,sword)
	R.act(w,"local","market_sell",sword)
	check(p.gold==coins+quote and not p.gear_instances.has(sword) and not p.gear_quality.has(sword) and not p.gear_condition.has(sword) and p.sword==2,"Exact sword and metadata removed, other swords preserved")
	coins=p.gold
	R.act(w,"local","market_sell",sword)
	check(p.gold==coins,"Unique sword cannot be sold twice")
	p.x=7
	R.act(w,"local","market_buy","cloth")
	check(p.gold==coins,"Remote trade rejected")
	p.x=14
	p.room="home"
	R.act(w,"local","market_sell","cloth")
	check(p.gold==coins,"Matching indoor coordinates cannot trade")
	p.room="village"
	p.offline=true
	R.act(w,"local","market_sell","cloth")
	check(p.gold==coins,"Offline trade rejected")
	p.offline=false
	w.market.stock.cloth=0
	R.act(w,"local","market_buy","cloth")
	check(p.gold==coins,"Depleted stock blocks purchase")
	var path:=OS.get_temp_dir()+"/vestige-market-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Market state saves")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and loaded.market.stock.cloth==0 and loaded.people.local.gold==coins,"Reload preserves depleted stock and wallet")
	R.advance(w,R.DAY)
	check(w.market.stock.cloth==8 and w.market.day==1,"Next world day replenishes stock")
	R.act(w,"local","market_buy","cloth")
	R.advance(w,0)
	check(w.market.stock.cloth==7,"Same day simulation does not replenish twice")
	R.born(w,"other","다른 손님")
	var other: Dictionary=w.people.other
	other.x=14
	other.y=15
	R.act(w,"other","market_buy","cloth")
	check(w.market.stock.cloth==6 and other.gold==9,"Multiple residents use the same stock")
	var invalid:=w.duplicate(true)
	invalid.market.stock.cloth=-1
	check(not R.Store.valid(invalid),"Corrupt market stock rejected")
	invalid=w.duplicate(true)
	invalid.market.day=999
	check(not R.Store.valid(invalid),"Future replenishment date rejected")
	var old:=w.duplicate(true)
	old.version=8
	old.erase("market")
	var file:=FileAccess.open(path+".old",FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var migrated:=R.load_world(path+".old",false)
	check(not migrated.is_empty() and migrated.version==10 and migrated.market.stock.cloth==8 and migrated.people.local.gold==p.gold,"Legacy save gains market without changing wallet")
	for entry in [path,path+".old"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(entry+ext)
	quit(1 if failures else 0)
