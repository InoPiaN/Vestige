extends Panel
const T=preload("res://travel.gd")
signal action(kind: String,value: String)
var person: Dictionary={}
var heading: Label
var info: Label
var feedback: Label
var coach_button: Button
var labels: Array[Label]=[]
var shops: Dictionary={}
const POINTS=[Vector2(155,190),Vector2(470,240),Vector2(775,170)]
func label(text: String,at: Vector2,font_size: int=18) -> Label:
	var l:=Label.new()
	l.text=text
	l.position=at
	l.add_theme_font_size_override("font_size",font_size)
	add_child(l)
	return l
func button(text: String,at: Vector2,width: int,callback: Callable) -> Button:
	var b:=Button.new()
	b.text=text
	b.position=at
	b.size=Vector2(width,38)
	b.pressed.connect(callback)
	add_child(b)
	return b
func _ready() -> void:
	position=Vector2(160,90)
	size=Vector2(960,620)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172520")
	style.border_color=Color("a28e64")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel",style)
	heading=label("",Vector2(28,24),24)
	button("닫기 · M / ESC",Vector2(755,20),175,hide)
	label("직접 도착하면 지역이 지도에 기록됩니다. 출구 가까이에서 E로 이동하세요.",Vector2(28,80),17)
	for at in POINTS: labels.append(label("",at-Vector2(88,10),20))
	info=label("",Vector2(28,335),17)
	info.size=Vector2(900,80)
	info.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	coach_button=button("마차 탑승 · 은화5",Vector2(630,425),300,func(): action.emit("coach",""))
	label("나루 상인 소하 · 상인 가까이에서만 구매 가능",Vector2(28,435),17)
	var index:=0
	for id in T.GOODS:
		shops[id]=button("",Vector2(28+index*305,480),290,func(): action.emit("harbor_buy",id))
		index+=1
	feedback=label("",Vector2(28,540),16)
	feedback.size=Vector2(900,60)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hide()
func refresh(w: Dictionary,p: Dictionary) -> void:
	person=p
	heading.text="지역 지도 · 현재 "+T.NAMES[T.region(p)]
	var ids: Array=T.NAMES.keys()
	for i in range(3): labels[i].text=(T.NAMES[ids[i]] if ids[i] in p.discovered else "미발견 지역")+("\n● 현재 위치" if T.region(p)==ids[i] else "")
	var reason:=T.coach_reason(p)
	coach_button.disabled=not reason.is_empty()
	coach_button.tooltip_text=reason
	info.text="서신 의뢰 · "+{"new":"잿불 마을 전령 유나(서쪽 길가)에게 받기","outbound":"안개나루의 도윤에게 전달","reply":"잿불 마을 유나에게 답신 전달 · 보상 은화12","done":"답신 전달 완료"}[p.mail_quest]
	info.text+="\n"+(reason if not reason.is_empty() else "마차로 발견한 반대편 마을에 이동합니다. 운임 은화5.")
	var place:=T.nearby(p)
	for id in shops:
		var price: int=T.GOODS[id].price
		shops[id].text="%s · %d은화 · 재고%d" % [preload("res://items.gd").CATALOG[id].name,price,w.harbor_market.stock[id]]
		shops[id].disabled=T.region(p)!="harbor" or place.get("kind")!="harbor_shop" or not T.near(p,place) or p.gold<price or w.harbor_market.stock[id]<=0
	queue_redraw()
func _draw() -> void:
	if person.is_empty(): return
	draw_polyline(PackedVector2Array(POINTS),Color("86795e"),4,false)
	var ids: Array=T.NAMES.keys()
	for i in range(3):
		var found: bool=ids[i] in person.discovered
		draw_rect(Rect2(POINTS[i]-Vector2(115,35),Vector2(230,85)),Color("394e43") if found else Color("242d2b"))
		draw_rect(Rect2(POINTS[i]-Vector2(115,35),Vector2(230,85)),Color("ddc88c") if T.region(person)==ids[i] else Color("65746a"),false,2)
