extends SceneTree
const R=preload("res://world.gd")
const D=preload("res://investigation_demo.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func place(p: Dictionary,x: float,y: float) -> void:
	p.x=x
	p.y=y
func item(p: Dictionary,kind: String) -> String:
	for id in p.gear_instances:
		if p.gear_instances[id]==kind: return id
	return ""
func run() -> void:
	var w:=D.professions()
	var p: Dictionary=w.people.local
	check(R.Store.valid(w) and p.skill_slots==["", ""],"New life starts with two unlearned paths and empty slots")
	R.act(w,"local","lesson","hunter")
	check(p.professions.hunter.state=="new","Remote mentor cannot grant a task")
	R.act(w,"local","lesson","warrior")
	check(p.professions.warrior.state=="active","Nearby warrior mentor grants entry task")
	R.act(w,"local","lesson","warrior")
	check(p.professions.warrior.state=="active" and p.ore==6,"Missing equipped sword preserves task resources")
	place(p,5,8)
	R.act(w,"local","interact")
	var sword:=item(p,"iron_sword")
	place(p,8,7)
	R.act(w,"local","lesson","warrior")
	check(p.professions.warrior.state=="learned" and p.skill_slots==["heavy","guard"] and p.ore==2 and p.gold==34,"Warrior initiation teaches two skills and rewards once")
	R.act(w,"local","lesson","warrior")
	check(p.gold==34 and p.ore==2,"Completed mentor task cannot duplicate rewards")
	R.act(w,"local","skill_slot","0|aim")
	check(p.skill_slots[0]=="heavy","Unlearned skill cannot be prepared")
	R.act(w,"local","skill_slot","0|guard")
	check(p.skill_slots[0]=="heavy","Duplicate prepared skill rejected")
	var before: int=w.craft_rng
	R.act(w,"local","craft_bow")
	check(item(p,"shortbow").is_empty() and w.craft_rng==before,"Remote bow crafting consumes no resources or RNG")
	place(p,5,8)
	R.act(w,"local","craft_bow")
	var bow:=item(p,"shortbow")
	check(not bow.is_empty() and p.belongings.wood==0 and p.belongings.cloth==0 and p.craft_xp.handicraft==14,"Bow crafted from wood and cloth with handicraft XP")
	check(p.gear_quality[bow].attack>=14 and p.gear_quality[bow].attack<=23 and p.gear_records[bow].maker.name==p.name,"Bow carries quality damage and maker record")
	check(p.equipped_ids.weapon==sword,"Crafting a bow preserves currently equipped sword")
	R.act(w,"local","equip_weapon",bow)
	R.outfit(p)
	check(p.equipment.weapon=="shortbow" and p.equipped_ids.weapon==bow,"Equipment screen selects persistent bow identity")
	place(p,16,8)
	R.act(w,"local","lesson","hunter")
	p.herb=1
	R.act(w,"local","lesson","hunter")
	check(p.professions.hunter.state=="active" and p.herb==1,"Missing hunter supplies cannot complete task")
	p.herb=2
	R.act(w,"local","lesson","hunter")
	check(p.professions.hunter.state=="learned" and p.professions.warrior.state=="learned" and p.gold==38,"One character learns both paths")
	check(p.skill_slots==["heavy","guard"],"Learning second path preserves prepared slots")
	R.act(w,"local","skill_slot","0|aim")
	R.act(w,"local","skill_slot","1|slow")
	var stamina: float=p.stamina
	R.act(w,"local","use_skill","aim")
	check(p.stamina==stamina,"Command accepts slot indices only")
	R.act(w,"local","use_skill","0")
	check(p.stamina==stamina and p.skill_cooldowns.aim==0,"Out of range skill cannot consume stamina or cooldown")
	place(p,19,10)
	p.attack=0
	var damage:=R.weapon_damage(p)
	R.act(w,"local","use_skill","0")
	check(w.wolf.hp==50-roundi(damage*1.5) and p.stamina==stamina-22 and p.skill_cooldowns.aim==4,"Aimed shot hits beyond ordinary bow range with exact cost")
	check(p.gear_condition[bow]==95 and p.professions.hunter.xp==5 and p.professions.warrior.xp==0,"Actual bow hit wears bow and trains only hunter")
	var hp: int=w.wolf.hp
	p.attack=0
	R.act(w,"local","use_skill","0")
	check(w.wolf.hp==hp,"Cooldown blocks repeated skill")
	R.act(w,"local","skill_slot","0|")
	R.act(w,"local","skill_slot","0|aim")
	check(p.skill_cooldowns.aim==4,"Reassigning slot cannot reset cooldown")
	place(p,20,10)
	R.act(w,"local","use_skill","1")
	check(w.wolf.slow==3 and p.skill_cooldowns.slow==5 and p.professions.hunter.xp==10,"Slowing shot applies timed debuff and trains on hit")
	R.advance(w,1)
	check(p.skill_cooldowns.aim==3 and w.wolf.slow==2 and p.shot_time==0,"World advance expires cooldowns and visual effects")
	R.advance(w,5)
	check(p.skill_cooldowns.aim==0 and w.wolf.slow==0,"Long elapsed interval clears timers")
	check(not R.Professions.clear_line(Vector2(3,7),Vector2(7,7)) and R.Professions.clear_line(Vector2(20,10),Vector2(25,10)),"Ranged line of sight blocks buildings")
	R.act(w,"local","skill_slot","0|heavy")
	p.attack=0
	p.stamina=100
	R.act(w,"local","use_skill","0")
	check(p.stamina==100,"Sword skill rejects bow without charging")
	R.act(w,"local","equip_weapon",sword)
	R.act(w,"local","skill_slot","1|guard")
	R.act(w,"local","use_skill","1")
	check(p.guard_time==2 and p.stamina==82,"Guard works without target with exact stamina cost")
	check(R.Armor.hit(p,18)==9,"Guard halves incoming physical damage")
	R.advance(w,2)
	check(R.Armor.hit(p,18)==18,"Guard mitigation expires")
	place(p,24,10)
	w.wolf.hp=100
	p.attack=0
	p.stamina=100
	var sword_damage:=R.weapon_damage(p)
	R.act(w,"local","use_skill","0")
	check(w.wolf.hp==100-roundi(sword_damage*1.6) and p.professions.warrior.xp==5,"Heavy strike damages and trains warrior")
	p.attack=0
	p.stamina=1
	hp=w.wolf.hp
	R.act(w,"local","attack")
	check(w.wolf.hp==hp and p.professions.warrior.xp==5,"Insufficient stamina cannot train without hit")
	p.stamina=100
	p.offline=true
	R.act(w,"local","use_skill","0")
	check(p.stamina==100,"Offline characters cannot manually cast")
	p.offline=false
	p.room="home"
	R.advance(w,10)
	R.act(w,"local","use_skill","0")
	check(p.stamina==100,"Skills cannot attack from matching house coordinates")
	p.room="village"
	p.attack=0
	R.act(w,"local","equip_weapon",bow)
	place(p,20,10)
	w.wolf.hp=1
	var before_reward: int=p.gold
	R.act(w,"local","attack")
	var gold: int=p.gold
	check(w.wolf.hp==0 and gold==before_reward+8,"Basic bow attack kills and awards standard loot")
	p.attack=0
	R.act(w,"local","attack")
	check(p.gold==gold,"Dead target cannot award loot twice")
	place(p,5,8)
	p.gear_condition[bow]=0
	check(R.weapon_damage(p)==9,"Broken bow loses base attack bonus")
	R.act(w,"local","forge_repair",bow+"|0|5")
	check(p.gear_condition[bow]==100 and p.gear_records[bow].events.back().kind=="repaired","Paid repair restores exact bow and adds history")
	place(p,14,14)
	R.act(w,"local","equip_weapon","none")
	R.act(w,"local","market_sell",bow)
	check(p.buyback.gear_instances.has(bow) and R.Store.valid(w),"Bow sale preserves a valid buyback container")
	R.act(w,"local","market_repurchase",p.buyback_orders[0].token)
	check(p.gear_instances.has(bow) and p.gear_records[bow].events.back().kind=="repurchased","Bow repurchase retains identity and record")
	place(p,7,14)
	R.act(w,"local","enter_home")
	p.room="village"
	place(p,7,14)
	R.act(w,"local","store_item",bow)
	check(w.estate.storage.gear_instances.has(bow),"Bow transfers to house storage")
	R.act(w,"local","take_item",bow)
	check(p.gear_instances.has(bow),"Bow transfers back without new identity")
	var path: String=OS.get_temp_dir()+"/vestige-professions-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path,1800000000),"Professions and bow save with schema nineteen")
	var loaded:=R.load_world(path,true,w.saved+10)
	check(not loaded.is_empty() and JSON.parse_string(JSON.stringify(loaded.people.local.professions))==JSON.parse_string(JSON.stringify(p.professions)) and loaded.people.local.skill_slots==p.skill_slots and loaded.people.local.skill_cooldowns.heavy==0,"Reload preserves paths and prepared skills and processes elapsed cooldowns")
	for key in ["professions","skill_slots","skill_cooldowns"]:
		var bad:=w.duplicate(true)
		bad.people.local[key]={}
		check(not R.Store.valid(bad),"Save rejects malformed "+key)
	var invalid:=w.duplicate(true)
	invalid.people.local.professions.hunter.xp=-1
	check(not R.Store.valid(invalid),"Save rejects negative proficiency")
	invalid=w.duplicate(true)
	invalid.people.local.skill_cooldowns.heavy=INF
	check(not R.Store.valid(invalid),"Save rejects infinite cooldown")
	invalid=w.duplicate(true)
	invalid.people.local.gear_quality[bow].attack=999
	check(not R.Store.valid(invalid),"Save rejects forged bow stats")
	var view:=w.duplicate(true)
	R.born(view,"other","다른 여행자")
	R.Investigation.redact(view,"other")
	check(not view.people.local.has("professions") and not view.people.local.has("skill_slots") and not view.people.local.has("skill_cooldowns"),"Other players cannot inspect private training and slots")
	var legacy:=D.professions()
	legacy.version=18
	legacy.market.stock.erase("wood")
	for key in ["professions","skill_slots","skill_cooldowns","guard_time","shot_time","shot_x","shot_y"]: legacy.people.local.erase(key)
	legacy.wolf.erase("slow")
	var f:=FileAccess.open(path+".old",FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy))
	f.close()
	loaded=R.load_world(path+".old",false)
	check(not loaded.is_empty() and loaded.version==22 and loaded.people.local.professions.warrior.state=="new" and loaded.market.stock.wood==10,"Version eighteen migrates without invented training")
	var motion:=D.professions()
	var mover: Dictionary=motion.people.local
	place(mover,22,10)
	var normal:=motion.duplicate(true)
	motion.wolf.slow=3
	R.tick(motion,0.1)
	R.tick(normal,0.1)
	check(is_equal_approx(25-motion.wolf.x,(25-normal.wolf.x)*0.5),"Slow reduces actual pursuit speed by half")
	var craft:=D.professions()
	var crafter: Dictionary=craft.people.local
	place(crafter,5,8)
	var tiers: Dictionary={}
	for seed in range(1,101):
		var sample:=craft.duplicate(true)
		sample.craft_rng=seed*1234567
		R.act(sample,"local","craft_bow")
		var bp: Dictionary=sample.people.local
		var key:=item(bp,"shortbow")
		tiers[bp.gear_quality[key].tier]=true
		if not R.Store.valid(sample): check(false,"Crafted bow seed remains valid: "+str(seed))
	check(tiers.size()==3,"Bow crafting reaches all three quality tiers with valid bounds")
	crafter.belongings.wood=20
	crafter.belongings.cloth=20
	for i in range(3): R.act(craft,"local","craft_bow")
	var remaining: int=crafter.belongings.wood
	before=craft.craft_rng
	R.act(craft,"local","craft_bow")
	check(crafter.belongings.shortbow==3 and crafter.belongings.wood==remaining and craft.craft_rng==before,"Bow capacity rejects crafting before resource or RNG mutation")
	place(p,7,14)
	R.act(w,"local","enter_home")
	place(p,15,12)
	p.belongings.repair_kit=1
	p.gear_condition[bow]=40
	R.act(w,"local","repair_gear",bow)
	check(p.gear_condition[bow]==80 and p.belongings.repair_kit==0,"Home workbench repairs bow with kit")
	p.room="village"
	place(p,24,10)
	R.act(w,"local","equip_weapon",sword)
	p.attack=0
	p.stamina=100
	p.professions.warrior.xp=995
	w.wolf.hp=100
	R.act(w,"local","attack")
	check(p.professions.warrior.xp==1000 and R.Professions.rank(p,"warrior")=="장인","Actual sword hit reaches profession mastery cap")
	p.attack=0
	R.act(w,"local","attack")
	check(p.professions.warrior.xp==1000,"Additional actual hits cannot exceed mastery cap")
	invalid=w.duplicate(true)
	invalid.people.local.skill_slots=["heavy","heavy"]
	check(not R.Store.valid(invalid),"Save rejects duplicated prepared skill")
	invalid=w.duplicate(true)
	invalid.people.local.professions.warrior.state="new"
	check(not R.Store.valid(invalid),"Save rejects prepared skill that was not learned")
	var life: String=p.life
	R.die(w,"local","늑대와의 전투")
	check(w.remains[life].contents.gear_instances.has(bow) and R.Store.valid(w),"Bow remains at death scene with quality and maker")
	R.born(w,"local","후계자")
	check(w.people.local.professions.warrior.state=="new" and w.people.local.skill_slots==["", ""],"New life does not inherit learned skills")
	for file in [path,path+".old"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(file+ext)
	quit(1 if failures else 0)
