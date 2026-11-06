extends SceneTree
const Main=preload("res://main.gd")
const Rules=preload("res://world.gd")
var game: Node
var requested:=false
var started:=0
func _initialize() -> void:
	call_deferred("start")
func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):
			var w:=preload("res://investigation_demo.gd").create()
			var traveler: Dictionary=w.people.local
			w.people.erase("local")
			w.people["c".repeat(48)]=traveler
			traveler.x=7
			traveler.y=14
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
	game.multiplayer.connected_to_server.connect(func(): game.register_player.rpc_id(1,"c".repeat(48),"여행자"))
	started=Time.get_ticks_msec()
func _process(_dt: float) -> bool:
	if game==null: return false
	if Time.get_ticks_msec()-started>12000:
		push_error("Timed out waiting for investigation snapshot")
		quit(1)
		return false
	if game.mode!="client": return false
	if game.world.has("cases") or game.world.estate.has("shelf") or not game.world.books.is_empty() or not game.world.visible_traces.is_empty():
		push_error("Remote client received undiscovered evidence")
		quit(1)
		return false
	if not requested:
		var pos:=Rules.pos(game.world.people[game.me])
		var door:=Vector2(7,14)
		if pos.distance_to(door)>0.5:
			game.movement.rpc_id(1,(door-pos).normalized())
			return false
		game.movement.rpc_id(1,Vector2.ZERO)
		requested=true
		game.command.rpc_id(1,"investigate")
		return false
	if not game.world.people[game.me].notebook.is_empty():
		if not game.panel_text.text.contains("예배당"):
			push_error("Shelf text did not reach investigator")
			quit(1)
		else:
			print("PASS: ENet client opens shelf by proximity while remote truth stays hidden")
			quit()
	return false
