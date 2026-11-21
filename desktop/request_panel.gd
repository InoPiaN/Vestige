extends Panel
signal action(kind: String,value: String)
const R=preload("res://village_requests.gd")
var jobs: ItemList
var details: Label
var accept_button: Button
var deliver_button: Button
var feedback: Label
var current:="herbs"
var world: Dictionary={}
var person: Dictionary={}
func label(text: String,at: Vector2,font_size: int=18) -> Label:
	var node:=Label.new()
	node.text=text
	node.position=at
	node.add_theme_font_size_override("font_size",font_size)
	add_child(node)
	return node
func button(text: String,at: Vector2,width: int,callback: Callable) -> Button:
	var node:=Button.new()
	node.text=text
	node.position=at
	node.size=Vector2(width,40)
	node.pressed.connect(callback)
	add_child(node)
	return node
func _ready() -> void:
	position=Vector2(160,90)
	size=Vector2(960,620)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("172520")
	style.border_color=Color("a28e64")
	style.set_border_width_all(2)
	add_theme_stylebox_override("panel",style)
	label("마을 의뢰 · 게시판과 납품",Vector2(28,24),24)
	button("닫기 · L / ESC",Vector2(755,20),175,hide)
	label("수락은 해당 마을 게시판에서 · 납품은 의뢰인 곁에서 · 진행 상황은 어디서든 L",Vector2(28,80),17)
	jobs=ItemList.new()
	jobs.position=Vector2(28,125)
	jobs.size=Vector2(320,300)
	jobs.add_theme_font_size_override("font_size",18)
	add_child(jobs)
	for id in R.JOBS:
		var index:=jobs.add_item(R.JOBS[id].title)
		jobs.set_item_metadata(index,id)
	jobs.select(0)
	jobs.item_selected.connect(func(index): current=jobs.get_item_metadata(index); feedback.text=""; refresh(world,person))
	details=label("",Vector2(375,125),17)
	details.size=Vector2(555,340)
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	accept_button=button("의뢰 수락",Vector2(375,465),260,func(): action.emit("request_accept",current))
	deliver_button=button("표시된 물품 납품",Vector2(660,465),270,func(): action.emit("request_deliver",current))
	feedback=label("",Vector2(28,525),16)
	feedback.size=Vector2(900,72)
	feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hide()
func refresh(w: Dictionary,p: Dictionary) -> void:
	world=w
	person=p
	if p.is_empty(): return
	for i in range(jobs.item_count):
		var id: String=jobs.get_item_metadata(i)
		jobs.set_item_text(i,R.JOBS[id].title+"\n"+R.status(w,p,id))
	var job: Dictionary=R.JOBS[current]
	var npc:=R.actor(w,current)
	var lines: PackedStringArray=[job.title,job.story,"", "의뢰인 · "+R.REGIONS[job.region]+" / "+job.name+" · "+npc.activity]
	for kind in job.needs:
		lines.append("%s · 소지 %d / 필요 %d" % [R.Items.CATALOG[kind].name,R.Items.family_quantity(p,kind),job.needs[kind]])
	lines.append("품질 · 일반 이상, 낮은 품질부터 납품합니다.")
	var selected:=R.delivery_items(p,current)
	var names: PackedStringArray=[]
	for kind in selected: names.append(R.Items.CATALOG[kind].name+" %d개" % selected[kind])
	lines.append("납품 예정 · "+(", ".join(names) if not names.is_empty() else "소지품 없음"))
	lines.append("보상 · 은화%d (품질에 따른 추가 보상 없음)" % job.reward)
	lines.append("기한 없음 · 완료한 다음 월드 날부터 재수락")
	var accept_reason:=R.accept_reason(w,p,current)
	var deliver_reason:=R.deliver_reason(w,p,current)
	lines.append(deliver_reason if p.requests[current].state=="active" else accept_reason)
	details.text="\n".join(lines)
	accept_button.disabled=not accept_reason.is_empty()
	accept_button.tooltip_text=accept_reason
	deliver_button.disabled=not deliver_reason.is_empty()
	deliver_button.tooltip_text=deliver_reason
