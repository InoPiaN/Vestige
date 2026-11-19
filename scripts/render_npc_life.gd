extends SceneTree
const R=preload("res://world.gd")
const L=preload("res://npc_life.gd")
var failed:=false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failed=true
		push_error(text)
func run() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,800)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").travel()
	game.save_path="/tmp/vestige-npc-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.set_physics_process(false)
	var p: Dictionary=game.world.people.local
	p.room="harbor"
	p.discovered=["village","road","harbor"]
	p.x=15
	p.y=12
	var images: Array[Image]=[]
	for row in [[6.5,"dawn"],[12.0,"day"],[18.5,"sunset"],[23.0,"night"]]:
		game.world.time=fposmod(row[0]-8,24)*120
		game.refresh()
		await process_frame
		await RenderingServer.frame_post_draw
		var img:=vp.get_texture().get_image()
		img.save_png("/tmp/vestige-life-"+row[1]+".png")
		images.append(img.get_region(Rect2i(430,10,420,60)))
		check(is_equal_approx(game.sky_clock.world_time,game.world.time),"Sky receives world time: "+row[1])
	for i in range(1,images.size()):
		check(images[i].get_data()!=images[i-1].get_data(),"Sky pixels differ between phases "+str(i))
	game.world.time=0
	p.x=18
	p.y=10
	game.interact()
	check(game.travel.visible and not game.travel.shops.wood.disabled,"Open merchant enables actual buy button")
	# Simulate a live multiplayer snapshot crossing closing time with modal left open.
	game.world.time=1200
	game.refresh()
	check(game.travel.shops.wood.disabled and game.travel.info.text.contains("귀가 중"),"Open panel refreshes hours and NPC activity when server time changes")
	var gold: int=p.gold
	game.perform("harbor_buy","wood")
	check(p.gold==gold,"Stale purchase command denied after closing")
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-life-schedule.png")
	check(game.sky_clock.get_global_rect().end.y<game.travel.position.y,"Sky remains above map modal")
	game.travel.hide()
	game.world.time=1260
	var npc:=L.state("soha",game.world.time)
	p.x=npc.x
	p.y=npc.y
	game.interact()
	check(not game.travel.visible,"Following off-duty merchant gives dialogue instead of shop")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	quit(1 if failed else 0)
