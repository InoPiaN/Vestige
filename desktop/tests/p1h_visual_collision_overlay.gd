extends Node2D
## QA-only overlay for real village drawing versus runtime movement collision.
## The overlay is created only by the P1-H capture test; never shipped in gameplay.
const World=preload("res://world.gd")
const Clues=preload("res://story/chapter1_investigation.gd")
const Dialogue=preload("res://story/chapter1_dialogue.gd")
var spawn: Vector2=Vector2(9,9)
var show_overlay: bool=true

func _draw() -> void:
	if not show_overlay: return
	for place in World.PLACES:
		if not place.kind in ["forge","library","inn","home"]: continue
		var foot: Rect2=Rect2(Vector2(float(place.x)-1.0,float(place.y)-1.5)*16.0,Vector2(2.0,1.9)*16.0)
		draw_rect(foot,Color(1.0,0.14,0.18,0.22),true)
		draw_rect(foot,Color(1.0,0.2,0.22,0.95),false,1.0)
		draw_circle(Vector2(float(place.x),float(place.y))*16.0,2.5,Color(1,0.3,0.3))
	var center: Vector2=spawn*16.0
	draw_line(center+Vector2(-8,0),center+Vector2(8,0),Color(0,1,1),1.5)
	draw_line(center+Vector2(0,-8),center+Vector2(0,8),Color(0,1,1),1.5)
	draw_arc(center,9,0,TAU,32,Color(0,1,1),1.0)
	for evidence in Clues.EVIDENCE:
		var item: Dictionary=Clues.EVIDENCE[evidence]
		draw_arc(Vector2(float(item.x),float(item.y))*16.0,Clues.RADIUS*16.0,0,TAU,24,Color(1,0.83,0.14,0.7),1.0)
	for npc_id in Dialogue.NPCS:
		var npc: Dictionary=Dialogue.NPCS[npc_id]
		draw_arc(Vector2(float(npc.x),float(npc.y))*16.0,Dialogue.RADIUS*16.0,0,TAU,24,Color(0.35,0.75,1.0,0.8),1.0)
