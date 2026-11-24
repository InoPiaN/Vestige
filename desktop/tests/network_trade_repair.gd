extends SceneTree
const Main=preload("res://main.gd")
const Rules=preload("res://world.gd")
var game: Node
var stage:=0
var waypoint:=0
var started:=0
var sent:=0
var item:=""
var cache:=""
func _initialize() -> void:
	call_deferred("start")
func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):
			var w:=preload("res://investigation_demo.gd").trade_repair()
			var p: Dictionary=w.people.local
			p.policy="work"
			w.people.erase("local")
			w.people["c".repeat(48)]=p
			quit(0 if Rules.save_world(w,arg.trim_prefix("--fixture=")) else 1)
			return
	game=Main.new()
	game.name="Vestige"
	root.add_child(game)
	game.set_physics_process(false)
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
		push_error("Trade network timeout, stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client": return false
	if game.world.has("craft_rng") or game.world.has("cases") or game.world.estate.has("shelf"):
		push_error("Hidden case leaked")
		quit(1)
		return false
	var p: Dictionary=game.world.people[game.me]
	if stage==0:
		item=p.equipped_ids.body
		game.command.rpc_id(1,"forge_repair",item+"|35|8")
		sent=Time.get_ticks_msec()
		stage=1
	elif stage==1 and p.gear_condition[item]==100 and Time.get_ticks_msec()-sent>150:
		if p.gold!=72 or p.gear_quality[item].upgrade!=1 or p.gear_records[item].events.back().kind!="repaired":
			push_error("Network repair stats/history mismatch")
			quit(1)
			return false
		# Move with the real movement RPC to the market, staying in the village.
		stage=2
	elif stage==2:
		var targets: Array[Vector2]=[Vector2(5,15),Vector2(14,15),Vector2(14,14)]
		var delta: Vector2=targets[waypoint]-Vector2(p.x,p.y)
		game.movement.rpc_id(1,delta.normalized())
		if delta.length()<0.3 and waypoint<2:
			waypoint+=1
		elif delta.length()<0.5 and waypoint==2:
			game.movement.rpc_id(1,Vector2.ZERO)
			game.command.rpc_id(1,"equip_body","none")
			sent=Time.get_ticks_msec()
			stage=3
	elif stage==3 and Time.get_ticks_msec()-sent>200:
		game.command.rpc_id(1,"market_sell",item)
		sent=Time.get_ticks_msec()
		stage=4
	elif stage==4 and not p.gear_instances.has(item) and Time.get_ticks_msec()-sent>200:
		game.command.rpc_id(1,"market_repurchase",p.buyback_orders[0].token)
		stage=5
	elif stage==5 and p.gear_instances.has(item):
		if p.gold!=72 or not p.buyback_orders.is_empty() or p.gear_records[item].events.back().kind!="repurchased":
			push_error("Network repurchase mismatch")
			quit(1)
		else:
			print("PASS: ENet repair sale and repurchase preserve identity costs and history")
			quit()
	return false
