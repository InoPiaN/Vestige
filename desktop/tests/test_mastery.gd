extends SceneTree
const R=preload("res://world.gd")
const M=preload("res://craft_mastery.gd")
const Items=preload("res://items.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var w:=preload("res://investigation_demo.gd").craft()
	var p: Dictionary=w.people.local
	check(M.valid(p) and M.xp(p,"smithing")==0 and M.xp(p,"herbalism")==0,"New life starts with three independent beginner professions")
	for i in range(4):
		p.craft_xp.herbalism=M.THRESHOLDS[i]
		var rates:=M.rates(p,"herbalism")
		check(M.stage(p,"herbalism")==i and rates==M.RATES[i] and rates.common+rates.fine+rates.great==100,"Approved probability tier "+M.STAGES[i])
	p.craft_xp.herbalism=96
	var before_seed: int=w.craft_rng
	var control:=w.duplicate(true)
	var expected:=R.Quality.roll(control,0,M.rates(p,"herbalism"))
	var msg:=R.act(w,"local","craft_home","bandage")
	var output: String="bandage"+("" if expected.tier=="common" else "_"+expected.tier)
	check(p.craft_xp.herbalism==104 and p.craft_xp.handicraft==0 and p.craft_xp.smithing==0,"Successful bandage only awards herbalism once")
	check(Items.quantity(p,output)==1 and w.craft_rng==control.craft_rng,"Level-up craft uses pre-award probability and normal RNG consumption")
	check(msg.contains("견습 달성") and p.events.any(func(e): return e.contains("약초 조제의 견습")),"Rank change feedback and pending diary record")
	check(M.gain(p,"bandage")==4,"Easy recipe experience diminishes after becoming apprentice")
	var xp: int=p.craft_xp.herbalism
	p.belongings.cloth=0
	before_seed=w.craft_rng
	R.act(w,"local","craft_home","bandage")
	R.act(w,"local","craft_home","fake")
	check(p.craft_xp.herbalism==xp and w.craft_rng==before_seed,"Missing materials and invalid recipes award neither XP nor RNG")
	p.belongings.cloth=10
	p.belongings.bandage=10
	R.act(w,"local","craft_home","bandage")
	check(p.craft_xp.herbalism==xp,"Full output family capacity blocks experience")
	p.belongings.bandage=0
	p.x=7
	R.act(w,"local","craft_home","bandage")
	check(p.craft_xp.herbalism==xp,"Remote crafting cannot grant experience")
	p.x=15
	p.craft_xp.handicraft=999
	R.act(w,"local","craft_home","repair_kit")
	check(p.craft_xp.handicraft==1000 and M.gain(p,"repair_kit")==0,"Master rank caps experience without overflow")
	var sword: String=""
	for id in p.gear_instances:
		if p.gear_instances[id]=="iron_sword": sword=id
	var smith_xp: int=p.craft_xp.smithing
	R.act(w,"local","repair_gear",sword)
	check(p.craft_xp.smithing==smith_xp and p.craft_xp.handicraft==1000,"Repair does not farm production XP")
	p.craft_xp.herbalism=1000
	p.belongings.mug_great=1
	var rates:=M.rates(p,"herbalism",5)
	check(rates.common==40 and rates.fine==30 and rates.great==30,"Great cup adds 5 points to master great chance, deducted from common")
	# Verify actual tea roll matches the displayed profession and cup probabilities.
	p.herb=2
	w.estate.interior.fire=true
	control=w.duplicate(true)
	expected=R.Quality.roll(control,0,rates)
	R.act(w,"local","craft_home","herbal_tea")
	output="herbal_tea"+("" if expected.tier=="common" else "_"+expected.tier)
	check(Items.quantity(p,output)==1 and p.craft_xp.herbalism==1000,"Actual tea uses mastery and cup rates at cap")
	var direct:=R.fresh()
	R.born(direct,"local","장인 후보")
	var worker: Dictionary=direct.people.local
	worker.x=5
	worker.y=8
	worker.ore=2
	worker.craft_xp.smithing=96
	direct.craft_rng=100
	var offline:=direct.duplicate(true)
	offline.people.local.offline=true
	offline.people.local.policy="work"
	R.act(direct,"local","interact")
	R.advance(offline,R.DAY)
	check(worker.craft_xp.smithing==108 and offline.people.local.craft_xp.smithing==108 and direct.craft_rng==offline.craft_rng,"Offline and active forging give identical XP and quality RNG")
	check(offline.people.local.journal[0].text.contains("대장 기술의 견습"),"Offline rank increase enters the daily diary")
	R.advance(offline,R.DAY)
	check(offline.people.local.craft_xp.smithing==108,"Offline work without materials grants no XP")
	var path:=OS.get_temp_dir()+"/vestige-mastery-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Profession state saves")
	var copy:=R.load_world(path,false)
	check(not copy.is_empty() and copy.people.local.craft_xp.herbalism==1000 and copy.people.local.craft_xp.handicraft==1000,"Reload preserves exact profession progression")
	var old:=w.duplicate(true)
	old.version=9
	old.people.local.erase("craft_xp")
	old.people.local.skill=17
	var file:=FileAccess.open(path+".old",FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var migrated:=R.load_world(path+".old",false)
	check(not migrated.is_empty() and migrated.version==11 and migrated.people.local.skill==17 and migrated.people.local.craft_xp.smithing==0,"Legacy generic skill preserved without inventing profession history")
	for value in [-1,0.5,1001,"invalid"]:
		var invalid:=w.duplicate(true)
		invalid.people.local.craft_xp.herbalism=value
		check(not R.Store.valid(invalid),"Malformed XP rejected: "+str(value))
	var snapshot:=w.duplicate(true)
	R.born(snapshot,"other","장인")
	R.Investigation.redact(snapshot,"local")
	check(snapshot.people.local.has("craft_xp") and not snapshot.people.other.has("craft_xp"),"Only own profession details exposed in multiplayer snapshot")
	R.advance(w,R.DAY)
	check(p.journal[0].text.contains("약초 조제의 견습"),"Active rank change becomes a daily diary page")
	R.die(w,"local","노환")
	R.born(w,"local","후계자")
	check(M.xp(w.people.local,"herbalism")==0 and w.books.back().pages[0].text.contains("약초 조제의 견습"),"Successor begins anew while deceased artisan diary remains")
	for entry in [path,path+".old"]:
		for ext in ["",".bak"]: DirAccess.remove_absolute(entry+ext)
	quit(1 if failures else 0)
