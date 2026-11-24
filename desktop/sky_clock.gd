extends Control
const Life=preload("res://npc_life.gd")
var world_time:=0.0
func _ready() -> void:
	position=Vector2(430,10)
	size=Vector2(420,60)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	clip_contents=true
func refresh(time: float) -> void:
	world_time=time
	queue_redraw()
func _draw() -> void:
	var h:=Life.hour(world_time)
	var night:=Color("17243e")
	var dawn:=Color("af827d")
	var day:=Color("6b9baf")
	var sunset:=Color("ac6b56")
	var sky: Color
	if h<5: sky=night
	elif h<8: sky=night.lerp(dawn,(h-5)/3)
	elif h<10: sky=dawn.lerp(day,(h-8)/2)
	elif h<16: sky=day
	elif h<18: sky=day.lerp(sunset,(h-16)/2)
	elif h<21: sky=sunset.lerp(night,(h-18)/3)
	else: sky=night
	# Native pixel artwork: no clock face, dial, numbers or external assets.
	draw_rect(Rect2(0,0,420,60),Color("ad9d73"))
	draw_rect(Rect2(2,2,416,56),sky)
	if h<6 or h>=20:
		for at in [Vector2(25,13),Vector2(75,22),Vector2(125,9),Vector2(205,18),Vector2(285,12),Vector2(365,25),Vector2(395,10)]:
			draw_rect(Rect2(at,Vector2(2,2)),Color("d5d7c0"))
	var sun: bool=h>=6 and h<18
	var progress: float=(h-6)/12 if sun else fposmod(h-18,24)/12
	var at:=Vector2(roundf(12+progress*390),roundf(43-sin(progress*PI)*31))
	draw_rect(Rect2(at-Vector2(5,4),Vector2(10,8)),Color("f3d995") if sun else Color("e4e7d1"))
	draw_rect(Rect2(at-Vector2(3,6),Vector2(6,12)),Color("f3d995") if sun else Color("e4e7d1"))
	if not sun: draw_rect(Rect2(at+Vector2(0,-6),Vector2(6,8)),sky)
	for i in range(7):
		var x:=float(i*69)+fposmod(world_time*0.04,40)-30
		draw_rect(Rect2(x+32,26+(i%2)*8,28,2),Color(sky.lightened(0.22),0.4))
	var hills:=PackedVector2Array([Vector2(2,56),Vector2(2,48),Vector2(40,40),Vector2(70,44),Vector2(105,33),Vector2(150,46),Vector2(200,37),Vector2(260,44),Vector2(310,32),Vector2(370,43),Vector2(418,38),Vector2(418,58),Vector2(2,58)])
	draw_colored_polygon(hills,Color("344742"))
	for x in [18,55,340,390]:
		draw_rect(Rect2(x,43,4,15),Color("202f2c"))
		draw_rect(Rect2(x-4,41,12,8),Color("202f2c"))
