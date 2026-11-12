extends Panel
signal action(kind: String,value: String)
const P=preload("res://craft_plan.gd")
const Items=preload("res://items.gd")
var plan_picker: OptionButton
var selected_plan:=0
var picker_stamp:=""
var pending_reload:=false
var pending_stamp:=""
var manage_buttons: Array[Button]=[]
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
	plan_picker=OptionButton.new()
	plan_picker.position=Vector2(28,65)
	plan_picker.size=Vector2(390,30)
	add_child(plan_picker)
	plan_picker.item_selected.connect(func(i): selected_plan=i; load_selected())
	manage_buttons.append(button("↑",Vector2(435,60),55,func(): manage("plan_up")))
	manage_buttons.append(button("↓",Vector2(500,60),55,func(): manage("plan_down")))
	manage_buttons.append(button("정지 / 재개",Vector2(565,60),165,func(): manage("plan_pause")))
	manage_buttons.append(button("선택 삭제",Vector2(745,60),175,func(): manage("plan_delete")))
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
	var status_scroll:=ScrollContainer.new()
	status_scroll.position=Vector2(28,400)
	status_scroll.size=Vector2(900,100)
	status_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(status_scroll)
	status=label("",Vector2.ZERO,16)
	status.reparent(status_scroll)
	status.custom_minimum_size=Vector2(880,0)
	status.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	save_button=button("계획 저장",Vector2(28,505),220,func(): submit(false))
	start_button=button("저장 · 생활 맡기기",Vector2(268,505),260,func(): submit(true))
	button("전체 삭제 · 휴식",Vector2(548,505),240,func(): action.emit("plan_cancel",""); hide())
	feedback=label("",Vector2(28,553),17)
	feedback.size=Vector2(900,45)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("하루 최대 1개 · 몸 상태가 나쁘면 회복 우선 · 결과는 J의 일기에 기록됩니다.
위에서부터 가능한 계획 1개를 수행합니다. 순서 변경·재저장은 남은 횟수를 보존합니다.",Vector2(28,590),16)
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
	selected_plan=0
	refresh(w,p)
	load_selected()
	feedback.text=""
func load_selected() -> void:
	var rows:=P.plans(person)
	var plan: Dictionary=rows[selected_plan] if selected_plan<rows.size() else {}
	recipes.select(P.RECIPES.find(plan.get("recipe","bandage")))
	mode.select(1 if plan.get("mode")=="target" else 0)
	source_picker.select(1 if plan.get("source")=="home" else 0)
	destination_picker.select(1 if plan.get("destination")=="home" else 0)
	update_details()
	amount.value=plan.get("amount",3)
func manage(kind: String) -> void:
	var previous:=selected_plan
	pending_stamp=JSON.stringify(P.plans(person))
	pending_reload=true
	if kind=="plan_up": selected_plan=maxi(0,selected_plan-1)
	if kind=="plan_down": selected_plan=mini(P.plans(person).size()-1,selected_plan+1)
	action.emit(kind,str(previous))
	refresh(world,person)
func update_details() -> void:
	if person.is_empty(): return
	var id: String=P.RECIPES[recipes.selected]
	amount.max_value=Items.CATALOG[id].limit
	source_picker.disabled=id in P.FORGE
	destination_picker.disabled=id in P.FORGE
	if id in P.FORGE:
		source_picker.select(0)
		destination_picker.select(0)
	var supply: Dictionary={"source":"home" if source_picker.selected==1 else "bag","destination":"home" if destination_picker.selected==1 else "bag"}
	var lines: PackedStringArray=[]
	if id=="iron_sword": lines.append("마을 대장간 · 철광석 2개 필요")
	elif id in P.Armor.RECIPES:
		lines.append("마을 대장간 · 소지품 재료 사용")
		for material in P.Armor.RECIPES[id].cost: lines.append("%s · 소지 %d / 필요 %d" % [Items.CATALOG[material].name,Items.quantity(person,material),P.Armor.RECIPES[id].cost[material]])
	else:
		lines.append("본인 소유의 집에서 제작")
		for material in P.C.RECIPES[id].cost: lines.append("%s · 소지 %d / 집 %d · 필요 %d" % [Items.CATALOG[material].name,Items.quantity(person,material),Items.quantity(P.Supply.box(world,person),material),P.C.RECIPES[id].cost[material]])
		if id=="herbal_tea": lines.append("찻잔과 켜진 벽난로 필요")
		if world.estate.owner!=person.life: lines.append("현재 본인 소유의 집이 없습니다.")
	lines.append("집 보관함 %d / 40개" % P.C.Storage.total(P.Supply.box(world,person)))
	lines.append(("목표 계산 · 소지+집 합계 %d개" if P.Supply.linked(supply) else "목표 계산 · 소지 %d개") % P.Supply.target_count(world,person,id,supply))
	lines.append("정해진 횟수 완료 후 다음 계획" if mode.selected==0 else "목표 충족 시 다음 계획 · 감소 시 다시 제작")
	details.text="\n".join(lines)
func refresh(w: Dictionary,p: Dictionary) -> void:
	world=w
	person=p
	var rows:=P.plans(p)
	var names: Array=[]
	for row in rows: names.append(row.recipe)
	var stamp:=JSON.stringify(names)
	if picker_stamp!=stamp:
		picker_stamp=stamp
		plan_picker.clear()
		for i in rows.size(): plan_picker.add_item("%d순위 · %s" % [i+1,Items.CATALOG[rows[i].recipe].name])
		if rows.size()<3: plan_picker.add_item("+ 새 계획 추가")
	selected_plan=clampi(selected_plan,0,plan_picker.item_count-1)
	plan_picker.select(selected_plan)
	if pending_reload and JSON.stringify(rows)!=pending_stamp:
		pending_reload=false
		load_selected()
	for node in manage_buttons: node.disabled=not p.alive or selected_plan>=rows.size()
	manage_buttons[0].disabled=manage_buttons[0].disabled or selected_plan==0
	manage_buttons[1].disabled=manage_buttons[1].disabled or selected_plan>=rows.size()-1
	status.text="저장된 계획: "+P.summary(p)+("\n제작 계획 방침 적용 중" if p.policy=="plan" else "\n다른 생활 방침 적용 중")
	save_button.disabled=not p.alive
	start_button.disabled=not p.alive
	update_details()
func submit(start: bool) -> void:
	amount.apply()
	var value: String=str(selected_plan)+"|"+P.RECIPES[recipes.selected]+"|"+("count" if mode.selected==0 else "target")+"|"+str(int(amount.value))+"|"+("home" if source_picker.selected==1 else "bag")+"|"+("home" if destination_picker.selected==1 else "bag")
	action.emit("plan_start" if start else "plan_save",value)
	if start: hide()
