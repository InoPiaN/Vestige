extends RefCounted
# Existing resource counters remain the single source of truth for old saves.
const CATALOG := {
	"ore":{"name":"철광석","category":"재료","field":"ore","limit":20,"color":"92a6a1","description":"철검 제작 재료. 대장간에서 2개를 소비합니다."},
	"herb":{"name":"달빛 약초","category":"소모품","field":"herb","limit":20,"color":"8ab88e","description":"1개를 사용해 체력 30을 회복합니다."},
	"iron_sword":{"name":"철검","category":"장비","field":"sword","limit":5,"slot":"weapon","color":"c4d4d0","description":"착용 시 공격력 22.\n맨손 공격력은 9입니다.\n보유한 검 중 1개를 착용합니다."},
	"leather":{"name":"가죽 갑옷","category":"장비","limit":1,"slot":"body","color":"ae8257","description":"여행자를 위한 시작 방어구.\n현재는 외형 장비이며 방어력은 없습니다."},
	"hood":{"name":"여행 후드","category":"장비","limit":1,"slot":"head","color":"749995","description":"머리를 덮는 시작 장비.\n투구 숨김 설정은 외형 · 장비에서 변경합니다."},
	"traveler":{"name":"여행 망토","category":"장비","limit":1,"slot":"cloak","color":"648c9e","description":"어깨에서 내려오는 시작 망토.\n착용하면 인물의 실루엣이 바뀝니다."},
	"relic":{"name":"이렌의 유물","category":"기록","field":"relic","limit":1,"color":"d1b777","description":"예배당에서 발견한 유물.\n서재에서 이렌의 기록을 읽을 수 있습니다."}
}
static func quantity(p: Dictionary, id: String) -> int:
	if not CATALOG.has(id): return 0
	var item: Dictionary=CATALOG[id]
	if item.has("field"): return maxi(0,int(p.get(item.field,0)))
	return maxi(0,int(p.get("belongings",{}).get(id,0)))
static func entries(p: Dictionary, category: String="전체") -> Array:
	var result: Array=[]
	for id in CATALOG:
		var count:=quantity(p,id)
		if count<=0 or (category!="전체" and CATALOG[id].category!=category): continue
		result.append({"id":id,"count":count})
	result.sort_custom(func(a,b): return String(CATALOG[a.id].name)<String(CATALOG[b.id].name))
	return result
