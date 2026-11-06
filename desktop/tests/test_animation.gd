extends SceneTree
const Rules=preload("res://world.gd")
const Motion=preload("res://animation.gd")
var failed:=0
func check(ok: bool, description: String) -> void:
	if ok: print("PASS: ",description)
	else:
		failed+=1
		push_error(description)
func _initialize() -> void:
	var w:=Rules.fresh()
	Rules.born(w,"a","방향 시험")
	var p: Dictionary=w.people.a
	for d in [Vector2.DOWN,Vector2.UP,Vector2.LEFT,Vector2.RIGHT]:
		Rules.move(w,"a",d,0.1)
		check(p.direction==Motion.direction(d) and p.motion>0,"movement faces "+Motion.direction(d))
	Rules.tick(w,0.2)
	check(p.motion==0 and Motion.pose(p).stride==0,"stopping returns to neutral feet")
	p.x=1
	p.y=5
	var steps: float=p.steps
	Rules.move(w,"a",Vector2.LEFT,0.2)
	check(p.steps==steps and p.motion==0,"blocked movement does not walk in place")
	p.x=21
	p.y=5
	Rules.act(w,"a","interact")
	check(Motion.pose(p).phase=="idle","gathering cooldown is not a sword attack")
	p.attack=0
	p.x=24
	p.y=10
	Rules.act(w,"a","attack")
	check(p.direction=="right" and Motion.pose(p).phase=="strike","attack faces struck enemy")
	Rules.tick(w,0.3)
	check(Motion.pose(p).phase=="recover","attack transitions to recovery")
	Rules.tick(w,0.3)
	check(Motion.pose(p).phase=="idle","attack returns to idle")
	p.x=25
	p.y=10
	w.wolf.cooldown=0
	Rules.tick(w,0.01)
	Rules.tick(w,0.7)
	check(p.hurt>0 and Motion.pose(p).hurt,"damage triggers hit reaction")
	Rules.tick(w,0.3)
	check(not Motion.pose(p).hurt,"hit reaction expires")
	p.offline=true
	p.policy="rest"
	p.x=11
	p.y=12
	p.motion=0
	steps=p.steps
	Rules.tick(w,0.1)
	check(p.steps==steps and p.motion==0,"resident stands still at destination")
	Rules.save_world(w,"/tmp/vestige-animation-test.json")
	var loaded:=Rules.load_world("/tmp/vestige-animation-test.json")
	check(loaded.people.a.direction==p.direction,"facing survives save reload")
	quit(1 if failed else 0)
