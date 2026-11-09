extends SceneTree
const Main=preload("res://main.gd")
func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	var canvas:=SubViewport.new()
	canvas.size=Vector2i(1280,800)
	canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var game:=Main.new()
	canvas.add_child(game)
	game.world=preload("res://investigation_demo.gd").remains()
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.open_storage(true)
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-remains-preview.png")
	quit()
