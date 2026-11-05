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
	game.chosen_look={"hair":2,"hair_color":3,"skin":1,"cloth":1}
	game.open_dressing("create")
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("res://../artifacts/art/character-creation.png")
	game.world=Rules.fresh()
	Rules.born(game.world,"local","린",game.chosen_look)
	game.world.people.local.sword=1
	for value in ["body:leather","head:hood","cloak:traveler","weapon:iron_sword"]: Rules.act(game.world,"local","equip",value)
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.open_dressing("gear")
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("res://../artifacts/art/character-equipment.png")
	game.world.people.local.ore=6
	game.world.people.local.herb=4
	game.world.people.local.hp=65
	game.world.people.local.relic=1
	game.open_inventory()
	game.bag.choose("iron_sword")
	await process_frame
	await RenderingServer.frame_post_draw
	canvas.get_texture().get_image().save_png("res://../artifacts/art/inventory.png")
	print("CUSTOMIZATION_AND_INVENTORY_RENDERED")
	quit()
