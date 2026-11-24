extends SceneTree
func _initialize() -> void: call_deferred("render")
func render() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,800)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").trade_repair()
	game.save_path="/tmp/vestige-trade-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.interact()
	var p: Dictionary=game.world.people.local
	var id: String=p.equipped_ids.body
	for i in game.forge.gear.item_count:
		if game.forge.gear.get_item_metadata(i)==id:
			game.forge.gear.select(i)
			game.forge.gear.item_selected.emit(i)
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-forge-repair.png")
	game.forge.repair_button.pressed.emit()
	if p.gear_condition[id]!=100 or p.gold!=72:
		push_error("Paid repair UI failed")
		quit(1)
		return
	game.perform("equip_body","none")
	p.x=14
	p.y=14
	game.open_market()
	for i in game.market.sales.item_count:
		if game.market.sales.get_item_metadata(i)==id:
			game.market.sales.select(i)
			game.market.sales.item_selected.emit(i)
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-armor-sale.png")
	game.market.sell_button.pressed.emit()
	if p.gear_instances.has(id):
		push_error("Sale UI failed")
		quit(1)
		return
	game.market.sale_mode.select(1)
	game.market.sale_mode.item_selected.emit(1)
	game.market.sales.select(0)
	game.market.sales.item_selected.emit(0)
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-gear-buyback.png")
	game.market.sell_button.pressed.emit()
	if not p.gear_instances.has(id) or not p.buyback_orders.is_empty() or p.gold!=72:
		push_error("Buyback UI failed")
		quit(1)
		return
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	print("PASS: Actual UI repairs sells and repurchases same armor with net repair cost only")
	quit()
