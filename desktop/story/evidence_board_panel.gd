extends PanelContainer
signal combination_requested(first: String, second: String)
signal close_requested

const BoardRules = preload("res://story/evidence_board_rules.gd")
var entries: VBoxContainer
var picked: Label
var feedback: Label
var first_id: String = ""
var second_id: String = ""
var fingerprint: String = ""

func _ready() -> void:
	position = Vector2(190, 85)
	size = Vector2(900, 625)
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("e0d8c1")
	paper.set_content_margin_all(20)
	add_theme_stylebox_override("panel", paper)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 9)
	add_child(body)
	var title := Label.new()
	title.text = "제1장 · 사건 재구성"
	title.add_theme_color_override("font_color", Color("303d34"))
	title.add_theme_font_size_override("font_size", 25)
	body.add_child(title)
	var hint := Label.new()
	hint.text = "서로 다른 증거 두 개를 선택하세요. 기록의 연결만 확인하며 미확정 진실은 밝히지 않습니다."
	hint.add_theme_color_override("font_color", Color("425044"))
	body.add_child(hint)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	entries = VBoxContainer.new()
	entries.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(entries)
	picked = Label.new()
	picked.add_theme_color_override("font_color", Color("303d34"))
	body.add_child(picked)
	feedback = Label.new()
	feedback.add_theme_color_override("font_color", Color("5f3c30"))
	body.add_child(feedback)
	var actions := HBoxContainer.new()
	body.add_child(actions)
	var verify := Button.new()
	verify.text = "선택한 증거 조합"
	verify.pressed.connect(_verify)
	actions.add_child(verify)
	var reset := Button.new()
	reset.text = "선택 초기화"
	reset.pressed.connect(func():
		first_id = ""
		second_id = ""
		_update_selection())
	actions.add_child(reset)
	var close := Button.new()
	close.text = "수첩으로 돌아가기"
	close.pressed.connect(func(): close_requested.emit())
	actions.add_child(close)
	_update_selection()
	hide()

func open_for(p: Dictionary) -> void:
	first_id = ""
	second_id = ""
	fingerprint = ""
	feedback.text = ""
	reload(p)
	show()

func reload(p: Dictionary) -> void:
	var records := BoardRules.available_records(p)
	var ids: PackedStringArray = PackedStringArray()
	for record in records:
		ids.append(str(record.id))
	var current := "|".join(ids)
	if current == fingerprint:
		return
	fingerprint = current
	for child in entries.get_children():
		entries.remove_child(child)
		child.queue_free()
	if records.is_empty():
		var empty := Label.new()
		empty.text = "아직 조사한 증거가 없습니다. E키로 현장 조사부터 진행하세요."
		entries.add_child(empty)
	for record in records:
		var clue_id: String = record.id
		var button := Button.new()
		button.text = "#%d · %s [%s] — %s" % [record.order,record.title,clue_id,record.source]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(func(): select_evidence(clue_id))
		entries.add_child(button)
	if not first_id in ids: first_id = ""
	if not second_id in ids: second_id = ""
	_update_selection()

func select_evidence(id: String) -> void:
	if id == first_id:
		first_id = second_id
		second_id = ""
	elif id == second_id:
		second_id = ""
	elif first_id.is_empty():
		first_id = id
	elif second_id.is_empty():
		second_id = id
	else:
		first_id = second_id
		second_id = id
	_update_selection()

func _update_selection() -> void:
	picked.text = "선택: %s  +  %s" % [first_id if not first_id.is_empty() else "(없음)", second_id if not second_id.is_empty() else "(없음)"]

func _verify() -> void:
	if first_id.is_empty() or second_id.is_empty():
		feedback.text = "서로 다른 증거 두 개를 선택하세요."
		return
	combination_requested.emit(first_id,second_id)

func set_feedback(text: String) -> void:
	feedback.text = text
