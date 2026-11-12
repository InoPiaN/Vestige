extends SceneTree
class Sample extends "res://pixel_world.gd":
	var person: Dictionary={}
	func _draw() -> void: hero(32,32,person)
var failed:=0
var vp: SubViewport
var sample: Sample
func check(ok: bool,label: String) -> void:
	if ok: print("PASS: ",label)
	else:
		failed+=1
		push_error(label)
func frame(p: Dictionary,time: float=0.0) -> int:
	sample.person=p
	sample.clock=time
	sample.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return hash(vp.get_texture().get_image().get_data())
func _initialize() -> void: call_deferred("run")
func run() -> void:
	vp=SubViewport.new()
	vp.size=Vector2i(128,128)
	vp.transparent_bg=true
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	vp.canvas_transform=Transform2D(0,Vector2(2,2),0,Vector2.ZERO)
	sample=Sample.new()
	vp.add_child(sample)
	sample.set_process(false)
	var p: Dictionary={"alive":true,"equipment":{"body":"cloth","head":"none","cloak":"none","weapon":"iron_sword"},"look":{"hair":0,"hair_color":0,"skin":0,"cloth":0},"equipped_ids":{"weapon":"sword"},"gear_quality":{"sword":{"upgrade":0}}}
	var base:=await frame(p)
	for key in ["hair","hair_color","skin","cloth"]:
		var changed:=p.duplicate(true)
		changed.look[key]=1
		check(await frame(changed)!=base,"Actual pixels change for customization: "+key)
	for slot in ["body","head","cloak"]:
		var changed:=p.duplicate(true)
		changed.equipment[slot]={"body":"leather","head":"hood","cloak":"traveler"}[slot]
		check(await frame(changed)!=base,"Actual pixels change for equipment: "+slot)
	var metal:=p.duplicate(true)
	metal.equipment.body="iron_armor"
	var leather:=p.duplicate(true)
	leather.equipment.body="leather"
	check(await frame(metal)!=await frame(leather),"Iron and leather armor have distinct actual pixels")
	metal.direction="up"
	leather.direction="up"
	check(await frame(metal)!=await frame(leather),"Iron armor back plate differs from leather")
	var hood:=p.duplicate(true)
	hood.equipment.head="hood"
	hood.hide_helmet=true
	check(await frame(hood)==base,"Hidden hood restores exact hair pixels")
	var directions: Array=[]
	for direction in ["down","up","left","right"]:
		var changed:=p.duplicate(true)
		changed.direction=direction
		var result:=await frame(changed)
		check(not directions.has(result),"Distinct actual directional frame: "+direction)
		directions.append(result)
	for state in ["walk","strike","recover","hurt","dodge"]:
		var changed:=p.duplicate(true)
		if state=="walk":
			changed.motion=1.0
			changed.steps=1
		elif state=="strike": changed.attack=0.5
		elif state=="recover": changed.attack=0.2
		elif state=="hurt": changed.hurt=0.2
		else: changed.dodge=0.2
		check(await frame(changed)!=base,"Actual action pixels: "+state)
	var last:=base
	for grade in range(1,4):
		p.gear_quality.sword.upgrade=grade
		var result:=await frame(p)
		check(result!=last,"Each upgrade has distinct visible blade: +"+str(grade))
		last=result
	check(await frame(p,0.0)!=await frame(p,1.0),"High upgrade particles animate locally")
	p.equipment.weapon="none"
	var bare:=await frame(p)
	p.gear_quality.sword.upgrade=0
	check(await frame(p)==bare,"Unequipped sword does not leave enhancement glow")
	p.equipment.weapon="iron_sword"
	p.equipped_ids.weapon="legacy"
	check(await frame(p)==base,"Unknown legacy enhancement defaults to unenhanced rendering")
	var armor:=p.duplicate(true)
	armor.equipment.weapon="none"
	armor.equipped_ids.body="armor"
	armor.gear_instances={"armor":"iron_armor"}
	armor.gear_quality.armor={"upgrade":0}
	armor.equipment.body="iron_armor"
	var plain:=await frame(armor)
	var previous:=plain
	for grade in range(1,4):
		armor.gear_quality.armor.upgrade=grade
		var current:=await frame(armor)
		check(current!=previous,"Armor enhancement distinct pixels: +"+str(grade))
		previous=current
	check(await frame(armor,0.0)!=await frame(armor,0.6),"Armor +3 particles animate")
	for direction in ["left","right","up"]:
		armor.direction=direction
		armor.gear_quality.armor.upgrade=0
		var unenhanced:=await frame(armor)
		armor.gear_quality.armor.upgrade=3
		check(await frame(armor)!=unenhanced,"Armor enhancement follows direction: "+direction)
	armor.equipment.cloak="traveler"
	var covered:=await frame(armor)
	armor.gear_quality.armor.upgrade=0
	check(await frame(armor)==covered,"Back cloak occludes armor highlights")
	armor.direction="down"
	armor.equipment.body="none"
	var unequipped:=await frame(armor)
	armor.gear_quality.armor.upgrade=3
	check(await frame(armor)==unequipped,"Removed armor leaves no glow")
	armor.equipment.body="leather"
	armor.gear_instances.armor="leather"
	var glowing_leather:=await frame(armor)
	armor.gear_quality.armor.upgrade=0
	check(await frame(armor)!=glowing_leather,"Leather armor also displays upgrade")
	p.alive=false
	var dead:=await frame(p)
	var empty:=Image.create(128,128,false,Image.FORMAT_RGBA8)
	check(dead==hash(empty.get_data()),"Dead character renders no sprite or glow")
	quit(1 if failed else 0)
