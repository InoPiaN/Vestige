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
			var w:=preload("res://investigation_demo.gd").legacy()
			var p: Dictionary=w.people.local
			w.people.erase("local")
			w.people["c".repeat(48)]=p
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
		push_error("Gear records network timeout, stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client": return false
	if game.world.has("craft_rng") or game.world.has("cases") or game.world.estate.has("shelf"):
		push_error("Hidden case leaked")
		quit(1)
		return false
	var p: Dictionary=game.world.people[game.me]
	if stage==0:
		for id in p.gear_instances:
			if p.gear_instances[id]=="iron_sword": item=id
		game.command.rpc_id(1,"equip_weapon",item)
		sent=Time.get_ticks_msec()
		stage=1
	elif stage==1 and p.equipped_ids.get("weapon")==item and Time.get_ticks_msec()-sent>150:
		game.command.rpc_id(1,"equip_weapon",item)
		sent=Time.get_ticks_msec()
		stage=2
	elif stage==2 and Time.get_ticks_msec()-sent>300:
		if p.equipped_ids.get("weapon")!=item or p.gear_records[item].maker.name!="은결" or p.gear_records[item].events.size()!=2:
			push_error("Exact equipment or inherited provenance failed over ENet")
			quit(1)
		else:
			print("PASS: ENet exact sword selection is idempotent and preserves maker and recovery history")
			quit()
	return false
