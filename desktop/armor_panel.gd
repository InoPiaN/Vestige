extends "res://crafting_panel.gd"
const A=preload("res://armor_crafting.gd")
var armor_kind:="leather"
func _ready() -> void:
	position=Vector2(160,90)
	size=Vector2(960,620)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172520")
	style.border_color=Color("a28e64")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel",style)
	label("잿불 대장간 · 방어구 제작",Vector2(28,24),24)
	button("닫기 · ESC",Vector2(770,20),160,hide)
	recipes=ItemList.new()
	recipes.position=Vector2(28,95)
	recipes.size=Vector2(270,150)
	for id in A.RECIPES:
		recipes.add_item(Items.CATALOG[id].name)
		recipes.set_item_metadata(recipes.item_count-1,id)
	recipes.select(0)
	recipes.item_selected.connect(func(i): armor_kind=recipes.get_item_metadata(i); refresh(world,person))
	add_child(recipes)
	description=label("",Vector2(330,95),18)
	description.size=Vector2(600,350)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	craft_button=button("선택한 갑옷 1개 제작",Vector2(330,420),320,func(): action.emit("craft_armor",armor_kind))
	feedback=label("",Vector2(28,480),17)
	feedback.size=Vector2(900,65)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("착용은 외형·장비에서 합니다. 가죽은 장터에서 구입할 수 있습니다.\n피격 시 내구도 -5, 내구도 0이면 방어 효과가 사라집니다. 집 작업대에서 수선하세요.",Vector2(28,550),16)
	hide()
func refresh(w: Dictionary,p: Dictionary) -> void:
	world=w
	person=p
	var recipe: Dictionary=A.RECIPES[armor_kind]
	var text: String=Items.CATALOG[armor_kind].name+"\n"+M.progress(p,recipe.field)+"\n"+M.rate_text(p,recipe.field)+"\n"
	text+="피해 감소 · 일반 3~4 / 양품 5 / 대성공 6~7\n회피 기력 32\n" if armor_kind=="leather" else "피해 감소 · 일반 6~7 / 양품 8 / 대성공 9~10\n회피 기력 38\n"
	text+="\n제작 재료 (소지품)\n"
	for id in recipe.cost: text+="%s · 필요 %d / 소지 %d\n" % [Items.CATALOG[id].name,recipe.cost[id],Items.quantity(p,id)]
	text+="완성 경험치 +%d · 소지 %d / 3\n" % [M.gain(p,armor_kind),Items.quantity(p,armor_kind)]
	var why:=A.reason(p,armor_kind)
	if not why.is_empty(): text+="\n"+why
	description.text=text
	craft_button.disabled=not why.is_empty()
