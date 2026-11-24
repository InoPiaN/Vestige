extends RefCounted
# One world day remains 48 real minutes. Existing worlds start at morning (08:00).
const DAY=2880.0
const OFFSET=8.0
const NAMES={"soha":"소하","doyun":"도윤"}
# hour, position, activity; moving segments interpolate along safe outdoor paths.
const ROUTES={
	"soha":[[0,9,6,"수면"],[6,9,6,"아침 휴식"],[7,9,6,"출근 중"],[7.5,12,10,"출근 중"],[8,18,10,"영업 중"],[18,18,10,"귀가 중"],[18.5,12,10,"귀가 중"],[19,9,6,"저녁 휴식"],[22,9,6,"수면"],[24,9,6,"수면"]],
	"doyun":[[0,11,6,"수면"],[6,11,6,"출근 중"],[7,12,9,"나루 업무"],[12,12,9,"부두로 이동"],[13,22,14,"부두 순찰"],[16,22,14,"나루로 이동"],[17,12,9,"나루 업무"],[20,12,9,"귀가 중"],[21,11,6,"수면"],[24,11,6,"수면"]]
}
static func hour(time: float) -> float:
	return fposmod(time/DAY*24.0+OFFSET,24.0)
static func phase(time: float) -> String:
	var h:=hour(time)
	if h<5 or h>=20: return "밤"
	if h<8: return "새벽"
	if h<17: return "낮"
	return "노을"
static func state(id: String,time: float) -> Dictionary:
	var h:=hour(time)
	var route: Array=ROUTES[id]
	for i in range(route.size()-1):
		var a: Array=route[i]
		var b: Array=route[i+1]
		if h>=a[0] and h<b[0]:
			var at:=Vector2(a[1],a[2]).lerp(Vector2(b[1],b[2]),(h-a[0])/(b[0]-a[0]))
			var velocity:=Vector2(b[1]-a[1],b[2]-a[2])
			return {"id":id,"name":NAMES[id],"x":at.x,"y":at.y,"room":"harbor","activity":a[3],"moving":velocity.length()>0,"direction":"right" if velocity.x>0 else ("left" if velocity.x<0 else "down"),"awake":a[3]!="수면","open":id=="soha" and h>=8 and h<18}
	return {}
static func shop_open(time: float) -> bool:
	return hour(time)>=8 and hour(time)<18
static func record(w: Dictionary,previous: float) -> void:
	if not w.has("npc_activity"): w.npc_activity=[]
	# Keep a bounded recent history even after years offline; do not invent observations.
	var first:=maxf(previous,float(w.time)-DAY*2)
	var events: Array=[]
	for day in range(int(floor(first/DAY))-1,int(floor(float(w.time)/DAY))+2):
		for id in ROUTES:
			for row in ROUTES[id]:
				if row[0]==24 or row[0]==0: continue
				var at: float=(day+(float(row[0])-OFFSET)/24.0)*DAY
				if at>first and at<=float(w.time):
					events.append({"npc":id,"time":at,"room":"harbor","x":float(row[1]),"y":float(row[2]),"activity":row[3]})
	events.sort_custom(func(a,b): return a.time<b.time)
	w.npc_activity.append_array(events)
	while w.npc_activity.size()>96: w.npc_activity.pop_front()
static func valid(w: Dictionary) -> bool:
	if not w.has("npc_activity"): return true # Additive migration of schema 21.
	if not w.npc_activity is Array or w.npc_activity.size()>96: return false
	var last: float=-1
	for row in w.npc_activity:
		if not row is Dictionary or row.get("npc") not in NAMES or row.get("room")!="harbor" or not row.get("activity") is String: return false
		for key in ["time","x","y"]:
			var n=row.get(key)
			if not (n is int or n is float) or not is_finite(float(n)): return false
		if row.time<last or row.time<0 or row.time>w.time or row.x<1 or row.x>29 or row.y<1 or row.y>18: return false
		last=row.time
	return true
