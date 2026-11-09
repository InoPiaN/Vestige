extends SceneTree
const Main=preload("res://main.gd")
const Rules=preload("res://world.gd")
var game: Node
var stage:=0
var started:=0
var sent:=0
var item:=""
var cache:=""
func _initialize() -> void:
	call_deferred("start")
func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):
			var w:=preload("res://investigation_demo.gd").remains()
			var p: Dictionary=w.people.local
			w.people.erase("local")
			w.people["c".repeat(48)]=p
			p.x=15
			p.y=13
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
	if Time.get_ticks_msec()-started>15000:
		push_error("Storage network timeout, stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client": return false
	if game.world.has("cases") or game.world.estate.has("shelf"):
		push_error("Hidden case leaked")
		quit(1)
		return false
	var p: Dictionary=game.world.people[game.me]
	if stage==0:
		if game.world.remains.is_empty():
			game.movement.rpc_id(1,(Vector2(16,13)-Rules.pos(p)).normalized())
			return false
		game.movement.rpc_id(1,Vector2.ZERO)
		cache=game.world.remains.keys()[0]
		var box: Dictionary=game.world.remains[cache].contents
		for id in box.gear_instances:
			if box.gear_instances[id]=="iron_sword": item=id
		if item.is_empty():
			push_error("No inherited sword")
			quit(1)
			return false
		game.command.rpc_id(1,"take_remains",cache+"|"+item)
		stage=1
	elif stage==1 and p.gear_instances.has(item):
		if game.world.remains[cache].contents.gear_instances.has(item):
			push_error("Duplicated inherited gear")
			quit(1)
			return false
		sent=Time.get_ticks_msec()
		stage=2
	elif stage==2 and Time.get_ticks_msec()-sent>150:
		game.command.rpc_id(1,"take_remains",cache+"|"+item)
		sent=Time.get_ticks_msec()
		stage=3
	elif stage==3 and Time.get_ticks_msec()-sent>250:
		if p.sword!=1:
			push_error("Repeated recovery changed quantity")
			quit(1)
		else:
			print("PASS: ENet death cache recovery preserves one exact sword across repeated requests")
			quit()
	return false
