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
			var w:=preload("res://investigation_demo.gd").mastery()
			w.craft_rng=685
			var p: Dictionary=w.people.local
			w.people.erase("local")
			w.people["c".repeat(48)]=p
			p.x=15
			p.y=12
			p.belongings.cloth=1
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
		push_error("Mastery network timeout, stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client": return false
	if game.world.has("craft_rng") or game.world.has("cases") or game.world.estate.has("shelf"):
		push_error("Hidden case leaked")
		quit(1)
		return false
	var p: Dictionary=game.world.people[game.me]
	if stage==0:
		game.command.rpc_id(1,"craft_home","bandage")
		sent=Time.get_ticks_msec()
		stage=1
	elif stage==1 and p.craft_xp.herbalism==104 and Time.get_ticks_msec()-sent>150:
		game.command.rpc_id(1,"craft_home","bandage")
		sent=Time.get_ticks_msec()
		stage=2
	elif stage==2 and Time.get_ticks_msec()-sent>300:
		if p.craft_xp.herbalism!=104 or p.herb!=2 or p.belongings.cloth!=0 or p.craft_xp.handicraft!=1000 or not p.events.any(func(e): return e.contains("약초 조제의 견습")):
			push_error("Remote production duplicated XP or lost profession journal")
			quit(1)
		else:
			print("PASS: ENet craft awards one profession, rank and journal; retry without materials gives no XP")
			quit()
	return false
