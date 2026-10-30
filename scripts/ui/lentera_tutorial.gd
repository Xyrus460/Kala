extends PanelContainer
signal continued
var video: VideoStreamPlayer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	anchor_left = 0.07; anchor_right = 0.93; anchor_top = 0.025; anchor_bottom = 0.975
	var frame = StyleBoxFlat.new()
	frame.bg_color = Color("080909"); frame.border_color = Color("59584e"); frame.set_border_width_all(1)
	add_theme_stylebox_override("panel", frame)
	var stack = VBoxContainer.new(); stack.add_theme_constant_override("separation", 0); add_child(stack)
	var header = HBoxContainer.new(); header.custom_minimum_size.y = 62
	var header_margin = margin(header, 28, 0); stack.add_child(header_margin)
	var title = label("L E N T E R A - G", 20); title.size_flags_horizontal = Control.SIZE_EXPAND_FILL; header.add_child(title)
	var index = label("P A N D U A N   A L A T", 9); index.modulate.a = 0.55; header.add_child(index)
	var picture = AspectRatioContainer.new(); picture.ratio = 16.0 / 9.0
	picture.size_flags_vertical = Control.SIZE_EXPAND_FILL; picture.stretch_mode = AspectRatioContainer.STRETCH_FIT
	stack.add_child(picture)
	video = VideoStreamPlayer.new(); video.name = "TutorialVideo"
	video.stream = load("res://assets/video/lentera_tutorial.ogv"); video.expand = true
	video.autoplay = true; video.loop = true; video.volume = 0; video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.add_child(video)
	var footer = VBoxContainer.new(); footer.add_theme_constant_override("separation", 18)
	stack.add_child(margin(footer, 28, 22))
	footer.add_child(label("Cahaya mengungkap tanda inspeksi dan melemahkan tatapan Pengawas. Tangan-Tangan melawan sorotan lama.", 12))
	var controls = HBoxContainer.new(); controls.add_theme_constant_override("separation", 24); footer.add_child(controls)
	controls.add_child(label("[ R ]  Julurkan / tarik penjepit", 13))
	controls.add_child(label("[ F ]  Lampu", 13))
	controls.add_child(label("[ Q ]  Pulse • jeda 6 d • memakai panas", 12))
	var spacer = Control.new(); spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL; controls.add_child(spacer)
	var next = Button.new(); next.text = "E  LANJUTKAN"; next.flat = true
	next.add_theme_font_size_override("font_size", 12); next.pressed.connect(func(): continued.emit()); controls.add_child(next)
	video.play()

func label(value: String, font_size: int) -> Label:
	var result = Label.new(); result.text = value; result.add_theme_font_size_override("font_size", font_size)
	result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER; result.modulate = Color("d3d0c3"); return result

func margin(child: Control, horizontal: int, vertical: int) -> MarginContainer:
	var result = MarginContainer.new()
	for side in ["left", "right"]: result.add_theme_constant_override("margin_" + side, horizontal)
	for side in ["top", "bottom"]: result.add_theme_constant_override("margin_" + side, vertical)
	result.add_child(child); return result

func stop() -> void:
	if is_instance_valid(video): video.stop()
