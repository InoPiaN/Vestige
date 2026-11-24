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
			var w:=preload("res://investigation_demo.gd").foraging()
			w.time=1440
			var p: Dictionary=w.people.local
			p.room="road"
			p.x=15
			p.y=7
			p.hp=20
			p.herbal_quest="active"
			p.belongings.forest_mushroom=2
			p.belongings.harbor_reed=2
			w.estate.owner=p.life
			w.people.erase("local")
			w.people["c".repeat(48)]=p
			R.born(w,"b".repeat(48),"함께 온 채집가")
			var other: Dictionary=w.people["b".repeat(48)]
			other.room="road"
			other.x=15
			other.y=7
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
		fail("Foraging network timeout stage "+str(stage))
		return false
	if game.mode!="client" or Time.get_ticks_msec()-sent<250: return false
	var p: Dictionary=game.world.people[game.me]
	if game.world.has("craft_rng") or game.world.has("npc_activity"):
		fail("Hidden state leaked")
		return false
	for id in game.world.people:
		if id!=game.me and (game.world.people[id].has("herbal_quest") or game.world.people[id].has("forage_xp")):
			fail("Other player's progress leaked")
			return false
	if observer:
		if stage==0 and game.world.forage_ready.flower_west>game.world.time:
			command("harvest","flower_west")
			stage=1
		elif stage==1:
			if I.quantity(p,"night_blossom")!=0 or p.forage_xp!=0: fail("Second client duplicated harvested resource")
			else:
				print("PASS: ENet second client sees shared depletion and cannot duplicate resource or XP")
				quit()
		return false
	if stage==0 and walk(p,Vector2(15,7)):
		command("harvest","flower_west")
		stage=1
	elif stage==1 and I.quantity(p,"night_blossom")==1:
		command("harvest","flower_west")
		stage=2
	elif stage==2:
		if I.quantity(p,"night_blossom")!=1 or p.forage_xp!=5:
			fail("Repeat harvest duplicated resource")
			return false
		if walk(p,Vector2(25,7)):
			command("harvest","flower_east")
			stage=3
	elif stage==3 and I.quantity(p,"night_blossom")==2 and walk(p,Vector2(29,9)):
		command("interact")
		stage=4
	elif stage==4 and p.room=="harbor":
		var npc:=R.Travel.Life.state("soha",game.world.time)
		if walk(p,Vector2(npc.x,npc.y)):
			command("herbal_quest")
			stage=5
	elif stage==5 and p.herbal_quest=="done" and walk(p,Vector2(5,14)):
		command("coach")
		stage=6
	elif stage==6 and p.room=="village" and walk(p,Vector2(7,14)):
		command("enter_home")
		stage=7
	elif stage==7 and p.room=="home" and walk(p,Vector2(15,12)):
		command("craft_home","healing_salve")
		stage=8
	elif stage==8 and I.family_quantity(p,"healing_salve")==1:
		command("use_crafted",I.best(p,"healing_salve"))
		stage=9
	elif stage==9 and I.family_quantity(p,"healing_salve")==0:
		if p.hp<80 or p.craft_xp.herbalism<=0 or p.gold!=28 or p.herbal_quest!="done": fail("Server crafting, learning or reward mismatch")
		else:
			print("PASS: ENet night gathering, real travel, apprenticeship, coach return, learned craft and consumable use")
			quit()
	return false
