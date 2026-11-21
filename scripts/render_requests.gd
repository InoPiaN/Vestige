extends SceneTree
const R=preload("res://world.gd")
const Q=preload("res://village_requests.gd")
const I=preload("res://items.gd")
var failed:=false
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failed=true
		push_error(text)
func shot(vp: SubViewport,name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-requests-"+name+".png")
func key(game: Node,code: Key) -> void:
	var event:=InputEventKey.new()
	event.physical_keycode=code
	event.pressed=true
	game._unhandled_key_input(event)
func board(p: Dictionary,region: String) -> void:
	p.room=region
	p.x=Q.BOARDS[region].x
	p.y=Q.BOARDS[region].y
func actor(w: Dictionary,p: Dictionary,id: String) -> void:
	var npc:=Q.actor(w,id)
	p.room=Q.JOBS[id].region
	p.x=npc.x
	p.y=npc.y
func select_job(panel: Panel,id: String) -> void:
	for i in range(panel.jobs.item_count):
		if panel.jobs.get_item_metadata(i)==id:
			panel.jobs.select(i)
			panel.jobs.item_selected.emit(i)
func run() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,800)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").requests()
	game.save_path="/tmp/vestige-requests-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	game.set_physics_process(false)
	var w: Dictionary=game.world
	var p: Dictionary=w.people.local
	game.refresh()
	await shot(vp,"harbor-board")
	game.interact()
	check(game.requests.visible and game.requests.current=="herbs","E opens local notice board with matching town request")
	check(game.requests.details.text.contains("은화8") and game.requests.details.text.contains("품질") and game.requests.details.text.contains("필요 1"),"Quantities, quality and reward shown before acceptance")
	await shot(vp,"offer")
	game.requests.accept_button.pressed.emit()
	check(p.requests.herbs.state=="active" and game.requests.accept_button.disabled,"Actual accept button starts contract and disables repeat acceptance")
	var time: float=w.time
	game._physics_process(1.0)
	check(w.time==time,"Single-player request panel pauses world time")
	key(game,KEY_L)
	check(not game.requests.visible,"L closes request panel")
	p.x=1
	p.y=14
	key(game,KEY_L)
	check(game.requests.visible and game.requests.deliver_button.disabled,"L tracks progress remotely but cannot deliver")
	actor(w,p,"herbs")
	game.refresh()
	check(not game.requests.deliver_button.disabled,"Actual Soha location enables delivery")
	await shot(vp,"delivery")
	var gold: int=p.gold
	game.requests.deliver_button.pressed.emit()
	check(p.gold==gold+8 and I.quantity(p,"forest_mushroom")==1,"Delivery button consumes materials and pays exactly once")
	game.requests.deliver_button.pressed.emit()
	check(p.gold==gold+8,"Repeated stale button event cannot repay")
	game.requests.hide()
	board(p,"harbor")
	game.interact()
	select_job(game.requests,"salve")
	check(game.requests.details.text.contains("납품 예정 · 회복 연고 1개"),"Preview identifies ordinary salve before consumption")
	game.requests.accept_button.pressed.emit()
	actor(w,p,"salve")
	game.refresh()
	game.requests.deliver_button.pressed.emit()
	check(p.requests.salve.state=="done" and I.quantity(p,"healing_salve")==0 and I.quantity(p,"healing_salve_great")==1,"Quality preview matches consumed item and preserves great salve")
	await shot(vp,"completed")
	game.open_inventory()
	check(not game.requests.visible and game.bag.visible,"Inventory replaces request panel without overlapping modals")
	game.bag.hide()
	board(p,"village")
	game.refresh()
	await shot(vp,"village-board")
	game.interact()
	check(game.requests.current=="tusk" and not game.requests.accept_button.disabled,"Village board selects local tusk request")
	game.requests.accept_button.pressed.emit()
	actor(w,p,"tusk")
	game.refresh()
	game.requests.deliver_button.pressed.emit()
	check(p.requests.tusk.state=="done" and p.gold==gold+24,"Raon's actual delivery button completes third contract")
	R.advance(w,2880)
	board(p,"harbor")
	game.requests.hide()
	game.interact()
	check(game.requests.current=="herbs" and not game.requests.accept_button.disabled,"Next day UI enables repeat acceptance at board")
	game.requests.accept_button.pressed.emit()
	check(p.requests.herbs.state=="active" and p.requests.herbs.accepted_day==1,"Repeat acceptance starts a new dated contract")
	await shot(vp,"repeat")
	check(R.save_world(w,game.save_path) and R.load_world(game.save_path,false).people.local.requests.herbs.state=="active","UI flow persists active repeated contract")
	for ext in ["",".bak"]: DirAccess.remove_absolute(game.save_path+ext)
	quit(1 if failed else 0)
