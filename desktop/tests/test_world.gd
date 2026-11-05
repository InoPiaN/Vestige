extends SceneTree
const Rules=preload("res://world.gd")
var failed:=0
func check(condition: bool, description: String) -> void:
	if not condition:
		failed+=1
		push_error(description)
	else: print("PASS: ",description)
func _initialize() -> void:
	var w:=Rules.fresh()
	Rules.born(w,"a","에단")
	var p: Dictionary=w.people.a
	check((p.limit-p.age)*Rules.DAY/86400==480,"480 real-day lifespan")
	p.x=21
	p.y=5
	Rules.act(w,"a","interact")
	Rules.tick(w,1)
	Rules.act(w,"a","interact")
	p.x=5
	p.y=8
	Rules.act(w,"a","interact")
	check(p.ore==0 and p.sword==1,"ore consumed by crafting")
	p.offline=true
	p.policy="gather"
	Rules.advance(w,Rules.DAY*3)
	check(p.herb==6 and p.journal.size()==3,"offline gathering and daily journal")
	p.age=p.limit-2
	Rules.advance(w,Rules.DAY*5)
	check(not p.alive and w.graves.size()==1 and w.books.size()==1,"death preserves one grave and book")
	var items: int=p.herb
	Rules.advance(w,Rules.DAY)
	check(p.herb==items,"dead characters stop producing")
	Rules.born(w,"a","후계자")
	check(w.people.a.skill==0 and w.books.size()==1,"new life preserves history, not skills")
	var path: String="/tmp/vestige-world-test.json"
	Rules.save_world(w,path)
	var loaded:=Rules.load_world(path)
	check(loaded.books.size()==1 and loaded.people.a.name=="후계자","save roundtrip")
	w=Rules.fresh()
	Rules.born(w,"a","전사")
	p=w.people.a
	p.x=25
	p.y=10
	Rules.tick(w,0.1)
	check(w.wolf.warning>0 and p.hp==100,"wolf telegraphs before damage")
	p.dodge=1
	Rules.tick(w,0.7)
	check(p.hp==100,"dodge avoids the telegraphed attack")
	quit(1 if failed else 0)
