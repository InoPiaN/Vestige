extends SceneTree
const R=preload("res://world.gd")
const Items=preload("res://items.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func place(p: Dictionary,x: float,y: float) -> void:
	p.x=x
	p.y=y
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var w:=R.fresh()
	R.born(w,"local","집주인")
	var p: Dictionary=w.people.local
	R.act(w,"local","enter_home")
	check(not R.Interior.inside(p),"Remote entry rejected")
	place(p,7,14)
	R.act(w,"local","enter_home")
	check(R.Interior.inside(p) and p.gold==4 and p.x==15,"Door purchase and interior entry")
	R.born(w,"visitor","방문자")
	place(w.people.visitor,7,14)
	R.act(w,"visitor","enter_home")
	check(not R.Interior.inside(w.people.visitor),"Living owner's home blocks another resident")
	R.move(w,"local",Vector2.RIGHT,0.2)
	check(p.x>15,"Interior uses actual movement")
	place(p,22,7)
	R.move(w,"local",Vector2.UP,0.2)
	check(p.y==7,"Bed furniture blocks movement")
	p.hp=40
	p.stamina=20
	R.act(w,"local","interact")
	R.act(w,"local","interact")
	check(p.hp==65 and p.stamina==100 and w.time==0,"Bed restores once without skipping shared time")
	place(p,16,6)
	R.act(w,"local","interact")
	place(p,7,15)
	R.act(w,"local","interact")
	check(w.estate.interior.curtain and w.estate.interior.fire,"Curtains and hearth retain toggled state")
	place(p,7,7)
	var initial: Dictionary=w.estate.interior.drawers.duplicate(true)
	p.belongings.cloth=20
	R.act(w,"local","interact")
	check(w.estate.interior.drawers.drawer==initial.drawer,"Full inventory leaves drawer contents intact")
	p.belongings.cloth=0
	var total: int=initial.drawer.cloth+initial.drawer.bent_nail
	for i in range(total+2): R.act(w,"local","interact")
	check(Items.quantity(p,"cloth")+Items.quantity(p,"bent_nail")==total,"Drawer transfers finite randomized contents")
	var events: int=p.events.size()
	R.act(w,"local","interact")
	check(p.events.size()==events,"Empty drawer cannot farm items or journal entries")
	p.herb=2
	R.act(w,"local","store_item","herb")
	check(p.herb==2,"Storage cannot be accessed through distant furniture")
	place(p,22,13)
	R.act(w,"local","store_item","herb")
	check(w.estate.storage.herb==1 and p.herb==1,"Indoor chest uses existing persistent storage")
	place(p,11,7)
	p.events.append("새 집에서 첫날을 보냈다.")
	check(R.act(w,"local","interact").contains("새 집에서 첫날"),"Bookshelf preserves and reads owner's actual journal")
	var view:=w.duplicate(true)
	R.Investigation.redact(view,"local")
	check(view.estate.has("interior") and not view.estate.interior.has("drawers"),"Indoor client sees ambience but not undiscovered loot")
	view=w.duplicate(true)
	R.Investigation.redact(view,"visitor")
	check(not view.estate.has("interior"),"Outdoor client receives no interior contents")
	var path:=OS.get_temp_dir()+"/vestige-interior-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Interior saves")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and R.Interior.inside(loaded.people.local) and loaded.estate.interior.fire and loaded.estate.interior.curtain and loaded.estate.interior.drawers.drawer.cloth==0 and loaded.estate.interior.drawers.drawer.bent_nail==0 and loaded.estate.interior.drawers.cupboard.broken_cup==initial.cupboard.broken_cup and loaded.estate.interior.drawers.cupboard.herb==initial.cupboard.herb,"Reload preserves room, lighting and emptied drawers")
	place(p,15,16)
	R.act(w,"local","interact")
	check(not R.Interior.inside(p) and p.x==7 and p.y==14,"Door returns to walkable village entrance")
	R.act(w,"local","enter_home")
	check(w.estate.interior.drawers.drawer.cloth==0 and w.estate.interior.drawers.drawer.bent_nail==0,"Re-entry does not respawn loot")
	place(p,22,7)
	var hp: int=p.hp
	w.wolf.x=22
	w.wolf.y=7
	R.tick(w,0.1)
	R.act(w,"local","attack")
	check(p.hp==hp and w.wolf.hp==50 and w.wolf.warning==0,"Village enemy cannot target or be attacked through rooms")
	R.die(w,"local","노환")
	var life: String=p.life
	check(w.remains[life].room=="home" and w.cases[life].room=="home","Indoor death preserves room for case and belongings")
	place(w.people.visitor,22,7)
	check(R.Remains.visible(w,w.people.visitor).is_empty(),"Same coordinates outside cannot reveal indoor remains")
	place(w.people.visitor,7,14)
	R.act(w,"visitor","enter_home")
	place(w.people.visitor,22,7)
	check(R.Interior.inside(w.people.visitor) and R.Remains.visible(w,w.people.visitor).has(life),"Visitor discovers dead owner's home and indoor remains")
	var game:=preload("res://main.gd").new()
	root.add_child(game)
	game.world=w
	game.me="visitor"
	game.mode="single"
	game.save_path=path
	place(w.people.visitor,22,13)
	game.interact()
	check(game.chest.visible and not game.chest.remains_mode,"E at interior chest opens storage UI")
	game.chest.hide()
	place(w.people.visitor,11,7)
	game.interact()
	check(game.panel.visible and game.panel_text.text.contains("새 집에서 첫날"),"E at inherited shelf opens surviving journal")
	game.queue_free()
	for ext in ["",".bak"]: DirAccess.remove_absolute(path+ext)
	quit(1 if failures else 0)
