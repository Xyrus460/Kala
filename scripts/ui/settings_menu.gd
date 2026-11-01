extends Control
signal changed
signal closed
const S=preload("res://scripts/ui/menu_style.gd")
const TABS=["KONTROL","DISPLAY","AUDIO","GAMEPLAY"]
const TITLES={"KONTROL":"KONTROL","DISPLAY":"TAMPILAN","AUDIO":"AUDIO","GAMEPLAY":"PERMAINAN"}
const SPECS={
	"KONTROL":[["sensitivity","SENSITIVITAS MOUSE",[0.5,0.75,1.0,1.25,1.5,1.8],["0.50","0.75","1.00","1.25","1.50","1.80"],"Kecepatan pandangan saat menggerakkan mouse."],["head_bob","GERAK KAMERA",[false,true],["OFF","ON"],"Gerakan ringan kamera ketika berjalan. Matikan untuk pandangan yang stabil."]],
	"DISPLAY":[["fullscreen","MODE LAYAR",[false,true],["WINDOWED","FULLSCREEN"],"Pilih tampilan berjendela atau layar penuh."],["vsync","V-SYNC",[false,true],["OFF","ON"],"Sinkronkan gambar dengan refresh rate monitor untuk mengurangi screen tearing."],["fps_limit","BATAS FRAME RATE",[30,60,90,120,144,0],["30 FPS","60 FPS","90 FPS","120 FPS","144 FPS","UNLIMITED"],"Batas kecepatan render. V-Sync dapat membatasi frame rate sesuai monitor."],["fov","FIELD OF VIEW",[65.0,70.0,75.0,80.0,85.0,90.0],["65°","70°","75°","80°","85°","90°"],"Lebar sudut pandang kamera pemain."],["quality","PRESET KUALITAS",[0,1,2],["LOW","HIGH","CINEMATIC"],"Mengatur resolusi render, anti-aliasing, bayangan, ambient occlusion, pencahayaan tidak langsung dan bloom sekaligus."],["render_scale","RESOLUSI RENDER",[0.5,0.67,0.75,1.0],["50%","67%","75%","100%"],"Resolusi gambar 3D. Antarmuka tetap tajam pada resolusi layar."],["msaa","ANTI-ALIASING",[0,1,2,3],["OFF","MSAA 2×","MSAA 4×","MSAA 8×"],"Menghaluskan tepi objek. Nilai lebih tinggi membutuhkan lebih banyak daya GPU."],["shadows","BAYANGAN SENTER",[false,true],["OFF","ON"],"Bayangan dinamis dari senter pemain."],["ssao","AMBIENT OCCLUSION",[false,true],["OFF","ON"],"Bayangan kontak lembut di sudut dan pertemuan objek."],["ssil","INDIRECT LIGHTING",[false,true],["OFF","ON"],"Pantulan cahaya layar untuk kedalaman pencahayaan ruangan."],["bloom","BLOOM",[false,true],["OFF","ON"],"Cahaya lembut di sekitar sumber yang terang."]],
	"AUDIO":[["volume","VOLUME UTAMA",[0.0,0.25,0.5,0.75,1.0],["0%","25%","50%","75%","100%"],"Volume keseluruhan suara permainan."],["music","VOLUME MUSIK",[0.0,0.25,0.45,0.75,1.0],["0%","25%","45%","75%","100%"],"Volume musik latar."]],
	"GAMEPLAY":[["scares","JUMPSCARE",[false,true],["OFF","ON"],"Tampilkan animasi jumpscare saat tertangkap. Kondisi kalah tetap berlaku."]]
}
var canvas: Control
var rows: VBoxContainer
var heading: Label
var detail_title: Label
var detail: Label
var category="DISPLAY"
var tab_buttons: Array[Button]=[]

func label(text: String,p: Vector2,sz: Vector2,font_size=18,color=Color("d4d2d0")) -> Label:
	var l=Label.new();l.text=text;l.position=p;l.size=sz;l.add_theme_font_size_override("font_size",font_size);l.add_theme_color_override("font_color",color);canvas.add_child(l);return l

func style(active=false) -> StyleBoxFlat:
	return S.box(active)

func build(initial="DISPLAY") -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme=S.menu_theme();S.backdrop(self,0.78)
	canvas=Control.new();canvas.size=Vector2(1280,720);add_child(canvas);resized.connect(_resize);_resize()
	heading=label("PENGATURAN",Vector2(38,36),Vector2(350,48),34,S.WHITE);S.ink(heading)
	S.rule(canvas,Rect2(39,86,238,2))
	for i in range(TABS.size()):
		var b=Button.new();b.icon=load("res://assets/ui/settings_"+str([0,1,3,4][i])+".svg");b.icon_alignment=HORIZONTAL_ALIGNMENT_CENTER;b.tooltip_text=TITLES[TABS[i]];b.position=Vector2(476+i*106,32);b.size=Vector2(62,52)
		b.add_theme_stylebox_override("normal",style());b.add_theme_stylebox_override("hover",style(true));b.add_theme_stylebox_override("focus",style(true));canvas.add_child(b);tab_buttons.append(b)
		b.pressed.connect(func():show_category(TABS[i]))
		var caption=label(TITLES[TABS[i]],Vector2(450+i*106,91),Vector2(114,22),11,S.MUTED);caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	label("Q",Vector2(425,46),Vector2(20,25),14);label("E",Vector2(876,46),Vector2(20,25),14)
	var scroll=ScrollContainer.new();scroll.position=Vector2(42,142);scroll.size=Vector2(570,470);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;canvas.add_child(scroll)
	rows=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",12);scroll.add_child(rows)
	detail_title=label("",Vector2(660,145),Vector2(560,36),24,S.WHITE);S.ink(detail_title)
	detail=label("",Vector2(660,196),Vector2(520,220),18);detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label("KALA  /  PENGATURAN",Vector2(42,655),Vector2(400,28),12,Color("79777c"))
	for spec in [["R   RESET DEFAULT",Vector2(875,652),true],["ESC   KEMBALI",Vector2(1080,652),false]]:
		var b=Button.new();b.text=spec[0];b.position=spec[1];b.size=Vector2(180,40);b.add_theme_stylebox_override("normal",StyleBoxEmpty.new());b.add_theme_font_size_override("font_size",15);canvas.add_child(b)
		if spec[2]:b.pressed.connect(reset_defaults)
		else:b.pressed.connect(func():closed.emit())
	S.grain(self)
	show_category(initial)

func _resize() -> void:
	if canvas==null:return
	var s=minf(size.x/1280.0,size.y/720.0);canvas.scale=Vector2.ONE*s;canvas.position=(size-Vector2(1280,720)*s)/2

func show_category(value: String) -> void:
	category=value if value in TABS else "DISPLAY"
	for i in range(tab_buttons.size()):tab_buttons[i].add_theme_stylebox_override("normal",style(TABS[i]==category))
	for c in rows.get_children():rows.remove_child(c);c.queue_free()
	for spec in SPECS[category]:add_row(spec)
	if category=="KONTROL":
		var l=Label.new();l.text="WASD    Bergerak     SHIFT    Lari\nCTRL    Jongkok       E    Interaksi\nF    Senter       R    Penjepit       Q    Pulse\nJ    Jurnal       ESC    Jeda / kembali";l.add_theme_font_size_override("font_size",16);rows.add_child(l)
	focus_spec(SPECS[category][0])

func focus_spec(spec: Array) -> void:
	detail_title.text=spec[1];detail.text=spec[4]
	if spec[0] in ["ssao","ssil","bloom"] and RenderingServer.get_current_rendering_method()!="forward_plus":detail.text+="\n\nEfek ini tersedia pada renderer utama (Forward+)."

func add_row(spec: Array) -> void:
	var row=PanelContainer.new();row.custom_minimum_size=Vector2(548,46);row.add_theme_stylebox_override("panel",style());rows.add_child(row)
	var h=HBoxContainer.new();row.add_child(h)
	var name_label=Label.new();name_label.text=spec[1];name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;name_label.add_theme_font_size_override("font_size",14);h.add_child(name_label)
	var text_value=Label.new();text_value.custom_minimum_size.x=145;text_value.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;text_value.add_theme_font_size_override("font_size",14)
	for step in [-1,1]:
		var b=Button.new();b.text="◀" if step<0 else "▶";b.custom_minimum_size.x=34;b.add_theme_stylebox_override("normal",StyleBoxEmpty.new());h.add_child(b)
		if step<0:h.add_child(text_value)
		b.pressed.connect(func():cycle(spec,step,text_value))
		b.focus_entered.connect(func():focus_spec(spec));b.mouse_entered.connect(func():focus_spec(spec))
		b.disabled=spec[0] in ["ssao","ssil","bloom"] and RenderingServer.get_current_rendering_method()!="forward_plus"
	row.mouse_entered.connect(func():focus_spec(spec))
	refresh_value(spec,text_value)

func refresh_value(spec: Array,l: Label) -> void:
	var i=spec[2].find(State.settings[spec[0]]);l.text=spec[3][i] if i>=0 else str(State.settings[spec[0]])

func cycle(spec: Array,step: int,l: Label) -> void:
	var i=spec[2].find(State.settings[spec[0]]);i=posmod(maxi(0,i)+step,spec[2].size());State.settings[spec[0]]=spec[2][i]
	if spec[0]=="quality":
		State.apply_quality_preset(i)
	State.save_settings();changed.emit();refresh_value(spec,l);focus_spec(spec)
	if spec[0]=="quality":show_category(category)

func reset_defaults() -> void:
	State.settings=State.DEFAULT_SETTINGS.duplicate();State.save_settings();changed.emit();show_category(category)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():return
	if event.keycode in [KEY_Q,KEY_E]:show_category(TABS[posmod(TABS.find(category)+(-1 if event.keycode==KEY_Q else 1),TABS.size())]);get_viewport().set_input_as_handled()
	if event.keycode==KEY_R:reset_defaults();get_viewport().set_input_as_handled()
