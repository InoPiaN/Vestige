extends RefCounted
const F=preload("res://foraging.gd")
static func draw(canvas: Node,w: Dictionary,p: Dictionary) -> void:
	for id in F.NODES:
		var n: Dictionary=F.NODES[id]
		if p.get("room","village")!=n.room: continue
		var x: float=n.x*16
		var y: float=n.y*16
		var ready: bool=w.time>=float(w.get("forage_ready",{}).get(id,0))
		if not ready:
			canvas.box(x-4,y+3,9,2,"655f49")
			canvas.box(x,y,2,4,"7c8062")
			continue
		match n.item:
			"forest_mushroom":
				for delta in [-3,4]:
					canvas.box(x+delta,y-2,2,6,"c5b28c")
					canvas.box(x+delta-3,y-5,8,4,"ad735e")
					canvas.box(x+delta-1,y-6,4,2,"d09c76")
					canvas.box(x+delta-2,y-4,2,1,"ead1a2")
			"harbor_reed":
				for delta in [-4,0,4]:
					canvas.box(x+delta,y-9+abs(delta),1,13-abs(delta),"a5ac73")
					canvas.box(x+delta-1,y-12+abs(delta),3,5,"c1ab71")
				canvas.box(x-5,y+2,11,2,"7b956b")
			"night_blossom":
				canvas.box(x,y-4,2,8,"77976e")
				canvas.box(x-4,y,5,2,"8caa7c")
				if F.blooming(w.time):
					canvas.box(x-7,y-9,15,12,"a9bbdf24")
					canvas.box(x-4,y-6,9,3,"bdc8e9")
					canvas.box(x-1,y-9,3,9,"d6d8f0")
					canvas.box(x,y-5,2,2,"f1dfad")
				else: canvas.box(x-1,y-6,4,4,"6e827e")
		if F.nearby(p)==id:
			canvas.box(x-7,y+6,15,1,"d8c28a")
