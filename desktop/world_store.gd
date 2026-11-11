extends RefCounted

static func numbers(row: Dictionary, fields: Array) -> bool:
	for key in fields:
		var value=row.get(key)
		if not (value is int or value is float) or not is_finite(float(value)): return false
	return true

static func pages_valid(pages: Variant) -> bool:
	if not pages is Array: return false
	for page in pages:
		if not page is Dictionary or not numbers(page,["day"]) or not page.get("text") is String:
			return false
	return true

static func valid(w: Dictionary) -> bool:
	if (w.get("version")!=1 and w.get("version")!=2 and w.get("version")!=3 and w.get("version")!=4 and w.get("version")!=5 and w.get("version")!=6 and w.get("version")!=7 and w.get("version")!=8 and w.get("version")!=9 and w.get("version")!=10 and w.get("version")!=11 and w.get("version")!=12 and w.get("version")!=13) or not numbers(w,["time","saved"]): return false
	if w.time<0 or w.saved<0: return false
	if not w.get("people") is Dictionary or not w.get("wolf") is Dictionary: return false
	if not numbers(w.wolf,["x","y","hp","cooldown","warning","respawn"]): return false
	if not w.get("books") is Array or not w.get("graves") is Array: return false
	for book in w.books:
		if not book is Dictionary or not book.get("author") is String or not book.get("last") is String or not pages_valid(book.get("pages")): return false
	for grave in w.graves:
		if not grave is Dictionary or not numbers(grave,["day","x","y"]) or not grave.get("name") is String or not grave.get("cause") is String: return false
	for p in w.people.values():
		if not p is Dictionary or not numbers(p,["x","y","age","limit","hp","stamina","attack","dodge","steps","ore","herb","sword","gold","skill","relic"]): return false
		if w.version>=12 and not preload("res://craft_supply.gd").valid(p): return false
		if w.version>=11 and not preload("res://craft_plan.gd").valid(p): return false
		if w.version>=10 and not preload("res://craft_mastery.gd").valid(p): return false
		if not p.get("alive") is bool or not p.get("name") is String or not p.get("policy") is String: return false
		if not p.get("events") is Array or not pages_valid(p.get("journal")): return false
		for event in p.events:
			if not event is String: return false
		for key in ["look","equipment","belongings"]:
			if p.has(key) and not p[key] is Dictionary: return false
	if w.version>=2: return history_valid(w)
	return true

static func history_valid(w: Dictionary) -> bool:
	if not w.get("estate") is Dictionary or not w.get("cases") is Dictionary: return false
	if not w.estate.get("owner") is String or not w.estate.get("shelf") is String: return false
	for p in w.people.values():
		if not p.get("life") is String or p.life.is_empty() or not p.get("notebook") is Dictionary: return false
		for id in p.notebook:
			if not w.cases.has(id) or not p.notebook[id] is Dictionary: return false
			for note in p.notebook[id].values():
				if not note is String: return false
	for id in w.cases:
		var c=w.cases[id]
		if not c is Dictionary or not numbers(c,["x","y"]): return false
		if c.get("room","village") not in ["home","village"]: return false
		if not c.get("name") is String or not c.get("truth") is String or not c.get("resolved") is bool: return false
		if c.truth=="칼에 의한 살해":
			if not c.get("roster") is Array or c.roster.size()!=2 or not c.get("attacker") is String or not c.get("trace_mark") is String: return false
			for suspect in c.roster:
				if not suspect is Dictionary or not suspect.get("name") is String or not suspect.get("mark") is String: return false
			if not c.get("observation") is Dictionary: return false
			if not c.observation.is_empty() and (not numbers(c.observation,["day"]) or not c.observation.get("mark") is String): return false
		if id!=w.estate.owner: return false
		if not w.graves.any(func(grave): return grave.get("case_id","")==id): return false
		if not w.books.any(func(book): return book.get("case_id","")==id): return false
	for book in w.books:
		if book.has("case_id") and not w.cases.has(book.case_id): return false
	for grave in w.graves:
		if grave.has("case_id") and not w.cases.has(grave.case_id): return false
	if not w.estate.owner.is_empty() and not w.cases.has(w.estate.owner):
		if not w.people.values().any(func(person): return person.life==w.estate.owner and person.alive): return false
	if w.version>=9 and not preload("res://village_market.gd").valid(w): return false
	if w.version>=8 and not preload("res://craft_quality.gd").valid(w): return false
	if w.version>=6 and not preload("res://house_interior.gd").valid(w): return false
	if w.version>=5 and not preload("res://death_belongings.gd").valid(w): return false
	return preload("res://evidence_items.gd").valid(w) and (w.version<4 or preload("res://house_storage.gd").valid(w))

static func read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null: return {}
	var parser:=JSON.new()
	if parser.parse(file.get_as_text())!=OK or not parser.data is Dictionary: return {}
	return parser.data

static func unsupported(w: Dictionary) -> bool:
	return numbers(w,["version"]) and w.version>13

# Write beside the destination. Replace each file only after its staging step succeeds.
static func replace(w: Dictionary, path: String, previous: Dictionary) -> bool:
	if not valid(w) or unsupported(previous): return false
	var file:=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	if not file.store_string(JSON.stringify(w,"",true,true)): return false
	file.flush()
	if file.get_error()!=OK: return false
	file.close()
	if not valid(read(path+".tmp")): return false
	if valid(previous) or not FileAccess.file_exists(path+".bak"):
		var source:=path if valid(previous) else path+".tmp"
		if DirAccess.copy_absolute(source,path+".bak.tmp")!=OK: return false
		if DirAccess.rename_absolute(path+".bak.tmp",path+".bak")!=OK: return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK
