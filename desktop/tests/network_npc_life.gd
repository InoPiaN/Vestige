extends SceneTree
const R=preload("res://world.gd")
var game: Node
var stage:=0
var waypoint:=0
var started:=0
var sent:=0
var initial_gold:=0
func _initialize() -> void: call_deferred("start")
func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):
			var w:=preload("res://investigation_demo.gd").travel()
			var p: Dictionary=w.people.local
			p.policy="rest"
			p.room="harbor"
			p.x=18
			p.y=10
			w.time=1190
			w.people.erase("local")
			w.people["c".repeat(48)]=p
			quit(0 if R.save_world(w,arg.trim_prefix("--fixture=")) else 1)
			return
	game=preload("res://main.gd").new()
	game.name="Vestige"
	root.add_child(game)
	game.set_physics_process(false)
	game.mode="connecting"
	var peer:=ENetMultiplayerPeer.new()
	if peer.create_client("127.0.0.1",27180)!=OK:
		quit(1)
		return
	game.multiplayer.multiplayer_peer=peer
	game.multiplayer.connected_to_server.connect(func(): game.register_player.rpc_id(1,"c".repeat(48),"원정자"))
	started=Time.get_ticks_msec()
func command(kind: String,value: String="") -> void:
	game.command.rpc_id(1,kind,value)
	sent=Time.get_ticks_msec()
func walk(p: Dictionary,to: Vector2) -> bool:
	var delta:=to-Vector2(p.x,p.y)
	game.movement.rpc_id(1,delta.normalized() if delta.length()>0.25 else Vector2.ZERO)
	return delta.length()<=0.25
func _process(_dt: float) -> bool:
	if game==null: return false
	if Time.get_ticks_msec()-started>35000:
		push_error("NPC life ENet timeout at stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client" or Time.get_ticks_msec()-sent<220: return false
	var p: Dictionary=game.world.people[game.me]
	if not p.alive:
		push_error("NPC life network test character died")
		quit(1)
		return false
	if game.world.has("cases") or game.world.has("craft_rng") or game.world.has("npc_activity"):
		push_error("Hidden state leaked")
		quit(1)
		return false
	if stage==0 and walk(p,Vector2(18,10)):
		initial_gold=p.gold
		command("harbor_buy","wood")
		stage=1
	elif stage==1 and p.belongings.get("wood",0)==1:
		game.open_travel()
		stage=2
	elif stage==2 and game.world.time>1203:
		if not game.travel.shops.wood.disabled or game.sky_clock.world_time!=game.world.time:
			push_error("Client sky or shop hours out of sync")
			quit(1)
		command("harbor_buy","wood")
		stage=3
	elif stage==3:
		if p.gold!=initial_gold-2 or p.belongings.wood!=1:
			push_error("Closed shop accepted stale client request")
			quit(1)
		var npc:=R.Travel.Life.state("soha",game.world.time)
		if walk(p,Vector2(npc.x,npc.y)):
			command("interact")
			stage=4
	elif stage==4:
		if not game.travel.feedback.text.contains("귀가 중"):
			push_error("Moving NPC dialogue not resolved at server position")
			quit(1)
		else:
			print("PASS: ENet sky time, moving NPC, opening purchase, closing UI and stale request rejection")
			quit()
	return false
