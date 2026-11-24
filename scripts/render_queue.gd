extends SceneTree
func _initialize() -> void: call_deferred("render")
func render() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,800)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").queue()
	game.save_path="/tmp/vestige-queue-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.open_planner()
	var panel=game.planner
	var p: Dictionary=game.world.people.local
	for i in range(3):
		panel.plan_picker.select(i)
		panel.plan_picker.item_selected.emit(i)
		panel.recipes.select(panel.P.RECIPES.find(["bandage","iron_armor","leather"][i]))
		panel.recipes.item_selected.emit(panel.recipes.selected)
		panel.amount.get_line_edit().text="2" if i!=2 else "1"
		panel.save_button.pressed.emit()
	if game.Rules.Plan.plans(p).size()!=3:
		push_error("UI did not save three plans")
		quit(1)
		return
	panel.plan_picker.select(1)
	panel.plan_picker.item_selected.emit(1)
	panel.manage_buttons[2].pressed.emit()
	panel.manage_buttons[0].pressed.emit()
	if p.craft_plan.recipe!="iron_armor" or not p.craft_plan.paused or panel.selected_plan!=0:
		push_error("UI pause/reorder failed")
		quit(1)
		return
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-queue-planner.png")
	panel.manage_buttons[2].pressed.emit()
	panel.start_button.pressed.emit()
	if not p.offline or panel.visible:
		push_error("UI did not entrust control")
		quit(1)
		return
	game.Rules.advance(game.world,game.Rules.DAY)
	game.open_planner()
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-queue-results.png")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	print("PASS: Queue UI adds three plans pauses reorders and entrusts control")
	quit()
