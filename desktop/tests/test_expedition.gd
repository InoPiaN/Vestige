extends SceneTree
const R=preload("res://world.gd")
const E=preload("res://expedition.gd")
const D=preload("res://investigation_demo.gd")
var failures:=0
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failures+=1
		push_error(text)
func _initialize() -> void: call_deferred("run")
func at(p: Dictionary,x: float,y: float) -> void:
	p.x=x
	p.y=y
func kill(w: Dictionary,id: String) -> void:
	var p: Dictionary=w.people.local
	var e: Dictionary=w.enemies[id]
	at(p,e.x-1,e.y)
	p.target_enemy=id
	for i in range(20):
		if e.hp<=0: break
		p.attack=0
		p.stamina=100
		R.act(w,"local","attack")
func run() -> void:
	var w:=D.expedition()
	var p: Dictionary=w.people.local
	check(R.Store.valid(w) and w.enemies.size()==2,"New schema has two valid enemies and fresh expedition state")
	R.act(w,"local","expedition","hunter")
	check(p.expeditions.hunter=="new","Remote quest acceptance rejected")
	R.act(w,"local","expedition","warrior")
	check(p.expeditions.warrior=="active","Learned warrior accepts expedition at mentor")
	var coins: int=p.gold
	R.act(w,"local","expedition","warrior")
	check(p.gold==coins,"Unfinished quest grants no money")
	at(p,16,8)
	R.act(w,"local","expedition","hunter")
	check(p.expeditions.hunter=="active","One person accepts both expeditions")
	at(p,25,7)
	var first:=E.selected(w,p)
	R.act(w,"local","cycle_target")
	check(E.selected(w,p)!=first and E.selected(w,p) in E.candidates(w,p),"Tab cycles eligible nearby living enemies")
	p.room="home"
	check(E.selected(w,p).is_empty(),"Indoor coordinates cannot target outdoor enemies")
	p.room="village"
	kill(w,"boar")
	check(w.enemies.boar.hp==0 and p.expeditions.warrior=="ready" and p.gold==coins,"Actual selected enemy kill readies quest without paying report reward")
	check(w.wolf.hp==50 and w.enemies.wraith.hp==75,"Selected enemy damage does not affect other enemies")
	check(w.field_loot.size()==1,"Enemy death creates one persistent loot pile")
	p.attack=0
	R.act(w,"local","attack")
	check(w.field_loot.size()==1,"Repeated attack on dead enemy cannot duplicate loot")
	R.act(w,"local","expedition","warrior")
	check(p.gold==coins,"Remote completion cannot claim reward")
	p.belongings.hide=20
	p.belongings.boar_tusk=20
	R.act(w,"local","take_field_loot")
	check(w.field_loot.size()==1,"Full inventory preserves unclaimed field loot")
	p.belongings.hide=19
	R.act(w,"local","take_field_loot")
	check(p.belongings.hide==20 and w.field_loot.values()[0].contents.hide==1,"Partial pickup respects per-item capacity")
	p.belongings.hide=0
	p.belongings.boar_tusk=0
	R.act(w,"local","take_field_loot")
	check(p.belongings.hide==1 and p.belongings.boar_tusk==1 and w.field_loot.is_empty(),"Remaining loot picked up once with empty pile removed")
	R.act(w,"local","take_field_loot")
	check(p.belongings.boar_tusk==1,"Repeated pickup cannot duplicate items")
	at(p,8,7)
	R.act(w,"local","expedition","warrior")
	check(p.gold==coins+14 and p.expeditions.warrior=="done","Returning to correct mentor pays quest reward")
	R.act(w,"local","expedition","warrior")
	check(p.gold==coins+14,"Reported quest cannot be paid twice")
	kill(w,"wraith")
	R.act(w,"local","take_field_loot")
	check(p.belongings.spectral_ash==2 and p.expeditions.hunter=="ready","Wraith drops sellable ash and records hunter objective")
	at(p,16,8)
	R.act(w,"local","expedition","hunter")
	check(p.gold==coins+30 and p.expeditions.hunter=="done","Second mentor reports independent quest")
	at(p,14,14)
	R.act(w,"local","market_sell","boar_tusk")
	R.act(w,"local","market_sell","spectral_ash")
	check(p.gold==coins+35 and p.belongings.boar_tusk==0 and p.belongings.spectral_ash==1,"Expedition trophies sell through existing market")
	R.advance(w,R.DAY)
	check(w.enemies.boar.hp==95 and w.enemies.wraith.hp==75,"Enemies respawn on world day without resetting quests")
	check(p.journal.back().text.contains("원정 귀환 보고") and p.journal.back().text.contains("원정 전리품"),"Daily diary records expedition and collected loot")
	var fight:=D.expedition()
	var fp: Dictionary=fight.people.local
	at(fp,25,3)
	E.tick(fight,0.1,R.die)
	check(fight.enemies.boar.warning==1 and fp.hp==100,"Boar warns before charge damage")
	var aim: float=fight.enemies.boar.aim_y
	at(fp,25,5)
	E.tick(fight,1.01,R.die)
	check(fp.hp==100 and fight.enemies.boar.aim_y==aim and fight.enemies.boar.cooldown>0,"Sideways movement evades locked charge line")
	fight=D.expedition()
	fp=fight.people.local
	at(fp,25,3)
	E.tick(fight,0.1,R.die)
	E.tick(fight,1.01,R.die)
	check(fp.hp==76 and fight.enemies.boar.x<26,"Boar charge crosses locked segment and applies physical damage")
	fight=D.expedition()
	fp=fight.people.local
	at(fp,26,14)
	E.tick(fight,0.1,R.die)
	check(fight.enemies.wraith.warning==1.2 and fp.hp==100,"Wraith locks visible aim before firing")
	fp.guard_time=2
	E.tick(fight,1.21,R.die)
	check(fp.hp==91,"Guard mitigates new enemy physical projectile")
	var distance:=E.position(fp).distance_to(E.position(fight.enemies.wraith))
	E.tick(fight,0.1,R.die)
	check(E.position(fp).distance_to(E.position(fight.enemies.wraith))>distance,"Wraith retreats from nearby player during recovery")
	fight=D.expedition()
	fp=fight.people.local
	at(fp,26,14)
	E.tick(fight,0.1,R.die)
	fp.dodge=0.4
	E.tick(fight,1.21,R.die)
	check(fp.hp==100,"Active dodge avoids projectile impact")
	fight=D.expedition()
	fp=fight.people.local
	at(fp,25,3)
	E.tick(fight,0.1,R.die)
	at(fp,17,3)
	E.tick(fight,1.01,R.die)
	check(fp.hp==100 and fight.enemies.boar.warning==0,"Returning toward village cancels distant pursuit")
	fight=D.expedition()
	fp=fight.people.local
	at(fp,25,3)
	fp.hp=1
	E.tick(fight,0.1,R.die)
	E.tick(fight,1.01,R.die)
	check(not fp.alive and fight.remains.has(fp.life) and fight.graves.back().cause.contains("들멧돼지"),"New enemy death preserves grave and existing remains rules")
	var lootlife: String=p.life
	p.belongings.boar_tusk=2
	R.die(w,"local","원정 중 사망")
	check(w.remains[lootlife].contents.belongings.boar_tusk==2,"Carried expedition loot becomes recoverable death belongings")
	R.born(w,"local","후계자")
	check(w.people.local.expeditions.warrior=="new","New life does not inherit quest rewards")
	var path: String=OS.get_temp_dir()+"/vestige-expedition-"+str(OS.get_process_id())+".json"
	var save:=D.expedition()
	R.act(save,"local","expedition","warrior")
	kill(save,"boar")
	check(R.save_world(save,path),"Quest progress and ground loot save")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and loaded.people.local.expeditions.warrior=="ready" and loaded.field_loot.size()==1 and loaded.enemies.boar.hp==0,"Reload preserves unreported objective, loot and enemy death")
	for key in ["enemies","field_loot"]:
		var bad:=save.duplicate(true)
		bad[key]=[]
		check(not R.Store.valid(bad),"Malformed expedition save rejected: "+key)
	var bad:=save.duplicate(true)
	bad.enemies.boar.hp=1000
	check(not R.Store.valid(bad),"Enemy HP outside bounds rejected")
	bad=save.duplicate(true)
	bad.field_loot.values()[0].contents.boar_tusk=-1
	check(not R.Store.valid(bad),"Negative field loot rejected")
	bad=save.duplicate(true)
	bad.people.local.target_enemy="fake"
	check(not R.Store.valid(bad),"Unknown target rejected by save validation")
	var view:=save.duplicate(true)
	R.born(view,"other","관찰자")
	R.Investigation.redact(view,"other")
	check(not view.people.local.has("expeditions") and not view.people.local.has("target_enemy"),"Other players do not receive private quest or selection state")
	var old:=D.professions()
	old.version=19
	old.erase("enemies")
	old.erase("field_loot")
	old.people.local.erase("expeditions")
	old.people.local.erase("target_enemy")
	var file:=FileAccess.open(path+".old",FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	loaded=R.load_world(path+".old",false)
	check(not loaded.is_empty() and loaded.version==22 and loaded.people.local.expeditions.warrior=="new" and loaded.enemies.size()==2,"Version nineteen migrates without invented quest progress")
	for name in [path,path+".old"]:
		for suffix in ["",".bak"]: DirAccess.remove_absolute(name+suffix)
	quit(1 if failures else 0)
