extends RefCounted
# Existing resource counters remain the single source of truth for old saves.
const BASE_CATALOG := {
	"bandage":{"name":"약초 붕대","category":"소모품","limit":10,"color":"c7c5a1","description":"체력 45 회복. 천 1개와 약초 1개로 제작합니다."},
	"repair_kit":{"name":"간이 수선 도구","category":"재료","limit":10,"color":"b6a07b","description":"집 작업대에서 선택한 철검 내구도 +40. 천 1개와 못 2개로 제작합니다."},
	"mug":{"name":"고친 찻잔","category":"재료","limit":5,"color":"c0bd9a","description":"약초차 제작 도구. 사용할 때 사라지지 않습니다."},
	"herbal_tea":{"name":"약초차","category":"소모품","limit":10,"color":"8da67a","description":"체력 20 · 기력 40 회복. 찻잔과 켜진 벽난로가 있어야 약초 1개로 만듭니다."},
	"cloth":{"name":"낡은 천 조각","category":"재료","limit":20,"color":"a29a80","description":"서랍에 남은 수선용 천. 보관하거나 유품으로 남길 수 있습니다. 집 작업대에서 붕대·수선 도구·찻잔 수선에 사용합니다."},
	"bent_nail":{"name":"휘어진 못","category":"재료","limit":20,"color":"8e9690","description":"오래된 가구에서 모아 둔 못. 천과 함께 간이 수선 도구를 만듭니다."},
	"broken_cup":{"name":"금 간 찻잔","category":"기록","limit":5,"color":"b7bba5","description":"누군가 매일 사용했을 법한 찻잔. 천으로 고치면 약초차 제작 도구가 됩니다."},
	"ore":{"name":"철광석","category":"재료","field":"ore","limit":20,"color":"92a6a1","description":"철검 제작 재료. 대장간에서 2개를 소비합니다."},
	"herb":{"name":"달빛 약초","category":"소모품","field":"herb","limit":20,"color":"8ab88e","description":"1개를 사용해 체력 30을 회복합니다."},
	"iron_sword":{"name":"철검","category":"장비","field":"sword","limit":5,"slot":"weapon","color":"c4d4d0","description":"착용 시 공격력 22. 명중할 때 내구도 5 소모.\n내구도 0이면 공격력 9. 검은 사라지지 않습니다."},
	"leather":{"name":"가죽 갑옷","category":"장비","limit":1,"slot":"body","color":"ae8257","description":"여행자를 위한 시작 방어구.\n현재는 외형 장비이며 방어력은 없습니다."},
	"hood":{"name":"여행 후드","category":"장비","limit":1,"slot":"head","color":"749995","description":"머리를 덮는 시작 장비.\n투구 숨김 설정은 외형 · 장비에서 변경합니다."},
	"traveler":{"name":"여행 망토","category":"장비","limit":1,"slot":"cloak","color":"648c9e","description":"어깨에서 내려오는 시작 망토.\n착용하면 인물의 실루엣이 바뀝니다."},
	"relic":{"name":"이렌의 유물","category":"기록","field":"relic","limit":1,"color":"d1b777","description":"예배당에서 발견한 유물.\n서재에서 이렌의 기록을 읽을 수 있습니다."}
}
static var CATALOG: Dictionary=make_catalog()
static func make_catalog() -> Dictionary:
	var catalog:=BASE_CATALOG.duplicate(true)
	for base in ["bandage","repair_kit","mug","herbal_tea"]:
		for tier in ["fine","great"]:
			var item: Dictionary=BASE_CATALOG[base].duplicate()
			item.base=base
			item.tier=tier
			item.name=("양품 " if tier=="fine" else "대성공 ")+item.name
			item.color="94b9ad" if tier=="fine" else "e2c481"
			if base=="bandage": item.description="체력 %d 회복." % (48 if tier=="fine" else 54)
			if base=="repair_kit": item.description="작업대에서 철검 내구도 %d 복원." % (44 if tier=="fine" else 50)
			if base=="herbal_tea": item.description="체력 %d · 기력 %d 회복." % [22 if tier=="fine" else 25,44 if tier=="fine" else 50]
			if base=="mug": item.description="재사용 찻잔. 약초차 대성공 확률 +%d%%p." % (2 if tier=="fine" else 5)
			catalog[base+"_"+tier]=item
	return catalog
static func base_id(id: String) -> String:
	return CATALOG.get(id,{}).get("base",id)
static func family_quantity(p: Dictionary,id: String) -> int:
	var base:=base_id(id)
	return quantity(p,base)+quantity(p,base+"_fine")+quantity(p,base+"_great")
static func best(p: Dictionary,base: String) -> String:
	for id in [base+"_great",base+"_fine",base]:
		if quantity(p,id)>0: return id
	return ""
static func definition(p: Dictionary,id: String) -> Dictionary:
	if p.get("gear_instances",{}).has(id):
		var def: Dictionary=CATALOG[p.gear_instances[id]].duplicate()
		def.name+=" · "+id.right(4)
		def.limit=1
		if p.gear_instances[id]=="iron_sword":
			var quality: Dictionary=p.get("gear_quality",{}).get(id,{"tier":"common","attack":22})
			def.name=preload("res://craft_quality.gd").LABELS[quality.tier]+" "+def.name
			if quality.tier!="common": def.color="94b9ad" if quality.tier=="fine" else "e2c481"
			def.description="공격력 %d · 내구도 0이면 9.\n명중 시 내구도 5 소모." % quality.attack
			def.description+="\n내구도 %d / 100" % int(p.get("gear_condition",{}).get(id,100))
		return def
	return CATALOG.get(id,p.get("evidence_items",{}).get(id,{}))
static func quantity(p: Dictionary, id: String) -> int:
	if p.get("gear_instances",{}).has(id): return 1
	if p.get("evidence_items",{}).has(id): return 1
	if not CATALOG.has(id): return 0
	var item: Dictionary=CATALOG[id]
	if item.has("field"): return maxi(0,int(p.get(item.field,0)))
	return maxi(0,int(p.get("belongings",{}).get(id,0)))
static func entries(p: Dictionary, category: String="전체") -> Array:
	var result: Array=[]
	for id in CATALOG:
		if CATALOG[id].has("slot") and p.has("gear_instances"): continue
		var count:=quantity(p,id)
		if count<=0 or (category!="전체" and CATALOG[id].category!=category): continue
		result.append({"id":id,"count":count})
	for id in p.get("gear_instances",{}):
		if category in ["전체","장비"]: result.append({"id":id,"count":1})
	for id in p.get("evidence_items",{}):
		if category in ["전체","기록"]: result.append({"id":id,"count":1})
	result.sort_custom(func(a,b): return String(definition(p,a.id).name)<String(definition(p,b.id).name))
	return result
