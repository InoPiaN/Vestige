extends SceneTree
func _initialize() -> void: call_deferred("render")
func render() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,800)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").armor_upgrade()
	game.save_path="/tmp/vestige-armor-up-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.interact()
	var p: Dictionary=game.world.people.local
	var id:=""
	for i in game.forge.gear.item_count:
		var key: String=game.forge.gear.get_item_metadata(i)
		if p.gear_instances[key]=="iron_armor":
			id=key
			game.forge.gear.select(i)
			game.forge.gear.item_selected.emit(i)
			break
	game.forge.upgrade_button.pressed.emit()
	if id.is_empty() or p.gear_quality[id].upgrade!=1:
		push_error("Armor upgrade UI failed")
		quit(1)
		return
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-armor-upgrade-forge.png")
	game.forge.upgrade_button.pressed.emit()
	game.forge.upgrade_button.pressed.emit()
	game.perform("equip_body",id)
	game.open_dressing("gear")
	if game.Rules.Armor.defense(p)!=p.gear_quality[id].defense+3:
		push_error("Armor upgrade equip failed")
		quit(1)
		return
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-armor-upgrade-equipment.png")
	game.gear_record_button.pressed.emit()
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-armor-upgrade-record.png")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	print("PASS: Actual armor upgrade UI selects crafts enhancement equips and displays history")
	quit()
