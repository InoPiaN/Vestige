extends SceneTree
## Real ENet multi-process fixture and two-client Chapter I authority regression.
## This is a test script; it must never use actual user:// saves.
const World = preload("res://world.gd")
const Bridge = preload("res://story/chapter1_bridge.gd")
const Clues = preload("res://story/chapter1_investigation.gd")
const NPC = preload("res://story/chapter1_dialogue.gd")
const A := "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
const B := "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb"
var game: Node
var observer := false
var stage := 0
var started := 0
var stage_time := 0
var pending_id := 0
var failures := 0

func _initialize() -> void:
	call_deferred("start")

func start() -> void:
	observer = "--observer" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--fixture="):
			var w: Dictionary = World.fresh()
			World.born(w,A,"서재 조사자")
			World.born(w,B,"관찰자")
			w.wolf.hp = 0
			w.wolf.respawn = 999999.0
			var p: Dictionary = w.people[A]
			p.room = "village"
			for clue in ["chapel_traces","device_log"]:
				p.x = Clues.EVIDENCE[clue].x
				p.y = Clues.EVIDENCE[clue].y
				if not Bridge.inspect(w,A,clue).contains("증거 기록"):
					quit(1)
					return
			p.x = NPC.NPCS.sera.x
			p.y = NPC.NPCS.sera.y
			var q: Dictionary = w.people[B]
			q.room = "village"
			q.x = NPC.NPCS.kael.x
			q.y = NPC.NPCS.kael.y
			var ok: bool = World.save_world(w,arg.trim_prefix("--fixture="))
			quit(0 if ok else 1)
			return
	game = preload("res://main.gd").new()
	game.name = "Vestige"
	root.add_child(game)
	game.set_physics_process(false)
	game.mode = "connecting"
	var peer := ENetMultiplayerPeer.new()
	if peer.create_client("127.0.0.1",27180) != OK:
		quit(1)
		return
	game.multiplayer.multiplayer_peer = peer
	game.multiplayer.connected_to_server.connect(func(): game.register_player.rpc_id(1,B if observer else A,"ENet 조사자"))
	started = Time.get_ticks_msec()
	stage_time = started

func check(condition: bool, title: String) -> bool:
	if condition:
		print("PASS: ENet Chapter I ", title)
		return true
	push_error("FAIL: ENet Chapter I " + title)
	failures += 1
	quit(1)
	return false

func next_stage() -> void:
	stage += 1
	stage_time = Time.get_ticks_msec()

func _process(_delta: float) -> bool:
	if game == null: return false
	if Time.get_ticks_msec()-started > 35000:
		push_error("ENet Chapter I timeout at stage " + str(stage) + " observer=" + str(observer))
		quit(1)
		return false
	if game.mode!="client": return false
	var p: Dictionary=game.world.people[game.me]
	for id in game.world.people:
		if id!=game.me and not check(not game.world.people[id].has("story"),"other player's story redacted"):
			return false
	if observer:
		return observer_steps(p)
	return primary_steps(p)

func primary_steps(p: Dictionary) -> bool:
	if stage==0:
		if not check(p.story.chapter1.evidence_links.has("E05") and p.story.chapter1.evidence_links.has("E07"),"authorized player received own E05/E07"):
			return false
		game.chapter1_board_pending_request=1
		game.chapter1_reconstruct.rpc_id(1,"E05","E07",1)
		next_stage()
	elif stage==1 and game.chapter1_board_pending_request==0:
		if not check(p.story.chapter1.inferences.has("I03"),"server accepted only owned I03"):
			return false
		game.chapter1_dialogue_open.rpc_id(1)
		next_stage()
	elif stage==2 and not game.dialogue_session_token.is_empty():
		if not check(game.dialogue_npc=="sera","server chose nearby Sera"):
			return false
		game.chapter1_dialogue_choose.rpc_id(1,"wrong-token","rumor")
		next_stage()
	elif stage==3 and Time.get_ticks_msec()-stage_time>350:
		if not check(not p.story.iren_missing_rumor,"forged dialogue token did not mutate state"):
			return false
		game.chapter1_dialogue_choose.rpc_id(1,game.dialogue_session_token,"rumor")
		next_stage()
	elif stage==4 and p.story.iren_missing_rumor:
		if not check(p.story.visits.sera and p.story.chapter1.inferences.has("I03"),"Sera source-scoped rumor and inference persisted"):
			return false
		game.chapter1_dialogue_end.rpc_id(1,game.dialogue_session_token)
		print("PASS: ENet Chapter I primary evidence reconstruction, server-only NPC session, forged token rejection")
		quit(0)
	return false

func observer_steps(p: Dictionary) -> bool:
	if stage==0:
		if not check(p.get("story",{}).get("chapter1",{}).get("evidence_links",{}).is_empty(),"observer starts without source evidence"):
			return false
		game.chapter1_board_pending_request=1
		game.chapter1_reconstruct.rpc_id(1,"E05","E07",1)
		next_stage()
	elif stage==1 and game.chapter1_board_pending_request==0:
		if not check(p.get("story",{}).get("chapter1",{}).get("inferences",{}).is_empty(),"observer cannot borrow E05/E07 logical IDs"):
			return false
		game.chapter1_dialogue_choose.rpc_id(1,"forged-token","rumor")
		next_stage()
	elif stage==2 and Time.get_ticks_msec()-stage_time>400:
		if not check(p.get("story",{}).get("iren_missing_rumor",false)==false,"dialogue without active session denied"):
			return false
		print("PASS: ENet Chapter I observer private evidence, rejected reconstruction and unauthenticated choice")
		quit(0)
	return false
