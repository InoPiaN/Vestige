extends SceneTree
const R=preload("res://world.gd")
const F=preload("res://foraging.gd")
const I=preload("res://items.gd")
var failures:=0
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failures+=1
		push_error(text)
func at_node(p: Dictionary,id: String) -> void:
	var n: Dictionary=F.NODES[id]
	p.room=n.room
	p.x=n.x
	p.y=n.y
func mentor(w: Dictionary,p: Dictionary) -> void:
	var npc:=F.Life.state("soha",w.time)
	p.room="harbor"
	p.x=npc.x
	p.y=npc.y
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w:=preload("res://investigation_demo.gd").travel()
	var p: Dictionary=w.people.local
	check(F.valid(w) and p.herbal_quest=="new" and p.forage_xp==0,"Fresh world has six ready nodes and personal herbalist progress")
	var safe:=true
	for id in F.NODES:
		at_node(p,id)
		safe=safe and R.Travel.walkable(p,Vector2(p.x,p.y))
	check(safe,"Every resource node is on reachable regional terrain")
	mentor(w,p)
	R.act(w,"local","herbal_quest")
	check(p.herbal_quest=="active","Soha accepts herbalist apprenticeship")
	var gold: int=p.gold
	R.act(w,"local","herbal_quest")
	check(p.gold==gold and p.herbal_quest=="active","Incomplete delivery does not pay or consume materials")
	at_node(p,"mushroom_west")
	p.room="village"
	R.act(w,"local","harvest","mushroom_west")
	check(I.quantity(p,"forest_mushroom")==0,"Matching coordinates in wrong region cannot harvest")
	at_node(p,"mushroom_west")
	p.offline=true
	R.act(w,"local","harvest","mushroom_west")
	check(w.forage_ready.mushroom_west==0,"Offline player cannot consume a node")
	p.offline=false
	p.stamina=5
	R.act(w,"local","interact")
	check(w.forage_ready.mushroom_west==0 and p.forage_xp==0,"Insufficient stamina preserves node and XP")
	p.stamina=100
	R.act(w,"local","interact")
	check(I.quantity(p,"forest_mushroom")==1 and p.stamina==94 and p.forage_xp==5,"E harvest grants item and XP with stamina cost")
	R.act(w,"local","interact")
	check(I.quantity(p,"forest_mushroom")==1 and p.forage_xp==5,"Repeated input cannot harvest depleted node twice")
	R.born(w,"other","다른 채집가")
	var other: Dictionary=w.people.other
	at_node(other,"mushroom_west")
	R.act(w,"other","interact")
	check(I.quantity(other,"forest_mushroom")==0,"Depletion shared between players")
	at_node(p,"flower_west")
	R.act(w,"local","interact")
	check(I.quantity(p,"night_blossom")==0 and w.forage_ready.flower_west==0,"Daytime flower stays closed without depletion")
	check(F.blooming(1440) and not F.blooming(1439.99) and not F.blooming(2520) and F.blooming(2519.99),"Night flower uses exact 20:00 and 05:00 boundaries")
	R.advance(w,1440)
	R.act(w,"local","interact")
	check(I.quantity(p,"night_blossom")==1,"Night opens real flower harvest")
	at_node(p,"reed_bank")
	R.act(w,"local","interact")
	check(I.quantity(p,"harbor_reed")==1,"Harbor supplies distinct reed material")
	mentor(w,p)
	R.act(w,"local","herbal_quest")
	check(p.herbal_quest=="done" and p.gold==gold+8,"Off-duty awake Soha teaches two recipes and pays once")
	check(I.quantity(p,"forest_mushroom")==0 and I.quantity(p,"harbor_reed")==0 and I.quantity(p,"night_blossom")==0,"Delivery consumes exact requested materials")
	R.act(w,"local","herbal_quest")
	check(p.gold==gold+8,"Repeated report cannot duplicate reward")
	for id in ["mushroom_east","reed_pier","flower_east"]:
		at_node(p,id)
		R.act(w,"local","interact")
	check(I.quantity(p,"forest_mushroom")==1 and I.quantity(p,"harbor_reed")==1 and I.quantity(p,"night_blossom")==1,"Remaining nodes supply first crafts without waiting for regrowth")
	at_node(p,"mushroom_west")
	R.advance(w,1439)
	check(not F.reason(w,p,"mushroom_west").is_empty(),"Node stays depleted until its exact regrowth time")
	R.advance(w,1)
	R.act(w,"local","interact")
	check(I.quantity(p,"forest_mushroom")==2,"Node regrows one world day after harvest")
	at_node(p,"reed_bank")
	R.advance(w,1440)
	p.belongings.harbor_reed=20
	var xp: int=p.forage_xp
	var ready: float=w.forage_ready.reed_bank
	R.act(w,"local","interact")
	check(p.forage_xp==xp and w.forage_ready.reed_bank==ready,"Full inventory neither depletes node nor farms XP")
	p.belongings.harbor_reed=19
	p.forage_xp=150
	R.act(w,"local","interact")
	check(p.belongings.harbor_reed==20,"Skilled double yield clamps to remaining capacity")
	p.room="home"
	p.x=15
	p.y=12
	w.estate.owner=p.life
	p.herbal_quest="active"
	var seed: int=w.craft_rng
	R.act(w,"local","craft_home","healing_salve")
	check(I.family_quantity(p,"healing_salve")==0 and w.craft_rng==seed,"Unlearned recipe rejects without consuming RNG or materials")
	R.act(w,"local","plan_save","healing_salve|count|1")
	check(p.craft_plan.is_empty(),"Unlearned recipe cannot be scheduled for offline crafting")
	p.herbal_quest="done"
	var old_xp: int=p.craft_xp.herbalism
	R.act(w,"local","craft_home","healing_salve")
	check(I.family_quantity(p,"healing_salve")==1 and p.craft_xp.herbalism>old_xp,"Learned salve uses existing herbalism mastery and quality system")
	seed=w.craft_rng
	R.act(w,"local","craft_home","vigor_tea")
	check(I.family_quantity(p,"vigor_tea")==0 and w.craft_rng==seed,"Tea requires reusable mug and fire")
	p.belongings.mug=1
	w.estate.interior.fire=true
	R.act(w,"local","craft_home","vigor_tea")
	check(I.family_quantity(p,"vigor_tea")==1 and p.belongings.mug==1,"Tea crafts with flower and herb without consuming mug")
	# Exercise every quality's actual consumption and bounded effect.
	for row in [["healing_salve",60],["healing_salve_fine",66],["healing_salve_great",75]]:
		p.belongings[row[0]]=1
		p.hp=10
		R.act(w,"local","use_crafted",row[0])
		check(p.hp==10+row[1] and I.quantity(p,row[0])==0,"Salve quality effect and single consumption: "+row[0])
	for row in [["vigor_tea",60],["vigor_tea_fine",70],["vigor_tea_great",85]]:
		p.belongings[row[0]]=1
		p.stamina=10
		p.hp=80
		R.act(w,"local","use_crafted",row[0])
		check(p.stamina==10+row[1] and p.hp==80 and I.quantity(p,row[0])==0,"Tea restores only energy: "+row[0])
	p.belongings.vigor_tea=1
	p.stamina=100
	p.hp=20
	R.act(w,"local","use_crafted","vigor_tea")
	check(I.quantity(p,"vigor_tea")==1,"Full energy does not waste tea even when injured")
	p.belongings.healing_salve=9
	p.belongings.healing_salve_great=1
	seed=w.craft_rng
	R.act(w,"local","craft_home","healing_salve")
	check(w.craft_rng==seed,"Combined quality-family cap rejects excess crafting")
	p.x=22
	p.y=13
	R.act(w,"local","store_item","healing_salve_great")
	check(I.quantity(w.estate.storage,"healing_salve_great")==1,"Great-quality new consumable stored without losing quality")
	R.act(w,"local","take_item","healing_salve_great")
	check(I.quantity(p,"healing_salve_great")==1,"New consumable withdrawn intact")
	p.belongings.healing_salve=0
	p.belongings.healing_salve_great=0
	w.estate.storage.belongings.forest_mushroom=2
	w.estate.storage.belongings.harbor_reed=2
	R.act(w,"local","plan_save","healing_salve|count|1|home|home")
	p.hp=100
	p.offline=true
	R.advance(w,2880)
	check(p.craft_plan.remaining==0 and I.family_quantity(w.estate.storage,"healing_salve")==1,"Learned recipe supports offline plan with home supply and output")
	var diary:=JSON.stringify(p.journal)
	check(diary.contains("채집") and diary.contains("조제법") and diary.contains("연고"),"Gathering, learning and production are preserved in daily journal")
	p.offline=false
	p.belongings.healing_salve_great=1
	p.belongings.night_blossom=1
	p.room="road"
	p.x=15
	p.y=7
	var life: String=p.life
	R.die(w,"local","노환")
	R.born(w,"local","새로운 삶")
	p=w.people.local
	p.room="road"
	p.x=15
	p.y=7
	R.act(w,"local","take_remains",life+"|healing_salve_great")
	R.act(w,"local","take_remains",life+"|night_blossom")
	check(I.quantity(p,"healing_salve_great")==1 and I.quantity(p,"night_blossom")==1,"Regional remains preserve flower and great salve for successor")
	check(p.herbal_quest=="new" and p.forage_xp==0,"New life has independent apprenticeship and gathering mastery")
	var path: String="/tmp/vestige-foraging-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"New nodes, items and life history save with schema22")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and loaded.forage_ready==w.forage_ready and I.quantity(loaded.people.local,"healing_salve_great")==1,"Reload preserves depletion and item quality")
	var view:=w.duplicate(true)
	R.Investigation.redact(view,"local")
	check(not view.people.other.has("herbal_quest") and not view.people.other.has("forage_xp"),"Other players' apprenticeship progress stays private")
	for field in ["herbal_quest","forage_xp"]:
		var bad:=w.duplicate(true)
		bad.people.local[field]="invalid"
		check(not R.Store.valid(bad),"Malformed personal foraging state rejected: "+field)
	var bad:=w.duplicate(true)
	bad.forage_ready.mushroom_west=w.time+2881
	check(not R.Store.valid(bad),"Impossible regrowth timestamp rejected")
	var legacy:=w.duplicate(true)
	legacy.version=21
	legacy.erase("forage_ready")
	for actor in legacy.people.values():
		actor.erase("herbal_quest")
		actor.erase("forage_xp")
	var legacy_path:=path+".legacy"
	var file:=FileAccess.open(legacy_path,FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	var migrated:=R.load_world(legacy_path,false)
	check(not migrated.is_empty() and migrated.version==22 and migrated.people.local.herbal_quest=="new" and F.valid(migrated),"Version21 migrates with fresh nodes and unlearned recipes")
	for base in [path,legacy_path]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(base+ext)
	quit(1 if failures else 0)
