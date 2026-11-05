extends SceneTree
const Rules=preload("res://world.gd")
const Items=preload("res://items.gd")
const Main=preload("res://main.gd")
var failures:=0
func check(ok: bool, text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failures+=1
		push_error(text)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game:=Main.new()
	root.add_child(game)
	game.mode="single"
	game.save_path="/tmp/vestige-inventory-ui-test.json"
	game.world=Rules.fresh()
	Rules.born(game.world,"local","가방 시험")
	var p: Dictionary=game.world.people.local
	check(Items.entries(p).size()==3,"starter gear belongs to inventory")
	p.ore=2
	p.x=5
	p.y=8
	Rules.act(game.world,"local","interact")
	check(Items.quantity(p,"ore")==0 and Items.quantity(p,"iron_sword")==1,"craft consumes inventory material and grants sword")
	game.open_inventory()
	game.bag.choose("iron_sword")
	game.bag.activate()
	check(p.equipment.weapon=="none" and p.sword==1,"inventory unequip preserves owned sword")
	game.bag.activate()
	check(p.equipment.weapon=="iron_sword" and p.sword==1,"inventory equip does not duplicate item")
	p.herb=2
	p.hp=80
	game.bag.choose("herb")
	game.bag.activate()
	check(p.hp==100 and p.herb==1,"inventory consumes one herb and caps health")
	game.bag.activate()
	Rules.act(game.world,"local","heal")
	check(p.herb==1 and game.bag.use_button.disabled,"full health blocks herb consumption in UI and rules")
	check(Items.entries(p,"장비").size()==4 and Items.entries(p,"소모품").size()==1,"category filtering uses actual ownership")
	p.belongings.erase("hood")
	Rules.act(game.world,"local","equip","head:hood")
	check(p.equipment.head=="none","server rejects unowned starter equipment")
	Rules.save_world(game.world,game.save_path)
	var saved:=Rules.load_world(game.save_path)
	check(Items.entries(saved.people.local)==Items.entries(p) and saved.people.local.equipment==p.equipment,"inventory and equipment survive reload")
	game.queue_free()
	quit(1 if failures else 0)
