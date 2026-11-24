extends Panel
signal action(kind: String,value: String)
const M=preload("res://village_market.gd")
const Items=preload("res://items.gd")
var sale_mode: OptionButton
var details: Label
var repurchasing:=false
var repurchase_token:=""
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
	sale_mode=OptionButton.new()
	sale_mode.position=Vector2(490,115)
	sale_mode.size=Vector2(440,35)
	sale_mode.add_item("판매 · 소지품")
	sale_mode.add_item("되사기 · 최근 판매 장비 10개")
	add_child(sale_mode)
	sale_mode.item_selected.connect(func(i): repurchasing=i==1; stamp=""; refresh(world,person))
	purchases=ItemList.new()
	purchases.position=Vector2(28,160)
	purchases.size=Vector2(430,210)
	purchases.add_theme_font_size_override("font_size",18)
	add_child(purchases)
	purchases.item_selected.connect(func(i): buying=purchases.get_item_metadata(i); refresh(world,person))
	sales=ItemList.new()
	sales.position=Vector2(490,160)
	sales.size=Vector2(440,210)
	sales.add_theme_font_size_override("font_size",18)
	add_child(sales)
	sales.item_selected.connect(select_sale)
	buy_button=button("선택한 재료 1개 구매",Vector2(28,380),300,func(): action.emit("market_buy",buying))
	sell_button=button("선택한 물품 1개 판매",Vector2(490,380),300,func(): action.emit("market_repurchase" if repurchasing else "market_sell",repurchase_token if repurchasing else selling))
	details=label("물품을 선택하면 판매 정보가 표시됩니다.",Vector2(28,430),16)
	details.size=Vector2(900,75)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	feedback=label("",Vector2(28,515),17)
	feedback.size=Vector2(900,48)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("장비 가격은 품질·강화·내구 반영. 착용 장비·시작 의복·사건 증거는 판매 불가.
되사기는 같은 인물의 최근 장비 10개만 유지. 초과 시 오래된 장비부터 사라집니다.",Vector2(28,580),16)
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
	var signature:=JSON.stringify([w.market,p.gold,p.belongings,p.ore,p.herb,p.gear_instances,p.gear_condition,p.gear_quality,p.equipped_ids,p.get("buyback_orders",[]),repurchasing])
	if stamp!=signature:
		stamp=signature
		purchases.clear()
		for id in M.GOODS:
			var i:=purchases.add_item("%s · %d은화 / %d개" % [Items.CATALOG[id].name,M.GOODS[id].price,w.market.stock[id]])
			purchases.set_item_metadata(i,id)
			if id==buying: purchases.select(i)
		sales.clear()
		var entries: Array=p.get("buyback_orders",[]).duplicate() if repurchasing else Items.entries(p)
		if repurchasing: entries.reverse()
		for row in entries:
			var holder: Dictionary=p.buyback if repurchasing else p
			var coins: int=row.price if repurchasing else M.price(p,row.id)
			if coins<=0: continue
			var def:=Items.definition(holder,row.id)
			var worn: bool=row.id in p.equipped_ids.values()
			var i:=sales.add_item("%s · %d은화 / %d개%s" % [def.name,coins,1 if repurchasing else row.count," · 착용" if worn else ""])
			sales.set_item_metadata(i,row.token if repurchasing else row.id)
			sales.set_item_tooltip(i,def.description)
			sales.set_item_custom_fg_color(i,Color(def.color))
			if (row.token==repurchase_token if repurchasing else row.id==selling): sales.select(i)
	buy_button.disabled=not M.allowed(p) or w.market.stock.get(buying,0)<=0 or p.gold<M.GOODS[buying].price or Items.family_quantity(p,buying)>=Items.CATALOG[buying].limit
	sell_button.disabled=not M.allowed(p) or Items.quantity(p,selling)<1 or M.price(p,selling)<=0 or selling in p.equipped_ids.values()

	update_details()

func select_sale(i: int) -> void:
	if repurchasing: repurchase_token=sales.get_item_metadata(i)
	else: selling=sales.get_item_metadata(i)
	refresh(world,person)
func update_details() -> void:
	var row:=M.order(person,repurchase_token) if repurchasing else {}
	var id: String=row.get("id","") if repurchasing else selling
	var holder: Dictionary=person.buyback if repurchasing else person
	var coins: int=row.get("price",0) if repurchasing else M.price(person,id)
	sell_button.text="선택한 장비 되사기" if repurchasing else "선택한 물품 1개 판매"
	if repurchasing:
		sell_button.disabled=not M.allowed(person) or row.is_empty() or person.gold<coins
		if not row.is_empty(): sell_button.disabled=sell_button.disabled or Items.quantity(person,holder.gear_instances[id])>=Items.CATALOG[holder.gear_instances[id]].limit
	if coins<=0 or Items.quantity(holder,id)<=0:
		details.text="목록에서 물품을 선택하세요."
		return
	var def:=Items.definition(holder,id)
	details.text="%s · %s %d은화" % [def.name,"되사기" if repurchasing else "판매가",coins]
	if holder.gear_instances.has(id):
		var maker: Dictionary=holder.gear_records[id].maker
		details.text+="\n제작자 %s · 강화 +%d · 내구도 %d / 100" % [maker.get("name","기록 없음"),holder.gear_quality[id].upgrade,holder.gear_condition[id]]
		if repurchasing: details.text+=" · 원래 장비와 기록을 회수합니다."
		elif id in person.equipped_ids.values(): details.text+=" · 착용 중: 먼저 해제하세요."
	else: details.text+="\n재료와 소모품은 되사기 대상이 아닙니다."
