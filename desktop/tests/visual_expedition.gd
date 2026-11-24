extends SceneTree
const R=preload("res://world.gd")
const E=preload("res://expedition.gd")
class Sample extends Node2D:
	var world: Dictionary
	var player: Dictionary
	func _draw() -> void: preload("res://expedition_art.gd").draw(self,world,player)
var vp: SubViewport
var sample: Sample
var failures:=0
func _initialize() -> void: call_deferred("run")
func frame(w: Dictionary,p: Dictionary={}) -> int:
	sample.world=w
	sample.player=p
	sample.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return hash(vp.get_texture().get_image().get_data())
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failures+=1
		push_error(text)
func run() -> void:
	vp=SubViewport.new()
	vp.size=Vector2i(480,320)
	vp.transparent_bg=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	sample=Sample.new()
	vp.add_child(sample)
	var w:=R.fresh()
	w.enemies.boar.hp=0
	w.enemies.wraith.hp=0
	var empty:=await frame(w)
	w.enemies.boar=E.spawn("boar")
	var boar:=await frame(w)
	check(boar!=empty,"Boar produces actual distinct pixels")
	w.enemies.boar.warning=1
	w.enemies.boar.aim_x=23
	check(await frame(w)!=boar,"Charge warning line is visible")
	w.enemies.boar.warning=0
	w.enemies.boar.flash=0.18
	check(await frame(w)!=boar,"Charge trail is visible after impact")
	w.enemies.boar.hp=0
	w.enemies.wraith=E.spawn("wraith")
	var wraith:=await frame(w)
	check(wraith!=empty and wraith!=boar,"Wraith silhouette differs from boar")
	w.enemies.wraith.warning=1
	w.enemies.wraith.aim_y=13
	check(await frame(w)!=wraith,"Wraith aim warning is visible")
	w.enemies.wraith.warning=0
	R.born(w,"local","시각 시험")
	var p: Dictionary=w.people.local
	p.x=26
	p.y=14
	p.target_enemy="wraith"
	check(await frame(w,p)!=wraith,"Selected target ring is visible")
	w.enemies.wraith.hp=0
	check(E.selected(w,p)=="wolf" and await frame(w,p)!=wraith,"Dead target falls back to nearby living enemy")
	w.wolf.hp=0
	check(await frame(w,p)==empty,"No living target leaves no target ring")
	w.field_loot["loot-test"]={"x":27,"y":16,"contents":{"spectral_ash":2}}
	check(await frame(w)!=empty,"Ground loot has visible bag pixels")
	w.field_loot.clear()
	check(await frame(w)==empty,"Collected loot bag disappears")
	quit(1 if failures else 0)
