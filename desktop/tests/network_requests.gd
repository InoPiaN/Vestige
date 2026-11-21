extends SceneTree
const R=preload("res://world.gd")
const I=preload("res://items.gd")
var game: Node
var stage:=0
var started:=0
var sent:=0
var observer:=false
func _initialize() -> void: call_deferred("start")
func start() -> void:
	observer="--observer" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):
			var w:=preload("res://investigation_demo.gd").requests()
			var p: Dictionary=w.people.local
			w.people.erase("local")
			w.people["c".repeat(48)]=p
			R.born(w,"b".repeat(48),"함께 온 심부름꾼")
			var other: Dictionary=w.people["b".repeat(48)]
			other.room="harbor"
			other.x=15
			other.y=14
			other.gold=25
			other.belongings.forest_mushroom=2
			other.belongings.harbor_reed=2
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
	game.multiplayer.connected_to_server.connect(func(): game.register_player.rpc_id(1,("b" if observer else "c").repeat(48),"약초길"))
	started=Time.get_ticks_msec()
func command(kind: String,value: String="") -> void:
	game.command.rpc_id(1,kind,value)
	sent=Time.get_ticks_msec()
func walk(p: Dictionary,to: Vector2) -> bool:
	var delta:=to-Vector2(p.x,p.y)
	game.movement.rpc_id(1,delta.normalized() if delta.length()>0.25 else Vector2.ZERO)
	return delta.length()<=0.25
func fail(text: String) -> void:
	push_error(text)
	quit(1)
func _process(_dt: float) -> bool:
	if game==null: return false
	if Time.get_ticks_msec()-started>100000:
		fail("Requests network timeout stage "+str(stage))
		return false
	if game.mode!="client" or Time.get_ticks_msec()-sent<250: return false
	var p: Dictionary=game.world.people[game.me]
	if game.world.has("craft_rng") or game.world.has("npc_activity"):
		fail("Hidden state leaked")
		return false
	for id in game.world.people:
		if id!=game.me and game.world.people[id].has("requests"):
			fail("Other player's requests leaked")
			return false
	if stage==0:
		command("request_accept","herbs")
		stage=1
	elif stage==1 and p.requests.herbs.state=="active":
		var npc:=R.Travel.Life.state("soha",game.world.time)
		if walk(p,Vector2(npc.x,npc.y)):
			command("request_deliver","herbs")
			stage=2
	elif stage==2 and p.requests.herbs.state=="done":
		command("request_deliver","herbs")
		stage=3
	elif stage==3:
		if p.gold!=33 or I.quantity(p,"forest_mushroom")!=1 or I.quantity(p,"harbor_reed")!=1:
			fail("Personal delivery reward or duplicate protection mismatch")
			return false
		if observer:
			print("PASS: ENet second client independently accepts and delivers; private progress and duplicate protection")
			quit()
		elif walk(p,Vector2(15,14)):
			command("request_accept","salve")
			stage=4
	elif stage==4 and p.requests.salve.state=="active":
		var npc:=R.Travel.Life.state("doyun",game.world.time)
			# Use the resident's actual server time location.
		if walk(p,Vector2(npc.x,npc.y)):
			command("request_deliver","salve")
			stage=5
	elif stage==5 and p.requests.salve.state=="done":
		if p.gold!=43 or I.quantity(p,"healing_salve")!=0 or I.quantity(p,"healing_salve_great")!=1:
			fail("Quality selection or salve reward mismatch")
		else:
			print("PASS: ENet board acceptance, resident delivery, exact rewards and great quality preservation")
			quit()
	return false
