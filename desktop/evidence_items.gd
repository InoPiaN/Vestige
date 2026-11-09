extends RefCounted
# Each case owns one physical object. Inventory entries are derived views only.
const HOME=Vector2(7,13)
static func prepare(w: Dictionary) -> void:
	for id in w.cases:
		var c: Dictionary=w.cases[id]
		if c.has("trace_mark") and not c.has("object"):
			c.object={"place":"ground","holder":"","x":c.x,"y":c.y}
	sync(w)
static func sync(w: Dictionary) -> void:
	for p in w.people.values():
		p.evidence_items={}
		for id in w.cases:
			var c: Dictionary=w.cases[id]
			if c.has("object") and c.object.place=="carried" and c.object.holder==p.life:
				p.evidence_items["evidence:"+id]={"name":"고리 조각","category":"기록","limit":1,"color":"bca77c","description":c.name+" 사건의 증거 · "+c.trace_mark+"\n집 근처에서 보관할 수 있습니다."}
static func collect(w: Dictionary,p: Dictionary) -> String:
	var lines: PackedStringArray=[]
	for id in w.cases:
		var c: Dictionary=w.cases[id]
		if not c.has("object"): continue
		var obj: Dictionary=c.object
		var point:=HOME if obj.place=="house" else Vector2(obj.x,obj.y)
		if obj.place=="carried" or Vector2(p.x,p.y).distance_to(point)>=2: continue
		if obj.place=="house" and w.estate.owner!=p.life and not w.cases.has(w.estate.owner): continue
		var text: String=c.name+" 사건의 "+c.trace_mark+" 조각을 "+("집 보관함" if obj.place=="house" else "바닥")+"에서 수집했다."
		obj.place="carried"
		obj.holder=p.life
		var notes: Dictionary=p.notebook.get(id,{})
		notes.object=text
		p.notebook[id]=notes
		p.events.append(text)
		lines.append(text)
	sync(w)
	return "\n".join(lines)
static func deposit(w: Dictionary,p: Dictionary,item: String) -> String:
	var id:=item.trim_prefix("evidence:")
	if not item.begins_with("evidence:") or not w.cases.has(id): return "보관할 증거물이 없습니다."
	var c: Dictionary=w.cases[id]
	if not c.has("object") or c.object.place!="carried" or c.object.holder!=p.life: return "소지한 증거물만 보관할 수 있습니다."
	if Vector2(p.x,p.y).distance_to(HOME)>=2: return "집 가까이에서 증거물을 보관하세요."
	if w.estate.owner!=p.life and not w.cases.has(w.estate.owner): return "다른 주민의 집에는 보관할 수 없습니다."
	c.object.place="house"
	c.object.holder=""
	p.events.append(c.name+" 사건의 고리 조각을 집 보관함에 남겼다.")
	sync(w)
	return "증거물을 집 보관함에 남겼습니다. 다른 인물이 F로 발견할 수 있습니다."
static func drop(w: Dictionary,p: Dictionary) -> void:
	for c in w.cases.values():
		if c.has("object") and c.object.place=="carried" and c.object.holder==p.life:
			c.object={"place":"ground","holder":"","x":p.x,"y":p.y}
	sync(w)
static func valid(w: Dictionary) -> bool:
	for c in w.cases.values():
		if not c.has("object"):
			if w.version>=3 and c.has("trace_mark"): return false
			continue
		var obj=c.object
		if not c.get("trace_mark") is String or not obj is Dictionary: return false
		if not obj.get("place") in ["ground","house","carried"] or not obj.get("holder") is String: return false
		for key in ["x","y"]:
			if not (obj.get(key) is float or obj.get(key) is int) or not is_finite(float(obj[key])): return false
		if obj.place=="carried":
			if not w.people.values().any(func(p): return p.alive and p.life==obj.holder): return false
		elif obj.holder!="": return false
	return true
