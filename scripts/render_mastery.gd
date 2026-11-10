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
	game.world=preload("res://investigation_demo.gd").mastery()
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.open_crafting()
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-mastery-preview.png")
	game.save_path="/tmp/vestige-mastery-ui-"+str(OS.get_process_id())+".json"
	game.bench.craft_button.pressed.emit()
	if game.world.people.local.craft_xp.herbalism!=104 or not game.bench.description.text.contains("양품 23%"):
		push_error("Crafting UI did not refresh mastery after production")
		quit(1)
		return
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-mastery-after.png")
	game.bench.hide()
	game.world.people.local.room="village"
	game.world.people.local.x=5
	game.world.people.local.y=8
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-mastery-forge.png")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	print("PASS: Craft button updates mastery and displayed probability")
	quit()
