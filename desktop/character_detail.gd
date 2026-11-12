extends RefCounted
# 32x52 logical sprite, drawn at half world-texel scale in a 2x canvas.
var canvas: CanvasItem
var look: Dictionary
var gear: Dictionary
var pose: Dictionary
var part:="fixed"
var time:=0.0
const SKINS=[Color("e0b78a"),Color("b88963"),Color("805c49")]
const HAIRS=[Color("927348"),Color("c3a56c"),Color("b27060"),Color("c4c8c0")]
const CLOTHS=[Color("a36c52"),Color("637e9b"),Color("63877b"),Color("967fa0")]
func r(x: int,y: int,w: int,h: int,c: String) -> void:
	var color:=Color(c)
	if part=="cloth" and c in ["91604d","b27b5f","a36c52","704c40","69473c","c18a67","7d5544","9b6b50"]:
		color=CLOTHS[look.cloth]* (color.get_luminance()/Color("a36c52").get_luminance())
	if part=="fixed" and c in ["78513f","ae7858"]:
		color=CLOTHS[look.cloth]*(color.get_luminance()/Color("a36c52").get_luminance())
	if part=="face" and c not in ["252827","222c2b","654c3a","79553f"]:
		color=SKINS[look.skin]*(color.get_luminance()/Color("d9aa7a").get_luminance())
	if part=="fixed" and c in ["d3a576","a47654","d9ad7d","d4a574","886049"]:
		color=SKINS[look.skin]*(color.get_luminance()/Color("d9ad7d").get_luminance())
	if part=="hair": color=HAIRS[look.hair_color]*(color.get_luminance()/Color("927348").get_luminance())
	if pose.hurt: color=color.lerp(Color("f0d7b3"),0.65)
	elif pose.dodging: color=color.lerp(Color("b7d8d5"),0.35)
	if part=="boots": y+=int(pose.stride)*(1 if x<16 else -1)
	if pose.direction in ["left","right"]:
		x=16+roundi((x-16)*0.76)
		w=maxi(1,roundi(w*0.76))
	canvas.draw_rect(Rect2(x,y,w,h),color)
func draw_character(p: Dictionary,animation: Dictionary,clock: float) -> void:
	pose=animation
	time=clock
	look=preload("res://world.gd").clean_look(p.get("look",{}))
	gear=p.get("equipment",{})
	# 2x sampling density within the original character footprint.
	r(3,46,25,3,"111d19")
	# Split cloak, stepped hem and folds.
	if gear.get("cloak")=="traveler":
		r(5,22,20,21,"17272c")
		r(3,25,4,18,"263c42")
		r(5,23,3,19,"4c666c")
		r(6,25,1,15,"78908c")
		r(22,26,4,16,"304b51")
		r(24,29,2,12,"577277")
		r(9,39,4,4,"182c31")
		r(19,38,4,6,"20343b")
	part="boots"
	# Boots with toe planes and separate trouser legs.
	r(9,36,5,11,"1c2426")
	r(18,36,5,11,"182123")
	r(10,36,3,6,"444a45")
	r(19,36,3,6,"353e3a")
	r(8,43,6,5,"292e2d")
	r(18,43,7,5,"282c2b")
	r(8,46,5,1,"797061")
	r(19,46,5,1,"625e52")
	r(9,43,4,1,"9b8060")
	r(19,43,3,1,"86694d")
	part="cloth"
	# Tunic silhouette and three-value fabric folds.
	r(8,21,15,17,"252b2b")
	r(9,22,12,14,"91604d")
	r(10,24,3,9,"b27b5f")
	r(14,23,5,12,"a36c52")
	r(19,25,2,10,"704c40")
	r(13,29,1,6,"69473c")
	r(16,32,3,2,"c18a67")
	r(9,35,5,3,"7d5544")
	r(16,35,5,3,"9b6b50")
	r(14,35,2,4,"302b29")
	part="fixed"
	# Collar, neck and diagonal shoulder strap.
	r(13,19,6,5,"76513d")
	r(14,19,4,3,"d3a576")
	r(12,22,2,3,"c9b78b")
	r(18,22,2,3,"d6c59b")
	r(12,25,2,3,"b69c72")
	r(14,27,2,3,"b69c72")
	r(16,30,2,3,"b69c72")
	if gear.get("body")=="leather":
		r(10,25,11,9,"46372c")
		r(11,25,9,2,"98754c")
		r(11,28,4,5,"795538")
		r(16,28,4,5,"63472f")
		r(15,27,1,7,"c3a777")
		r(11,28,1,1,"dec48a")
		r(19,28,1,1,"c5a46c")
	# Rounded pauldron as a few clean pixel clusters.
	r(5,22,8,6,"26373b")
	r(6,21,6,2,"9caeaa")
	r(5,23,8,2,"6f8889")
	r(6,22,5,1,"d5d7bf")
	r(6,25,6,2,"435d65")
	r(7,27,4,1,"a3a999")
	# Arms, cuff, fingers and belt hardware.
	r(5,28,4,9,"3a4b4d")
	r(6,29,2,5,"647879")
	r(5,34,4,2,"a58c64")
	r(5,36,4,4,"a47654")
	r(6,36,2,3,"d9ad7d")
	r(21,25,4,10,"78513f")
	r(22,26,2,7,"ae7858")
	r(21,33,4,2,"d0b17a")
	r(22,35,3,4,"d4a574")
	r(24,36,1,2,"886049")
	r(9,33,12,3,"3d3029")
	r(10,33,10,1,"8e704d")
	r(14,33,4,3,"d5b16a")
	r(15,34,2,1,"65503a")
	r(19,35,3,4,"614331")
	r(19,35,3,1,"a47f50")
	part="face"
	# Face: shadow outline, cheek plane, brow, eye and nose.
	r(10,7,12,13,"252827")
	r(11,10,10,9,"a67754")
	r(12,11,8,7,"d9aa7a")
	r(13,12,5,3,"e4bb8a")
	r(11,14,1,3,"b98b61")
	r(20,12,2,4,"bc8b60")
	r(13,13,2,1,"654c3a")
	r(18,13,2,1,"654c3a")
	r(14,14,1,1,"222c2b")
	r(19,14,1,1,"222c2b")
	r(17,15,1,2,"b68258")
	r(18,15,1,1,"f0cda0")
	r(15,18,4,1,"79553f")
	r(14,19,5,1,"bc9067")
	part="hair"
	# Swept hair, silhouette steps, restrained highlights.
	r(10,5,11,4,"312d27")
	r(8,8,14,4,"493b2d")
	r(9,6,11,4,"685135")
	r(12,4,7,2,"59472f")
	r(11,6,8,2,"927348")
	r(12,6,5,1,"b09460")
	r(9,9,4,3,"826442")
	r(13,9,6,2,"725637")
	r(10,11,2,5,"4b3b2c")
	r(11,11,1,3,"98734b")
	r(20,10,2,3,"3c3329")
	if look.hair==1:
		r(8,10,3,13,"493b2d")
		r(9,11,1,11,"927348")
		r(21,11,3,10,"493b2d")
	elif look.hair==2:
		r(13,1,5,4,"685135")
		r(21,7,5,7,"493b2d")
		r(22,8,2,5,"927348")
	if pose.direction in ["left","right"]:
		r(10,11,5,7,"493b2d")
	if pose.direction=="up":
		r(10,9,12,11,"493b2d")
		r(11,10,3,8,"927348")
		r(17,11,2,8,"685135")
		if look.hair==1: r(9,13,14,12,"493b2d")
	part="fixed"
	if gear.get("head")=="hood" and not p.get("hide_helmet",false):
		r(10,3,11,3,"354c50")
		r(8,6,15,5,"354c50")
		r(9,6,3,4,"66858a")
		r(8,10,3,12,"354c50")
		r(9,11,1,9,"8b9b8d")
		r(21,10,3,12,"354c50")
		if pose.direction=="up":
			r(10,10,12,12,"354c50")
			r(11,11,3,9,"66858a")
	if pose.direction=="up":
		part="cloth"
		r(10,22,12,14,"91604d")
		part="fixed"
		if gear.get("body")=="leather":
			r(10,23,12,12,"63472f")
			r(15,23,1,11,"98754c")
		if gear.get("cloak")=="traveler":
			r(7,22,17,21,"304b51")
			r(8,23,4,18,"577277")
			r(12,24,1,17,"78908c")
			r(19,25,2,17,"20343b")
	weapon(p)
func weapon(p: Dictionary) -> void:
	var back: bool=pose.direction=="up"
	var side: bool=pose.direction in ["left","right"]
	var hand:=Vector2(28,36)
	var tip:=Vector2(29,10)
	if pose.phase=="strike":
		if back:
			hand=Vector2(24,14)
			tip=Vector2(24,-14)
		elif side:
			hand=Vector2(34,24)
			tip=Vector2(62,24)
		else:
			hand=Vector2(24,44)
			tip=Vector2(24,72)
	elif pose.phase=="recover":
		hand+=Vector2(4,-4)
		tip+=Vector2(8,6)
	if pose.phase!="idle":
		canvas.draw_line(Vector2(23,26),hand,CLOTHS[look.cloth],4,false)
		canvas.draw_line(Vector2(23,26),hand,Color("c9a476"),1,false)
	if gear.get("weapon")!="iron_sword":
		return
	var id: String=p.get("equipped_ids",{}).get("weapon","")
	var grade:=int(p.get("gear_quality",{}).get(id,{}).get("upgrade",0))
	grade=clampi(grade,0,3)
	var edge:=Vector2(-(tip-hand).y,(tip-hand).x).normalized().round()
	var direction: Vector2=(tip-hand).normalized()
	var start:=hand+direction*5
	# Pixel silhouettes, without blur; strength stays local to the blade.
	if grade>0:
		var glow: Color=[Color.TRANSPARENT,Color("91a89b70"),Color("71a8bf80"),Color("8ed9e59a")][grade]
		canvas.draw_line(start,tip,glow,5 if grade==3 else 4,false)
	canvas.draw_line(start,tip,Color("293c45"),3,false)
	canvas.draw_line(start,tip,Color("718e9a") if grade<2 else Color("81bfcc"),2,false)
	canvas.draw_line((start+edge).round(),(tip+edge).round(),Color("dce2c9") if grade==0 else Color("ddf4e5"),1,false)
	canvas.draw_line(hand-direction*2,hand+direction*4,Color("523c2e"),3,false)
	canvas.draw_line(hand+edge*5+direction*4,hand-edge*5+direction*4,Color("c4a66c"),2,false)
	canvas.draw_line(hand-edge*2-direction*3,hand+edge*2-direction*3,Color("ae8b52"),2,false)
	canvas.draw_rect(Rect2(hand-Vector2(2,1),Vector2(3,3)),SKINS[look.skin])
	if grade>=2:
		var frame:=int(time*5)%8
		for i in range(grade-1):
			if (frame+i*3)%8>3: continue
			var at: Vector2=(start.lerp(tip,0.3+0.25*i)+edge*(4 if frame%2==0 else -4)+Vector2(0,-frame)).round()
			canvas.draw_rect(Rect2(at,Vector2.ONE),Color("b4e4eb"))
	if pose.phase=="strike":
		var angle: float=-PI/2 if back else (0.0 if side else PI/2)
		canvas.draw_arc(Vector2(16,29),38,angle-0.65,angle+0.65,12,Color("efd59b"),2,false)
		if grade==3:
			canvas.draw_arc(Vector2(16,29),34,angle-0.9,angle+0.35,10,Color("7fc4d18a"),2,false)
			canvas.draw_arc(Vector2(16,29),30,angle-1.05,angle+0.1,8,Color("7fc4d14a"),1,false)
	if pose.hurt:
		canvas.draw_rect(Rect2(0,17,2,2),Color("f2ddba"))
		canvas.draw_rect(Rect2(31,22,2,2),Color("f2ddba"))
