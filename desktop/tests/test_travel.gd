extends SceneTree
const R=preload("res://world.gd")
const T=preload("res://travel.gd")
var failed:=0
func _initialize() -> void: call_deferred("run")
func check(ok: bool,text: String) -> void:
	if ok: print("PASS: ",text)
	else:
		failed+=1
		push_error(text)
func at(p: Dictionary,x: float,y: float) -> void:
	p.x=x
	p.y=y
func run() -> void:
	var w:=preload("res://investigation_demo.gd").travel()
	var p: Dictionary=w.people.local
	check(R.Store.valid(w) and p.discovered==["village"],"New traveler knows only starting village")
	R.act(w,"local","interact")
	check(p.mail_quest=="outbound","Village messenger starts letter quest")
	R.act(w,"local","interact")
	check(p.mail_quest=="outbound" and p.gold==25,"Repeated acceptance gives no reward")
	at(p,9,16)
	R.act(w,"local","coach")
	check(p.gold==25 and T.region(p)=="village","Undiscovered town cannot be reached by coach")
	at(p,29,9)
	R.act(w,"local","interact")
	check(p.room=="road" and p.x==2.5 and "road" in p.discovered,"East gate enters road and records discovery")
	for i in range(100): R.move(w,"local",Vector2.UP,1.0/60)
	check(p.y>=6,"Road terrain bounds stop movement into forest")
	at(p,2.5,9)
	for i in range(500): R.move(w,"local",Vector2.RIGHT,1.0/60)
	check(p.x>28,"Road can be traversed through actual movement")
	R.act(w,"local","interact")
	check(p.room=="harbor" and p.discovered.size()==3,"Road east gate discovers harbor")
	at(p,25,8)
	var before: float=p.x
	R.move(w,"local",Vector2.RIGHT,0.1)
	check(p.x==before,"Harbor water blocks movement")
	at(p,12,9)
	R.act(w,"local","interact")
	check(p.mail_quest=="reply","Harbor guide accepts letter and hands back reply")
	R.act(w,"local","interact")
	check(p.gold==25,"Reply cannot award sender reward remotely")
	at(p,9,5)
	p.hp=20
	p.stamina=10
	R.act(w,"local","interact")
	check(p.hp==100 and p.stamina==100,"Harbor inn restores health and stamina")
	at(p,18,10)
	R.act(w,"local","harbor_buy","wood")
	check(p.belongings.wood==1 and p.gold==23 and w.harbor_market.stock.wood==9,"Harbor merchant has real shared stock and cost")
	check(w.market.stock.wood==10,"Harbor stock is separate from first village")
	at(p,5,8)
	R.act(w,"local","harbor_buy","wood")
	check(p.gold==23,"Remote harbor purchase rejected")
	p.ore=4
	R.act(w,"local","craft_bow")
	R.act(w,"local","interact")
	check(p.sword==0 and p.ore==4,"Matching forge coordinates in harbor cannot craft old village sword")
	at(p,7,14)
	R.act(w,"local","enter_home")
	R.act(w,"local","store_item","wood")
	check(p.room=="harbor" and w.estate.owner=="" and p.belongings.wood==1,"Matching house coordinates cannot enter buy or use distant storage")
	at(p,25,10)
	w.wolf.warning=0.1
	R.tick(w,0.2)
	check(p.hp==100 and R.Expedition.selected(w,p).is_empty(),"Other-region wolf cannot damage or become target")
	R.act(w,"local","attack")
	check(w.wolf.hp==50,"Cross-region attacks cannot damage old enemies")
	at(p,5,14)
	p.offline=true
	R.act(w,"local","coach")
	check(p.room=="harbor" and p.gold==23,"Offline travel rejected")
	p.policy="work"
	R.advance(w,R.DAY)
	check(p.sword==0 and p.ore==4,"Away traveler rests without crafting in distant workshop")
	check(w.harbor_market.stock.wood==10,"Harbor merchant restocks next world day")
	p.offline=false
	R.act(w,"local","coach")
	check(p.room=="village" and p.gold==18 and p.x==9 and p.y==16,"Discovered coach route returns to safe village stop for five coins")
	at(p,3,9)
	R.act(w,"local","interact")
	check(p.mail_quest=="done" and p.gold==30,"Returning reply awards exactly twelve coins")
	R.act(w,"local","interact")
	check(p.gold==30,"Completed letter quest cannot be paid twice")
	at(p,9,16)
	p.gold=4
	R.act(w,"local","coach")
	check(p.room=="village" and p.gold==4,"Insufficient coach fare consumes nothing")
	p.gold=30
	R.act(w,"local","coach")
	check(p.room=="harbor" and p.gold==25,"Coach supports both directions after discovery")
	at(p,1,9)
	R.act(w,"local","interact")
	check(p.room=="road" and p.x==27.5,"Harbor west exit returns to road east end")
	at(p,1,9)
	R.act(w,"local","interact")
	check(p.room=="village" and p.x==27.5,"Road west exit returns to village east end")
	R.advance(w,R.DAY)
	check(p.journal.back().text.contains("답신") and p.journal.back().text.contains("마차"),"Travel and letter events reach daily diary")
	var path: String=OS.get_temp_dir()+"/vestige-travel-"+str(OS.get_process_id())+".json"
	check(R.save_world(w,path),"Travel state saves with schema twenty three")
	var loaded:=R.load_world(path,false)
	check(not loaded.is_empty() and loaded.people.local.discovered.size()==3 and loaded.people.local.mail_quest=="done","Reload preserves discovery and letter completion")
	for key in ["room","mail_quest"]:
		var bad:=w.duplicate(true)
		bad.people.local[key]="invalid"
		check(not R.Store.valid(bad),"Malformed travel state rejected: "+key)
	var bad:=w.duplicate(true)
	bad.people.local.discovered=["village","village"]
	check(not R.Store.valid(bad),"Duplicate discovery rejected")
	bad=w.duplicate(true)
	bad.harbor_market.stock.wood=-1
	check(not R.Store.valid(bad),"Invalid harbor inventory rejected")
	# A house owner's death abroad remains investigable at the correct region.
	at(p,7,14)
	R.act(w,"local","enter_home")
	p.room="road"
	at(p,12,9)
	var life: String=p.life
	R.die(w,"local","노환")
	check(w.remains[life].room=="road" and w.cases[life].room=="road" and w.graves.back().room=="village","Death preserves regional remains and scene with village memorial")
	R.born(w,"local","후계 여행자")
	var successor: Dictionary=w.people.local
	at(successor,12,9)
	check(R.Remains.visible(w,successor).is_empty(),"Same coordinates in other region do not reveal remains")
	R.act(w,"local","investigate")
	check(not successor.notebook.get(life,{}).has("scene"),"Same coordinates in other region do not reveal scene")
	at(successor,7,14)
	R.act(w,"local","enter_home")
	at(successor,11,6)
	R.act(w,"local","investigate")
	successor.room="road"
	at(successor,12,9)
	R.act(w,"local","investigate")
	check(successor.notebook[life].has("scene") and not R.Remains.visible(w,successor).is_empty(),"Successor discovers actual foreign-region scene and belongings")
	R.act(w,"local","take_remains",life+"|wood")
	check(successor.belongings.wood==1,"Foreign-region belongings can be recovered")
	successor.room="village"
	at(successor,4,14)
	R.act(w,"local","investigate")
	check(w.cases[life].resolved and R.Store.valid(w),"House scene and village memorial resolve death across regions")
	check(successor.discovered==["village"] and successor.mail_quest=="new","New life has own exploration and letter progress")
	var view:=w.duplicate(true)
	R.born(view,"other","관찰자")
	R.Investigation.redact(view,"other")
	check(not view.people.local.has("discovered") and not view.people.local.has("mail_quest"),"Other players do not receive personal exploration history")
	var legacy:=R.fresh()
	R.born(legacy,"local","이전 여행자")
	legacy.version=20
	legacy.erase("harbor_market")
	legacy.people.local.erase("discovered")
	legacy.people.local.erase("mail_quest")
	var file:=FileAccess.open(path+".old",FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy))
	file.close()
	loaded=R.load_world(path+".old",false)
	check(not loaded.is_empty() and loaded.version==23 and loaded.people.local.discovered==["village"],"Version twenty migrates without invented discoveries")
	for name in [path,path+".old"]:
		for suffix in ["",".bak"]: DirAccess.remove_absolute(name+suffix)
	quit(1 if failed else 0)
