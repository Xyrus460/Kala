extends Control
signal action_requested(action: String,value: String)
var book: Control
var pages: Control
var cover: Panel
var binding: Panel
var cover_title: Label
var animation: Tween
var opened=false
var closing=false
var opening=0.0

func _panel(parent: Control,rect: Rect2,color: Color) -> Panel:
	var p=Panel.new();p.position=rect.position;p.size=rect.size;var s=StyleBoxFlat.new();s.bg_color=color;s.set_corner_radius_all(3);s.shadow_color=Color(0,0,0,0.35);s.shadow_size=12;p.add_theme_stylebox_override("panel",s);parent.add_child(p);return p

func _label(parent: Control,text: String,point: Vector2,font_size=20) -> Label:
	var l=Label.new();l.text=text;l.position=point;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",Color("3c3932"));parent.add_child(l);return l

func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	book=Control.new();book.size=Vector2(960,570);book.pivot_offset=Vector2(480,285);add_child(book)
	binding=_panel(book,Rect2(-12,-12,984,594),Color("383e39"))
	pages=Control.new();book.add_child(pages)
	_panel(pages,Rect2(0,0,477,570),Color("cfc8b3"));_panel(pages,Rect2(483,0,477,570),Color("dfd7c1"))
	for x in [474,478,482]:_panel(pages,Rect2(x,8,2,554),Color("aba38d"))
	_label(pages,"KALA",Vector2(38,36),15)
	_label(pages,"Catatan penyelidikan",Vector2(38,75),31)
	pages.get_child(pages.get_child_count()-1).add_theme_font_override("font",preload("res://assets/fonts/Caveat.ttf"))
	_label(pages,"BUKTI  %d / 4     ·     SANITY  %d"%[State.data.evidence.size(),int(State.data.sanity)],Vector2(38,138),16)
	var ev={"op1":"Foto Danu dan Raka","op2":"Agenda Sari","A":"Surat Raka","B":"Album dan perjanjian"}
	var index=0
	for key in ev:
		_label(pages,("●  " if State.data.evidence.has(key) else "○  ")+ev[key],Vector2(38,180+index*37),19);index+=1
	var inventory_scroll = ScrollContainer.new()
	inventory_scroll.position = Vector2(38, 343)
	inventory_scroll.size = Vector2(392, 160)
	inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	pages.add_child(inventory_scroll)
	var inventory = Label.new()
	inventory.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory.add_theme_font_size_override("font_size", 16)
	inventory.add_theme_color_override("font_color", Color("3c3932"))
	inventory.text = "BARANG\n%s\n\nTERPASANG\n%s" % [item_names(State.data.items), item_names(State.data.installed)]
	inventory_scroll.add_child(inventory)
	_label(pages,"CATATAN TERSIMPAN",Vector2(520,40),16)
	var scroll=ScrollContainer.new();scroll.position=Vector2(515,86);scroll.size=Vector2(410,408);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;pages.add_child(scroll)
	var list=VBoxContainer.new();list.size_flags_horizontal=Control.SIZE_EXPAND_FILL;list.add_theme_constant_override("separation",8);scroll.add_child(list)
	if State.data.notes.is_empty():
		var empty=Label.new();empty.text="Catatan yang kamu temukan\nakan disimpan di sini.";empty.add_theme_color_override("font_color",Color("655f52"));list.add_child(empty)
	for key in State.data.notes:_button(list,str(State.data.notes[key].title),"journal_note",key)
	if State.data.evidence.has("op1"):_button(list,"Periksa kembali foto","photo","")
	if State.flag("lenteraOwned"):_button(list,"Panduan Lentera-G","tutorial","")
	_label(pages,"01",Vector2(43,529),14);_label(pages,"02",Vector2(892,529),14)
	var close=Button.new();close.text="J / ESC   TUTUP JURNAL";close.position=Vector2(665,518);close.size=Vector2(245,35);close.add_theme_stylebox_override("normal",StyleBoxEmpty.new());close.add_theme_color_override("font_color",Color("514c42"));close.add_theme_font_size_override("font_size",14);pages.add_child(close);close.pressed.connect(func():action_requested.emit("close",""))
	cover=_panel(book,Rect2(480,-5,487,580),Color("354339"));cover.pivot_offset=Vector2.ZERO
	cover_title=_label(cover,"KALA\n\nCATATAN\nPENYELIDIKAN",Vector2(62,150),29);cover_title.add_theme_color_override("font_color",Color("c5b580"))
	resized.connect(_resize);_apply_open(0.0)
	animation=create_tween()
	animation.tween_method(_apply_open,0.0,1.0,0.82).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	animation.finished.connect(func():opened=true)

func _button(parent: Control,text: String,action: String,value: String) -> void:
	var b=Button.new();b.text=text;b.alignment=HORIZONTAL_ALIGNMENT_LEFT;b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;b.custom_minimum_size.y=42;b.add_theme_stylebox_override("normal",StyleBoxEmpty.new());b.add_theme_color_override("font_color",Color("3c3932"));b.add_theme_font_size_override("font_size",17);parent.add_child(b);b.pressed.connect(func():
		if opened and not closing:action_requested.emit(action,value))

func _resize() -> void:
	if book==null:return
	_apply_open(opening)

func _apply_open(amount: float) -> void:
	opening=amount
	var ease=smoothstep(0.0,1.0,amount)
	var s=minf(size.x/1100,size.y/700)*(0.93+ease*0.07)
	book.scale=Vector2.ONE*s
	book.position=(size-book.size)*0.5+Vector2(0,(1.0-ease)*66.0)
	book.rotation=(1.0-ease)*0.035
	book.modulate.a=smoothstep(0.0,0.26,amount)
	binding.modulate.a=smoothstep(0.10,0.72,amount)
	pages.modulate.a=smoothstep(0.18,0.78,amount)
	# Project a hinge turn; hide the printing on the reverse of the cover.
	cover.scale.x=cos(amount*PI)
	cover.modulate.a=1.0-smoothstep(0.78,1.0,amount)
	cover.visible=amount<0.999
	cover_title.visible=amount<0.36

func item_names(items: Dictionary) -> String:
	if items.is_empty():
		return "—"
	var names: PackedStringArray = []
	for id in items:
		var label = KalaLevel.ITEMS.find_key(id)
		names.append(str(label) if label != null else str(id).replace("fragment_", "Potongan ").capitalize())
	return ", ".join(names)

func _exit_tree() -> void:
	if animation!=null:animation.kill()

func close_book() -> void:
	if closing:return
	closing=true
	opened=false
	if animation!=null:animation.kill()
	animation=create_tween()
	animation.tween_method(_apply_open,opening,0.0,maxf(0.12,0.48*opening)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await animation.finished
