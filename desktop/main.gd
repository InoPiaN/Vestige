extends Node

const Rules=preload("res://world.gd")
const PixelWorld=preload("res://pixel_world.gd")
var world: Dictionary={}
var me: String="local"
var mode: String="menu"
var save_path: String="user://single-world.json"
var peers: Dictionary={}
var inputs: Dictionary={}
var last_commands: Dictionary={}
var ui: Control
var menu: Control
var view: Node2D
var status: Label
var inventory: Label
var market: Panel
var planner: Panel
var forge: Panel
var bench: Panel
var chest: Panel
var bag: Panel
var date_label: Label
var notice: Label
var prompt: Label
var health: ProgressBar
var stamina: ProgressBar
var policy: OptionButton
var panel: PanelContainer
var panel_text: RichTextLabel
var input_name: LineEdit
var input_host: LineEdit
var new_button: Button
var day_button: Button
var sync_clock:=0.0
var save_clock:=0.0
var chosen_look: Dictionary={}
var dressing: Panel
var portrait: Node2D
var dress_title: Label
var dress_controls: VBoxContainer
var dress_confirm: Button
var dress_name: LineEdit
var dressing_mode: String="create"
var dress_status: Label
var gear_pickers: Dictionary={}
var weapon_stamp:=""
var gear_record_button: Button


func _ready() -> void:
	get_tree().auto_accept_quit=false
	if "--server" in OS.get_cmdline_user_args():
		start_server()
		return
	build_ui()
	var demos: Dictionary={"detail":"detail","upgrade":"upgrade","legacy":"legacy","supply":"supply","plan":"plan","mastery":"mastery","market":"market","quality":"quality","craft":"craft","home":"home","remains":"remains","witness":"murder","investigation":"create"}
	for kind in demos:
		if ("--"+kind+"-demo") not in OS.get_cmdline_user_args(): continue
		save_path="user://"+kind+"-demo.json"
		if not FileAccess.file_exists(save_path) and not FileAccess.file_exists(save_path+".bak"):
			var demo=preload("res://investigation_demo.gd")
			var opening: Dictionary={}
			match kind:
				"detail": opening=demo.detail()
				"upgrade": opening=demo.upgrade()
				"legacy": opening=demo.legacy()
				"supply": opening=demo.supply()
				"plan": opening=demo.plan()
				"mastery": opening=demo.mastery()
				"market": opening=demo.market()
				"quality": opening=demo.quality()
				"craft": opening=demo.craft()
				"home": opening=demo.home()
				"remains": opening=demo.remains()
				"witness": opening=demo.murder()
				"investigation": opening=demo.create()
			if not Rules.save_world(opening,save_path):
				push_error("체험 월드를 만들 수 없습니다.")
				return
		start_single()
		if mode=="single":
			if kind=="detail": message("외형·장비에서 +0~+3 철검을 비교하세요. 이동과 공격으로 세밀해진 도트와 강화 효과를 확인할 수 있습니다.")
			elif kind=="upgrade": message("E로 대장간을 열고 철검을 선택해 비용과 강화 전후 공격력을 확인하세요.")
			elif kind=="legacy": message("외형·장비에서 개별 철검을 선택해 착용하세요. 착용 철검 기록에서 은결의 제작 서명과 유품 회수 이력을 읽습니다.")
			elif kind=="supply": message("E로 작업대를 열어 집 보관함의 천과 약초로 붕대를 만드세요. 완성품은 B로 확인합니다. 부재 계획에도 보관함을 설정할 수 있습니다.")
			elif kind=="plan": message("부재 중의 하루에서 제작 계획 설정을 선택하세요. 붕대 3개를 맡기고 하루 진행으로 결과를 확인할 수 있습니다.")
			elif kind=="mastery": message("E로 작업대를 열어 붕대 1개를 만드세요. 약초 조제가 견습으로 성장하고 확률이 바뀝니다. J에서 모든 분야를 확인합니다.")
			elif kind=="market": message("E로 장터를 열어 재료를 사고 제작품을 판매하세요. 재고는 다음 월드 날짜에 보충됩니다.")
			elif kind=="quality": message("I에서 일반·양품·대성공 철검의 공격력을 비교하세요. E로 작업대 제작도 가능합니다.")
			elif kind=="craft": message("E로 작업대를 열어 제작하고 검을 수선하세요. 약초차는 벽난로 불이 필요합니다.")
			elif kind=="home": message("가구 가까이에서 E · 서랍, 책장, 침대, 보관함, 커튼, 벽난로를 이용하세요.")
			elif kind=="remains": message("G로 근처 여행자의 유품을 회수하세요. 집에서는 B로 보관합니다.")
			else: message("마을 서남쪽 묘지에서 F로 조사하세요. J로 일기와 조사 수첩을 읽습니다.")
		return
	if "--qa" in OS.get_cmdline_user_args():
		DisplayServer.window_set_title("Vestige QA · 독립 시험 월드")
		save_path="user://qa-world.json"
		input_name.text="시험 여행자"
		start_single()
		return
	if "--single" in OS.get_cmdline_user_args(): start_single()

func start_server() -> void:
	mode="server"
	save_path="user://shared-world.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--world-file="): save_path=arg.trim_prefix("--world-file=")
	var net:=ENetMultiplayerPeer.new()
	var error:=net.create_server(27180,8)
	if error!=OK:
		push_error("Server could not open UDP 27180: %s" % error)
		get_tree().quit(1)
		return
	world=Rules.load_world(save_path,false)
	if world.is_empty():
		net.close()
		push_error("서버 저장을 복원할 수 없습니다: "+save_path)
		get_tree().quit(1)
		return
	multiplayer.multiplayer_peer=net
	multiplayer.peer_disconnected.connect(disconnected)
	print("Vestige server ready · UDP 27180 · ",ProjectSettings.globalize_path(save_path))

func disconnected(peer: int) -> void:
	if peers.has(peer):
		world.people[peers[peer]].offline=true
		inputs.erase(peer)
		peers.erase(peer)
		last_commands.erase(peer)
		Rules.save_world(world,save_path)

func request_single() -> void:
	if FileAccess.file_exists(save_path) or FileAccess.file_exists(save_path+".bak"): start_single()
	else: open_dressing("first")

func start_single() -> void:
	mode="single"
	me="local"
	world=Rules.load_world(save_path)
	if world.is_empty():
		mode="menu"
		var dialog:=AcceptDialog.new()
		dialog.dialog_text="월드를 불러올 수 없습니다. 저장 파일과 백업, 게임 버전 및 쓰기 권한을 확인하세요."
		add_child(dialog)
		dialog.close_requested.connect(dialog.queue_free)
		dialog.confirmed.connect(dialog.queue_free)
		dialog.popup_centered()
		return
	if not world.people.has(me): Rules.born(world,me,input_name.text,chosen_look)
	world.people[me].offline=false
	menu.hide()
	ui.show()
	message("WASD로 이동 · 동쪽 광맥에서 철을 모아 첫 검을 만드세요.")
	refresh()

func connect_world() -> void:
	var net:=ENetMultiplayerPeer.new()
	var error:=net.create_client(input_host.text.strip_edges(),27180)
	if error!=OK:
		input_host.text="연결 실패: 주소 확인"
		return
	mode="connecting"
	multiplayer.multiplayer_peer=net
	multiplayer.connected_to_server.connect(connected,CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(connection_failed,CONNECT_ONE_SHOT)
	multiplayer.server_disconnected.connect(connection_failed,CONNECT_ONE_SHOT)
	input_host.editable=false
	input_name.editable=false

func connection_failed() -> void:
	mode="menu"
	multiplayer.multiplayer_peer=null
	ui.hide()
	menu.show()
	input_host.editable=true
	input_name.editable=true
	input_host.placeholder_text="서버 연결이 종료되었습니다."

func connected() -> void:
	var token: String=""
	if FileAccess.file_exists("user://identity.txt"):
		token=FileAccess.get_file_as_string("user://identity.txt")
	else:
		token=Crypto.new().generate_random_bytes(24).hex_encode()
		var f:=FileAccess.open("user://identity.txt",FileAccess.WRITE)
		f.store_string(token)
	register_player.rpc_id(1,token,input_name.text,JSON.stringify(chosen_look))

@rpc("any_peer","call_remote","reliable")
func register_player(token: String, display_name: String, look_json: String="{}") -> void:
	if mode!="server" or token.length()!=48: return
	var peer:=multiplayer.get_remote_sender_id()
	if peers.has(peer) or peers.values().has(token): return
	peers[peer]=token
	if not world.people.has(token): Rules.born(world,token,display_name,parse_look(look_json))
	world.people[token].offline=false
	inputs[peer]=Vector2.ZERO
	send_snapshot(peer)

func send_snapshot(peer: int) -> void:
	var snapshot: Dictionary=world.duplicate(true)
	Rules.Investigation.redact(snapshot,peers[peer])
	for id in snapshot.people:
		if id!=peers[peer]:
			snapshot.people[id].journal=[]
			snapshot.people[id].events=[]
	# Network IDs are session-scoped; don't send other players' identity secrets.
	var people: Dictionary={}
	for id in snapshot.people:
		people[id.sha256_text()]=snapshot.people[id]
	snapshot.people=people
	receive_snapshot.rpc_id(peer,snapshot,String(peers[peer]).sha256_text())

@rpc("authority","call_remote","reliable")
func receive_snapshot(snapshot: Dictionary, identity: String) -> void:
	world=snapshot
	me=identity
	mode="client"
	menu.hide()
	ui.show()
	refresh()

@rpc("any_peer","call_remote","unreliable_ordered")
func movement(direction: Vector2) -> void:
	var peer:=multiplayer.get_remote_sender_id()
	if mode=="server" and peers.has(peer) and direction.is_finite():
		inputs[peer]=direction.limit_length()

@rpc("any_peer","call_remote","reliable")
func command(kind: String, value: String="") -> void:
	var peer:=multiplayer.get_remote_sender_id()
	if mode!="server" or not peers.has(peer): return
	var now:=Time.get_ticks_msec()
	if now-int(last_commands.get(peer,0))<100: return
	last_commands[peer]=now
	var id: String=peers[peer]
	if kind=="new":
		Rules.born(world,id,value.get_slice("|",0),parse_look(value.get_slice("|",1)))
	else:
		remote_message.rpc_id(peer,Rules.act(world,id,kind,value))
	send_snapshot(peer)

@rpc("authority","call_remote","reliable")
func remote_message(text: String) -> void:
	message(text)

func perform(kind: String, value: String="") -> void:
	if mode=="client":
		command.rpc_id(1,kind,value)
	elif mode=="single":
		if kind=="new": Rules.born(world,me,dress_name.text,chosen_look)
		else: message(Rules.act(world,me,kind,value))
		Rules.save_world(world,save_path)
		refresh()

func _physics_process(dt: float) -> void:
	if mode in ["menu","connecting"]: return
	if mode=="single" and (panel.visible or dressing.visible or bag.visible or chest.visible or planner.visible or bench.visible or market.visible or forge.visible): return
	if mode=="server":
		for peer in inputs:
			Rules.move(world,peers[peer],inputs[peer],dt)
		Rules.tick(world,dt)
	else:
		var d:=Vector2.ZERO
		if not panel.visible and not dressing.visible and not bag.visible and not chest.visible and not planner.visible and not bench.visible and not market.visible and not forge.visible:
			d=Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))).limit_length()
		if mode=="single":
			Rules.move(world,me,d,dt)
			Rules.tick(world,dt)
			refresh()
		else:
			sync_clock+=dt
			if sync_clock>0.05:
				sync_clock=0
				movement.rpc_id(1,d)
	if mode=="server":
		sync_clock+=dt
		if sync_clock>0.1:
			sync_clock=0
			for peer in peers: send_snapshot(peer)
	if mode in ["single","server"]:
		save_clock+=dt
		if save_clock>10:
			save_clock=0
			Rules.save_world(world,save_path)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if not mode in ["single","client"]: return
	if event.keycode==KEY_ESCAPE:
		panel.hide()
		dressing.hide()
		bag.hide()
		chest.hide()
		forge.hide()
		market.hide()
		planner.hide()
		bench.hide()
		return
	if event.physical_keycode==KEY_G:
		if chest.visible and chest.remains_mode: chest.hide()
		else: open_storage(true)
		return
	if event.physical_keycode==KEY_B:
		if chest.visible and not chest.remains_mode: chest.hide()
		else: open_storage()
		return
	if event.physical_keycode==KEY_I:
		if bag.visible: bag.hide()
		else: open_inventory()
		return
	if panel.visible and panel_text.text.contains("지목할 이를 고르세요") and event.physical_keycode in [KEY_1,KEY_2]:
		perform("identify","1" if event.physical_keycode==KEY_1 else "2")
		return
	if panel.visible or dressing.visible or bag.visible or chest.visible or planner.visible or bench.visible or market.visible or forge.visible: return
	match event.physical_keycode:
		KEY_E: interact()
		KEY_F: perform("investigate")
		KEY_SPACE: perform("attack")
		KEY_SHIFT: perform("dodge")
		KEY_Q: perform("heal")
		KEY_J: open_journal()

func interact() -> void:
	if Rules.Interior.inside(world.people[me]):
		perform("interact")
		return
	var t:=Rules.nearby(world.people[me])
	if t.get("kind","")=="home": perform("enter_home")
	elif t.get("kind","")=="forge": open_forge()
	elif t.get("kind","")=="library": open_library()
	elif t.get("kind","")=="grave": open_graves()
	else: perform("interact")

func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST:
		if mode=="single":
			var was_offline: bool=world.people[me].offline
			world.people[me].offline=true
			if not Rules.save_world(world,save_path):
				world.people[me].offline=was_offline
				message("저장하지 못했습니다. 디스크 공간과 권한을 확인한 뒤 다시 종료하세요.")
				return
		if mode=="server" and not Rules.save_world(world,save_path): return
		get_tree().quit()

func label_at(parent: Node,text: String,at: Vector2,size: int=16,color: Color=Color("c5c7b6")) -> Label:
	var l:=Label.new()
	l.text=text
	l.position=at
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",color)
	parent.add_child(l)
	return l

func button_at(parent: Node,text: String,at: Vector2,width: float,callback: Callable) -> Button:
	var b:=Button.new()
	b.text=text
	b.position=at
	b.size=Vector2(width,36)
	b.focus_mode=Control.FOCUS_NONE
	b.pressed.connect(callback)
	parent.add_child(b)
	return b

func build_ui() -> void:
	var layer:=CanvasLayer.new()
	add_child(layer)
	var root:=Control.new()
	layer.add_child(root)
	var theme:=Theme.new()
	theme.default_font_size=15
	var system_font:=SystemFont.new()
	system_font.font_names=PackedStringArray(["Apple SD Gothic Neo","Malgun Gothic","Noto Sans CJK KR","sans-serif"])
	theme.default_font=system_font
	for style in ["normal","hover","pressed"]:
		var sb:=StyleBoxFlat.new()
		sb.bg_color=Color("303e37") if style=="hover" else Color("202d29")
		sb.border_color=Color("647261")
		sb.set_border_width_all(1)
		sb.set_content_margin_all(8)
		theme.set_stylebox(style,"Button",sb)
	root.theme=theme
	menu=Control.new()
	root.add_child(menu)
	label_at(menu,"V E S T I G E",Vector2(90,100),64,Color("e1d1a3"))
	label_at(menu,"잿불의 기록",Vector2(95,183),24)
	label_at(menu,"당신이 떠난 뒤에도,\n이곳의 삶은 계속된다.",Vector2(95,260),30)
	label_at(menu,"검을 만들고, 숲을 건너고, 살아온 날들을 책으로 남기세요.\n설치형 도트 시제품 0.4.1 · Steam 출시를 향한 첫 여정",Vector2(95,365),17)
	input_name=LineEdit.new()
	input_name.text="에단"
	input_name.max_length=20
	input_name.position=Vector2(95,450)
	input_name.size=Vector2(250,40)
	menu.add_child(input_name)
	button_at(menu,"인물 외형 선택",Vector2(360,450),190,func(): open_dressing("create"))
	button_at(menu,"나만의 세계 시작 / 이어하기",Vector2(95,508),300,request_single)
	input_host=LineEdit.new()
	input_host.text="127.0.0.1"
	input_host.position=Vector2(95,570)
	input_host.size=Vector2(170,36)
	menu.add_child(input_host)
	button_at(menu,"공유 서버 접속",Vector2(280,570),190,connect_world)
	label_at(menu,"싱글은 인터넷 없이 실행됩니다. 공유 세계는 별도 서버가 필요합니다.",Vector2(95,637),14,Color("899a8b"))
	# Decorative pixel scene on the title screen, using the same original art.
	var title_view:=SubViewport.new()
	title_view.size=Vector2i(960,640)
	title_view.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	var title_art:=PixelWorld.new()
	title_view.add_child(title_art)
	var title_container:=SubViewportContainer.new()
	title_container.position=Vector2(600,160)
	title_container.scale=Vector2(0.6,0.6)
	title_container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	menu.add_child(title_container)
	title_container.add_child(title_view)
	title_view.canvas_transform=Transform2D(0,Vector2(2,2),0,Vector2.ZERO)
	ui=Control.new()
	root.add_child(ui)
	ui.hide()
	label_at(ui,"V E S T I G E",Vector2(24,17),27,Color("dccb9b"))
	date_label=label_at(ui,"",Vector2(600,24),16)
	var container:=SubViewportContainer.new()
	container.position=Vector2(16,80)
	container.scale=Vector2.ONE
	container.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ui.add_child(container)
	var viewport:=SubViewport.new()
	viewport.size=Vector2i(960,640)
	viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)
	viewport.canvas_transform=Transform2D(0,Vector2(2,2),0,Vector2.ZERO)
	view=PixelWorld.new()
	viewport.add_child(view)
	status=label_at(ui,"",Vector2(1000,88),19)
	health=ProgressBar.new()
	health.position=Vector2(1000,160)
	health.size=Vector2(250,12)
	health.show_percentage=false
	style_meter(health,Color("a2b883"))
	ui.add_child(health)
	health.size=Vector2(250,12)
	stamina=ProgressBar.new()
	stamina.position=Vector2(1000,180)
	stamina.size=Vector2(250,8)
	stamina.show_percentage=false
	style_meter(stamina,Color("c2aa72"))
	ui.add_child(stamina)
	stamina.size=Vector2(250,8)
	inventory=label_at(ui,"",Vector2(1000,205),16)
	button_at(ui,"I · 소지품",Vector2(1000,321),120,open_inventory)
	button_at(ui,"외형 · 장비",Vector2(1130,321),120,func(): open_dressing("gear"))
	label_at(ui,"부재 중의 하루",Vector2(1000,365),21,Color("d2bd89"))
	policy=OptionButton.new()
	policy.allow_reselect=true
	for text in ["휴식과 치료","대장간 제작","근교 약초 채집","기본기 수련","제작 계획 설정…"]: policy.add_item(text)
	policy.position=Vector2(1000,410)
	policy.size=Vector2(250,36)
	policy.item_selected.connect(func(index):
		if index==4: open_planner()
		else: perform("policy",["rest","work","gather","train"][index]))
	ui.add_child(policy)
	button_at(ui,"생활 맡기기",Vector2(1000,460),120,func(): perform("leave"))
	button_at(ui,"직접 조종",Vector2(1130,460),120,func(): perform("resume"))
	button_at(ui,"J · 나의 일기",Vector2(1000,510),250,open_journal)
	day_button=button_at(ui,"실험 · 하루 진행",Vector2(1000,558),250,func():
		if mode=="single":
			Rules.advance(world,Rules.DAY)
			Rules.save_world(world,save_path)
			message("하루가 흘렀습니다. J로 일기를 확인하세요.")
			refresh())
	new_button=button_at(ui,"새로운 삶 시작",Vector2(1000,606),250,func(): open_dressing("new"))
	label_at(ui,"WASD  이동   E  상호작용\nSPACE  공격   SHIFT  회피\nQ  약초 사용   J  일기",Vector2(1000,670),14,Color("8fa394"))
	prompt=label_at(ui,"",Vector2(30,730),16,Color("dfcd97"))
	notice=label_at(ui,"",Vector2(30,762),14)
	panel=PanelContainer.new()
	panel.position=Vector2(230,100)
	panel.size=Vector2(820,590)
	var paper:=StyleBoxFlat.new()
	paper.bg_color=Color("d6cfb5")
	paper.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel",paper)
	root.add_child(panel)
	var column:=VBoxContainer.new()
	panel.add_child(column)
	var close:=Button.new()
	close.text="기록 덮기 · ESC"
	close.pressed.connect(func(): panel.hide())
	column.add_child(close)
	panel_text=RichTextLabel.new()
	panel_text.bbcode_enabled=false
	panel_text.add_theme_color_override("default_color",Color("343e32"))
	panel_text.add_theme_font_size_override("normal_font_size",18)
	panel_text.size_flags_vertical=Control.SIZE_EXPAND_FILL
	column.add_child(panel_text)
	panel.hide()
	build_dressing(root)
	bag=preload("res://inventory_panel.gd").new()
	root.add_child(bag)
	bag.action.connect(perform)
	chest=preload("res://storage_panel.gd").new()
	root.add_child(chest)
	chest.action.connect(perform)
	market=preload("res://market_panel.gd").new()
	root.add_child(market)
	market.action.connect(perform)
	planner=preload("res://craft_plan_panel.gd").new()
	root.add_child(planner)
	planner.action.connect(perform)
	forge=preload("res://forge_panel.gd").new()
	root.add_child(forge)
	forge.action.connect(perform)
	bench=preload("res://crafting_panel.gd").new()
	root.add_child(bench)
	bench.action.connect(perform)

func refresh() -> void:
	if world.is_empty() or not world.people.has(me): return
	var p: Dictionary=world.people[me]
	if dressing.visible and dressing_mode=="gear":
		portrait.person=p
		dress_status.text="공격력 %d · 철검은 내구도에 따라 성능이 변합니다." % Rules.weapon_damage(p)
		for slot in gear_pickers:
			if slot!="weapon": gear_pickers[slot].select(Rules.GEAR[slot].find(p.equipment[slot]))
		refresh_weapon_picker(p)
	if bag.visible: bag.refresh(p)
	if chest.visible: chest.refresh(world,p)
	if planner.visible: planner.refresh(world,p)
	if forge.visible: forge.refresh(world,p)
	if bench.visible: bench.refresh(world,p)
	if market.visible: market.refresh(world,p)
	view.world=world
	view.player_id=me
	status.text="%s\n%s · %d세" % [p.name,"주민으로 생활 중" if p.offline else "직접 조종 중",int(p.age/360)]
	if not p.alive: status.text=p.name+"\n삶을 마쳤습니다"
	health.value=p.hp
	stamina.value=p.stamina
	inventory.text="체력 %d / 100\n철광석     %d\n달빛 약초  %d\n철검       %d\n유물       %d\n은화       %d   ·   기초 숙련 %d" % [p.hp,p.ore,p.herb,p.sword,p.relic,p.gold,p.skill]
	date_label.text="잿불 마을   /   제 %d일   /   %s" % [int(world.time/Rules.DAY)+1,"나만의 세계" if mode=="single" else "공유 세계"]
	policy.select(["rest","work","gather","train","plan"].find(p.policy))
	day_button.visible=mode=="single"
	new_button.visible=not p.alive
	var t:=Rules.nearby(p)
	prompt.text="E · "+t.name if not t.is_empty() else ("여정 완료 · 서재에서 이렌의 기록을 읽어보세요." if p.relic>0 else "첫 여정 · 동쪽 철광맥 → 대장간 → 예배당")

	if t.get("kind")=="forge": prompt.text="E · 대장간 제작 / 강화 · "+Rules.Mastery.progress(p,"smithing")+"  |  "+Rules.Mastery.rate_text(p,"smithing")+" · 완성 경험치 +%d" % Rules.Mastery.gain(p,"iron_sword")
	if t.get("kind")=="home" and world.estate.owner!="": prompt.text="E · 언덕집 들어가기   B · 보관함"
	if t.get("kind") in ["home","grave"] or not Rules.Investigation.traces(world,p).is_empty():
		prompt.text+="   F · 흔적 조사"
	elif Rules.Investigation.has_witness(world) and Rules.Investigation.near(p,Rules.Investigation.Witness.STATION): prompt.text="F · 등불지기 미라에게 묻기"

	if not Rules.Remains.visible(world,p).is_empty(): prompt.text+="   G · 유품 회수"

	if Rules.Interior.inside(p):
		var furniture:=Rules.Interior.nearby(p)
		prompt.text="E · "+Rules.Interior.OBJECTS[furniture].name if not furniture.is_empty() else "언덕집 · 가구 가까이에서 E / 아래쪽 문으로 나가기"
		if not Rules.Remains.visible(world,p).is_empty(): prompt.text+="   G · 유품 회수"
		date_label.text="언덕집 내부 · 제 %d일" % [int(world.time/Rules.DAY)+1]

func style_meter(bar: ProgressBar, color: Color) -> void:
	var background:=StyleBoxFlat.new()
	background.bg_color=Color("28342e")
	var fill:=StyleBoxFlat.new()
	fill.bg_color=color
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)

func message(text: String) -> void:
	if text.is_empty(): return
	if text.begins_with("조사 기록\n"): show_pages(text)
	elif text=="장터": open_market()
	elif text=="작업대": open_crafting()
	elif text=="보관함": open_storage()
	elif text=="서재": open_library()
	elif text=="묘지": open_graves()
	else:
		notice.text=text
		if bag.visible: bag.feedback.text=text
		if chest.visible: chest.feedback.text=text
		if bench.visible: bench.feedback.text=text
		if planner.visible: planner.feedback.text=text
		if market.visible: market.feedback.text=text
		if forge.visible: forge.feedback.text=text

func show_pages(text: String) -> void:
	forge.hide()
	market.hide()
	planner.hide()
	bench.hide()
	bag.hide()
	chest.hide()
	dressing.hide()
	panel_text.text=text
	panel.show()

func open_journal() -> void:
	if world.is_empty(): return
	var p: Dictionary=world.people[me]
	var text: String=p.name+"의 일기\n────────────────────\n\n"
	text+="부재 제작 계획\n"+Rules.Plan.summary(p)+"\n\n"
	text+="제작 숙련도\n"
	for field in Rules.Mastery.FIELDS: text+=Rules.Mastery.progress(p,field)+"\n"
	text+="\n"
	for entry in p.journal: text+="제 %d일\n%s\n\n" % [entry.day,entry.text]
	if p.journal.is_empty(): text+="아직 하루가 끝나지 않았습니다.\n생활을 맡긴 뒤 ‘하루 진행’으로 첫 기록을 확인할 수 있습니다.\n\n"
	text+="오늘의 메모\n"+"\n".join(p.events)
	if not p.notebook.is_empty():
		text+="\n\n조사 수첩\n"
		for notes in p.notebook.values():
			for entry in notes.values(): text+=entry+"\n"
	show_pages(text)

func open_library() -> void:
	var text: String="기억의 서재\n────────────────────\n\n"
	if world.people[me].relic>0:
		text+="약초사 이렌의 마지막 장\n\n“종소리가 멎은 지 사흘. 예배당에 약을 두고 간다.\n돌아오지 못하더라도, 누군가는 이 길을 걸을 것이다.”\n\n예배당에서 발견한 고정된 이야기 기록입니다.\n\n"
	for book in world.books:
		if not Rules.Investigation.may_read(world.people[me],book): continue
		text+=book.author+"의 남겨진 일기\n"
		for e in book.pages: text+="%d일 · %s\n" % [e.day,e.text]
		text+=book.last+"\n\n"
	if world.books.is_empty() and world.people[me].relic==0: text+="아직 보관된 유품이 없습니다. 동쪽 예배당에는 오래된 기록이 남아 있습니다."
	show_pages(text)

func open_graves() -> void:
	var text: String="이름의 묘지\n────────────────────\n\n"
	for grave in world.graves: text+="%s\n제 %d일 · %s\n이 마을에서 살아간 이를 기억하며.\n\n" % [grave.name,grave.day,grave.cause]
	if world.graves.is_empty(): text+="아직 새로 새겨진 이름이 없습니다."
	show_pages(text)

func parse_look(raw: String) -> Dictionary:
	if raw.length()>512: return Rules.clean_look({})
	var value=JSON.parse_string(raw)
	return Rules.clean_look(value if value is Dictionary else {})

func build_dressing(root: Control) -> void:
	dressing=Panel.new()
	dressing.position=Vector2(260,90)
	dressing.size=Vector2(760,620)
	var bg:=StyleBoxFlat.new()
	bg.bg_color=Color("182622")
	bg.border_color=Color("9c8b64")
	bg.set_border_width_all(2)
	dressing.add_theme_stylebox_override("panel",bg)
	root.add_child(dressing)
	dress_title=label_at(dressing,"인물 만들기",Vector2(32,24),26)
	button_at(dressing,"닫기",Vector2(620,24),100,func(): dressing.hide())
	var vc:=SubViewportContainer.new()
	vc.position=Vector2(42,125)
	vc.scale=Vector2(3,3)
	vc.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	vc.mouse_filter=Control.MOUSE_FILTER_IGNORE
	dressing.add_child(vc)
	var vp:=SubViewport.new()
	vp.size=Vector2i(64,72)
	vp.transparent_bg=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	vc.add_child(vp)
	vp.canvas_transform=Transform2D(0,Vector2(2,2),0,Vector2.ZERO)
	portrait=preload("res://portrait.gd").new()
	vp.add_child(portrait)
	dress_name=LineEdit.new()
	dress_name.position=Vector2(290,80)
	dress_name.size=Vector2(420,38)
	dress_name.max_length=20
	dressing.add_child(dress_name)
	dress_controls=VBoxContainer.new()
	dress_controls.position=Vector2(290,135)
	dress_controls.size=Vector2(420,310)
	dress_controls.add_theme_constant_override("separation",12)
	dressing.add_child(dress_controls)
	dress_status=label_at(dressing,"",Vector2(32,455),15)
	label_at(dressing,"의복·후드·망토는 시작 장비입니다. 철검은 제작 후 착용합니다.\n외형은 능력치와 독립적이며, 철검 공격력은 착용할 때 적용됩니다.",Vector2(32,490),15)
	gear_record_button=button_at(dressing,"착용 철검 기록",Vector2(32,550),220,func():
		var p: Dictionary=world.people[me]
		var id: String=p.equipped_ids.get("weapon","")
		if not id.is_empty(): show_pages(preload("res://items.gd").definition(p,id).name+"\n\n"+preload("res://items.gd").definition(p,id).description))
	gear_record_button.hide()
	dress_confirm=button_at(dressing,"외형 선택 완료",Vector2(290,560),420,func():
		input_name.text=dress_name.text.replace("|","").strip_edges()
		if input_name.text.is_empty(): input_name.text="여행자"
		dress_name.text=input_name.text
		if dressing_mode=="first": start_single()
		if dressing_mode=="new": perform("new",input_name.text+"|"+JSON.stringify(chosen_look))
		dressing.hide())
	dressing.hide()

func open_dressing(purpose: String) -> void:
	forge.hide()
	market.hide()
	planner.hide()
	bench.hide()
	bag.hide()
	chest.hide()
	panel.hide()
	dressing_mode=purpose
	gear_pickers.clear()
	weapon_stamp=""
	gear_record_button.visible=purpose=="gear"
	for child in dress_controls.get_children():
		dress_controls.remove_child(child)
		child.queue_free()
	dress_name.text=input_name.text
	dress_name.visible=purpose!="gear"
	dress_confirm.visible=purpose!="gear"
	dress_title.text="착용 장비" if purpose=="gear" else "새 인물의 모습"
	dress_status.text="머리·피부·옷 색을 선택하세요. 기존 인물의 외형은 바뀌지 않습니다."
	if purpose=="gear":
		portrait.person=world.people[me]
		for slot in Rules.GEAR:
			if slot=="weapon":
				var weapon:=OptionButton.new()
				weapon.add_theme_font_size_override("font_size",16)
				weapon.custom_minimum_size=Vector2(420,40)
				weapon.item_selected.connect(func(i): perform("equip_weapon",weapon.get_item_metadata(i)))
				gear_pickers.weapon=weapon
				dress_controls.add_child(weapon)
				continue
			var names: Dictionary={"body":["기본 의복","가죽 갑옷"],"head":["투구 없음","여행 후드"],"cloak":["망토 없음","여행 망토"],"weapon":["맨손","철검"]}
			var picker:=OptionButton.new()
			for text in names[slot]: picker.add_item(text)
			picker.select(Rules.GEAR[slot].find(world.people[me].equipment[slot]))
			gear_pickers[slot]=picker
			picker.item_selected.connect(func(i): perform("equip",slot+":"+Rules.GEAR[slot][i]))
			dress_controls.add_child(picker)
		var hide:=CheckButton.new()
		hide.text="투구 숨기기"
		hide.button_pressed=world.people[me].hide_helmet
		hide.toggled.connect(func(on): perform("helmet","hide" if on else "show"))
		dress_controls.add_child(hide)
	else:
		chosen_look=Rules.clean_look(chosen_look)
		portrait.person={"alive":true,"look":chosen_look}
		var names: Dictionary={"hair":["머리 · 짧은 가르마","머리 · 긴 머리","머리 · 묶은 머리"],"hair_color":["머리색 · 밤색","머리색 · 금빛","머리색 · 적갈색","머리색 · 은빛"],"skin":["피부 · 밝음","피부 · 중간","피부 · 어두움"],"cloth":["의복 · 벽돌색","의복 · 청색","의복 · 녹색","의복 · 자주색"]}
		for key in Rules.LOOK_OPTIONS:
			var picker:=OptionButton.new()
			for text in names[key]: picker.add_item(text)
			picker.select(chosen_look[key])
			picker.item_selected.connect(func(i): chosen_look[key]=i)
			dress_controls.add_child(picker)
	dressing.show()
	if purpose=="gear": refresh()

func open_inventory() -> void:
	forge.hide()
	market.hide()
	planner.hide()
	bench.hide()
	chest.hide()
	if world.is_empty() or not world.people.has(me): return
	panel.hide()
	dressing.hide()
	bag.feedback.text=""
	bag.refresh(world.people[me])
	bag.show()

func open_storage(remains_mode: bool=false) -> void:
	forge.hide()
	market.hide()
	planner.hide()
	bench.hide()
	if world.is_empty() or not world.people.has(me): return
	panel.hide()
	dressing.hide()
	bag.hide()
	chest.feedback.text=""
	chest.signature=""
	chest.remains_mode=remains_mode
	chest.refresh(world,world.people[me])
	chest.show()

func open_crafting() -> void:
	planner.hide()
	forge.hide()
	market.hide()
	if world.is_empty() or not world.people.has(me): return
	panel.hide()
	dressing.hide()
	bag.hide()
	chest.hide()
	bench.feedback.text=""
	bench.refresh(world,world.people[me])
	bench.show()

func open_market() -> void:
	forge.hide()
	if world.is_empty() or not world.people.has(me): return
	panel.hide()
	dressing.hide()
	bag.hide()
	chest.hide()
	planner.hide()
	bench.hide()
	market.feedback.text=""
	market.refresh(world,world.people[me])
	market.show()

func open_planner() -> void:
	if world.is_empty() or not world.people.has(me): return
	panel.hide()
	dressing.hide()
	bag.hide()
	chest.hide()
	forge.hide()
	market.hide()
	bench.hide()
	planner.setup(world,world.people[me])
	planner.show()

func refresh_weapon_picker(p: Dictionary) -> void:
	if not gear_pickers.has("weapon"): return
	var picker: OptionButton=gear_pickers.weapon
	var stamp:=JSON.stringify([p.gear_instances,p.gear_condition,p.gear_quality,p.gear_records])
	if stamp!=weapon_stamp:
		weapon_stamp=stamp
		picker.clear()
		picker.add_item("맨손 · 공격력 9")
		picker.set_item_metadata(0,"none")
		for id in p.gear_instances:
			if p.gear_instances[id]!="iron_sword": continue
			var item:=preload("res://items.gd").definition(p,id)
			var damage: int=Rules.Quality.attack(p,id) if p.gear_condition[id]>0 else 9
			var index:=picker.item_count
			picker.add_item("%s · 공격 %d · 내구 %d" % [item.name,damage,p.gear_condition[id]])
			picker.set_item_metadata(index,id)
			picker.set_item_tooltip(index,item.description)
	var worn: String=p.equipped_ids.get("weapon","none")
	for i in range(picker.item_count):
		if picker.get_item_metadata(i)==worn: picker.select(i)
	picker.disabled=not p.alive
	gear_record_button.disabled=worn=="none"

func open_forge() -> void:
	market.hide()
	planner.hide()
	bench.hide()
	bag.hide()
	chest.hide()
	dressing.hide()
	panel.hide()
	forge.feedback.text=""
	forge.refresh(world,world.people[me])
	forge.show()
