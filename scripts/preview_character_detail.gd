extends SceneTree
# Review-only drawing; does not replace the in-game renderer or touch saves.
class DetailedHero extends Node2D:
	var grade:=0
	var leather:=false
	func r(x: int,y: int,w: int,h: int,c: String) -> void:
		draw_rect(Rect2(x,y,w,h),Color(c))
	func _draw() -> void:
		# 2x sampling density within the original character footprint.
		r(3,46,25,3,"111d19")
		# Split cloak, stepped hem and folds.
		r(5,22,20,21,"17272c")
		r(3,25,4,18,"263c42")
		r(5,23,3,19,"4c666c")
		r(6,25,1,15,"78908c")
		r(22,26,4,16,"304b51")
		r(24,29,2,12,"577277")
		r(9,39,4,4,"182c31")
		r(19,38,4,6,"20343b")
		# Boots with toe planes and separate trouser legs.
		r(9,36,5,11,"1c2426")
		r(18,36,5,11,"182123")
		r(10,36,3,6,"444a45")
		r(19,36,3,6,"353e3a")
		r(8,43,6,5,"292e2d")
		r(18,43,7,5,"282c2b")
		r(8,46,5,1,"797061")
		r(19,46,5,1,"625e52")
		r(9,43,4,1,"9b8060")
		r(19,43,3,1,"86694d")
		# Tunic silhouette and three-value fabric folds.
		r(8,21,15,17,"252b2b")
		r(9,22,12,14,"91604d")
		r(10,24,3,9,"b27b5f")
		r(14,23,5,12,"a36c52")
		r(19,25,2,10,"704c40")
		r(13,29,1,6,"69473c")
		r(16,32,3,2,"c18a67")
		r(9,35,5,3,"7d5544")
		r(16,35,5,3,"9b6b50")
		r(14,35,2,4,"302b29")
		# Collar, neck and diagonal shoulder strap.
		r(13,19,6,5,"76513d")
		r(14,19,4,3,"d3a576")
		r(12,22,2,3,"c9b78b")
		r(18,22,2,3,"d6c59b")
		r(12,25,2,3,"b69c72")
		r(14,27,2,3,"b69c72")
		r(16,30,2,3,"b69c72")
		if leather:
			r(10,25,11,9,"46372c")
			r(11,25,9,2,"98754c")
			r(11,28,4,5,"795538")
			r(16,28,4,5,"63472f")
			r(15,27,1,7,"c3a777")
			r(11,28,1,1,"dec48a")
			r(19,28,1,1,"c5a46c")
		# Rounded pauldron as a few clean pixel clusters.
		r(5,22,8,6,"26373b")
		r(6,21,6,2,"9caeaa")
		r(5,23,8,2,"6f8889")
		r(6,22,5,1,"d5d7bf")
		r(6,25,6,2,"435d65")
		r(7,27,4,1,"a3a999")
		# Arms, cuff, fingers and belt hardware.
		r(5,28,4,9,"3a4b4d")
		r(6,29,2,5,"647879")
		r(5,34,4,2,"a58c64")
		r(5,36,4,4,"a47654")
		r(6,36,2,3,"d9ad7d")
		r(21,25,4,10,"78513f")
		r(22,26,2,7,"ae7858")
		r(21,33,4,2,"d0b17a")
		r(22,35,3,4,"d4a574")
		r(24,36,1,2,"886049")
		r(9,33,12,3,"3d3029")
		r(10,33,10,1,"8e704d")
		r(14,33,4,3,"d5b16a")
		r(15,34,2,1,"65503a")
		r(19,35,3,4,"614331")
		r(19,35,3,1,"a47f50")
		# Face: shadow outline, cheek plane, brow, eye and nose.
		r(10,7,12,13,"252827")
		r(11,10,10,9,"a67754")
		r(12,11,8,7,"d9aa7a")
		r(13,12,5,3,"e4bb8a")
		r(11,14,1,3,"b98b61")
		r(20,12,2,4,"bc8b60")
		r(13,13,2,1,"654c3a")
		r(18,13,2,1,"654c3a")
		r(14,14,1,1,"222c2b")
		r(19,14,1,1,"222c2b")
		r(17,15,1,2,"b68258")
		r(18,15,1,1,"f0cda0")
		r(15,18,4,1,"79553f")
		r(14,19,5,1,"bc9067")
		# Swept hair, silhouette steps, restrained highlights.
		r(10,5,11,4,"312d27")
		r(8,8,14,4,"493b2d")
		r(9,6,11,4,"685135")
		r(12,4,7,2,"59472f")
		r(11,6,8,2,"927348")
		r(12,6,5,1,"b09460")
		r(9,9,4,3,"826442")
		r(13,9,6,2,"725637")
		r(10,11,2,5,"4b3b2c")
		r(11,11,1,3,"98734b")
		r(20,10,2,3,"3c3329")
		# Blade: dark silhouette, cold flat, ridge and bright edge.
		if grade>0:
			var glow: String=["000000","778b8190","658faaa0","80bac9b0"][grade]
			r(27,12,4,22,glow)
			if grade>=2:
				r(26,19,1,2,"a3d4dc")
				r(32,25,1,1,"c4e8e6")
			if grade==3:
				r(31,14,1,2,"bce8ec")
				r(25,28,1,1,"91cddc")
		r(28,12,2,22,"263a41")
		r(29,10,1,2,"c4d6ce")
		r(28,14,1,19,"dce2c9" if grade==0 else "d9f1e7")
		r(29,12,1,21,"728e98" if grade<2 else "8ac2d2")
		r(27,33,5,2,"41382a")
		r(26,32,7,1,"c3a366")
		r(27,33,5,1,"88704c")
		r(28,35,2,4,"503d31")
		r(28,36,2,1,"947251")
		r(28,39,2,2,"bea16c")
		r(25,35,4,3,"bb8b61")
		r(25,35,3,1,"e2b783")
		r(28,36,1,1,"78543e")

func _initialize() -> void: call_deferred("render")
func label(parent: Node,text: String,at: Vector2,size: int,color: String="c8cbbd") -> void:
	var l:=Label.new()
	l.text=text
	l.position=at
	l.add_theme_font_size_override("font_size",size)
	l.add_theme_color_override("font_color",Color(color))
	parent.add_child(l)
func render() -> void:
	var vp:=SubViewport.new()
	vp.size=Vector2i(1280,780)
	vp.render_target_update_mode=SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var bg:=ColorRect.new()
	bg.color=Color("101b19")
	bg.size=Vector2(1280,780)
	vp.add_child(bg)
	label(vp,"VESTIGE  /  캐릭터·장비 디테일 시안",Vector2(40,24),28,"dac791")
	label(vp,"같은 화면 크기 · 캐릭터와 장비만 2배 픽셀 밀도 · 맵은 유지",Vector2(40,68),19)
	var titles: Array=["현재", "새 시안 · 기본", "새 시안 · 가죽 갑옷", "새 시안 · 강화 +3"]
	for i in range(4):
		var at:=Vector2(40+i*310,115)
		var card:=ColorRect.new()
		card.position=at
		card.size=Vector2(292,465)
		card.color=Color("1c2c28")
		vp.add_child(card)
		label(vp,titles[i],at+Vector2(16,14),19,"ddcda6")
		# Same display footprint: old texel 6px, new texel 3px.
		var scene:=SubViewport.new()
		scene.size=Vector2i(64,64) if i==0 else Vector2i(128,128)
		scene.transparent_bg=true
		scene.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		vp.add_child(scene)
		if i==0:
			var old:=preload("res://portrait.gd").new()
			old.position=Vector2(2,8)
			old.person={"alive":true,"equipment":{"weapon":"iron_sword","cloak":"traveler","body":"cloth","head":"none"},"look":{"hair":0,"hair_color":0,"skin":0,"cloth":0}}
			scene.add_child(old)
		else:
			var detail:=DetailedHero.new()
			detail.position=Vector2(12,30)
			detail.grade=3 if i==3 else 0
			detail.leather=i>=2
			scene.add_child(detail)
		var tex:=TextureRect.new()
		tex.texture=scene.get_texture()
		tex.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		tex.position=at+Vector2(23,75)
		tex.size=Vector2(384,384)
		vp.add_child(tex)
		label(vp,["기존 큰 픽셀 덩어리","머리 결 · 눈매 · 옷 주름","어깨 금속 · 가죽 이음새","칼날빛 · 작은 빛 입자"][i],at+Vector2(16,402),17)
		label(vp,"정면 대기 자세 / 확대 비교",at+Vector2(16,430),15,"8da49a")
	label(vp,"디테일 기준",Vector2(40,610),22,"dac791")
	label(vp,"칼날의 면과 날, 손잡이 감개 · 벨트 버클과 가죽 매듭 · 머리와 얼굴의 명암",Vector2(40,650),20)
	label(vp,"검토용 정지 시안입니다. 승인 후 4방향·걷기·공격·커스터마이징에 확장합니다.",Vector2(40,697),18,"91a79f")
	await process_frame
	await RenderingServer.frame_post_draw
	vp.get_texture().get_image().save_png("/tmp/vestige-character-detail-preview.png")
	quit()
