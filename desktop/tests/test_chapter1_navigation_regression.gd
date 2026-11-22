extends SceneTree
## P1-G: real World.move replay along traversable paths from default character spawn.
## Headless geometry/input QA, NOT a substitute for rendering and macOS manual play.
const World = preload("res://world.gd")
const Main = preload("res://main.gd")
const Clues = preload("res://story/chapter1_investigation.gd")
const Dialogue = preload("res://story/chapter1_dialogue.gd")
const STEP := 0.5
const SPAWN := Vector2(9.0,9.0)
const DIRECTIONS := [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
var failures := 0

func check(ok: bool, name: String) -> void:
	if ok:
		print("PASS: ",name)
	else:
		failures += 1
		push_error("FAIL: " + name)

func position(point: Vector2i) -> Vector2:
	return Vector2(float(point.x)*STEP,float(point.y)*STEP)

func route(start: Vector2, destination: Vector2, radius: float) -> Array[Vector2]:
	var origin:=Vector2i(roundi(start.x/STEP),roundi(start.y/STEP))
	var frontier: Array[Vector2i]=[origin]
	var parents: Dictionary={origin:origin}
	var cursor:=0
	var finish:=Vector2i(-1,-1)
	while cursor<frontier.size():
		var current: Vector2i=frontier[cursor]
		cursor+=1
		if position(current).distance_to(destination)<radius:
			finish=current
			break
		for move in DIRECTIONS:
			var following: Vector2i=current+move
			if parents.has(following) or not World.walkable(position(following)): continue
			parents[following]=current
			frontier.append(following)
	if not parents.has(finish): return []
	var path: Array[Vector2]=[]
	var point: Vector2i=finish
	while point!=origin:
		path.push_front(position(point))
		point=parents[point]
	return path

func move_along(w: Dictionary, id: String, path: Array[Vector2]) -> bool:
	var p: Dictionary=w.people[id]
	for target in path:
		var before:=Vector2(float(p.x),float(p.y))
		var delta: Vector2=target-before
		if delta.length()<0.001: continue
		World.move(w,id,delta.normalized(),delta.length()/3.2)
		if Vector2(float(p.x),float(p.y)).distance_to(target)>0.015:
			return false
	return true

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game:=Main.new()
	root.add_child(game)
	game.set_physics_process(false)
	var fixture: String="/tmp/vestige-p1g-navigation-%d.json" % OS.get_process_id()
	game.save_path=fixture
	game.start_single()
	check(game.mode=="single","isolated single-world QA launched")
	var w: Dictionary=game.world
	var p: Dictionary=w.people["local"]
	check(Vector2(float(p.x),float(p.y))==SPAWN,"default spawn remains (9,9)")
	check(World.walkable(SPAWN),"default spawn is not inside house or other blocking footprint")
	for building in ["forge","library","inn","home"]:
		for place in World.PLACES:
			if place.kind==building:
				check(not World.walkable(Vector2(float(place.x),float(place.y))),"solid "+building+" footprint blocks movement")
	# Every existing chapter clue must be reachable by ordinary movement from spawn.
	w.wolf.hp=0
	w.wolf.respawn=999999.0
	for clue in Clues.EVIDENCE:
		p.x=SPAWN.x
		p.y=SPAWN.y
		p.room="village"
		var target: Dictionary=Clues.EVIDENCE[clue]
		var steps: Array[Vector2]=route(SPAWN,Vector2(target.x,target.y),0.9)
		check(not steps.is_empty(),"walkable spawn path to "+clue)
		if steps.is_empty(): continue
		check(move_along(w,"local",steps),"World.move physically follows path to "+clue)
		check(Clues.nearby(p)==clue,"E focus selects "+clue+" after walking")
		if clue=="last_promise":
			game.interact()
			check(p.get("story",{}).get("evidence",{}).has("last_promise"),"E captures E01 by actual movement")
		else:
			check(game.Chapter1.inspect(w,"local",clue).contains("증거 기록"),"server-side evidence range permits "+clue)
	# Residents must be reachable without teleporting, including the library entrance.
	for npc_id in Dialogue.NPCS:
		p.x=SPAWN.x
		p.y=SPAWN.y
		p.room="village"
		var npc: Dictionary=Dialogue.NPCS[npc_id]
		var steps: Array[Vector2]=route(SPAWN,Vector2(npc.x,npc.y),0.9)
		check(not steps.is_empty(),"walkable spawn path to "+npc_id+" NPC")
		if steps.is_empty(): continue
		check(move_along(w,"local",steps),"World.move reaches "+npc_id+" NPC")
		check(game.Chapter1.nearby_npc(w,"local")==npc_id,"T NPC target after walking: "+npc_id)
		game.start_chapter1_dialogue()
		check(game.dialogue_npc==npc_id and game.panel.visible,"T opens "+npc_id+" dialogue")
		game.finish_chapter1_dialogue()
	# Test the known overlapping forge and Bran interaction hotspot (both radius checks).
	p.x=6.0
	p.y=7.5
	p.room="village"
	game.interact()
	check(game.forge.visible,"E keeps existing forge interaction near Bran")
	game.forge.hide()
	game.start_chapter1_dialogue()
	check(game.dialogue_npc=="bran","T can talk to Bran in forge overlap")
	game.finish_chapter1_dialogue()
	# Wrong-region collision coordinates must not open Chapter I NPCs or clues.
	p.room="harbor"
	p.x=Clues.EVIDENCE["last_promise"].x
	p.y=Clues.EVIDENCE["last_promise"].y
	check(not game.Chapter1.allowed(w,"local"),"wrong-region clue is not authorized")
	p.room="village"
	check(World.save_world(w,fixture),"p1g movement/interaction fixture saves with v23")
	game.mode="menu"
	game.queue_free()
	DirAccess.remove_absolute(fixture)
	DirAccess.remove_absolute(fixture+".bak")
	DirAccess.remove_absolute(fixture+".tmp")
	print("P1G_NAVIGATION: ","PASS" if failures==0 else "FAIL"," failures=",failures)
	quit(0 if failures==0 else 1)
