extends SceneTree
const Rules=preload("res://world.gd")
const Main=preload("res://main.gd")
var failures:=0
func check(ok: bool, what: String) -> void:
	if ok: print("PASS: ",what)
	else:
		failures+=1
		push_error(what)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var w:=Rules.fresh()
	Rules.born(w,"a","루안",{"hair":2,"skin":2,"hair_color":3,"cloth":1})
	var p: Dictionary=w.people.a
	check(p.look.hair==2 and p.look.skin==2,"creation keeps selected appearance")
	Rules.act(w,"a","equip","weapon:iron_sword")
	check(p.equipment.weapon=="none","unowned sword cannot be equipped")
	p.sword=1
	p.x=25
	p.y=10
	Rules.act(w,"a","equip","weapon:iron_sword")
	Rules.act(w,"a","attack")
	check(w.wolf.hp==28,"equipped sword changes combat damage")
	Rules.act(w,"a","equip","weapon:none")
	p.attack=0
	Rules.act(w,"a","attack")
	check(w.wolf.hp==19,"unequipping restores unarmed damage")
	Rules.act(w,"a","equip","body:leather")
	Rules.act(w,"a","equip","head:hood")
	Rules.act(w,"a","equip","cloak:traveler")
	Rules.act(w,"a","helmet","hide")
	Rules.act(w,"a","equip","weapon:invalid")
	check(p.equipment.weapon=="none" and p.equipment.head=="hood" and p.hide_helmet,"gear validation and hidden helmet")
	Rules.save_world(w,"/tmp/vestige-customization-test.json")
	var restored:=Rules.load_world("/tmp/vestige-customization-test.json")
	check(restored.people.a.look==p.look and restored.people.a.equipment==p.equipment and restored.people.a.hide_helmet,"appearance and equipment survive reload")
	p.erase("look")
	p.erase("equipment")
	p.erase("hide_helmet")
	var old:=w.duplicate(true)
	old.version=1
	var legacy_file:=FileAccess.open("/tmp/vestige-customization-legacy.json",FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(old))
	legacy_file.close()
	var legacy:=Rules.load_world("/tmp/vestige-customization-legacy.json")
	check(legacy.people.a.equipment.weapon=="iron_sword" and legacy.people.a.name=="루안","legacy save keeps name and sword with appearance defaults")
	Rules.die(w,"a","시험")
	Rules.born(w,"a","후임",{"hair":1})
	check(w.people.a.look.hair==1 and w.people.a.equipment.weapon=="none" and w.books.size()==1,"new life has independent appearance and preserves predecessor book")
	var game:=Main.new()
	root.add_child(game)
	game.open_dressing("create")
	game.dress_controls.get_child(0).item_selected.emit(2)
	check(game.chosen_look.hair==2 and game.portrait.person.look.hair==2,"creation controls update live portrait")
	game.save_path="/tmp/vestige-customization-ui.json"
	game.world=Rules.fresh()
	Rules.born(game.world,"local","시험",game.chosen_look)
	game.mode="single"
	game.open_dressing("gear")
	game.dress_controls.get_child(0).item_selected.emit(1)
	check(game.world.people.local.equipment.body=="leather" and game.portrait.person.equipment.body=="leather","equipment UI updates world and preview")
	Rules.die(game.world,"local","시험")
	game.open_dressing("new")
	game.dress_name.text="다음 여행자"
	game.dress_controls.get_child(0).item_selected.emit(1)
	game.dress_confirm.pressed.emit()
	check(game.world.people.local.name=="다음 여행자" and game.world.people.local.look.hair==1 and game.world.books.size()==1,"new-life form creates selected successor without losing history")
	check(Rules.clean_look({"hair":999,"skin":"invalid"})=={"hair":2,"hair_color":0,"skin":0,"cloth":0},"untrusted appearance values are bounded")
	game.queue_free()
	quit(1 if failures else 0)
