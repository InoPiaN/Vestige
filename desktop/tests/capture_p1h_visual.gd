extends SceneTree
## P1-H capture: real Main/PixelWorld, diagnostics in isolated QA output only.
## Saves world to /tmp. Screenshot files never touch user:// game saves.
const Main=preload("res://main.gd")
const Overlay=preload("res://tests/p1h_visual_collision_overlay.gd")
var failures:=0

func check(ok: bool, label: String) -> void:
	if ok:
		print("PASS: P1H ",label)
	else:
		failures+=1
		push_error("FAIL: P1H "+label)

func _initialize() -> void:
	call_deferred("run")

func capture(label: String, dir: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image=root.get_viewport().get_texture().get_image()
	var path: String=dir.path_join(label+".png")
	check(not image.is_empty(),"viewport nonempty "+label)
	if image.is_empty():return
	check(image.get_width()>=960 and image.get_height()>=640,"frame dimensions "+label)
	check(image.save_png(path)==OK,"PNG saved "+label)
	print("P1H_CAPTURE: ",path," ",image.get_width(),"x",image.get_height())

func run() -> void:
	var output: String=OS.get_environment("VESTIGE_VISUAL_OUTPUT")
	if output.is_empty(): output="/tmp/vestige-p1h-visual-%d" % OS.get_process_id()
	if DirAccess.make_dir_recursive_absolute(output)!=OK:
		push_error("P1H cannot create capture directory: "+output)
		quit(1)
		return
	var game:=Main.new()
	root.add_child(game)
	game.set_physics_process(false)
	game.save_path="/tmp/vestige-p1h-world-%d.json" % OS.get_process_id()
	game.start_single()
	check(game.mode=="single","isolated game started")
	var p: Dictionary=game.world.people["local"]
	check(Vector2(float(p.x),float(p.y))==Vector2(9,9),"default spawn (9,9)")
	var legend_found:=false
	for label_node in game.ui.find_children("*","Label",true,false):
		var label_text: String=String(label_node.get("text"))
		if label_text.contains("N 조사 수첩") and label_text.contains("F 사망 조사"):
			legend_found=true
			break
	check(legend_found,"HUD legend includes N notebook and F death investigation")
	await capture("01-spawn-actual",output)
	var overlay:=Overlay.new()
	game.view.add_child(overlay)
	await capture("02-spawn-collision-overlay",output)
	overlay.hide()
	p.x=16.0
	p.y=7.0
	game.refresh()
	await capture("03-iren-house-e01",output)
	game.interact()
	game.open_chapter1_notebook()
	await capture("04-notebook",output)
	game.open_chapter1_board()
	await capture("05-evidence-board",output)
	game.close_chapter1_board()
	p.x=12.0
	p.y=4.5
	game.refresh()
	game.start_chapter1_dialogue()
	await capture("06-sera-dialogue",output)
	game.finish_chapter1_dialogue()
	check(not game.panel.visible and not game.chapter1_board.visible,"dialogue/modals closed")
	game.mode="menu"
	game.queue_free()
	DirAccess.remove_absolute(game.save_path)
	DirAccess.remove_absolute(game.save_path+".bak")
	DirAccess.remove_absolute(game.save_path+".tmp")
	print("P1H_VISUAL_CAPTURE: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
