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
	game.world=preload("res://investigation_demo.gd").supply()
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.open_crafting()
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-supply-preview.png")
	game.save_path="/tmp/vestige-supply-ui-"+str(OS.get_process_id())+".json"
	game.bench.craft_button.pressed.emit()
	if preload("res://items.gd").family_quantity(game.world.estate.storage,"bandage")!=1:
		push_error("Craft button did not place output in chest")
		quit(1)
		return
	game.open_planner()
	game.planner.source_picker.select(1)
	game.planner.destination_picker.select(1)
	game.planner.start_button.pressed.emit()
	preload("res://world.gd").advance(game.world,2880)
	game.open_planner()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-supply-plan.png")
	if game.world.people.local.craft_plan.remaining!=2 or preload("res://items.gd").family_quantity(game.world.estate.storage,"bandage")!=2:
		push_error("Plan UI did not preserve chest settings")
		quit(1)
		return
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	print("PASS: Direct and plan UI use selected chest routing")
	quit()
