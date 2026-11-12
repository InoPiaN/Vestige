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
	check(R.Plan.valid(p) and p.craft_plan.is_empty(),"New character has no implicit plan")
	for bad in ["invalid|count|2","bandage|all|2","bandage|count|0","bandage|count|11","bandage|count|2.5","bandage"]: R.act(w,"local","plan_start",bad)
	check(p.craft_plan.is_empty() and not p.offline,"Malformed requests cannot start or mutate a plan")
	R.act(w,"local","plan_save","bandage|count|3")
	check(p.policy=="plan" and not p.offline and p.craft_plan.remaining==3,"Save selects plan without entrusting control")
	R.advance(w,R.DAY)
	check(I.family_quantity(p,"bandage")==0 and p.craft_plan.remaining==3,"Active character does not gain offline production")
	R.act(w,"local","leave")
	R.advance(w,R.DAY)
	check(I.family_quantity(p,"bandage")==1 and p.craft_plan.remaining==2 and p.belongings.cloth==4 and p.herb==2,"One day makes exactly one product and consumes real materials")
	check(p.craft_xp.herbalism==8 and p.journal.back().text.contains("약초 조제 경험치"),"Offline product awards mastery and journal")
	R.act(w,"local","plan_start","bandage|count|3")
	check(p.craft_plan.remaining==2,"Re-saving same plan preserves remaining count")
	R.advance(w,R.DAY*4)
	check(I.family_quantity(p,"bandage")==3 and p.craft_plan.remaining==0 and p.craft_xp.herbalism==24,"Catch-up stops at requested quantity and then rests")
	p.herb=5
	p.belongings.cloth=5
	R.act(w,"local","plan_start","bandage|count|3")
	R.advance(w,R.DAY)
	check(I.family_quantity(p,"bandage")==3,"Completed count plan is not rearmed by relog-style re-save")
	R.act(w,"local","plan_start","bandage|target|4")
	R.advance(w,R.DAY*2)
	check(I.family_quantity(p,"bandage")==4 and p.craft_plan.status=="목표 소지 수량 충족","Target mode counts all qualities and pauses at target")
	R.act(w,"local","resume")
	p.hp=30
	R.act(w,"local","use_crafted",I.best(p,"bandage"))
	R.act(w,"local","leave")
	R.advance(w,R.DAY)
	check(I.family_quantity(p,"bandage")==4,"Target resumes after product is used")
	R.act(w,"local","plan_start","repair_kit|count|2")
	p.hp=20
	var xp: int=p.craft_xp.handicraft
	var seed: int=w.craft_rng
	R.advance(w,R.DAY)
	check(p.hp==45 and p.craft_plan.remaining==2 and p.craft_xp.handicraft==xp and w.craft_rng==seed and p.journal.back().text.contains("회복"),"Poor health prioritizes recovery without consuming progress or RNG")
	p.belongings.bent_nail=0
	R.advance(w,R.DAY)
	check(p.craft_plan.remaining==2 and p.craft_plan.status.contains("부족") and w.craft_rng==seed,"Missing materials pause with reason and no RNG")
	p.belongings.bent_nail=4
	var owner: String=w.estate.owner
	w.estate.owner=""
	R.advance(w,R.DAY)
	check(p.craft_plan.status.contains("소유") and p.craft_plan.remaining==2,"Home crafting requires own house")
	w.estate.owner=owner
	R.advance(w,R.DAY)
	check(I.family_quantity(p,"repair_kit")==1 and p.room=="home","Restored conditions resume home production")
	R.act(w,"local","plan_start","herbal_tea|count|2")
	p.belongings.mug=0
	p.belongings.mug_fine=0
	p.belongings.mug_great=0
	p.herb=5
	R.advance(w,R.DAY)
	check(p.craft_plan.status.contains("찻잔") and p.herb==5,"Tea requires reusable cup")
	p.belongings.mug_great=1
	w.estate.interior.fire=false
	R.advance(w,R.DAY)
	check(p.craft_plan.status.contains("불") and p.herb==5,"Tea requires lit hearth without automatically lighting it")
	w.estate.interior.fire=true
	R.advance(w,R.DAY)
	check(I.family_quantity(p,"herbal_tea")==1 and p.herb==4 and p.belongings.mug_great==1,"Tea consumes herb but retains cup")
	# Manual and planned production share quality and mastery rules.
	var active:=preload("res://investigation_demo.gd").plan()
	active.craft_rng=685
	var offline:=active.duplicate(true)
	R.act(active,"local","craft_home","bandage")
	R.act(offline,"local","plan_start","bandage|count|1")
	R.advance(offline,R.DAY)
	check(active.craft_rng==offline.craft_rng and I.quantity(active.people.local,"bandage_great")==I.quantity(offline.people.local,"bandage_great") and active.people.local.craft_xp.herbalism==offline.people.local.craft_xp.herbalism,"Manual and planned production share exact quality and XP")
	R.act(w,"local","plan_start","iron_sword|count|2")
	p.ore=4
	var swords: int=p.sword
	R.advance(w,R.DAY*2)
	check(p.sword==swords+2 and p.ore==0 and p.craft_plan.remaining==0 and p.room=="village","Sword plans use forge and exact requested count")
	var path:=OS.get_temp_dir()+"/vestige-plan-"+str(OS.get_process_id())+".json"
	R.act(w,"local","plan_start","herbal_tea|count|2")
	check(R.save_world(w,path,1800000000.0),"Plan saves with current progress")
	var copy:=R.load_world(path,true,float(w.saved)+R.DAY)
	check(not copy.is_empty() and copy.people.local.craft_plan.remaining==1,"Offline load processes one elapsed day")
	var herbs: int=copy.people.local.herb
	copy=R.load_world(path,true,float(w.saved)+R.DAY)
	check(copy.people.local.craft_plan.remaining==1 and copy.people.local.herb==herbs,"Second load at same timestamp does not duplicate production")
	var bad:=w.duplicate(true)
	bad.people.local.craft_plan.remaining=99
	check(not R.Store.valid(bad),"Invalid plan counters rejected")
	var old:=w.duplicate(true)
	old.version=10
	old.people.local.policy="work"
	old.people.local.erase("craft_plan")
	var file:=FileAccess.open(path+".old",FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var migrated:=R.load_world(path+".old",false)
	check(not migrated.is_empty() and migrated.version==16 and migrated.people.local.craft_plan.is_empty() and migrated.people.local.policy=="work","Legacy work policy remains unchanged without invented plan")
	R.act(w,"local","plan_cancel")
	check(p.craft_plan.is_empty() and p.policy=="rest","Cancel removes plan and chooses rest")
	R.act(w,"local","plan_start","bandage|count|1")
	R.die(w,"local","노환")
	R.born(w,"local","후계자")
	check(w.people.local.craft_plan.is_empty(),"Successor does not inherit production instructions")
	for entry in [path,path+".old"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(entry+ext)
	quit(1 if failures else 0)
