extends Node2D

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
	var bob:=int(p.get("steps",0))%2
	box(x-5,y+5,11,3,"18251f")
	var look: Dictionary=Rules.clean_look(p.get("look",{"cloth":2 if other else 0}))
	var gear: Dictionary=p.get("equipment",{"weapon":"iron_sword" if p.get("sword",0)>0 else "none"})
	var skin: String=["e0b78a","b88963","805c49"][look.skin]
	var hair: String=["594a38","aa8854","754a43","a9aaa0"][look.hair_color]
	var cloth: String=["9b6652","637e9b","63877b","967fa0"][look.cloth]
	if gear.get("cloak")=="traveler":
		box(x-7,y-7,14,12,"263a42")
		box(x-6,y-6,3,10,"55727c")
		box(x+4,y-3,3,8,"55727c")
	if p.get("dodge",0)>0: cloth="b8d4cb"
	# A 16x24 silhouette: swept hair, one steel pauldron, split cloak.
	box(x-5,y-8,10,12,"222c2c")
	box(x-4,y-7,8,10,cloth)
	box(x-4,y-5,2,9,"45423a")
	box(x+3,y-4,2,7,"45423a")
	box(x-3,y+3,3,4+bob,"272c2c")
	box(x+1,y+3,3,5-bob,"272c2c")
	box(x-3,y+3,2,1,"8c7860")
	box(x+1,y+3,2,1,"8c7860")
	box(x-3,y-15,7,8,"292c2d")
	box(x-2,y-12,5,4,"b88963")
	box(x-1,y-12,4,2,skin)
	box(x+2,y-11,1,1,"292c2d")
	box(x-4,y-15,8,3,hair)
	box(x-2,y-17,5,3,hair)
	box(x-2,y-16,4,1,"a48a59")
	box(x-3,y-14,2,3,hair)
	if look.hair==1:
		box(x-5,y-15,3,12,hair)
		box(x+3,y-14,2,8,hair)
	elif look.hair==2:
		box(x-1,y-19,3,3,hair)
		box(x+4,y-15,3,5,hair)
	if gear.get("head")=="hood" and not p.get("hide_helmet",false):
		box(x-4,y-19,8,6,"354c50")
		box(x+4,y-15,3,5,"354c50")
		box(x-5,y-14,3,7,"55727c")
		box(x+3,y-14,2,7,"354c50")
	box(x-5,y-8,5,4,"45585b")
	box(x-5,y-8,4,1,"b0bcb0")
	box(x-4,y-7,3,1,"7b9290")
	box(x,y-7,2,6,"c0a273")
	if gear.get("body")=="leather":
		box(x-3,y-5,7,6,"594432")
		box(x-2,y-5,5,1,"b09765")
		box(x,y-4,1,4,"c8b788")
	box(x-3,y,7,2,"473a30")
	box(x,y,2,1,"d3ad61")
	box(x-6,y-4,2,5,"45585b")
	box(x+4,y-5,2,6,cloth)
	box(x-6,y,2,2,skin)
	box(x+4,y,2,2,skin)
	if gear.get("weapon")=="iron_sword":
		box(x+7,y-10,2,12,"738e90")
		box(x+7,y-10,1,11,"dce0c3")
		box(x+7,y-12,1,2,"dce0c3")
		box(x+5,y+2,6,2,"b89a5d")
		box(x+7,y+4,2,3,"584637")
	if p.get("attack",0)>0.25:
		draw_arc(Vector2(x,y-3),17,-1.4,1.1,8,Color("f4dc99"),2)

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
			"forge","inn","library": house(x,y,t.kind)
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
	hero(105+sin(clock*0.3)*8,135,{"steps":clock,"alive":true},true)
	hero(208,210,{"steps":0,"alive":true},true)
	if world.is_empty(): return
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
		hero(p.x*16,p.y*16,p,id!=player_id)
	# Subtle night tint; never hides gameplay silhouettes.
	var night: float=(sin(float(world.time)/Rules.DAY*TAU)+1)*0.5
	draw_rect(Rect2(0,0,480,320),Color(0.025,0.05,0.12,night*0.12))
