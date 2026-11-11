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
	game.world=preload("res://investigation_demo.gd").legacy()
	game.save_path="/tmp/vestige-legacy-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.open_dressing("gear")
	var picker: OptionButton=game.gear_pickers.weapon
	picker.select(3)
	picker.item_selected.emit(3)
	var id: String=picker.get_item_metadata(3)
	picker.item_selected.emit(3)
	if game.world.people.local.equipped_ids.get("weapon")!=id:
		push_error("Equipment picker failed exact selection")
		quit(1)
		return
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-legacy-equipment.png")
	game.gear_record_button.pressed.emit()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-legacy-record.png")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	print("PASS: Equipment UI selects exact sword idempotently and opens its history")
	quit()
