extends SceneTree
const R=preload("res://world.gd")
var game: Node
var stage:=0
var started:=0
var sent:=0
var bow:=""
func _initialize() -> void: call_deferred("start")
func start() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):
			var w:=preload("res://investigation_demo.gd").professions()
			var p: Dictionary=w.people.local
			p.x=5
			p.y=8
			R.act(w,"local","interact")
			R.act(w,"local","craft_bow")
			p.x=8
			p.y=7
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
	game.multiplayer.connected_to_server.connect(func(): game.register_player.rpc_id(1,"c".repeat(48),"여행자"))
	started=Time.get_ticks_msec()
func send(kind: String,value: String="") -> void:
	game.command.rpc_id(1,kind,value)
	sent=Time.get_ticks_msec()
	stage+=1
func _process(_dt: float) -> bool:
	if game==null: return false
	if Time.get_ticks_msec()-started>30000:
		push_error("Professions ENet timeout at stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client" or Time.get_ticks_msec()-sent<200: return false
	if game.world.has("cases") or game.world.has("craft_rng"):
		push_error("Hidden state leaked")
		quit(1)
		return false
	var p: Dictionary=game.world.people[game.me]
	if stage==0:
		var delta:=Vector2(8,7)-Vector2(p.x,p.y)
		game.movement.rpc_id(1,delta.normalized())
		if delta.length()<0.3:
			game.movement.rpc_id(1,Vector2.ZERO)
			send("lesson","warrior")
	elif stage==1 and p.professions.warrior.state=="active": send("lesson","warrior")
	elif stage==2 and p.professions.warrior.state=="learned":
		for id in p.gear_instances:
			if p.gear_instances[id]=="shortbow": bow=id
		send("equip_weapon",bow)
	elif stage==3 and p.equipped_ids.get("weapon")==bow:
		var delta:=Vector2(16,8)-Vector2(p.x,p.y)
		game.movement.rpc_id(1,delta.normalized())
		if delta.length()<0.4:
			game.movement.rpc_id(1,Vector2.ZERO)
			send("lesson","hunter")
	elif stage==4 and p.professions.hunter.state=="active": send("lesson","hunter")
	elif stage==5 and p.professions.hunter.state=="learned": send("skill_slot","0|aim")
	elif stage==6 and p.skill_slots[0]=="aim": send("skill_slot","1|slow")
	elif stage==7 and p.skill_slots[1]=="slow":
		var delta:=Vector2(20,10)-Vector2(p.x,p.y)
		game.movement.rpc_id(1,delta.normalized())
		if delta.length()<0.4:
			game.movement.rpc_id(1,Vector2.ZERO)
			send("use_skill","0")
	elif stage==8 and p.professions.hunter.xp==5:
		if p.gear_condition[bow]!=95 or p.skill_cooldowns.aim<=0 or game.world.wolf.hp>=50:
			push_error("Server bow damage / wear / cooldown mismatch")
			quit(1)
		else:
			print("PASS: ENet two mentor tasks, bow equipment, slot selection and authoritative shot")
			quit()
	return false
