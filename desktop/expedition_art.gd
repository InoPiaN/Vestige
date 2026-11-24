extends RefCounted
const E=preload("res://expedition.gd")
static func rect(c: CanvasItem,x: int,y: int,w: int,h: int,color: String) -> void:
	c.draw_rect(Rect2(x,y,w,h),Color(color))
static func draw(c: CanvasItem,w: Dictionary,p: Dictionary) -> void:
	for bag in w.get("field_loot",{}).values():
		var at:=Vector2(bag.x,bag.y)*16
		c.draw_rect(Rect2(at-Vector2(4,3),Vector2(8,7)),Color("9a7950"))
		c.draw_rect(Rect2(at-Vector2(2,5),Vector2(4,3)),Color("d3b77a"))
		c.draw_line(at+Vector2(-3,0),at+Vector2(3,0),Color("453a2c"),1)
	for id in w.get("enemies",{}):
		var e: Dictionary=w.enemies[id]
		if e.hp<=0: continue
		var at:=Vector2(e.x,e.y)*16
		var aim:=Vector2(e.aim_x,e.aim_y)*16
		if e.warning>0:
			c.draw_line(at,aim,Color("c266474d"),20 if id=="boar" else 6,false)
			c.draw_line(at,aim,Color("efb78b"),1,false)
			c.draw_circle(aim,4,Color("d86f54"),false,1)
		elif e.flash>0: c.draw_line(Vector2(e.trail_x,e.trail_y)*16,aim,Color("afdce2"),3 if id=="boar" else 2,false)
		c.draw_set_transform(at,0,Vector2(0.5,0.5))
		if id=="boar":
			rect(c,-23,9,46,5,"18251e")
			rect(c,-21,-10,36,21,"453a32")
			rect(c,-18,-14,27,5,"625041")
			rect(c,-14,-17,18,4,"84715b")
			rect(c,-18,-8,28,12,"786451")
			rect(c,-15,-7,18,3,"a28a68")
			rect(c,-17,8,5,9,"34302a")
			rect(c,5,8,5,9,"34302a")
			rect(c,11,-9,15,16,"685140")
			rect(c,17,-15,5,7,"9d805b")
			rect(c,24,-3,7,7,"aa8760")
			rect(c,20,-7,3,2,"e6b36d")
			rect(c,22,4,3,7,"d6c3a0")
			rect(c,25,2,3,4,"f0e0bb")
			for i in range(4): rect(c,-12+i*5,-18,2,7,"beb39a")
		else:
			rect(c,-13,8,27,4,"172923")
			rect(c,-12,-28,23,36,"283c41")
			rect(c,-9,-27,17,29,"47656b")
			rect(c,-10,-3,5,14,"5c8185")
			rect(c,3,-4,6,15,"345058")
			rect(c,-6,-37,13,13,"2c4249")
			rect(c,-5,-34,11,9,"bdc8b7")
			rect(c,-3,-32,3,2,"1e4149")
			rect(c,3,-32,3,2,"1e4149")
			rect(c,-2,-26,6,2,"829b96")
			rect(c,-3,-22,3,17,"94b0aa")
			c.draw_polyline(PackedVector2Array([Vector2(16,-31),Vector2(22,-23),Vector2(24,-14),Vector2(22,-5),Vector2(16,3)]),Color("9cb5ab"),2,false)
			c.draw_line(Vector2(16,-31),Vector2(13,-14),Color("c3d5bf"),1)
			c.draw_line(Vector2(13,-14),Vector2(16,3),Color("c3d5bf"),1)
			rect(c,4,-16,13,3,"9bb8b2")
		c.draw_set_transform(Vector2.ZERO)
		c.draw_rect(Rect2(at+Vector2(-12,-23),Vector2(24,2)),Color("352c2b"))
		c.draw_rect(Rect2(at+Vector2(-12,-23),Vector2(24*float(e.hp)/E.DEFS[id].hp,2)),Color("bd745e"))
	if p.is_empty(): return
	var selected:=E.selected(w,p)
	if not selected.is_empty():
		var enemy: Dictionary=E.all(w)[selected]
		c.draw_arc(Vector2(enemy.x,enemy.y)*16+Vector2(0,7),15,0,TAU,20,Color("eed6a1"),1,false)
