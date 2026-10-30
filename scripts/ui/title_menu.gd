extends Control

func build(hud: CanvasLayer) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade = TextureRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.006, 0.016, 0.014, 0.98))
	gradient.set_color(1, Color(0.005, 0.012, 0.012, 0))
	gradient.add_point(0.40, Color(0.005, 0.014, 0.012, 0.92))
	gradient.add_point(0.70, Color(0.005, 0.014, 0.012, 0.18))
	var texture = GradientTexture2D.new(); texture.gradient = gradient; texture.width = 1280; texture.height = 4
	texture.fill_from = Vector2.ZERO; texture.fill_to = Vector2.RIGHT
	shade.texture = texture; shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(shade)
	var margin = MarginContainer.new()
	margin.anchor_right = 0.51; margin.anchor_bottom = 1
	margin.offset_left = 80; margin.offset_top = 58; margin.offset_right = -30; margin.offset_bottom = -28
	add_child(margin)
	var column = VBoxContainer.new(); column.add_theme_constant_override("separation", 8); margin.add_child(column)
	_label(column, "C H A P T E R   0 1   /   J A L A N   K A R T I N I", 11, Color("c1b68f"))
	var title = _label(column, "KALA", 100, Color("c9c1a3"))
	title.add_theme_font_override("font", preload("res://assets/fonts/embedded_000.ttf"))
	_label(column, "Setiap cerita menyimpan seseorang yang disalahkan.", 14, Color("c6b688"))
	var body = _label(column, "Pagi bermula di rumah. Satu kejadian di kelas membawamu menyusuri kesaksian yang bertentangan, menuju pabrik tua di Jalan Kartini. Siapa yang memilih nama berikutnya?", 14, Color("a7b2a2"))
	body.custom_minimum_size.y = 68
	var save = State.read_save()
	var entries = [["01", "PLAY GAME", "new"], ["02", "LANJUTKAN PERMAINAN", "continue"], ["03", "OPTIONS", "settings"], ["04", "GRAPHICS", "graphics"], ["05", "CREDITS", "credits"], ["06", "EXIT", "quit"]]
	for entry in entries:
		var button = Button.new(); button.text = entry[0] + "    " + entry[1]
		button.custom_minimum_size.y = 34; button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color("d5cfb7"))
		button.add_theme_color_override("font_hover_color", Color("fff0c6"))
		var style = StyleBoxFlat.new(); style.bg_color = Color(0, 0, 0, 0)
		style.content_margin_left = 0; style.content_margin_top = 6; style.content_margin_bottom = 6
		button.add_theme_stylebox_override("normal", style); button.add_theme_stylebox_override("disabled", style)
		var hover = style.duplicate(); hover.bg_color = Color(0.65, 0.65, 0.45, 0.08); hover.border_color = Color("b9ae8b"); hover.border_width_left = 2; hover.content_margin_left = 12
		button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("focus", hover)
		button.disabled = entry[2] == "continue" and save.is_empty()
		button.pressed.connect(func(): hud.action_requested.emit(entry[2], ""))
		column.add_child(button)
		if entry[2] == "continue" and not save.is_empty():
			_label(column, "        " + State.TITLES[State.ROOMS.find(save.room)] + " · %02d:%02d" % [int(save.elapsed) / 60, int(save.elapsed) % 60], 10, Color("7f9685"))
	var spacer = Control.new(); spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL; column.add_child(spacer)
	_label(column, "WASD + mouse · Ctrl jongkok · E interaksi\nHeadphone disarankan · horor dan kejutan mendadak\nNATIVE EDITION  /  0.11", 11, Color("778d7d"))
	var card = Button.new(); card.text = "◈   GANTI LATAR\nSEKOLAH / JALUR SERVIS"
	card.anchor_left = 1; card.anchor_right = 1; card.anchor_top = 1; card.anchor_bottom = 1
	card.offset_left = -290; card.offset_right = -35; card.offset_top = -80; card.offset_bottom = -28
	card.add_theme_font_size_override("font_size", 12)
	card.pressed.connect(func(): hud.action_requested.emit("title_background", "")); add_child(card)

func _label(parent: Node, value: String, size: int, color: Color) -> Label:
	var label = Label.new(); label.text = value; label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color); label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label
