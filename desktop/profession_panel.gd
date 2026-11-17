extends Panel
const P=preload("res://professions.gd")
signal action(kind: String,value: String)
var field:="warrior"
var person: Dictionary={}
var selector: OptionButton
var details: Label
var lesson_button: Button
var feedback: Label
var slots: Array[OptionButton]=[]
var stamp:=""
func label(text: String,at: Vector2,font_size: int=18) -> Label:
	var node:=Label.new()
	node.text=text
	node.position=at
	node.add_theme_font_size_override("font_size",font_size)
	add_child(node)
	return node
func _ready() -> void:
	position=Vector2(160,90)
	size=Vector2(960,620)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172520")
	style.border_color=Color("a28e64")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel",style)
	label("성장의 길 · 스승과 기술",Vector2(28,24),24)
	var close:=Button.new()
	close.text="닫기 · ESC / K"
	close.position=Vector2(760,20)
	close.size=Vector2(170,36)
	close.pressed.connect(hide)
	add_child(close)
	selector=OptionButton.new()
	selector.position=Vector2(28,80)
	selector.size=Vector2(350,42)
	selector.add_item("전사 · 경비대 교관 라온")
	selector.add_item("사냥꾼 · 스승 세린")
	selector.item_selected.connect(func(i): field="warrior" if i==0 else "hunter"; refresh(person))
	add_child(selector)
	details=label("",Vector2(28,140),18)
	details.size=Vector2(900,185)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	lesson_button=Button.new()
	lesson_button.position=Vector2(590,82)
	lesson_button.size=Vector2(340,40)
	lesson_button.pressed.connect(func(): action.emit("lesson",field))
	add_child(lesson_button)
	label("전투에 준비할 기술 · 1 / 2 키로 사용",Vector2(28,335),20)
	for i in range(2):
		var slot:=OptionButton.new()
		slot.position=Vector2(28+i*455,375)
		slot.size=Vector2(435,42)
		slot.item_selected.connect(func(n): action.emit("skill_slot",str(i)+"|"+str(slot.get_item_metadata(n))))
		add_child(slot)
		slots.append(slot)
	label("각 기술에는 맞는 무기가 필요합니다. 기력과 재사용 시간은 화면 위에 표시됩니다.\n두 길을 함께 배울 수 있습니다. 실제 명중으로 해당 길의 숙련을 쌓습니다.",Vector2(28,445),17)
	feedback=label("",Vector2(28,515),17)
	feedback.size=Vector2(900,75)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hide()
func refresh(p: Dictionary) -> void:
	person=p
	selector.select(0 if field=="warrior" else 1)
	var mentor: Dictionary=P.Mentors[field]
	var row: Dictionary=p.professions[field]
	lesson_button.text={"new":"스승에게 입문 과제 받기","active":"준비를 마치고 기술 배우기","learned":"입문 완료"}[row.state]
	lesson_button.disabled=not P.near(p,field) or row.state=="learned"
	var lines: Array[String]=[mentor.name+" · "+P.rank(p,field)+" · %d / 1000 XP" % row.xp]
	lines.append("과제 · "+P.Items.CATALOG[mentor.weapon].name+" 착용 + "+P.Items.CATALOG[mentor.material].name+" 2개 전달 · 보상 은화 4")
	if row.state=="new": lines.append("마을의 스승 가까이에서 E를 눌러 대화하세요.")
	elif row.state=="active": lines.append("준비한 무기를 착용하고 재료를 가져오세요. 대장간에서 제작할 수 있습니다.")
	else: lines.append("기술 습득 완료 · 해당 무기의 전투 명중마다 경험치 +5")
	for id in P.SKILLS:
		var skill: Dictionary=P.SKILLS[id]
		if skill.field==field: lines.append("%s · 기력 %d / 재사용 %d초 · %s" % [skill.name,skill.cost,skill.cooldown,skill.description])
	details.text="\n".join(lines)
	var next:=JSON.stringify([p.professions,p.skill_slots,p.alive,p.offline])
	if next==stamp: return
	stamp=next
	for i in range(2):
		var slot: OptionButton=slots[i]
		slot.clear()
		slot.add_item("[%d] 비우기" % (i+1))
		slot.set_item_metadata(0,"")
		for id in P.SKILLS:
			if p.professions[P.SKILLS[id].field].state!="learned": continue
			slot.add_item("[%d] %s · 기력 %d" % [i+1,P.SKILLS[id].name,P.SKILLS[id].cost])
			slot.set_item_metadata(slot.item_count-1,id)
			if p.skill_slots[i]==id: slot.select(slot.item_count-1)
		slot.disabled=not p.alive or p.offline
