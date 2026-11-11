extends RefCounted

const Objects=preload("res://evidence_items.gd")
const Witness=preload("res://witness.gd")
const HOME := Vector2(7,13)
const CEMETERY := Vector2(4,14)
const PRICE := 8

static func prepare(w: Dictionary) -> void:
	if not w.has("estate"):
		w.estate={"owner":"","shelf":""}
	if not w.has("cases"): w.cases={}
	Objects.prepare(w)

static func prepare_person(p: Dictionary) -> void:
	if not p.has("life"): p.life=Crypto.new().generate_random_bytes(12).hex_encode()
	if not p.has("notebook"): p.notebook={}

static func near(p: Dictionary, point: Vector2) -> bool:
	if p.get("room","village")=="home":
		return point==HOME and preload("res://house_interior.gd").near(p,"shelf")
	return Vector2(p.x,p.y).distance_to(point)<2

static func visit_house(w: Dictionary,p: Dictionary) -> String:
	if w.estate.owner=="":
		if p.gold<PRICE: return "집을 사려면 은화 8개가 필요합니다."
		p.gold-=PRICE
		w.estate.owner=p.life
		p.events.append("은화 8개로 잿불 마을의 집을 샀다.")
	if w.estate.owner==p.life:
		var lines: PackedStringArray=[]
		for entry in p.journal: lines.append("제 %d일 · %s" % [entry.day,entry.text])
		for event in p.events: lines.append(event)
		w.estate.shelf="\n".join(lines)
		return "집 책장에 오늘까지의 일지를 보관했습니다."
	if w.cases.has(w.estate.owner): return investigate(w,p)
	return "다른 주민이 사는 집입니다."

static func record_death(w: Dictionary,p: Dictionary,grave: Dictionary,book: Dictionary) -> void:
	if w.estate.owner!=p.life: return
	var id: String=p.life
	w.cases[id]={"name":p.name,"truth":grave.cause,"x":p.x,"y":p.y,"resolved":false,"room":p.get("room","village")}
	grave.case_id=id
	grave.cause="사인 미확인"
	grave.x=CEMETERY.x
	grave.y=CEMETERY.y
	book.case_id=id

static func evidence(c: Dictionary) -> String:
	if c.has("roster"): return "현장의 기록에서 %s 모양의 흔적을 확인했다. 장터 상자 곁의 등불지기 미라에게 그날의 일을 물어보자." % c.trace_mark
	if c.truth=="늑대와의 전투": return "찢긴 옷과 그 주위를 맴돈 늑대 발자국을 확인했다."
	if c.truth=="노환": return "몸 곁의 유품은 가지런했고 다툰 흔적은 보이지 않았다."
	return "사망 장소에서 망자의 소지품을 확인했다."

static func has_witness(w: Dictionary) -> bool:
	if w.has("witness_available"): return w.witness_available
	return w.cases.get(w.estate.owner,{}).has("roster")

static func traces(w: Dictionary,p: Dictionary) -> Array:
	if w.has("visible_traces"): return w.visible_traces
	var found: Array=[]
	for c in w.cases.values():
		if p.get("room","village")==c.get("room","village") and Vector2(p.x,p.y).distance_to(Vector2(c.x,c.y))<2: found.append({"x":c.x,"y":c.y})
	for c in w.cases.values():
		if c.has("object") and c.object.place=="ground" and p.get("room","village")==c.object.get("room","village") and Vector2(p.x,p.y).distance_to(Vector2(c.object.x,c.object.y))<2:
			found.append({"x":c.object.x,"y":c.object.y})
	for row in preload("res://death_belongings.gd").visible(w,p).values():
		found.append({"x":row.x,"y":row.y})
	return found

static func investigate(w: Dictionary,p: Dictionary) -> String:
	var lines: PackedStringArray=[]
	var collected:=Objects.collect(w,p)
	if not collected.is_empty(): lines.append(collected)
	for id in w.cases:
		var c: Dictionary=w.cases[id]
		var notes: Dictionary=p.notebook.get(id,{})
		if near(p,HOME):
			notes.home=c.name+"의 집에서 읽은 일지\n"+w.estate.shelf
			lines.append(notes.home)
		if p.get("room","village")==c.get("room","village") and Vector2(p.x,p.y).distance_to(Vector2(c.x,c.y))<2:
			notes.scene=c.name+"의 현장 · "+evidence(c)
			lines.append(notes.scene)
		if c.has("roster") and near(p,Witness.STATION):
			var testimony:=Witness.testify(c)
			if not c.observation.is_empty(): notes.witness=testimony
			lines.append(testimony)
		if near(p,CEMETERY):
			if c.has("roster") and notes.has("home") and notes.has("scene"):
				if notes.has("finding"): lines.append(notes.finding)
				elif notes.has("witness"): lines.append(Witness.candidates(c))
				else: lines.append("장터의 등불지기에게 그날 무엇을 보았는지 물어보자.")
			elif notes.has("home") and notes.has("scene"):
				notes.finding=c.name+"의 장례 기록을 단서와 대조했다. 확인된 사인: "+c.truth
				if not c.resolved:
					for grave in w.graves:
						if grave.get("case_id","")==id: grave.cause=c.truth
					c.resolved=true
					p.events.append(notes.finding)
				lines.append(notes.finding)
			else:
				var area: String="언덕집 안" if c.get("room","village")=="home" else ("동쪽 숲" if c.x>=18 else "마을 안")
				notes.lead=c.name+"의 묘비 · 수습 지역: "+area+". 집 책장과 수습 장소의 기록을 찾아보자."
				lines.append(notes.lead)
		if not notes.is_empty(): p.notebook[id]=notes
	if lines.is_empty(): return "근처에 조사할 기록이 없습니다."
	return "조사 기록\n"+"\n\n".join(lines)

static func may_read(p: Dictionary,book: Dictionary) -> bool:
	if not book.has("case_id"): return true
	var id: String=book.case_id
	var notes: Dictionary=p.notebook.get(id,{})
	return p.life==id or (notes.has("home") and notes.has("scene"))

static func redact(snapshot: Dictionary,viewer: String) -> void:
	var p: Dictionary=snapshot.people[viewer]
	snapshot.remains=preload("res://death_belongings.gd").visible(snapshot,p)
	snapshot.witness_available=has_witness(snapshot)
	snapshot.visible_traces=traces(snapshot,p)
	for id in snapshot.people.keys():
		if id==viewer: continue
		var other: Dictionary=snapshot.people[id]
		other.erase("notebook")
		other.erase("craft_xp")
		other.erase("craft_plan")
		other.erase("craft_supply")
		other.erase("evidence_items")
		other.erase("gear_instances")
		other.erase("gear_condition")
		other.erase("gear_quality")
		other.erase("gear_records")
		other.erase("equipped_ids")
		if not other.alive and snapshot.cases.has(other.life): snapshot.people.erase(id)
	snapshot.books=snapshot.books.filter(func(book): return may_read(p,book))
	var storage_access:=preload("res://house_storage.gd").allowed(snapshot,p)
	snapshot.storage_access=storage_access
	snapshot.erase("cases")
	snapshot.erase("craft_rng")
	snapshot.estate.erase("shelf")
	if snapshot.estate.has("interior"):
		if p.get("room","village")!="home": snapshot.estate.erase("interior")
		else: snapshot.estate.interior.erase("drawers")
	if not storage_access and not (p.alive and snapshot.estate.owner==p.life): snapshot.estate.erase("storage")
