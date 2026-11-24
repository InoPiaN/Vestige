extends SceneTree
func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	var canvas:=SubViewport.new()
	canvas.size=Vector2i(1280,800)
	canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var game:=preload("res://main.gd").new()
	canvas.add_child(game)
	game.world=preload("res://investigation_demo.gd").upgrade()
	game.save_path="/tmp/vestige-upgrade-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.interact()
	if not game.forge.visible:
		push_error("E did not open forge")
		quit(1)
		return
	var id: String=game.forge.sword
	game.forge.upgrade_button.pressed.emit()
	if game.world.people.local.gear_quality[id].upgrade!=1:
		push_error("Forge upgrade button failed")
		quit(1)
		return
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-upgrade-forge.png")
	var count: int=game.world.people.local.sword
	game.forge.craft_button.pressed.emit()
	if game.world.people.local.sword!=count+1:
		push_error("Forge production button failed")
		quit(1)
		return
	game.perform("equip_weapon",id)
	game.open_dressing("gear")
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-upgrade-equipment.png")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	print("PASS: Forge UI opens from interaction and crafts upgrades and equips real sword")
	quit()
