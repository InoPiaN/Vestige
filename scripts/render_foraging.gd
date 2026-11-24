extends SceneTree
const R=preload("res://world.gd")
const F=preload("res://foraging.gd")
const I=preload("res://items.gd")
var failed:=false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failed=true
		push_error(text)
func shot(vp: SubViewport,name: String) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	var img:=vp.get_texture().get_image()
	img.save_png("/tmp/vestige-foraging-"+name+".png")
	return img
func at_node(p: Dictionary,id: String) -> void:
	var n: Dictionary=F.NODES[id]
	p.room=n.room
	p.x=n.x
	p.y=n.y
func great_seed() -> int:
	for seed in range(1,1000):
		var probe: Dictionary={"craft_rng":seed}
		if R.Quality.roll(probe).tier=="great": return seed
	return 1
func run() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,800)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").foraging()
	game.save_path="/tmp/vestige-foraging-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.set_physics_process(false)
	var w: Dictionary=game.world
	var p: Dictionary=w.people.local
	game.open_travel()
	check(not game.travel.quest_button.disabled,"Off-duty awake mentor enables apprenticeship button")
	game.travel.quest_button.pressed.emit()
	check(p.herbal_quest=="active" and game.travel.quest_button.text.contains("납품"),"Actual quest button accepts and displays requirements")
	await shot(vp,"quest")
	game.travel.hide()
	at_node(p,"flower_west")
	game.refresh()
	var closed:=await shot(vp,"closed")
	game.interact()
	check(I.quantity(p,"night_blossom")==0,"Daytime E input cannot collect closed flower")
	R.advance(w,40)
	game.refresh()
	var blooming:=await shot(vp,"bloom")
	check(closed.get_region(Rect2i(480,280,48,48)).get_data()!=blooming.get_region(Rect2i(480,280,48,48)).get_data(),"Flower pixels visibly open at night")
	game.interact()
	check(I.quantity(p,"night_blossom")==1,"Night E interaction collects flower")
	for id in ["mushroom_west","reed_bank"]:
		at_node(p,id)
		game.interact()
	game.refresh()
	await shot(vp,"reed")
	var npc:=F.Life.state("soha",w.time)
	p.room="harbor"
	p.x=npc.x
	p.y=npc.y
	game.open_travel()
	game.travel.quest_button.pressed.emit()
	check(p.herbal_quest=="done" and game.travel.quest_button.disabled,"Delivery button learns recipes and cannot claim twice")
	game.travel.hide()
	for id in ["flower_east","mushroom_east","reed_pier"]:
		at_node(p,id)
		game.interact()
	p.room="village"
	p.x=7
	p.y=13
	game.interact()
	check(p.room=="home" and w.estate.owner==p.life,"Travel proceeds into owned home for crafting")
	p.x=15
	p.y=12
	game.interact()
	for i in range(game.bench.recipes.item_count):
		if game.bench.recipes.get_item_metadata(i)=="healing_salve":
			game.bench.recipes.select(i)
			game.bench.recipes.item_selected.emit(i)
	check(game.bench.visible and not game.bench.craft_button.disabled,"Learned salve is selectable and craftable at workbench")
	w.craft_rng=great_seed()
	game.bench.craft_button.pressed.emit()
	check(I.quantity(p,"healing_salve_great")==1,"Craft button produces actual great-quality salve")
	await shot(vp,"salve")
	game.bench.hide()
	p.x=7
	p.y=15
	game.interact()
	check(R.save_world(w,game.save_path),"Lighting fireplace from reachable tile saves valid state")
	p.x=15
	p.y=12
	game.interact()
	game.bench.current="vigor_tea"
	game.bench.refresh(w,p)
	w.craft_rng=great_seed()
	game.bench.craft_button.pressed.emit()
	check(I.quantity(p,"vigor_tea_great")==1,"Lit fireplace and mug enable actual great-quality tea")
	game.bench.hide()
	p.hp=20
	p.stamina=10
	game.open_inventory()
	game.bag.selected="healing_salve_great"
	game.bag.refresh(p)
	await shot(vp,"inventory")
	game.bag.use_button.pressed.emit()
	check(p.hp==95 and I.quantity(p,"healing_salve_great")==0,"Inventory use consumes salve and applies quality healing")
	game.bag.selected="vigor_tea_great"
	game.bag.refresh(p)
	game.bag.use_button.pressed.emit()
	check(p.stamina==95 and I.quantity(p,"vigor_tea_great")==0,"Inventory use consumes tea and restores energy")
	check(R.save_world(w,game.save_path) and not R.load_world(game.save_path,false).is_empty(),"Complete UI journey persists valid world")
	# Expanded item catalog must not silently hide entries past the old 42 slots.
	for id in I.CATALOG:
		if not I.CATALOG[id].has("slot"): R.Storage.change(p,id,1)
	for id in ["iron_sword","shortbow","leather","iron_armor"]:
		R.Storage.change(p,id,I.CATALOG[id].limit-I.quantity(p,id))
	R.Storage.reconcile(p)
	game.bag.refresh(p)
	var rows:=I.entries(p)
	check(rows.size()>42 and game.bag.slots.size()>=rows.size(),"Expanded inventory grows beyond 42 visible entries")
	var last: String=rows[-1].id
	game.bag.slots[rows.size()-1].pressed.emit()
	check(game.bag.selected==last,"Last item beyond old slot count remains selectable")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	quit(1 if failed else 0)
