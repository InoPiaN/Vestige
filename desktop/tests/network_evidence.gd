extends SceneTree
const Main=preload("res://main.gd")
const Rules=preload("res://world.gd")
var game: Node
var stage:=0
var started:=0
var sent:=0
var item:=""
func _initialize() -> void:
	call_deferred("start")
func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):
			var w:=preload("res://investigation_demo.gd").murder()
			var p: Dictionary=w.people.local
			w.people.erase("local")
			w.people["c".repeat(48)]=p
			p.x=16
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
		push_error("Evidence network timeout, stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client": return false
	if game.world.has("cases") or game.world.estate.has("shelf"):
		push_error("Hidden custody leaked")
		quit(1)
		return false
	var p: Dictionary=game.world.people[game.me]
	var objects: Dictionary=p.get("evidence_items",{})
	if stage==0:
		game.command.rpc_id(1,"investigate")
		stage=1
	elif stage==1 and objects.size()==1:
		item=objects.keys()[0]
		stage=2
	elif stage==2:
		var delta:=Vector2(7,14)-Rules.pos(p)
		if delta.length()>0.5: game.movement.rpc_id(1,delta.normalized())
		else:
			game.movement.rpc_id(1,Vector2.ZERO)
			game.command.rpc_id(1,"store_evidence",item)
			sent=Time.get_ticks_msec()
			stage=3
	elif stage==3 and objects.is_empty() and Time.get_ticks_msec()-sent>150:
		game.command.rpc_id(1,"investigate")
		stage=4
	elif stage==4 and objects.size()==1:
		print("PASS: ENet collection, house deposit and recovery preserve one physical object without leaking custody")
		quit()
	return false
