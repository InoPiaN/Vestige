extends SceneTree
const R=preload("res://world.gd")
var failed:=false
func _initialize() -> void: call_deferred("render")
func check(ok: bool,text: String) -> void:
	if not ok:
		failed=true
		push_error(text)
	else: print("PASS: ",text)
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
	game.world=preload("res://investigation_demo.gd").professions()
	game.save_path="/tmp/vestige-prof-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.interact()
	var p: Dictionary=game.world.people.local
	check(game.professions.visible,"E opens nearby warrior mentor")
	game.professions.lesson_button.pressed.emit()
	check(p.professions.warrior.state=="active","Mentor button accepts initiation task")
	p.x=5
	p.y=8
	game.open_forge()
	game.forge.craft_button.pressed.emit()
	game.forge.bow_button.pressed.emit()
	check(p.belongings.get("shortbow",0)==1,"Forge button crafts bow")
	await shot(vp,"professions-forge")
	p.x=8
	p.y=7
	game.open_professions("warrior")
	game.professions.lesson_button.pressed.emit()
	check(p.professions.warrior.state=="learned","Mentor button completes warrior training")
	await shot(vp,"professions-warrior")
	game.open_dressing("gear")
	var picker: OptionButton=game.gear_pickers.weapon
	var bow:=""
	for i in picker.item_count:
		var id: String=picker.get_item_metadata(i)
		if p.gear_instances.get(id)=="shortbow":
			bow=id
			picker.select(i)
			picker.item_selected.emit(i)
	check(not bow.is_empty() and p.equipped_ids.weapon==bow,"Equipment picker equips crafted bow")
	await shot(vp,"professions-equipment")
	p.x=16
	p.y=8
	game.open_professions("hunter")
	game.professions.lesson_button.pressed.emit()
	game.professions.lesson_button.pressed.emit()
	check(p.professions.hunter.state=="learned","Mentor buttons complete hunter training")
	for slot in range(2):
		var choose: OptionButton=game.professions.slots[slot]
		for i in choose.item_count:
			if choose.get_item_metadata(i)==("aim" if slot==0 else "slow"):
				choose.select(i)
				choose.item_selected.emit(i)
	check(p.skill_slots==["aim","slow"],"Both slot selectors prepare learned skills")
	await shot(vp,"professions-hunter")
	game.professions.hide()
	game.set_physics_process(false)
	p.x=20
	p.y=10
	var key:=InputEventKey.new()
	key.pressed=true
	key.physical_keycode=KEY_1
	game._unhandled_key_input(key)
	game.refresh()
	check(game.world.wolf.hp<50 and p.skill_cooldowns.aim==4,"Number key casts prepared skill")
	await shot(vp,"professions-combat")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	quit(1 if failed else 0)
