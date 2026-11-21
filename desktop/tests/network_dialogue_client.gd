extends SceneTree
const Main=preload("res://main.gd")
var game: Node
var failed:=false
var token: String
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failed=true
		push_error(label)
func _initialize() -> void: call_deferred("start")
func start() -> void:
	create_timer(20).timeout.connect(func(): push_error("Dialogue network timeout"); quit(1))
	game=Main.new()
	game.name="Vestige"
	root.add_child(game)
	game.set_physics_process(false)
	game.mode="connecting"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--token="): token=arg.trim_prefix("--token=")
	var net:=ENetMultiplayerPeer.new()
	check(net.create_client("127.0.0.1",27180)==OK,"client connects")
	game.multiplayer.multiplayer_peer=net
	await game.multiplayer.connected_to_server
	game.register_player.rpc_id(1,token,"대화 네트워크 시험")
	while game.mode!="client": await process_frame
	if "--verify" in OS.get_cmdline_user_args():
		check(game.world.people[game.me].story.iren_missing_rumor,"rumor survives server restart and reconnect")
		# Other clients' tests let this offline resident walk to the inn.
		for destination in [Vector2(9,9),Vector2(7,7.5)]:
			while Main.Rules.pos(game.world.people[game.me]).distance_to(destination)>0.2:
				game.movement.rpc_id(1,(destination-Main.Rules.pos(game.world.people[game.me])).normalized())
				await create_timer(0.05).timeout
		game.movement.rpc_id(1,Vector2.ZERO)
		await create_timer(0.2).timeout
		game.interact()
		await create_timer(0.3).timeout
		check(game.dialogue_text.text.contains("다시 왔군"),"reconnected dialogue uses return branch")
		await finish()
		return
	# A remote request cannot bypass proximity checks or grant story state.
	game.dialogue.show()
	game.command.rpc_id(1,"talk","bran",game.dialogue_request_id)
	await create_timer(0.3).timeout
	check(not game.dialogue.visible and not game.world.people[game.me].story.visits.bran,"server rejects distant talk")
	var destination:=Vector2(7,7.5)
	while Main.Rules.pos(game.world.people[game.me]).distance_to(destination)>0.2:
		game.movement.rpc_id(1,(destination-Main.Rules.pos(game.world.people[game.me])).normalized())
		await create_timer(0.05).timeout
	game.movement.rpc_id(1,Vector2.ZERO)
	await create_timer(0.2).timeout
	game.interact()
	await create_timer(0.3).timeout
	check(game.dialogue.visible and game.dialogue_text.text.contains("처음 보는"),"server opens first greeting")
	var at:=Main.Rules.pos(game.world.people[game.me])
	game.movement.rpc_id(1,Vector2.RIGHT)
	game.command.rpc_id(1,"attack")
	await create_timer(0.3).timeout
	check(Main.Rules.pos(game.world.people[game.me]).distance_to(at)<0.01 and game.world.people[game.me].attack==0,"server blocks movement and attack during conversation")
	game.request_dialogue("dialogue_choice","rumor")
	await create_timer(0.3).timeout
	check(game.world.people[game.me].story.iren_missing_rumor and game.dialogue_text.text.contains("소문"),"server grants rumor and sends dialogue")
	var private_ok:=true
	var other_count:=0
	for id in game.world.people:
		if id!=game.me:
			other_count+=1
			var p: Dictionary=game.world.people[id]
			private_ok=private_ok and not p.has("story") and p.events.is_empty() and p.journal.is_empty()
	check(private_ok and other_count>0,"other players' story and journal remain private")
	game.movement.rpc_id(1,Vector2.ZERO)
	game.close_dialogue()
	await create_timer(0.2).timeout
	game.interact()
	await create_timer(0.3).timeout
	check(game.dialogue_text.text.contains("다시 왔군") and game.dialogue_text.text.contains("마음에 걸리나"),"network return and known-rumor branches")
	game.close_dialogue()
	await finish()

func finish() -> void:
	game.multiplayer.multiplayer_peer.get_peer(1).peer_disconnect()
	await create_timer(0.3).timeout
	quit(1 if failed else 0)
