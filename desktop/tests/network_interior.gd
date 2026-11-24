extends SceneTree
const Main=preload("res://main.gd")
const Rules=preload("res://world.gd")
var game: Node
var stage:=0
var started:=0
var sent:=0
var item:=""
var cache:=""
var waypoint:=0
var requests:=0
var collected:=0
const PATH=[Vector2(9,16),Vector2(9,7),Vector2(7,7)]
func _initialize() -> void:
	call_deferred("start")
func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):
			var w:=preload("res://investigation_demo.gd").home()
			var p: Dictionary=w.people.local
			w.people.erase("local")
			w.people["c".repeat(48)]=p
			p.room="village"
			p.x=7
			p.y=14
			quit(0 if Rules.save_world(w,arg.trim_prefix("--fixture=")) else 1)
			return
	game=Main.new()
	game.name="Vestige"
	root.add_child(game)
	game.mode="connecting"
	var peer:=ENetMultiplayerPeer.new()
	if peer.create_client("127.0.0.1",27180)!=OK:
		quit(1)
		return
	game.multiplayer.multiplayer_peer=peer
	game.multiplayer.connected_to_server.connect(func(): game.register_player.rpc_id(1,"c".repeat(48),"조사자"))
	started=Time.get_ticks_msec()
func _process(_dt: float) -> bool:
	if game==null: return false
	if Time.get_ticks_msec()-started>30000:
		push_error("Interior network timeout, stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client": return false
	if game.world.has("cases") or game.world.estate.has("shelf"):
		push_error("Hidden case leaked")
		quit(1)
		return false
	var p: Dictionary=game.world.people[game.me]
	if game.world.estate.get("interior",{}).has("drawers"):
		push_error("Unsearched drawer contents leaked")
		quit(1)
		return false
	if stage==0:
		var delta:=Vector2(7,14)-Rules.pos(p)
		if delta.length()>0.4:
			game.movement.rpc_id(1,delta.normalized())
			return false
		game.movement.rpc_id(1,Vector2.ZERO)
		game.command.rpc_id(1,"enter_home")
		stage=1
	elif stage==1 and Rules.Interior.inside(p):
		var delta: Vector2=PATH[waypoint]-Rules.pos(p)
		if delta.length()>0.25:
			game.movement.rpc_id(1,delta.normalized())
			return false
		waypoint+=1
		if waypoint==PATH.size():
			game.movement.rpc_id(1,Vector2.ZERO)
			stage=2
	elif stage==2 and Time.get_ticks_msec()-sent>200:
		game.command.rpc_id(1,"interact")
		sent=Time.get_ticks_msec()
		requests+=1
		if requests>=8: stage=3
	elif stage==3 and Time.get_ticks_msec()-sent>250:
		collected=int(p.belongings.get("cloth",0))+int(p.belongings.get("bent_nail",0))
		if collected<1 or collected>6 or not game.notice.text.contains("먼지만"):
			push_error("Drawer did not reach a finite empty state")
			quit(1)
			return false
		game.command.rpc_id(1,"interact")
		sent=Time.get_ticks_msec()
		stage=4
	elif stage==4 and Time.get_ticks_msec()-sent>250:
		if int(p.belongings.get("cloth",0))+int(p.belongings.get("bent_nail",0))!=collected:
			push_error("Empty drawer produced duplicate loot")
			quit(1)
		else:
			print("PASS: ENet enter home, navigate furniture, search finite drawer and repeat without duplication or hidden loot disclosure")
			quit()
	return false
