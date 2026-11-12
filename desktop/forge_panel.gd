extends "res://crafting_panel.gd"
const U=preload("res://sword_upgrade.gd")
const AU=preload("res://armor_upgrade.gd")
const Q=preload("res://craft_quality.gd")
var upgrade_button: Button
func _ready() -> void:
	position=Vector2(160,90)
	size=Vector2(960,620)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172520")
	style.border_color=Color("a28e64")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel",style)
	label("잿불 대장간 · 제작과 강화",Vector2(28,24),24)
	button("닫기 · ESC",Vector2(770,20),160,hide)
	label("새 철검 제작 · 철광석 2개",Vector2(28,90),20)
	craft_button=button("철검 1개 제작",Vector2(650,85),280,func(): action.emit("interact",""))
	condition=label("",Vector2(28,140),16)
	label("강화할 소지 장비",Vector2(28,205),20)
	gear=OptionButton.new()
	gear.position=Vector2(28,245)
	gear.size=Vector2(470,42)
	gear.item_selected.connect(func(i): sword=gear.get_item_metadata(i); refresh(world,person))
	add_child(gear)
	description=label("",Vector2(28,310),19)
	description.size=Vector2(900,135)
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	upgrade_button=button("선택한 장비 강화",Vector2(650,245),280,submit_upgrade)
	feedback=label("",Vector2(28,465),17)
	feedback.size=Vector2(900,60)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("강화는 확정 성공 · 최대 +3.\n품질·제작자·내구도를 보존합니다.",Vector2(28,545),16)
	button("가죽 / 철제 갑옷 제작",Vector2(650,545),280,func(): action.emit("armor_menu",""))
	hide()
func refresh(w: Dictionary,p: Dictionary) -> void:
	world=w
	person=p
	var stamp:=JSON.stringify([p.gear_instances,p.gear_quality])
	if stamp!=gear_stamp:
		gear_stamp=stamp
		gear.clear()
		for id in p.gear_instances:
			if p.gear_instances[id] not in ["iron_sword","leather","iron_armor"]: continue
			gear.add_item(Items.definition(p,id).name)
			gear.set_item_metadata(gear.item_count-1,id)
		if not p.gear_instances.has(sword):
			sword=gear.get_item_metadata(0) if gear.item_count>0 else ""
			for id in p.gear_instances:
				if p.gear_instances[id]=="iron_sword":
					sword=id
					break
		for i in range(gear.item_count):
			if gear.get_item_metadata(i)==sword: gear.select(i)
	condition.text=M.progress(p,"smithing")+"\n"+M.rate_text(p,"smithing")
	var near: bool=p.alive and not p.offline and p.get("room","village")=="village" and Vector2(p.x,p.y).distance_to(Vector2(5,7))<2
	craft_button.disabled=not near or p.ore<2 or p.sword>=5
	if p.gear_instances.get(sword) in AU.Stats.KINDS:
		refresh_armor(p)
		return
	var why:=U.reason(p,sword)
	upgrade_button.disabled=not why.is_empty()
	var n:=U.level(p,sword)
	description.text="소지 철광석 %d · 은화 %d\n" % [p.ore,p.gold]
	if sword.is_empty(): description.text+="제작하거나 회수한 장비가 필요합니다."
	elif n>=3: description.text+="최대 강화 +3 · 공격력 %d\n내구도 %d / 100" % [Q.attack(p,sword),p.gear_condition[sword]]
	else:
		description.text+="+%d → +%d · 공격력 %d → %d\n비용: 철광석 %d · 은화 %d\n내구도 %d / 100 · 내구도 0이면 실제 공격력 9" % [n,n+1,Q.attack(p,sword),Q.attack(p,sword)+2,U.ORE[n],U.GOLD[n],p.gear_condition[sword]]
		if not why.is_empty(): description.text+="\n"+why

func submit_upgrade() -> void:
	var kind: String="upgrade_armor" if person.gear_instances.get(sword) in AU.Stats.KINDS else "upgrade_sword"
	action.emit(kind,sword+"|"+str(U.level(person,sword)))
func refresh_armor(p: Dictionary) -> void:
	var n:=AU.level(p,sword)
	var why:=AU.reason(p,sword)
	upgrade_button.disabled=not why.is_empty()
	var rating:=AU.Stats.rating(p,sword)
	description.text="최대 강화 +3 · 피해 감소 %d" % rating if n>=3 else "+%d → +%d · 피해 감소 %d → %d" % [n,n+1,rating,rating+1]
	if n<3:
		description.text+="\n비용 (필요 / 소지): "
		for material in AU.COSTS[p.gear_instances[sword]][n]: description.text+="%s %d/%d · " % [Items.CATALOG[material].name,AU.COSTS[p.gear_instances[sword]][n][material],Items.quantity(p,material)]
		description.text+="은화 %d/%d" % [AU.GOLD[n],p.gold]
	description.text+="\n내구도 %d / 100 · 파손 시 피해 감소 0 · 회피 기력 %d 유지" % [p.gear_condition[sword],32 if p.gear_instances[sword]=="leather" else 38]
	if not why.is_empty(): description.text+="\n"+why
