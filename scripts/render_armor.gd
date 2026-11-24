extends SceneTree
func _initialize() -> void: call_deferred("render")
func render() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,800)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").armor()
	game.save_path="/tmp/vestige-armor-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.interact()
	game.perform("armor_menu")
	game.armor_bench.recipes.select(1)
	game.armor_bench.recipes.item_selected.emit(1)
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-armor-crafting.png")
	var p: Dictionary=game.world.people.local
	var before: int=p.belongings.iron_armor
	game.armor_bench.craft_button.pressed.emit()
	if p.belongings.iron_armor!=before+1:
		push_error("Armor UI craft failed")
		quit(1)
		return
	game.open_dressing("gear")
	var picker: OptionButton=game.gear_pickers.body
	var index:=picker.item_count-1
	var id: String=picker.get_item_metadata(index)
	picker.select(index)
	picker.item_selected.emit(index)
	picker.item_selected.emit(index)
	if p.equipped_ids.get("body")!=id:
		push_error("Exact armor selection failed")
		quit(1)
		return
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-armor-equipment.png")
	game.gear_record_button.pressed.emit()
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-armor-record.png")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	print("PASS: Armor UI craft exact repeat equip and record viewing")
	quit()
