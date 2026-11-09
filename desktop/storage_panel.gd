extends Panel
signal action(kind: String,value: String)
const Items=preload("res://items.gd")
const Storage=preload("res://house_storage.gd")
var carried: ItemList
var stored: ItemList
var feedback: Label
var title: Label
var put_button: Button
var take_button: Button
var signature:=""
func _ready() -> void:
	position=Vector2(160,80)
	size=Vector2(960,640)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172520")
	style.border_color=Color("a28e64")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel",style)
	title=label("집 보관함",Vector2(28,20))
	button("닫기 · B / ESC",Vector2(770,20),hide)
	label("소지품",Vector2(28,80))
	label("집에 남겨진 물건",Vector2(500,80))
	carried=list_at(Vector2(28,120))
	stored=list_at(Vector2(500,120))
	put_button=button("선택한 물품 1개 보관 →",Vector2(28,460),func(): transfer(false))
	take_button=button("← 선택한 물품 1개 꺼내기",Vector2(500,460),func(): transfer(true))
	feedback=label("",Vector2(28,520))
	feedback.size=Vector2(900,45)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("착용 중인 장비를 보관하면 벗습니다. 집에 보관한 물건은 죽어도 남습니다.\n증거물은 I의 별도 보관 버튼을 사용합니다. 싱글은 이 창에서 시간이 멈춥니다.",Vector2(28,580))
	hide()
func label(text: String,at: Vector2) -> Label:
	var node:=Label.new()
	node.position=at
	node.text=text
	node.add_theme_font_size_override("font_size",17)
	add_child(node)
	return node
func button(text: String,at: Vector2,callback: Callable) -> Button:
	var node:=Button.new()
	node.text=text
	node.position=at
	node.size=Vector2(230 if at.y>100 else 160,40)
	node.focus_mode=Control.FOCUS_NONE
	node.pressed.connect(callback)
	add_child(node)
	return node
func list_at(at: Vector2) -> ItemList:
	var node:=ItemList.new()
	node.position=at
	node.size=Vector2(430,320)
	node.add_theme_font_size_override("font_size",18)
	add_child(node)
	return node
func fill(list: ItemList,p: Dictionary) -> void:
	var selected: String=""
	if not list.get_selected_items().is_empty(): selected=list.get_item_metadata(list.get_selected_items()[0])
	list.clear()
	for row in Items.entries(p):
		if row.id.begins_with("evidence:"): continue
		var def:=Items.definition(p,row.id)
		var worn: bool=row.id in p.get("equipped_ids",{}).values()
		var index:=list.add_item(def.name+" ×%d" % row.count+(" · 착용" if worn else ""))
		list.set_item_metadata(index,row.id)
		list.set_item_tooltip(index,def.description)
		if selected==row.id: list.select(index)
func refresh(w: Dictionary,p: Dictionary) -> void:
	var access: bool=Storage.allowed(w,p) and w.estate.has("storage")
	put_button.disabled=not access
	take_button.disabled=not access
	if not access:
		carried.clear()
		stored.clear()
		signature=""
		feedback.text="집 가까이에서 이용하세요. 살아 있는 다른 주민의 집은 열 수 없습니다."
		return
	var box: Dictionary=w.estate.storage
	var stamp:=JSON.stringify([Items.entries(p),p.get("equipped_ids",{}),Items.entries(box)])
	if signature==stamp: return
	signature=stamp
	title.text="집 보관함 · %d / %d개" % [Storage.total(box),Storage.CAPACITY]
	fill(carried,p)
	fill(stored,box)
func transfer(take: bool) -> void:
	var list:=stored if take else carried
	if list.get_selected_items().is_empty():
		feedback.text="목록에서 물품을 선택하세요."
		return
	action.emit("take_item" if take else "store_item",list.get_item_metadata(list.get_selected_items()[0]))
