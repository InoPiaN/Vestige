extends Panel
signal action(kind: String,value: String)
const C=preload("res://home_crafting.gd")
const Items=preload("res://items.gd")
var recipes: ItemList
var description: Label
var feedback: Label
var craft_button: Button
var repair_button: Button
var gear: OptionButton
var condition: Label
var current:="bandage"
var sword:=""
var gear_stamp:=""
var world: Dictionary={}
var person: Dictionary={}
func _ready() -> void:
	position=Vector2(160,80)
	size=Vector2(960,640)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172520")
	style.border_color=Color("a28e64")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel",style)
	label("집 작업대 · 제작과 수선",Vector2(28,24),24)
	button("닫기 · ESC",Vector2(770,20),160,hide)
	recipes=ItemList.new()
	recipes.position=Vector2(28,90)
	recipes.size=Vector2(340,280)
	recipes.add_theme_font_size_override("font_size",20)
	for id in C.RECIPES:
		var index:=recipes.add_item(C.RECIPES[id].name)
		recipes.set_item_metadata(index,id)
	recipes.select(0)
	recipes.item_selected.connect(func(i): current=recipes.get_item_metadata(i); refresh(world,person))
	add_child(recipes)
	description=label("",Vector2(400,90),18)
	description.size=Vector2(510,260)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	craft_button=button("1개 만들기",Vector2(400,350),240,func(): action.emit("craft_home",current))
	label("철검 수선 · 도구 1개로 내구도 +40",Vector2(28,420),19)
	gear=OptionButton.new()
	gear.position=Vector2(28,460)
	gear.size=Vector2(340,40)
	gear.item_selected.connect(func(i): sword=gear.get_item_metadata(i); refresh(world,person))
	add_child(gear)
	condition=label("",Vector2(400,422),17)
	repair_button=button("선택한 철검 수선",Vector2(400,460),240,func(): action.emit("repair_gear",sword))
	feedback=label("",Vector2(28,525),17)
	feedback.size=Vector2(900,45)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("소지한 재료만 사용합니다. 집 보관물은 먼저 꺼내세요.\n완성품은 I에서 사용합니다. 싱글은 작업대 창을 여는 동안 멈춥니다.",Vector2(28,580),16)
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
func refresh(w: Dictionary,p: Dictionary) -> void:
	world=w
	person=p
	if p.is_empty(): return
	var recipe: Dictionary=C.RECIPES[current]
	var lines: PackedStringArray=[recipe.name,"",recipe.description,""]
	for id in recipe.cost: lines.append("%s · %d / %d개" % [Items.CATALOG[id].name,Items.quantity(p,id),recipe.cost[id]])
	if recipe.has("tool"): lines.append("고친 찻잔 · %d개 (소비하지 않음)" % Items.quantity(p,"mug"))
	var why:=C.reason(w,p,current)
	lines.append("\n"+("제작 가능" if why.is_empty() else why))
	description.text="\n".join(lines)
	craft_button.disabled=not why.is_empty()
	var stamp:=JSON.stringify([p.gear_instances,p.gear_condition])
	if gear_stamp!=stamp:
		gear_stamp=stamp
		gear.clear()
		for id in p.gear_instances:
			if p.gear_instances[id]!="iron_sword": continue
			gear.add_item("철검 · %s · %d / 100" % [id.right(4),p.gear_condition[id]])
			gear.set_item_metadata(gear.item_count-1,id)
		if p.gear_instances.get(sword,"")!="iron_sword": sword=gear.get_item_metadata(0) if gear.item_count else ""
		for i in range(gear.item_count):
			if gear.get_item_metadata(i)==sword: gear.select(i)
	condition.text="수선 도구 %d개 · 내구도 0이어도 검은 남습니다." % Items.quantity(p,"repair_kit")
	repair_button.disabled=not C.allowed(p) or sword.is_empty() or p.gear_condition.get(sword,100)>=100 or Items.quantity(p,"repair_kit")<1
