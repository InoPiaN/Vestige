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
			p.policy="train"
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
	if Time.get_ticks_msec()-started>100000:
		push_error("Travel ENet timeout at stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client" or Time.get_ticks_msec()-sent<220: return false
	var p: Dictionary=game.world.people[game.me]
	if not p.alive:
		push_error("Travel network test character died")
		quit(1)
		return false
	if game.world.has("cases") or game.world.has("craft_rng"):
		push_error("Hidden state leaked")
		quit(1)
		return false
	if stage==0 and walk(p,Vector2(3,9)):
		initial_gold=p.gold
		command("interact")
		stage=1
	elif stage==1 and p.mail_quest=="outbound":
		var targets: Array[Vector2]=[Vector2(17,9),Vector2(21,7),Vector2(29,7),Vector2(29,9)]
		if walk(p,targets[waypoint]):
			waypoint+=1
			if waypoint==4:
				command("interact")
				stage=2
	elif stage==2 and p.room=="road" and walk(p,Vector2(29,9)):
		command("interact")
		stage=3
	elif stage==3 and p.room=="harbor" and walk(p,Vector2(12,9)):
		command("interact")
		stage=4
	elif stage==4 and p.mail_quest=="reply" and walk(p,Vector2(5,14)):
		command("coach")
		stage=5
	elif stage==5 and p.room=="village" and walk(p,Vector2(3,9)):
		command("interact")
		stage=6
	elif stage==6 and p.mail_quest=="done":
		if p.gold!=initial_gold+7 or p.discovered.size()!=3:
			push_error("Travel server reward or discovery mismatch")
			quit(1)
		else:
			print("PASS: ENet letter, real road movement, harbor discovery, coach fare and return reward")
			quit()
	return false
