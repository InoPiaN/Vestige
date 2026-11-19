extends SceneTree
const R=preload("res://world.gd")
var failed:=false
func _initialize() -> void: call_deferred("render")
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failed=true
		push_error(text)
func shot(vp: SubViewport,name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-travel-"+name+".png")
func render() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,800)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").travel()
	game.save_path="/tmp/vestige-travel-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.set_physics_process(false)
	var p: Dictionary=game.world.people.local
	game.interact()
	check(p.mail_quest=="outbound","Messenger interaction accepts letter")
	var key:=InputEventKey.new()
	key.physical_keycode=KEY_M
	key.pressed=true
	game._unhandled_key_input(key)
	check(game.travel.visible and game.travel.labels[1].text.contains("미발견"),"M opens discovery map")
	await shot(vp,"unknown")
	game.travel.hide()
	p.x=29
	p.y=9
	game.interact()
	check(p.room=="road","Gate interaction enters road")
	check(R.save_world(game.world,game.save_path) and R.load_world(game.save_path,false).people.local.room=="road","Road saves and reloads")
	game.refresh()
	await shot(vp,"road")
	p.x=29
	game.interact()
	check(p.room=="harbor","Road gate enters harbor")
	p.x=12
	p.y=9
	game.interact()
	check(p.mail_quest=="reply","Harbor guide supplies reply")
	check(R.save_world(game.world,game.save_path) and R.load_world(game.save_path,false).people.local.room=="harbor","Harbor saves and reloads")
	game.refresh()
	await shot(vp,"harbor")
	p.x=18
	p.y=10
	game.interact()
	check(game.travel.visible and not game.travel.shops.wood.disabled,"Merchant opens usable shop")
	game.travel.shops.wood.pressed.emit()
	check(p.belongings.wood==1,"Shop button purchases actual item")
	await shot(vp,"shop")
	p.x=5
	p.y=14
	game.refresh()
	check(not game.travel.coach_button.disabled,"Discovered coach route enabled at stop")
	await shot(vp,"map")
	game.travel.coach_button.pressed.emit()
	check(p.room=="village" and p.gold==18,"Coach button charges fare and returns")
	game.travel.hide()
	p.x=3
	p.y=9
	game.interact()
	check(p.mail_quest=="done" and p.gold==30,"Returning letter completes reward through UI")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	quit(1 if failed else 0)
