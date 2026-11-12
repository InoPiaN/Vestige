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
	var w:=preload("res://investigation_demo.gd").plan()
	var p: Dictionary=w.people.local
	p.ore=12
	p.belongings.hide=8
	p.belongings.cloth=10
	p.herb=0
	R.act(w,"local","plan_save","0|bandage|target|3|bag|bag")
	R.act(w,"local","plan_save","1|iron_armor|count|2|bag|bag")
	R.act(w,"local","plan_start","2|leather|count|1|bag|bag")
	check(R.Plan.plans(p).size()==3 and p.offline,"Three independent plans accepted")
	var before:=JSON.stringify(p)
	for value in ["3|mug|count|1|bag|bag","-1|mug|count|1|bag|bag","1|iron_armor|count|1|home|bag"]: R.act(w,"local","plan_save",value)
	check(JSON.stringify(p)==before,"Fourth plan and unsupported armor supply rejected atomically")
	R.advance(w,R.DAY)
	check(I.quantity(p,"iron_armor")==1 and I.quantity(p,"leather")==1 and p.craft_queue[0].remaining==1,"Blocked first plan skips to armor and only one item per day")
	check(p.craft_plan.status.contains("부족") and p.craft_queue[1].status=="우선순위 대기","Blocked and waiting statuses are distinct")
	check(p.journal.back().text.contains("피해 감소") and p.journal.back().text.contains("부족"),"Journal records armor result and blocked reason")
	R.act(w,"local","plan_pause","1")
	R.advance(w,R.DAY)
	check(I.quantity(p,"leather")==2 and I.quantity(p,"iron_armor")==1 and p.craft_queue[0].paused,"Paused armor skipped while next plan completes")
	R.act(w,"local","plan_up","1")
	check(p.craft_plan.recipe=="iron_armor" and p.craft_plan.remaining==1 and p.craft_plan.paused,"Reorder preserves pause and remaining progress")
	R.act(w,"local","plan_save","0|iron_armor|count|2|bag|bag")
	check(p.craft_plan.remaining==1 and p.craft_plan.paused,"Resave does not restart or unpause")
	R.act(w,"local","plan_pause","0")
	p.hp=20
	var seed: int=w.craft_rng
	R.advance(w,R.DAY)
	check(p.hp==45 and p.ore==6 and w.craft_rng==seed,"Recovery prevents every queued craft")
	R.advance(w,R.DAY)
	check(p.ore==0 and I.quantity(p,"iron_armor")==2 and p.craft_plan.remaining==0,"Resumed plan finishes its original count")
	p.herb=4
	R.advance(w,R.DAY)
	check(I.family_quantity(p,"bandage")==1,"Completed first plan yields to target plan")
	R.act(w,"local","plan_delete","0")
	check(p.craft_plan.recipe=="bandage" and p.craft_queue.size()==1,"Deleting first plan promotes next without losing progress")
	var path: String=OS.get_temp_dir()+"/vestige-queue-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path,1800000000.0),"Queue saves with schema sixteen")
	var copy:=R.load_world(path,true,1800000000.0+R.DAY*2)
	check(not copy.is_empty() and I.family_quantity(copy.people.local,"bandage")==3,"Catch-up performs one eligible craft per elapsed day")
	var again:=R.load_world(path,true,1800000000.0+R.DAY*2)
	check(I.family_quantity(again.people.local,"bandage")==3,"Repeated load does not duplicate catch-up")
	var bad:=w.duplicate(true)
	bad.people.local.craft_queue[0].remaining=999
	check(not R.Store.valid(bad),"Invalid secondary plan rejected")
	bad=w.duplicate(true)
	bad.people.local.craft_queue=[42]
	check(not R.Store.valid(bad),"Non-dictionary queue entry safely rejected")
	bad=w.duplicate(true)
	bad.people.local.craft_queue[0].erase("source")
	check(not R.Store.valid(bad),"Current saves require routing on every queued plan")
	var private_world:=w.duplicate(true)
	R.born(private_world,"observer","다른 인물")
	R.Investigation.redact(private_world,"observer")
	check(not private_world.people.local.has("craft_queue") and not private_world.people.local.has("craft_plan"),"Other players cannot inspect queued plans")
	var legacy:=w.duplicate(true)
	legacy.version=15
	legacy.people.local.erase("craft_queue")
	legacy.people.local.craft_plan.erase("paused")
	var f:=FileAccess.open(path+".old",FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy))
	f.close()
	var migrated:=R.load_world(path+".old",false)
	check(not migrated.is_empty() and migrated.version==17 and migrated.people.local.craft_queue.is_empty() and migrated.people.local.craft_plan.amount==3,"Version fifteen preserves single plan as first priority")
	R.act(w,"local","plan_cancel")
	check(R.Plan.plans(p).is_empty() and p.policy=="rest","Cancel clears all instructions")
	# Compare the shared armor quality and mastery path; catch-up dates stay per-day.
	var active:=preload("res://investigation_demo.gd").plan()
	var a: Dictionary=active.people.local
	a.room="village"
	a.x=5.0
	a.y=8.0
	a.ore=12
	a.belongings.hide=2
	a.belongings.cloth=4
	var off:=active.duplicate(true)
	R.ArmorCraft.craft(active,a,"iron_armor")
	R.act(off,"local","plan_start","iron_armor|count|2")
	R.advance(off,R.DAY)
	check(active.craft_rng==off.craft_rng and a.craft_xp==off.people.local.craft_xp,"Offline armor matches direct quality RNG and mastery")
	R.advance(off,R.DAY)
	var dates: Array=[]
	for id in off.people.local.gear_records:
		if off.people.local.gear_instances[id]=="iron_armor": dates.append(off.people.local.gear_records[id].maker.day)
	check(dates==[1,2],"Armor provenance retains separate catch-up production days")
	for file in [path,path+".old"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(file+ext)
	quit(1 if failures else 0)
