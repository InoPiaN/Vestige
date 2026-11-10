extends Panel
signal action(kind: String,value: String)
const M=preload("res://village_market.gd")
const Items=preload("res://items.gd")
var purchases: ItemList
var sales: ItemList
var wallet: Label
var feedback: Label
var buy_button: Button
var sell_button: Button
var buying:="cloth"
var selling:=""
var stamp:=""
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
	label("잿불 장터 · 재료와 제작품",Vector2(28,24),24)
	button("닫기 · ESC",Vector2(770,20),160,hide)
	wallet=label("",Vector2(28,70),18)
	label("구매 · 1개 가격 / 남은 재고",Vector2(28,120),19)
	label("판매 · 1개 가격 / 소지 수량",Vector2(490,120),19)
	purchases=ItemList.new()
	purchases.position=Vector2(28,160)
	purchases.size=Vector2(430,285)
	purchases.add_theme_font_size_override("font_size",18)
	add_child(purchases)
	purchases.item_selected.connect(func(i): buying=purchases.get_item_metadata(i); refresh(world,person))
	sales=ItemList.new()
	sales.position=Vector2(490,160)
	sales.size=Vector2(440,285)
	sales.add_theme_font_size_override("font_size",18)
	add_child(sales)
	sales.item_selected.connect(func(i): selling=sales.get_item_metadata(i); refresh(world,person))
	buy_button=button("선택한 재료 1개 구매",Vector2(28,460),300,func(): action.emit("market_buy",buying))
	sell_button=button("선택한 물품 1개 판매",Vector2(490,460),300,func(): action.emit("market_sell",selling))
	feedback=label("",Vector2(28,515),17)
	feedback.size=Vector2(900,48)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("매일 재고 보충 · 품질과 철검 내구도에 따라 판매가가 달라집니다.
착용 장비·시작 의복·사건 증거는 판매 불가. 판매한 물품은 되살 수 없습니다.",Vector2(28,580),16)
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
	wallet.text="보유 은화 %d · 월드 %d일 · 싱글은 거래 창을 열면 시간이 멈춥니다." % [p.gold,int(w.time/M.DAY)+1]
	var signature:=JSON.stringify([w.market,p.gold,p.belongings,p.ore,p.herb,p.gear_instances,p.gear_condition,p.gear_quality,p.equipped_ids])
	if stamp!=signature:
		stamp=signature
		purchases.clear()
		for id in M.GOODS:
			var i:=purchases.add_item("%s · %d은화 / %d개" % [Items.CATALOG[id].name,M.GOODS[id].price,w.market.stock[id]])
			purchases.set_item_metadata(i,id)
			if id==buying: purchases.select(i)
		sales.clear()
		for row in Items.entries(p):
			var coins:=M.price(p,row.id)
			if coins<=0: continue
			var def:=Items.definition(p,row.id)
			var worn: bool=row.id in p.equipped_ids.values()
			var i:=sales.add_item("%s · %d은화 / %d개%s" % [def.name,coins,row.count," · 착용" if worn else ""])
			sales.set_item_metadata(i,row.id)
			sales.set_item_tooltip(i,def.description)
			sales.set_item_custom_fg_color(i,Color(def.color))
			if row.id==selling: sales.select(i)
	buy_button.disabled=not M.allowed(p) or w.market.stock.get(buying,0)<=0 or p.gold<M.GOODS[buying].price or Items.family_quantity(p,buying)>=Items.CATALOG[buying].limit
	sell_button.disabled=not M.allowed(p) or Items.quantity(p,selling)<1 or M.price(p,selling)<=0 or selling in p.equipped_ids.values()
