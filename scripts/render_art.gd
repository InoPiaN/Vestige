extends SceneTree
const Art=preload("res://pixel_world.gd")
const Rules=preload("res://world.gd")
class Figures extends Art:
	func _draw() -> void:
		for i in range(4):
			hero(18+i*34,22,{"alive":true,"sword":1 if i%2 else 0,"steps":i},i>1)
func _initialize() -> void:
	call_deferred("render")
func render() -> void:
	var canvas:=SubViewport.new()
	canvas.size=Vector2i(1100,850)
	canvas.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(canvas)
	var background:=ColorRect.new()
	background.color=Color("101c1b")
	background.size=Vector2(1100,850)
	canvas.add_child(background)
	var art:=Art.new()
	art.world=Rules.fresh()
	Rules.born(art.world,"sample","여행자")
	art.world.people.sample.sword=1
	art.player_id="sample"
	art.position=Vector2(70,16)
	art.scale=Vector2(2,2)
	canvas.add_child(art)
	art.set_process(false)
	var figures:=Figures.new()
	figures.position=Vector2(70,700)
	figures.scale=Vector2(4,4)
	canvas.add_child(figures)
	figures.set_process(false)
	var title:=Label.new()
	title.position=Vector2(70,666)
	title.text="VESTIGE  /  SMALL PIXELS, CLEAR DETAILS  /  STYLE STUDY 01"
	canvas.add_child(title)
	var note:=Label.new()
	note.position=Vector2(660,718)
	note.text="World: 2x / Figures: 4x\n16x24 body footprint\nHair / steel / cloak / blade\nSparse terrain clusters"
	canvas.add_child(note)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var result:=canvas.get_texture().get_image().save_png("res://../artifacts/art/style-study-01.png")
	print("ART_PREVIEW_SAVED ",result)
	quit(result)
