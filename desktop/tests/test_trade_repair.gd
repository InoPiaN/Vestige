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
	var w:=preload("res://investigation_demo.gd").armor_upgrade()
	var p: Dictionary=w.people.local
	var id: String=p.equipped_ids.body
	R.act(w,"local","upgrade_armor",id+"|0")
	var quality: Dictionary=p.gear_quality[id].duplicate(true)
	var maker: Dictionary=p.gear_records[id].maker.duplicate(true)
	p.gear_condition[id]=35
	var cost:=R.ForgeRepair.price(p,id)
	var coins: int=p.gold
	var rng: int=w.craft_rng
	var xp: Dictionary=p.craft_xp.duplicate(true)
	check(cost==8,"Repair price scales with damage and enhancement")
	R.act(w,"local","forge_repair",id+"|35|"+str(cost))
	check(p.gear_condition[id]==100 and p.gold==coins-cost,"Forge repair fully restores worn armor for quoted price")
	check(p.gear_quality[id]==quality and p.gear_records[id].maker==maker and w.craft_rng==rng and p.craft_xp==xp,"Repair preserves quality maker RNG and XP")
	check(p.gear_records[id].events.back().kind=="repaired" and p.events.back().contains("대장간 수리"),"Repair records history and personal memo")
	R.act(w,"local","forge_repair",id+"|35|"+str(cost))
	R.act(w,"local","forge_repair",id+"|100|0")
	check(p.gold==coins-cost,"Stale and pristine repair requests cannot charge twice")
	p.gear_condition[id]=50
	p.x=14
	p.y=14
	R.act(w,"local","forge_repair",id+"|50|6")
	check(p.gear_condition[id]==50,"Remote paid repair rejected")
	p.x=5
	p.y=8
	p.gold=0
	R.act(w,"local","forge_repair",id+"|50|6")
	check(p.gear_condition[id]==50,"Insufficient repair money preserves durability")
	p.gold=100
	p.offline=true
	R.act(w,"local","forge_repair",id+"|50|6")
	p.offline=false
	check(p.gear_condition[id]==50 and p.gold==100,"Offline paid repair rejected")
	p.x=14
	p.y=14
	var price:=R.Market.price(p,id)
	check(price>0,"Crafted enhanced armor has a sale price")
	R.act(w,"local","market_sell",id)
	check(p.gear_instances.has(id) and p.buyback_orders.is_empty(),"Worn armor cannot be sold")
	R.act(w,"local","equip_body","none")
	R.act(w,"local","market_sell",id)
	check(not p.gear_instances.has(id) and p.gold==100+price and p.buyback.gear_instances.has(id),"Sale transfers exact gear into personal buyback")
	var token: String=p.buyback_orders[0].token
	check(p.buyback.gear_quality[id]==quality and p.buyback.gear_condition[id]==50 and p.buyback.gear_records[id].maker==maker,"Buyback retains quality condition and maker")
	R.act(w,"local","market_sell",id)
	check(p.gold==100+price and p.buyback_orders.size()==1,"Duplicate gear sale cannot duplicate money")
	p.gold=0
	R.act(w,"local","market_repurchase",token)
	check(p.buyback_orders.size()==1,"Insufficient money blocks repurchase")
	p.gold=100+price
	R.act(w,"local","market_repurchase",token)
	check(p.gold==100 and p.gear_instances.has(id) and p.buyback_orders.is_empty(),"Repurchase restores same ID at original price")
	check(p.gear_records[id].events.back().kind=="repurchased" and p.gear_quality[id]==quality,"Repurchase keeps history and adds recovery transaction")
	R.act(w,"local","market_repurchase",token)
	check(p.gold==100,"Duplicate repurchase is harmless")
	var starter:=""
	for key in p.gear_instances:
		if p.gear_instances[key]=="leather" and p.gear_records[key].maker.is_empty(): starter=key
	R.act(w,"local","market_sell",starter)
	check(R.Market.price(p,starter)==0 and p.gear_instances.has(starter),"Starter clothing protected from sale")
	R.act(w,"local","market_sell",id)
	var new_token: String=p.buyback_orders[0].token
	R.act(w,"local","market_repurchase",token)
	check(new_token!=token and not p.gear_instances.has(id),"Old sale token cannot repurchase a later resale")
	var full:=w.duplicate(true)
	var fp: Dictionary=full.people.local
	R.Storage.change(fp,"iron_armor",3-I.quantity(fp,"iron_armor"))
	R.Storage.reconcile(fp)
	var balance: int=fp.gold
	R.act(full,"local","market_repurchase",new_token)
	check(fp.gold==balance and not fp.gear_instances.has(id),"Full gear capacity blocks repurchase without charging")
	R.born(full,"stranger","다른 상인")
	full.people.stranger.x=14
	full.people.stranger.y=14
	R.act(full,"stranger","market_repurchase",new_token)
	check(not full.people.stranger.gear_instances.has(id),"Another person cannot use seller's receipt")
	for kind in ["iron_sword","leather"]:
		var sample:=preload("res://investigation_demo.gd").armor_upgrade()
		var sp: Dictionary=sample.people.local
		if kind=="iron_sword": R.act(sample,"local","interact")
		var key:=""
		for candidate in sp.gear_instances:
			if sp.gear_instances[candidate]==kind and not sp.gear_records[candidate].maker.is_empty(): key=candidate
		sp.gear_condition[key]=0
		var quote:=R.ForgeRepair.price(sp,key)
		R.act(sample,"local","forge_repair",key+"|0|"+str(quote))
		check(sp.gear_condition[key]==100 and sp.gold==80-quote,"Paid repair supports broken "+kind)
		var plain:=R.Market.price(sp,key)
		sp.gear_quality[key].upgrade=3
		check(R.Market.price(sp,key)==plain+6,"Sale price values three enhancement levels: "+kind)
	var path: String=OS.get_temp_dir()+"/vestige-trade-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"World with sold gear saves")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and loaded.people.local.buyback_orders[0].token==new_token and loaded.people.local.buyback.gear_condition[id]==50,"Reload preserves personal buyback and exact condition")
	var bad:=w.duplicate(true)
	bad.people.local.buyback_orders[0].price=-1
	check(not R.Store.valid(bad),"Invalid buyback price rejected")
	bad=w.duplicate(true)
	bad.people.local.buyback.gear_quality[id].upgrade=9
	check(not R.Store.valid(bad),"Buyback gear receives normal quality validation")
	bad=w.duplicate(true)
	R.Market.move_gear(bad.people.local.buyback,bad.estate.storage,id)
	bad.people.local.buyback= p.buyback.duplicate(true)
	check(not R.Store.valid(bad),"Duplicate gear ID across storage and merchant rejected")
	var view:=w.duplicate(true)
	R.born(view,"other","다른 인물")
	R.Investigation.redact(view,"other")
	check(not view.people.local.has("buyback") and not view.people.local.has("buyback_orders"),"Other players cannot inspect buyback")
	R.act(w,"local","market_repurchase",new_token)
	for i in range(11):
		p.x=5
		p.y=8
		p.ore=2
		R.act(w,"local","interact")
		var sword:=""
		for key in p.gear_instances:
			if p.gear_instances[key]=="iron_sword": sword=key
		R.act(w,"local","equip_weapon","none")
		p.x=14
		p.y=14
		R.act(w,"local","market_sell",sword)
	check(p.buyback_orders.size()==10 and p.buyback.gear_instances.size()==10 and R.Store.valid(w),"Recent ten gear retained with oldest eviction and valid counts")
	var legacy:=preload("res://investigation_demo.gd").armor()
	legacy.version=17
	legacy.people.local.erase("buyback")
	legacy.people.local.erase("buyback_orders")
	var f:=FileAccess.open(path+".old",FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy))
	f.close()
	loaded=R.load_world(path+".old",false)
	check(not loaded.is_empty() and loaded.version==18 and loaded.people.local.buyback_orders.is_empty(),"Version seventeen migrates with no invented sales")
	R.die(w,"local","노환")
	R.born(w,"local","후계자")
	check(w.people.local.buyback_orders.is_empty(),"New life does not inherit personal repurchase rights")
	for file in [path,path+".old"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(file+ext)
	quit(1 if failures else 0)
