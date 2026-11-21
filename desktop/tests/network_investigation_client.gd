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
func pause() -> void: await create_timer(0.25).timeout
func travel(destination: Vector2) -> void:
	while Main.Rules.pos(game.world.people[game.me]).distance_to(destination)>0.2:
		game.movement.rpc_id(1,(destination-Main.Rules.pos(game.world.people[game.me])).normalized())
		await create_timer(0.05).timeout
	game.movement.rpc_id(1,Vector2.ZERO)
	await pause()
func finish() -> void:
	game.multiplayer.multiplayer_peer.get_peer(1).peer_disconnect()
	await pause()
	quit(1 if failed else 0)
func start() -> void:
	create_timer(45).timeout.connect(func(): push_error("Investigation network timeout"); quit(1))
	game=Main.new()
	game.name="Vestige"
	root.add_child(game)
	game.set_physics_process(false)
	game.mode="connecting"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--token="): token=arg.trim_prefix("--token=")
	var net:=ENetMultiplayerPeer.new()
	check(net.create_client("127.0.0.1",27180)==OK,"investigation client connects")
	game.multiplayer.multiplayer_peer=net
	await game.multiplayer.connected_to_server
	game.register_player.rpc_id(1,token,"현장 조사 시험")
	while game.mode!="client": await process_frame
	if "--verify" in OS.get_cmdline_user_args():
		var records: Dictionary=game.world.people[game.me].story.evidence
		check(records.size()==2 and records.last_promise.order==1 and records.chapel_traces.order==2,"both evidence records survive server restart")
		game.open_notebook()
		check(game.panel_text.text.contains("출처:") and game.panel_text.text.contains("추정 · 미확인"),"reconnected notebook preserves provenance and uncertainty")
		game.panel.hide()
		await travel(Vector2(9,9))
		await travel(Vector2(7,7.5))
		game.interact()
		await pause()
		game.request_dialogue("dialogue_choice","evidence")
		await pause()
		check(game.dialogue_text.text.contains("약속의 글과 현장 흔적"),"reconnected NPC uses combined-evidence branch")
		await finish()
		return
	game.command.rpc_id(1,"inspect","last_promise")
	await pause()
	check(game.world.people[game.me].story.evidence.is_empty(),"server rejects forged distant discovery")
	await travel(Vector2(7,7.5))
	game.interact()
	await pause()
	game.request_dialogue("dialogue_choice","evidence")
	await pause()
	check(not game.dialogue.visible and game.world.people[game.me].story.evidence.is_empty(),"server rejects unearned evidence dialogue")
	await travel(Vector2(9,9))
	await travel(Vector2(16,7))
	game.interact()
	await pause()
	check(game.world.people[game.me].story.evidence.has("last_promise"),"server awards diary at house entrance")
	var first: Dictionary=game.world.people[game.me].story.evidence.last_promise.duplicate(true)
	game.interact()
	await pause()
	check(game.world.people[game.me].story.evidence.last_promise==first,"duplicate RPC preserves first discovery")
	await travel(Vector2(18,10))
	await travel(Vector2(27,12))
	game.interact()
	await pause()
	check(game.world.people[game.me].story.evidence.size()==2,"server awards chapel traces independently of relic")
	check(game.world.people[game.me].relic==0,"investigation does not award legacy relic")
	var private_ok:=true
	for id in game.world.people:
		if id!=game.me: private_ok=private_ok and not game.world.people[id].has("story")
	check(private_ok and game.world.people.size()>1,"other players' evidence absent from snapshots")
	await travel(Vector2(18,10))
	await travel(Vector2(9,9))
	await travel(Vector2(7,7.5))
	game.interact()
	await pause()
	game.request_dialogue("dialogue_choice","evidence")
	await pause()
	check(game.dialogue_text.text.contains("약속의 글과 현장 흔적"),"server selects combined-evidence dialogue")
	game.close_dialogue()
	await pause()
	await finish()
