extends Node2D

const CharacterMotion=preload("res://animation.gd")
const Rules=preload("res://world.gd")
var world: Dictionary={}
var player_id: String=""
var clock:=0.0
var terrain: ImageTexture
var font: Font

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	font=ThemeDB.fallback_font
	var img:=Image.create(480,320,false,Image.FORMAT_RGB8)
	var rng:=RandomNumberGenerator.new()
	rng.seed=9831
	for y in range(320):
		for x in range(480):
			var road:=absi(y-152)<10 or (absi(x-144)<8 and y>52 and y<252)
			var base:=Color("514c39") if road else (Color("344033") if x<272 else Color("25372f"))
			img.set_pixel(x,y,base)
	# Sparse clusters leave quiet ground around readable silhouettes.
	for i in range(440):
		var px:=rng.randi_range(2,476)
		var py:=rng.randi_range(2,316)
		var road:=absi(py-152)<10 or (absi(px-144)<8 and py>52 and py<252)
		var shade:=Color("666049") if road else Color("42503b")
		for dx in range(rng.randi_range(2,4)):
			img.set_pixel(px+dx,py,shade)
		if not road: img.set_pixel(px+1,py-1,shade)
	terrain=ImageTexture.create_from_image(img)

func _process(dt: float) -> void:
	clock+=dt
	queue_redraw()

func box(x: float,y: float,w: float,h: float,hex: String) -> void:
	draw_rect(Rect2(roundf(x),roundf(y),w,h),Color(hex))

func tree(x: float,y: float,variant: int=0) -> void:
	box(x-10,y+5,21,4,"17251f")
	box(x-2,y-8,5,17,"423b2d")
	box(x-1,y-7,2,14,"82654a")
	box(x-4,y+6,8,2,"423b2d")
	var leaf: String="3c5540" if variant==0 else "375348"
	# Stepped, asymmetric foliage masses; highlights describe planes.
	box(x-8,y-28,16,5,"182e26")
	box(x-12,y-23,23,15,"182e26")
	box(x-10,y-8,19,5,"182e26")
	box(x-6,y-31,10,5,leaf)
	box(x-10,y-24,17,9,leaf)
	box(x-7,y-15,10,7,leaf)
	box(x+3,y-20,6,8,"2b4433")
	box(x-5,y-28,7,3,"63734b")
	box(x-9,y-22,5,3,"63734b")
	box(x-5,y-18,6,2,"4c6544")
	box(x-6,y-10,4,2,"4c6544")

func lamp(x: float,y: float) -> void:
	draw_circle(Vector2(x,y-8),13,Color(0.85,0.56,0.23,0.05))
	box(x,y-10,2,20,"3b3027")
	box(x-2,y-16,6,8,"9b7541")
	box(x-1,y-15,4,5,"f7ce7e")
	box(x,y-14,2,3,"fff0bd")
	box(x-3,y-18,8,2,"312e25")

func house(x: float,y: float,type: String) -> void:
	box(x-25,y+7,53,6,"202b23")
	box(x-23,y-20,46,31,"76745c")
	box(x-20,y-18,40,27,"a39b77")
	for i in range(5):
		box(x-22,y-17+i*6,44,1,"686c55")
	box(x-23,y-20,3,31,"494c3b")
	box(x+20,y-20,3,31,"494c3b")
	box(x-3,y-20,3,31,"494c3b")
	box(x+5,y-4,10,15,"332f27")
	box(x+7,y-2,6,12,"604d35")
	box(x+11,y+4,1,1,"d9b971")
	box(x-16,y-9,8,9,"3a3b31")
	box(x-15,y-8,6,6,"d8b46a")
	box(x-12,y-8,1,7,"62563b")
	var roof: String="6b443b" if type=="forge" else "435665"
	for i in range(6):
		box(x-27+i*3,y-21-i*4,54-i*6,4,roof)
		box(x-26+i*3,y-21-i*4,52-i*6,1,"8f6a52" if type=="forge" else "60737a")
		for j in range(5-i): box(x-20+i*3+j*9,y-20-i*4,1,3,"303f3f")
	box(x-28,y-21,56,3,"30382f")
	if type=="forge":
		box(x-18,y-49,8,21,"5e6257")
		box(x-19,y-50,10,3,"92917b")
		box(x-16,y-55-int(clock*2)%4,5,4,"6b7165")
		box(x-29,y+12,18,4,"252f2c")
		box(x-26,y+16,10,6,"444c43")
		box(x-30,y+10,19,3,"969986")
		box(x-27,y+22,12,3,"534733")
	else:
		box(x+24,y-11,10,13,"483c2c")
		box(x+26,y-9,6,8,"b5a477")
		if type=="library": box(x+28,y-8,1,7,"554d38")
	lamp(x+20,y+17)

func hero(x: float,y: float,p: Dictionary,other: bool=false) -> void:
	if not p.get("alive",true): return
	var pose:=CharacterMotion.pose(p)
	var mirror: float=-1.0 if pose.direction=="left" else 1.0
	var person:=p.duplicate()
	if not person.has("look"): person.look={"cloth":2 if other else 0}
	var painter:=preload("res://character_detail.gd").new()
	painter.canvas=self
	draw_set_transform(Vector2(roundf(x)-8*mirror,roundf(y)+pose.bob-17.5),0,Vector2(0.5*mirror,0.5))
	painter.draw_character(person,pose,clock)
	draw_set_transform(Vector2.ZERO)

func ruin(x: float,y: float) -> void:
	box(x-24,y-10,47,25,"4b5448")
	box(x-19,y-6,37,22,"252e28")
	for s in [-1,1]:
		box(x+s*20-4,y-37,8,54,"626958")
		box(x+s*20-4,y-40,8,4,"90917a")
		for j in range(6): box(x+s*20-4,y-31+j*8,8,1,"3b483d")
	box(x-17,y-29,33,5,"717760")
	box(x-12,y-35,23,7,"676e5b")
	box(x-4,y-41,7,8,"96917b")
	box(x-8,y-38,15,3,"96917b")
	box(x-7,y+5,14,7,"807a5d")
	box(x-5,y+6,10,2,"c0ac74")
	for i in range(5): box(x-29+i*12,y+19+(i%2)*3,6,4,"7a7b64")

func _draw() -> void:
	if terrain==null: return
	if world.get("people",{}).has(player_id) and Rules.Interior.inside(world.people[player_id]):
		draw_interior()
		return
	draw_texture(terrain,Vector2.ZERO)
	for x in range(0,480,18):
		tree(x,17,x%2)
		tree(x+4,317,x%2)
	for y in range(40,290,23):
		tree(7,y)
		tree(477,y)
	for x in range(284,450,25):
		for y in range(38,290,37):
			if abs(y-152)<30: continue
			if Vector2(x,y).distance_to(Vector2(336,80))<35: continue
			if Vector2(x,y).distance_to(Vector2(352,224))<30: continue
			if Vector2(x,y).distance_to(Vector2(432,144))<48: continue
			tree(x+(y%11),y,(x+y)%2)
	for x in range(30,260,11):
		if absi(x-144)<16: continue
		box(x,267,2,10,"777154")
		box(x,270,11,2,"615f46")
	for t in Rules.PLACES:
		var x: float=t.x*16
		var y: float=t.y*16
		match t.kind:
			"market":
				box(x-16,y-20,2,24,"8b7650")
				box(x+14,y-20,2,24,"8b7650")
				box(x-19,y-24,38,7,"697c63")
				box(x-17,y-23,10,5,"a39a71")
				box(x+4,y-23,10,5,"a39a71")
				box(x-16,y-5,32,8,"705c3c")
				box(x-12,y-9,6,4,"a29a80")
				box(x+5,y-10,5,5,"8ab88e")
			"forge","inn","library","home": house(x,y,t.kind)
			"grave":
				for i in range(4):
					box(x-18+i*12,y-7+(i%2)*9,8,13,"89917d")
					box(x-16+i*12,y-5+(i%2)*9,4,1,"444e43")
					box(x-15+i*12,y-7+(i%2)*9,1,6,"444e43")
			"ore":
				for i in range(4):
					box(x-13+i*7,y-6-(i%2)*6,10,13,"6b7972")
					box(x-12+i*7,y-5-(i%2)*6,7,3,"9bad9d")
			"herb":
				for i in range(6):
					box(x-14+i*5,y+(i%2)*6,2,8,"6d8956")
					box(x-16+i*5,y-2+(i%2)*6,6,3,"b0d1bd")
			"ruin": ruin(x,y)
		if not world.is_empty() and world.people.has(player_id):
			if Rules.pos(world.people[player_id]).distance_to(Rules.pos(t))<2:
				draw_rect(Rect2(x-14,y+18,28,1),Color("e7c980"))
	# A well, market crates and two residents make the village readable.
	box(111,170,20,12,"737967")
	box(114,168,14,7,"252f2a")
	box(110,167,22,3,"b4ad8b")
	box(110,155,2,15,"65563c")
	box(130,155,2,15,"65563c")
	box(109,153,24,3,"8b7650")
	for i in range(3):
		box(191+i*11,197,9,9,"705c3c")
		box(192+i*11,198,7,1,"a28b5a")
	for i in range(4): lamp(65+i*58,158)
	hero(105+sin(clock*0.3)*8,135,{"steps":clock,"motion":1.0,"direction":"right" if cos(clock*0.3)>0 else "left","alive":true},true)
	hero(208,210,{"steps":0,"alive":true},true)
	if world.is_empty(): return
	if world.people.has(player_id):
		for trace in Rules.Investigation.traces(world,world.people[player_id]):
			box(trace.x*16-3,trace.y*16+5,7,3,"877557")
			box(trace.x*16-2,trace.y*16+4,3,2,"d6bd86")
	var e: Dictionary=world.wolf
	if e.hp>0:
		var x: float=e.x*16
		var y: float=e.y*16
		if e.warning>0: draw_circle(Vector2(x,y),23,Color(0.9,0.35,0.2,0.25))
		box(x-10,y-4,19,9,"7e8176")
		box(x+6,y-9,7,10,"a1a294")
		box(x+6,y-12,3,4,"686f64")
		box(x+11,y-11,3,4,"686f64")
		box(x+11,y-6,2,2,"e0b166")
		box(x-9,y+4,3,5,"535d53")
		box(x+5,y+4,3,5,"535d53")
		box(x-14,y-6,5,3,"95968b")
		box(x-12,y-19,25,2,"382b28")
		box(x-12,y-19,maxf(0,e.hp/2.0),2,"bf735a")
	for id in world.people:
		var p: Dictionary=world.people[id]
		if not Rules.Interior.inside(p): hero(p.x*16,p.y*16,p,id!=player_id)
	# Subtle night tint; never hides gameplay silhouettes.
	var night: float=(sin(float(world.time)/Rules.DAY*TAU)+1)*0.5
	draw_rect(Rect2(0,0,480,320),Color(0.025,0.05,0.12,night*0.12))

func draw_interior() -> void:
	var state: Dictionary=world.estate.get("interior",{})
	box(0,0,480,320,"101814")
	box(66,38,348,246,"262c24")
	box(72,48,336,232,"554733")
	for y in range(64,278,16):
		box(80,y,320,1,"342e25")
		for x in range(80+(8 if y%32==0 else 0),400,32):
			box(x,y-14,1,14,"473c2e")
			box(x+4,y-8,10,1,"63523a")
	box(72,44,336,20,"77705a")
	for x in range(76,405,24): box(x,45,1,17,"514e40")
	box(72,62,8,218,"38372c")
	box(400,62,8,218,"38372c")
	box(72,272,152,8,"77705a")
	box(256,272,152,8,"77705a")
	box(224,270,32,10,"a08b5c")
	box(229,274,22,3,"5d4c32")
	# Faded rug and a repaired dining table.
	box(194,132,92,82,"644c40")
	box(198,136,84,74,"4d5142")
	box(201,140,78,1,"a18b5e")
	box(201,204,78,1,"a18b5e")
	for key in Rules.Interior.OBJECTS:
		var o: Dictionary=Rules.Interior.OBJECTS[key]
		var x: float=o.x*16
		var y: float=o.y*16
		match key:
			"drawer","cupboard":
				box(x-14,y-23,28,31,"3c3329")
				box(x-12,y-22,24,26,"816947")
				box(x-14,y-25,28,4,"b09360")
				for offset in [0,9,18]:
					box(x-11,y-20+offset,22,1,"4c3e2b")
					box(x-2,y-16+offset,4,2,"d0b980")
				if state.get("searched",{}).get(key,false): box(x-10,y-10,20,3,"2e2b24")
			"shelf":
				box(x-17,y-33,34,42,"47392a")
				for tier in range(3):
					for book in range(5):
						box(x-13+book*5,y-29+tier*12,4,9,["81907b","ae885a","825b4d","586d6c","b2a17d"][book])
					box(x-15,y-19+tier*12,30,2,"b39762")
			"bed":
				box(x-15,y-24,30,35,"493a2b")
				box(x-12,y-22,24,31,"8b8c73")
				box(x-10,y-20,20,7,"d2c9a2")
				box(x-12,y-11,24,20,"4f7068")
				box(x-8,y-8,2,15,"759385")
				box(x+9,y-8,2,15,"354e49")
			"chest":
				box(x-15,y-16,30,25,"45372a")
				box(x-13,y-15,26,21,"896b43")
				box(x-15,y-18,30,6,"b18b54")
				box(x-9,y-17,3,23,"424d45")
				box(x+6,y-17,3,23,"424d45")
				box(x-2,y-7,4,5,"dec28a")
			"curtain":
				box(x-18,y-28,36,26,"303d3b")
				box(x-14,y-25,28,20,"9ea993")
				box(x-1,y-25,2,20,"5b5b48")
				box(x-14,y-16,28,2,"5b5b48")
				var width: int=17 if state.get("curtain",false) else 6
				box(x-18,y-28,width,27,"6d4b44")
				box(x+18-width,y-28,width,27,"80594a")
				if not state.get("curtain",false): draw_colored_polygon(PackedVector2Array([Vector2(x-13,y),Vector2(x+13,y),Vector2(x+50,y+55),Vector2(x-28,y+55)]),Color(0.85,0.8,0.55,0.10))
			"hearth":
				box(x-18,y-27,36,35,"696857")
				box(x-12,y-18,24,23,"282c26")
				box(x-20,y+4,40,5,"999078")
				box(x-8,y-1,18,3,"675035")
				if state.get("fire",false):
					draw_circle(Vector2(x,y-4),35,Color(1.0,0.58,0.2,0.07))
					box(x-7,y-10,14,11,"be703b")
					box(x-4,y-13+(int(clock*4)%2),5,13,"e2a552")
					box(x+2,y-8,4,7,"f2d089")
			"table":
				box(x-15,y-15,30,20,"665036")
				box(x-17,y-19,34,17,"9a7d50")
				box(x-13,y-18,1,14,"b99b67")
				box(x-14,y+3,4,5,"b4aa8a")
				box(x+5,y-16,6,5,"c5c1a0")
				box(x-8,y-13,8,3,"574833")
				box(x-7,y-16,2,8,"58442c")
				box(x-10,y-17,8,3,"91a095")
				box(x+1,y-9,8,4,"c1b28e")
	var me: Dictionary=world.people[player_id]
	var focused:=Rules.Interior.nearby(me)
	if not focused.is_empty():
		var o: Dictionary=Rules.Interior.OBJECTS[focused]
		box(o.x*16-13,o.y*16+12,26,1,"e1c986")
	for row in Rules.Remains.visible(world,me).values():
		box(row.x*16-4,row.y*16+2,8,5,"a68d5b")
	var residents: Array=[]
	for id in world.people:
		if Rules.Interior.inside(world.people[id]): residents.append(id)
	residents.sort_custom(func(a,b): return world.people[a].y<world.people[b].y)
	for id in residents:
		var p: Dictionary=world.people[id]
		hero(p.x*16,p.y*16,p,id!=player_id)
	if state.get("curtain",false): draw_rect(Rect2(80,64,320,208),Color(0.02,0.03,0.06,0.13))
