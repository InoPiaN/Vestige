extends SceneTree
const R=preload("res://world.gd")
const D=preload("res://investigation_demo.gd")
const Items=preload("res://items.gd")
var failures:=0
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failures+=1
		push_error(label)
func place(p: Dictionary,x: float,y: float) -> void:
	p.x=x
	p.y=y
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var w:=D.murder()
	var p: Dictionary=w.people.local
	var id: String=w.estate.owner
	var item: String="evidence:"+id
	R.act(w,"local","investigate")
	check(Items.quantity(p,item)==0,"Distant collection denied")
	place(p,16,13)
	R.act(w,"local","investigate")
	R.act(w,"local","investigate")
	check(Items.quantity(p,item)==1 and p.events.count(p.notebook[id].object)==1,"Repeated pickup has one item and one event")
	R.born(w,"other","둘째")
	place(w.people.other,16,13)
	R.act(w,"other","investigate")
	check(Items.quantity(w.people.other,item)==0,"Competing collector cannot duplicate object")
	R.act(w,"other","store_evidence",item)
	R.act(w,"local","store_evidence",item)
	check(w.cases[id].object.holder==p.life,"Non-owner and distant deposit denied")
	var view:=w.duplicate(true)
	R.Investigation.redact(view,"other")
	check(not view.people.local.has("evidence_items") and not view.has("cases"),"Other inventories and hidden object locations redacted")
	place(p,7,14)
	var bag:=preload("res://inventory_panel.gd").new()
	root.add_child(bag)
	bag.refresh(p)
	bag.choose(item)
	bag.action.connect(func(kind,value): R.act(w,"local",kind,value))
	bag.activate()
	check(w.cases[id].object.place=="house" and Items.quantity(p,item)==0,"Inventory action deposits physical evidence")
	R.die(w,"local","노환")
	R.born(w,"local","후계자")
	p=w.people.local
	check(p.notebook.is_empty() and w.cases[id].object.place=="house","Successor has no inherited knowledge; stored object survives")
	place(p,7,14)
	R.act(w,"local","investigate")
	check(Items.quantity(p,item)==1 and p.notebook[id].object.contains("집 보관함"),"Successor discovers object at house")
	place(p,20,15)
	R.die(w,"local","늑대와의 전투")
	check(w.cases[id].object.place=="ground" and w.cases[id].object.x==20,"Carrier death drops object at actual death site")
	R.born(w,"local","세번째")
	p=w.people.local
	place(p,20,15)
	check(not R.Investigation.traces(w,p).is_empty(),"Nearby dropped object has investigation marker")
	R.act(w,"local","investigate")
	var path:=OS.get_temp_dir()+"/vestige-evidence-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Evidence custody saves")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and Items.quantity(loaded.people.local,item)==1,"Reload derives inventory from custody")
	var bad:=w.duplicate(true)
	bad.cases[id].object.holder="missing"
	check(not R.Store.valid(bad),"Orphaned custody rejected")
	var legacy:=D.murder()
	legacy.cases[legacy.estate.owner].erase("object")
	R.Investigation.Objects.prepare(legacy)
	check(legacy.cases[legacy.estate.owner].object.place=="ground","Old case gains one object")
	bag.queue_free()
	for ext in ["",".bak"]: DirAccess.remove_absolute(path+ext)
	quit(1 if failures else 0)
