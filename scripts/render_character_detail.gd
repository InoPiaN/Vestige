extends SceneTree
class Sample extends "res://pixel_world.gd":
	var person: Dictionary
	func _draw() -> void: hero(30,31,person)
func _initialize() -> void: call_deferred("render")
func title(parent: Node,text: String,position: Vector2) -> void:
	var label:=Label.new()
	label.text=text
	label.position=position
	label.add_theme_font_size_override("font_size",16)
	parent.add_child(label)
func render() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,850)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg:=ColorRect.new()
	bg.size=Vector2(1280,850)
	bg.color=Color("162720")
	vp.add_child(bg)
	title(vp,"VESTIGE · 실제 렌더러 / 4방향 · 외형 · 장비 · 강화",Vector2(32,18))
	var names: Array=["정면 / +0","뒷면 / +1","왼쪽 / +2","오른쪽 / +3","긴 머리 / +2","묶은 머리 / +3","후드 / +3","투구 숨김 / 맨손"]
	for row in range(3):
		for col in range(8):
			var p: Dictionary={"alive":true,"direction":["down","up","left","right","down","down","up","down"][col],"look":{"hair":1 if col==4 else (2 if col>=5 else 0),"hair_color":col%4,"skin":col%3,"cloth":col%4},"equipment":{"body":"leather" if col%2 else "cloth","head":"hood" if col>=6 else "none","cloak":"traveler" if col!=7 else "none","weapon":"none" if col==7 else "iron_sword"},"hide_helmet":col==7,"equipped_ids":{"weapon":"demo"},"gear_quality":{"demo":{"upgrade":mini(col,3)}},"steps":1,"motion":1.0 if row==1 else 0.0,"attack":0.5 if row==2 else 0.0}
			var scene:=SubViewport.new()
			scene.size=Vector2i(128,128)
			scene.transparent_bg=true
			scene.render_target_update_mode=SubViewport.UPDATE_ALWAYS
			vp.add_child(scene)
			scene.canvas_transform=Transform2D(0,Vector2(2,2),0,Vector2.ZERO)
			var sample:=Sample.new()
			sample.person=p
			sample.clock=0.2
			sample.set_process(false)
			scene.add_child(sample)
			var tex:=TextureRect.new()
			tex.texture=scene.get_texture()
			tex.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
			tex.position=Vector2(col*156,65+row*250)
			tex.size=Vector2(156,156)
			vp.add_child(tex)
			title(vp,names[col],Vector2(col*156+8,48+row*250))
			title(vp,["대기","걷기","공격"][row],Vector2(col*156+55,223+row*250))
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-character-motion-sheet.png")
	for child in vp.get_children():
		if child!=bg: child.queue_free()
	await process_frame
	vp.size=Vector2i(1280,800)
	var game:=preload("res://main.gd").new()
	vp.add_child(game)
	game.world=preload("res://investigation_demo.gd").upgrade()
	game.save_path="/tmp/vestige-detail-ui-"+str(OS.get_process_id())+".json"
	game.mode="single"
	game.menu.hide()
	game.ui.show()
	var p: Dictionary=game.world.people.local
	var id:=""
	for key in p.gear_instances:
		if p.gear_instances[key]=="iron_sword": id=key
	for n in range(3): preload("res://world.gd").act(game.world,"local","upgrade_sword",id+"|"+str(n))
	preload("res://world.gd").act(game.world,"local","equip_weapon",id)
	game.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-character-world.png")
	game.open_dressing("gear")
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-character-equipment.png")
	if game.view.get_viewport().size!=Vector2i(960,640) or game.portrait.get_viewport().size!=Vector2i(64,72):
		push_error("Detailed sprite requires two-times canvas sampling")
		quit(1)
		return
	print("PASS: World and portrait use high-density canvas; all directions looks and upgrade effects rendered")
	quit()
