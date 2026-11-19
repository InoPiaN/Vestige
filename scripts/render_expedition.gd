extends SceneTree
const R=preload("res://world.gd")
var failed:=false
func _initialize() -> void: call_deferred("render")
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failed=true
		push_error(text)
func shot(vp: SubViewport,name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-"+name+".png")
func render() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,800)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").expedition()
	game.save_path="/tmp/vestige-exp-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.set_physics_process(false)
	var p: Dictionary=game.world.people.local
	game.interact()
	game.professions.quest_button.pressed.emit()
	check(p.expeditions.warrior=="active","Mentor UI accepts expedition")
	await shot(vp,"expedition-quest")
	game.professions.hide()
	p.x=25
	p.y=7
	var before:=R.Expedition.selected(game.world,p)
	game.policy.grab_focus()
	var tab:=InputEventKey.new()
	tab.physical_keycode=KEY_TAB
	tab.pressed=true
	game._input(tab)
	check(R.Expedition.selected(game.world,p)!=before,"Target key works even when sidebar control has focus")
	p.x=25
	p.y=3
	p.target_enemy="boar"
	R.Expedition.tick(game.world,0.1,R.die)
	game.refresh()
	await shot(vp,"expedition-boar")
	check(game.target_hud.text.contains("들멧돼지"),"HUD identifies selected enemy")
	for i in range(10):
		if game.world.enemies.boar.hp<=0: break
		p.attack=0
		p.stamina=100
		game.perform("attack")
	check(p.expeditions.warrior=="ready" and game.world.field_loot.size()==1,"Combat progresses accepted quest and drops loot")
	game.refresh()
	await shot(vp,"expedition-loot")
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_R
	key.pressed=true
	game._unhandled_key_input(key)
	check(p.belongings.boar_tusk==1 and game.world.field_loot.is_empty(),"R key collects dropped items")
	p.x=8
	p.y=7
	game.open_professions("warrior")
	var coins: int=p.gold
	game.professions.quest_button.pressed.emit()
	check(p.expeditions.warrior=="done" and p.gold==coins+14,"Actual report button pays once at mentor")
	await shot(vp,"expedition-report")
	game.professions.hide()
	p.x=26
	p.y=14
	p.target_enemy="wraith"
	R.Expedition.tick(game.world,0.1,R.die)
	game.refresh()
	await shot(vp,"expedition-wraith")
	check(game.world.enemies.wraith.warning>0,"Ranged enemy shows locked attack warning")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	quit(1 if failed else 0)
