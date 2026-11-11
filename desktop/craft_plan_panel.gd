extends Panel
signal action(kind: String,value: String)
const P=preload("res://craft_plan.gd")
const Items=preload("res://items.gd")
var source_picker: OptionButton
var destination_picker: OptionButton
var recipes: OptionButton
var mode: OptionButton
var amount: SpinBox
var status: Label
var details: Label
var feedback: Label
var save_button: Button
var start_button: Button
var person: Dictionary={}
var world: Dictionary={}
func _ready() -> void:
	position=Vector2(160,80)
	size=Vector2(960,640)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172520")
	style.border_color=Color("a28e64")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel",style)
	label("부재 중 제작 계획",Vector2(28,24),24)
	button("닫기 · ESC",Vector2(770,20),160,hide)
	label("만들 물품",Vector2(28,100),18)
	recipes=OptionButton.new()
	recipes.position=Vector2(28,135)
	recipes.size=Vector2(360,40)
	for id in P.RECIPES: recipes.add_item(Items.CATALOG[id].name)
	add_child(recipes)
	recipes.item_selected.connect(func(_i): update_details())
	label("제작 방식",Vector2(28,200),18)
	mode=OptionButton.new()
	mode.position=Vector2(28,235)
	mode.size=Vector2(360,40)
	mode.add_item("정해진 개수 제작")
	mode.add_item("목표 소지 수량 유지")
	add_child(mode)
	mode.item_selected.connect(func(_i): update_details())
	label("수량 · 품질별 완성품도 합산",Vector2(28,300),18)
	amount=SpinBox.new()
	amount.position=Vector2(28,335)
	amount.size=Vector2(180,40)
	amount.min_value=1
	amount.step=1
	amount.value=3
	add_child(amount)
	source_picker=OptionButton.new()
	source_picker.position=Vector2(430,100)
	source_picker.size=Vector2(490,36)
	source_picker.add_item("재료 · 소지품만")
	source_picker.add_item("재료 · 집 보관함 우선 + 소지품")
	add_child(source_picker)
	destination_picker=OptionButton.new()
	destination_picker.position=Vector2(430,145)
	destination_picker.size=Vector2(490,36)
	destination_picker.add_item("완성품 · 소지품")
	destination_picker.add_item("완성품 · 집 보관함")
	add_child(destination_picker)
	source_picker.item_selected.connect(func(_i): update_details())
	destination_picker.item_selected.connect(func(_i): update_details())
	details=label("",Vector2(430,190),16)
	details.size=Vector2(490,205)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	status=label("",Vector2(28,400),17)
	status.size=Vector2(900,60)
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	save_button=button("계획 저장",Vector2(28,475),220,func(): submit(false))
	start_button=button("저장 · 생활 맡기기",Vector2(268,475),260,func(): submit(true))
	button("계획 취소 · 휴식",Vector2(548,475),240,func(): action.emit("plan_cancel",""); hide())
	feedback=label("",Vector2(28,530),17)
	feedback.size=Vector2(900,45)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("하루 최대 1개 · 몸 상태가 나쁘면 회복 우선 · 결과는 J의 일기에 기록됩니다.
같은 계획을 다시 저장해도 남은 횟수는 유지됩니다. 새로 시작하려면 취소 후 설정하세요.",Vector2(28,585),16)
	hide()
func label(text: String,at: Vector2,font_size: int) -> Label:
	var node:=Label.new()
	node.text=text
	node.position=at
	node.add_theme_font_size_override("font_size",font_size)
	add_child(node)
	return node
func button(text: String,at: Vector2,width: float,callback: Callable) -> Button:
	var node:=Button.new()
	node.text=text
	node.position=at
	node.size=Vector2(width,40)
	node.focus_mode=Control.FOCUS_NONE
	node.pressed.connect(callback)
	add_child(node)
	return node
func setup(w: Dictionary,p: Dictionary) -> void:
	world=w
	person=p
	var plan: Dictionary=p.get("craft_plan",{})
	recipes.select(P.RECIPES.find(plan.get("recipe","bandage")))
	mode.select(1 if plan.get("mode")=="target" else 0)
	source_picker.select(1 if plan.get("source")=="home" else 0)
	destination_picker.select(1 if plan.get("destination")=="home" else 0)
	update_details()
	amount.value=plan.get("amount",3)
	feedback.text=""
	refresh(w,p)
func update_details() -> void:
	if person.is_empty(): return
	var id: String=P.RECIPES[recipes.selected]
	amount.max_value=Items.CATALOG[id].limit
	source_picker.disabled=id=="iron_sword"
	destination_picker.disabled=id=="iron_sword"
	if id=="iron_sword":
		source_picker.select(0)
		destination_picker.select(0)
	var supply: Dictionary={"source":"home" if source_picker.selected==1 else "bag","destination":"home" if destination_picker.selected==1 else "bag"}
	var lines: PackedStringArray=[]
	if id=="iron_sword": lines.append("마을 대장간 · 철광석 2개 필요")
	else:
		lines.append("본인 소유의 집에서 제작")
		for material in P.C.RECIPES[id].cost: lines.append("%s · 소지 %d / 집 %d · 필요 %d" % [Items.CATALOG[material].name,Items.quantity(person,material),Items.quantity(P.Supply.box(world,person),material),P.C.RECIPES[id].cost[material]])
		if id=="herbal_tea": lines.append("찻잔과 켜진 벽난로 필요")
		if world.estate.owner!=person.life: lines.append("현재 본인 소유의 집이 없습니다.")
	lines.append("집 보관함 %d / 40개" % P.C.Storage.total(P.Supply.box(world,person)))
	lines.append(("목표 계산 · 소지+집 합계 %d개" if P.Supply.linked(supply) else "목표 계산 · 소지 %d개") % P.Supply.target_count(world,person,id,supply))
	lines.append("정해진 횟수 완료 후 휴식" if mode.selected==0 else "목표 충족 시 휴식 · 수량 감소 시 다시 제작")
	details.text="\n".join(lines)
func refresh(w: Dictionary,p: Dictionary) -> void:
	world=w
	person=p
	status.text="저장된 계획: "+P.summary(p)+("\n제작 계획 방침 적용 중" if p.policy=="plan" else "\n다른 생활 방침 적용 중")
	save_button.disabled=not p.alive
	start_button.disabled=not p.alive
	update_details()
func submit(start: bool) -> void:
	amount.apply()
	var value: String=P.RECIPES[recipes.selected]+"|"+("count" if mode.selected==0 else "target")+"|"+str(int(amount.value))+"|"+("home" if source_picker.selected==1 else "bag")+"|"+("home" if destination_picker.selected==1 else "bag")
	action.emit("plan_start" if start else "plan_save",value)
	if start: hide()
