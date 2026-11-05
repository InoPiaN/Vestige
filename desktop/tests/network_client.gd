extends SceneTree
const Main=preload("res://main.gd")
var game: Node
var started: int
var stage:=0
var before:=0.0
func _initialize() -> void:
	call_deferred("start")
func start() -> void:
	game=Main.new()
	game.name="Vestige"
	root.add_child(game)
	game.mode="connecting"
	var net:=ENetMultiplayerPeer.new()
	var error:=net.create_client("127.0.0.1",27180)
	if error!=OK:
		quit(1)
		return
	game.multiplayer.multiplayer_peer=net
	game.multiplayer.connected_to_server.connect(func(): game.register_player.rpc_id(1,Crypto.new().generate_random_bytes(24).hex_encode(),"네트워크 시험",JSON.stringify({"hair":2,"cloth":3})))
	started=Time.get_ticks_msec()
func _process(_dt: float) -> bool:
	if game==null: return false
	if Time.get_ticks_msec()-started>15000:
		push_error("Network test timed out")
		quit(1)
		return false
	if game.mode!="client": return false
	if stage==0 and game.world.people.size()>=2:
		for person in game.world.people.values():
			if person.look.hair!=2:
				push_error("Network appearance mismatch")
				quit(1)
				return false
		game.command.rpc_id(1,"equip","head:hood")
		before=game.world.people[game.me].x
		stage=1
	if stage==1:
		game.movement.rpc_id(1,Vector2.RIGHT)
		if game.world.people[game.me].x>before+0.1 and game.world.people[game.me].equipment.head=="hood":
			print("PASS: two ENet clients share authoritative appearance, equipment and movement")
			quit(0)
	return false
