extends SceneTree
const Rules=preload("res://world.gd")
var world: Dictionary
var dt: float
var failures:=0
const ID="traveler"

func verify(ok: bool, description: String) -> void:
	if not ok:
		failures+=1
		push_error(description)

func walk_to(destination: Vector2) -> void:
	for _frame in range(1800):
		var offset: Vector2=destination-Rules.pos(world.people[ID])
		if offset.length()<0.06: return
		Rules.move(world,ID,offset.normalized(),minf(dt,offset.length()/3.2))
		Rules.tick(world,dt)
	verify(false,"Unreachable waypoint %s" % destination)

func interact_at(kind: String) -> String:
	verify(Rules.nearby(world.people[ID]).get("kind","")==kind,"Expected to reach "+kind)
	return Rules.act(world,ID,"interact")

func journey(rate: int) -> void:
	dt=1.0/rate
	world=Rules.fresh()
	Rules.born(world,ID,"길잡이")
	walk_to(Vector2(21,9))
	walk_to(Vector2(21,5))
	interact_at("ore")
	for _frame in range(rate): Rules.tick(world,dt)
	interact_at("ore")
	walk_to(Vector2(21,9))
	walk_to(Vector2(5,9))
	walk_to(Vector2(5,8))
	interact_at("forge")
	var p: Dictionary=world.people[ID]
	verify(p.ore==0 and p.sword==1 and p.equipment.weapon=="iron_sword","Ore must become an equipped sword")
	walk_to(Vector2(5,9))
	walk_to(Vector2(26,9))
	interact_at("ruin")
	verify(p.relic==0,"Guarded ruin granted a reward")
	var gold_before: int=p.gold
	for _frame in range(rate*12):
		if world.wolf.hp<=0 or not p.alive: break
		if world.wolf.warning>0 and world.wolf.warning<0.25: Rules.act(world,ID,"dodge")
		if Rules.pos(p).distance_to(Rules.pos(world.wolf))<2: Rules.act(world,ID,"attack")
		Rules.tick(world,dt)
	verify(p.alive and world.wolf.hp==0 and p.gold==gold_before+8,"Victory must grant one bounty")
	interact_at("ruin")
	interact_at("ruin")
	verify(p.relic==1 and p.gold==gold_before+8,"Repeat inspection duplicated loot")
	var path: String=OS.get_temp_dir()+"/vestige-journey-%s-%s.json" % [OS.get_process_id(),rate]
	Rules.save_world(world,path)
	world=Rules.load_world(path)
	Rules.act(world,ID,"resume")
	p=world.people[ID]
	walk_to(Vector2(10,9))
	walk_to(Vector2(10,5))
	verify(interact_at("library")=="서재" and p.relic==1,"Relic must reach the library after reload")
	Rules.advance(world,Rules.DAY)
	var entry: String=p.journal.back().text
	verify(entry.count("늑대를 물리쳤다")==1 and entry.count("낡은 유물을 찾았다")==1,"Diary must record the victory and discovery once")
	walk_to(Vector2(10,9))
	walk_to(Vector2(26,9))
	verify(interact_at("ruin").begins_with("이미 조사한 장소"),"A returning traveler should recognize the surveyed ruin")
	DirAccess.remove_absolute(path)
	print("Completed first journey simulation at %d Hz" % rate)

func _initialize() -> void:
	for rate in [30,60]: journey(rate)
	# A wolf killed mid-lunge must telegraph again after respawning.
	world=Rules.fresh()
	Rules.born(world,ID,"정찰자")
	world.people[ID].x=25
	world.people[ID].y=10
	world.wolf.hp=1
	Rules.tick(world,0.02)
	Rules.act(world,ID,"attack")
	verify(world.wolf.hp==0,"Setup must defeat the attacking wolf")
	Rules.advance(world,Rules.DAY)
	Rules.tick(world,0.01)
	verify(world.wolf.warning>=0.65 and world.people[ID].hp==100,"Respawned wolf must start a full warning")
	quit(1 if failures else 0)
