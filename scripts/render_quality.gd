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
	game.world=preload("res://investigation_demo.gd").quality()
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.open_inventory()
	for id in game.world.people.local.gear_instances:
		if game.world.people.local.gear_quality[id].tier=="great": game.bag.choose(id)
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-quality-preview.png")
	quit()
