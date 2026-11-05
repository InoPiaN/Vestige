extends "res://pixel_world.gd"
var person: Dictionary={"alive":true}
func _draw() -> void:
	hero(12,23,person)
