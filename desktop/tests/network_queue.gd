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
			var w:=preload("res://investigation_demo.gd").queue()
			var p: Dictionary=w.people.local
			p.policy="work"
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
		push_error("Queue network timeout, stage "+str(stage))
		quit(1)
		return false
	if game.mode!="client": return false
	if game.world.has("craft_rng") or game.world.has("cases") or game.world.estate.has("shelf"):
		push_error("Hidden case leaked")
		quit(1)
		return false
	var p: Dictionary=game.world.people[game.me]
	if stage==0:
		game.open_planner()
		game.planner.plan_picker.select(1)
		game.planner.plan_picker.item_selected.emit(1)
		game.planner.manage_buttons[0].pressed.emit()
		sent=Time.get_ticks_msec()
		stage=1
	elif stage==1 and p.craft_plan.recipe=="iron_armor" and Time.get_ticks_msec()-sent>150:
		if game.planner.recipes.selected!=Rules.Plan.RECIPES.find("iron_armor"):
			push_error("Queue UI lost selected recipe after network reorder")
			quit(1)
			return false
		game.command.rpc_id(1,"plan_pause","0")
		sent=Time.get_ticks_msec()
		stage=2
	elif stage==2 and p.craft_plan.paused and Time.get_ticks_msec()-sent>150:
		game.command.rpc_id(1,"plan_delete","1")
		stage=3
	elif stage==3 and p.craft_queue.size()==1:
		if p.craft_queue[0].recipe!="leather" or p.craft_plan.remaining!=1:
			push_error("Queue network mutation lost progress")
			quit(1)
		else:
			print("PASS: ENet queue reorder pause delete and UI selection synchronize")
			quit()
	return false
