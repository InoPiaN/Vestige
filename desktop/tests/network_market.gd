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
			var w:=preload("res://investigation_demo.gd").market()
			w.craft_rng=685
			var p: Dictionary=w.people.local
			w.people.erase("local")
			w.people["c".repeat(48)]=p
			p.x=14
			p.y=15
			p.belongings.bandage_great=1
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
		push_error("Market network timeout, stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client": return false
	if game.world.has("craft_rng") or game.world.has("cases") or game.world.estate.has("shelf"):
		push_error("Hidden case leaked")
		quit(1)
		return false
	var p: Dictionary=game.world.people[game.me]
	if stage==0:
		game.command.rpc_id(1,"market_buy","cloth")
		sent=Time.get_ticks_msec()
		stage=1
	elif stage==1 and p.gold==27 and Time.get_ticks_msec()-sent>150:
		if game.world.market.stock.cloth!=7:
			push_error("Stock not decremented")
			quit(1)
		game.command.rpc_id(1,"market_sell","bandage_great")
		sent=Time.get_ticks_msec()
		stage=2
	elif stage==2 and p.gold==32 and Time.get_ticks_msec()-sent>150:
		game.command.rpc_id(1,"market_sell","bandage_great")
		sent=Time.get_ticks_msec()
		stage=3
	elif stage==3 and Time.get_ticks_msec()-sent>300:
		if p.gold!=32 or p.belongings.get("bandage_great",0)!=0 or game.world.market.stock.cloth!=7:
			push_error("Market duplicated sale or lost stock")
			quit(1)
		else:
			print("PASS: ENet purchase, quality sale and repeated-sale rejection preserve authoritative wallet and stock")
			quit()
	return false
