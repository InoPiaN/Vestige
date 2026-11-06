extends RefCounted
# Discrete pixel poses shared by world rendering, portraits and visual QA.
static func direction(v: Vector2) -> String:
	if absf(v.x)>absf(v.y): return "right" if v.x>0 else "left"
	return "down" if v.y>=0 else "up"
static func pose(p: Dictionary) -> Dictionary:
	var facing: String=p.get("direction","left" if p.get("facing",1)<0 else "down")
	var moving: bool=p.get("motion",0.0)>0
	var frame:=int(p.get("steps",0))%4 if moving else 0
	var attack: float=p.get("attack",0.0) if p.get("action","attack")=="attack" else 0.0
	var phase: String="strike" if attack>0.3 else ("recover" if attack>0.0 else "idle")
	return {"direction":facing,"stride":[0,2,0,-2][frame],"bob":-1 if moving and frame%2==1 else 0,"phase":phase,"dodging":p.get("dodge",0.0)>0,"hurt":p.get("hurt",0.0)>0}
