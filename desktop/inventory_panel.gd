extends Panel
signal action(kind: String, value: String)
const Items=preload("res://items.gd")
var person: Dictionary={}
var category: String="전체"
var selected: String=""
var slots: Array[Button]=[]
var heading: Label
var details: Label
var use_button: Button
var feedback: Label
var signature: String=""
func _ready() -> void:
	position=Vector2(160,80)
	size=Vector2(960,640)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172520")
	style.border_color=Color("a28e64")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel",style)
	heading=label("소지품",Vector2(28,20),24)
	var close:=button("닫기 · I / ESC",Vector2(770,20),160)
	close.pressed.connect(hide)
	var filter:=OptionButton.new()
	filter.position=Vector2(28,78)
	filter.size=Vector2(240,38)
	for text in ["전체","재료","소모품","장비","기록"]: filter.add_item(text)
	filter.item_selected.connect(func(i): category=filter.get_item_text(i); signature=""; refresh(person))
	add_child(filter)
	label("이름순 정렬 · 수량은 착용 중인 장비를 포함",Vector2(285,86),14)
	var grid:=GridContainer.new()
	grid.columns=6
	grid.position=Vector2(28,135)
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	add_child(grid)
	for i in range(24):
		var cell:=Button.new()
		cell.custom_minimum_size=Vector2(88,88)
		cell.add_theme_font_size_override("font_size",12)
		cell.focus_mode=Control.FOCUS_NONE
		cell.pressed.connect(func(): choose(String(cell.get_meta("item",""))))
		var icon:=TextureRect.new()
		icon.name="Icon"
		icon.position=Vector2(32,5)
		icon.size=Vector2(24,24)
		icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
		cell.add_child(icon)
		grid.add_child(cell)
		slots.append(cell)
	details=label("아이템을 선택하세요.",Vector2(630,140),19)
	details.size=Vector2(300,320)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	use_button=button("사용",Vector2(630,465),290)
	use_button.pressed.connect(activate)
	feedback=label("",Vector2(28,535),16)
	feedback.size=Vector2(900,40)
	label("은화는 지갑에 보관합니다. 장비를 벗어도 가방에서 사라지지 않습니다.\n싱글은 가방을 여는 동안 정지하며 공유 세계의 시간은 계속 흐릅니다.",Vector2(28,578),15)
	hide()
func label(text: String, at: Vector2, font_size: int) -> Label:
	var node:=Label.new()
	node.text=text
	node.position=at
	node.add_theme_font_size_override("font_size",font_size)
	add_child(node)
	return node
func button(text: String, at: Vector2, width: float) -> Button:
	var node:=Button.new()
	node.text=text
	node.position=at
	node.size=Vector2(width,38)
	node.focus_mode=Control.FOCUS_NONE
	add_child(node)
	return node
func choose(id: String) -> void:
	selected=id
	signature=""
	refresh(person)
func refresh(p: Dictionary) -> void:
	person=p
	var rows:=Items.entries(p,category)
	var stamp:=JSON.stringify([rows,p.get("equipment",{}),p.get("gear_condition",{}),p.get("stamina",0),p.get("hp",0),p.get("alive",true),p.get("offline",false),p.get("gold",0),selected])
	if signature==stamp: return
	signature=stamp
	heading.text="소지품  ·  %d항목  /  은화 %d" % [Items.entries(p).size(),p.get("gold",0)]
	for i in range(slots.size()):
		var cell:=slots[i]
		cell.disabled=i>=rows.size()
		cell.text=""
		cell.icon=null
		cell.get_node("Icon").texture=null
		cell.remove_theme_stylebox_override("normal")
		cell.set_meta("item","")
		if i>=rows.size(): continue
		var row: Dictionary=rows[i]
		var item: Dictionary=Items.definition(p,row.id)
		cell.set_meta("item",row.id)
		var equipped: bool=item.has("slot") and (p.get("equipped_ids",{}).get(item.slot)==row.id if row.id.begins_with("gear-") else p.get("equipment",{}).get(item.slot)==row.id)
		if row.id==selected:
			var highlight:=StyleBoxFlat.new()
			highlight.bg_color=Color("34483b")
			highlight.border_color=Color("d6bd7c")
			highlight.set_border_width_all(2)
			cell.add_theme_stylebox_override("normal",highlight)
		cell.get_node("Icon").texture=icon_for(row.id)
		cell.text="\n\n"+item.name+"\n×%d" % row.count+(" · 착용" if equipped else "")
		cell.tooltip_text=item.description
		cell.add_theme_color_override("font_color",Color(item.color))
	if selected.is_empty() or Items.quantity(p,selected)==0:
		details.text="아이템을 선택하세요." if selected.is_empty() else "이 아이템을 모두 사용했습니다."
		use_button.disabled=true
		use_button.text="선택 없음"
		return
	var item: Dictionary=Items.definition(person,selected)
	var count:=Items.quantity(p,selected)
	details.text=item.name+"\n"+item.category+" · %d / %d\n\n" % [count,item.limit]+item.description
	use_button.disabled=not p.get("alive",true)
	if item.has("slot"):
		var worn: bool=(p.get("equipped_ids",{}).get(item.slot)==selected if selected.begins_with("gear-") else p.equipment.get(item.slot)==selected)
		use_button.text="착용 해제" if worn else "착용"
	elif selected in ["bandage","herbal_tea"]:
		use_button.text="사용"
		use_button.disabled=use_button.disabled or p.offline or (p.hp>=100 and (selected=="bandage" or p.stamina>=100))
	elif selected.begins_with("evidence:"):
		use_button.text="집 보관함에 남기기"
		use_button.disabled=use_button.disabled or p.offline
	elif selected=="herb":
		use_button.text="약초 사용 · 체력 +30"
		use_button.disabled=use_button.disabled or p.hp>=100 or p.offline
	else:
		use_button.text="재료 / 기록 아이템"
		use_button.disabled=true
func activate() -> void:
	if selected.is_empty() or Items.quantity(person,selected)<=0 or use_button.disabled: return
	var item: Dictionary=Items.definition(person,selected)
	if selected.begins_with("gear-"):
		action.emit("equip_instance",selected)
	elif item.has("slot"):
		var value: String="none" if person.equipment.get(item.slot)==selected else selected
		action.emit("equip",item.slot+":"+value)
	elif selected.begins_with("evidence:"): action.emit("store_evidence",selected)
	elif selected in ["bandage","herbal_tea"]: action.emit("use_crafted",selected)
	elif selected=="herb": action.emit("heal","")

var icons: Dictionary={}
func icon_for(id: String) -> ImageTexture:
	if icons.has(id): return icons[id]
	var image:=Image.create(16,16,false,Image.FORMAT_RGBA8)
	var color:=Color(Items.definition(person,id).color)
	id=person.get("gear_instances",{}).get(id,id)
	if id in ["mug","herbal_tea","broken_cup"]:
		image.fill_rect(Rect2i(3,5,8,8),color)
		image.fill_rect(Rect2i(10,6,4,5),color)
		image.fill_rect(Rect2i(11,7,2,3),Color("172520"))
		image.fill_rect(Rect2i(4,5,6,2),Color("66543a"))
	elif id=="bandage":
		image.fill_rect(Rect2i(3,4,10,8),color)
		image.fill_rect(Rect2i(6,4,1,8),color.darkened(0.25))
		image.fill_rect(Rect2i(10,4,1,8),color.darkened(0.25))
	elif id=="iron_sword":
		image.fill_rect(Rect2i(7,1,2,10),color)
		image.fill_rect(Rect2i(4,10,8,2),Color("c5a46b"))
		image.fill_rect(Rect2i(7,12,2,3),Color("916c4d"))
	elif id=="herb":
		image.fill_rect(Rect2i(7,4,2,11),color.darkened(0.3))
		image.fill_rect(Rect2i(3,4,5,3),color)
		image.fill_rect(Rect2i(9,8,4,3),color)
		image.fill_rect(Rect2i(6,1,4,3),Color("d2dfac"))
	elif id=="ore":
		image.fill_rect(Rect2i(3,5,10,8),color.darkened(0.3))
		image.fill_rect(Rect2i(5,2,6,6),color)
		image.fill_rect(Rect2i(4,6,4,3),color.lightened(0.2))
	elif id.begins_with("evidence:"):
		image.fill_rect(Rect2i(4,3,8,10),color)
		image.fill_rect(Rect2i(6,5,4,6),Color("172520"))
		image.fill_rect(Rect2i(9,2,4,5),Color.TRANSPARENT)
	elif id=="relic":
		image.fill_rect(Rect2i(4,2,8,12),color)
		image.fill_rect(Rect2i(6,4,4,8),Color("645742"))
		image.fill_rect(Rect2i(7,6,2,4),color)
	else:
		image.fill_rect(Rect2i(4,4,8,10),color)
		image.fill_rect(Rect2i(2,4,12,3),color.darkened(0.2))
		if id=="hood":
			image.fill_rect(Rect2i(5,1,6,8),color)
			image.fill_rect(Rect2i(6,4,4,6),Color("273731"))
		elif id=="traveler":
			image.fill_rect(Rect2i(2,10,12,5),color)
			image.fill_rect(Rect2i(7,4,2,9),color.lightened(0.2))
		else:
			image.fill_rect(Rect2i(7,4,2,9),Color("d0b080"))
	icons[id]=ImageTexture.create_from_image(image)
	return icons[id]
