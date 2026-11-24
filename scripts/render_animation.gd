extends SceneTree
class Sheet extends "res://pixel_world.gd":
	func _draw() -> void:
		var directions: Array=["down","left","right","up"]
		for row in range(4):
			for col in range(8):
				var p: Dictionary={"alive":true,"direction":directions[row],"look":{"hair":1,"hair_color":1,"cloth":1},"equipment":{"body":"leather","cloak":"traveler","head":"hood","weapon":"iron_sword"},"hide_helmet":row<2,"steps":1 if col==1 else 3,"motion":1.0 if col in [1,2] else 0.0,"attack":0.45 if col==3 else (0.15 if col==4 else 0.0),"dodge":0.3 if col==5 else 0.0,"hurt":0.2 if col==6 else 0.0}
				if col==7: p.equipment.weapon="none"
				hero(18+col*38,32+row*45,p)
func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1040,700)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg:=ColorRect.new()
	bg.color=Color("172622")
	bg.size=vp.size
	vp.add_child(bg)
	var title:=Label.new()
	title.position=Vector2(25,15)
	title.text="VESTIGE / DIRECTION & EQUIPMENT / 3x PIXELS"
	vp.add_child(title)
	var sheet:=Sheet.new()
	sheet.position=Vector2(80,70)
	sheet.scale=Vector2(3,3)
	vp.add_child(sheet)
	sheet.set_process(false)
	for row in range(4):
		var l:=Label.new()
		l.position=Vector2(12,140+row*135)
		l.text=["DOWN","LEFT","RIGHT","UP"][row]
		vp.add_child(l)
	for col in range(8):
		var l:=Label.new()
		l.position=Vector2(104+col*114,65)
		l.text=["IDLE","STEP 1","STEP 2","STRIKE","RECOVER","DODGE","HIT","UNARMED"][col]
		vp.add_child(l)
	await process_frame
	await RenderingServer.frame_post_draw
	var error:=vp.get_texture().get_image().save_png("res://../artifacts/art/directional-animation.png")
	print("ANIMATION_SHEET ",error)
	quit(error)
