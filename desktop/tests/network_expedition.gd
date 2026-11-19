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
			var w:=preload("res://investigation_demo.gd").expedition()
			var p: Dictionary=w.people.local
			for id in p.gear_instances:
				if p.gear_instances[id]=="shortbow": R.act(w,"local","equip_weapon",id)
			p.policy="train"
			p.target_enemy="boar"
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
	if Time.get_ticks_msec()-started>65000:
		push_error("Expedition ENet timeout at stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client" or Time.get_ticks_msec()-sent<220: return false
	var p: Dictionary=game.world.people[game.me]
	if not p.alive:
		push_error("Expedition network test character died")
		quit(1)
		return false
	if game.world.has("cases") or game.world.has("craft_rng"):
		push_error("Hidden state leaked")
		quit(1)
		return false
	if stage==0 and walk(p,Vector2(8,7)):
		initial_gold=p.gold
		command("expedition","warrior")
		stage=1
	elif stage==1 and p.expeditions.warrior=="active":
		var targets: Array[Vector2]=[Vector2(17,7),Vector2(23,3)]
		if walk(p,targets[waypoint]):
			waypoint+=1
			if waypoint==2:
				command("cycle_target")
				stage=2
	elif stage==2 and p.target_enemy=="wolf":
		command("cycle_target")
		stage=3
	elif stage==3 and p.target_enemy=="boar":
		if p.expeditions.warrior=="ready": stage=4
		elif Time.get_ticks_msec()-sent>800:
			command("heal" if p.hp<55 else "attack")
	elif stage==4 and not game.world.field_loot.is_empty():
		var loot: Dictionary=game.world.field_loot.values()[0]
		if walk(p,Vector2(loot.x,loot.y)):
			command("take_field_loot")
			waypoint=0
			stage=5
	elif stage==5 and p.belongings.get("boar_tusk",0)>0:
		var targets: Array[Vector2]=[Vector2(17,7),Vector2(8,7)]
		if walk(p,targets[waypoint]):
			waypoint+=1
			if waypoint==2:
				command("expedition","warrior")
				stage=6
	elif stage==6 and p.expeditions.warrior=="done":
		if p.gold!=initial_gold+14 or p.belongings.boar_tusk!=1 or not game.world.field_loot.is_empty():
			push_error("Server expedition reward or loot mismatch")
			quit(1)
		else:
			print("PASS: ENet acceptance, real travel, target switching, combat, loot and return reward")
			quit()
	return false
