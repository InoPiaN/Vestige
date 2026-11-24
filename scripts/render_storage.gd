extends SceneTree
const Main=preload("res://main.gd")
const Rules=preload("res://world.gd")
func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	var canvas:=SubViewport.new()
	canvas.size=Vector2i(1280,800)
	canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var game:=Main.new()
	canvas.add_child(game)
	game.world=Rules.fresh()
	Rules.born(game.world,"local","린")
	var p: Dictionary=game.world.people.local
	p.x=7
	p.y=14
	p.ore=8
	p.herb=5
	p.sword=3
	Rules.act(game.world,"local","interact")
	Rules.act(game.world,"local","store_item","ore")
	Rules.act(game.world,"local","store_item","herb")
	for id in p.gear_instances.keys():
		if p.gear_instances[id]=="iron_sword":
			Rules.act(game.world,"local","store_item",id)
			break
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.open_storage()
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-storage-preview.png")
	game.open_inventory()
	for id in p.gear_instances:
		if p.gear_instances[id]=="iron_sword":
			game.bag.choose(id)
			break
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("/tmp/vestige-gear-preview.png")
	quit()
