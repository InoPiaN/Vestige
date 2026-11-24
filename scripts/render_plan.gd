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
	game.world=preload("res://investigation_demo.gd").plan()
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.open_planner()
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-plan-preview.png")
	game.save_path="/tmp/vestige-plan-ui-"+str(OS.get_process_id())+".json"
	game.planner.start_button.pressed.emit()
	if not game.world.people.local.offline or game.world.people.local.craft_plan.remaining!=3:
		push_error("Plan UI did not start selected plan")
		quit(1)
		return
	preload("res://world.gd").advance(game.world,2880)
	game.open_planner()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-plan-after.png")
	if game.world.people.local.craft_plan.remaining!=2 or not game.planner.status.text.contains("남은 제작 2 / 3"):
		push_error("Plan UI did not refresh remaining count")
		quit(1)
		return
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	print("PASS: Plan UI starts work and displays saved progress after one day")
	quit()
