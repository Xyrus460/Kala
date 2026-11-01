extends Control

const S = preload("res://scripts/ui/menu_style.gd")
var canvas: Control
var host: CanvasLayer

func build(hud: CanvasLayer) -> void:
	host = hud
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = S.menu_theme()
	var shade = TextureRect.new(); shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var gradient = Gradient.new()
	gradient.set_color(0, Color(0.005, 0.008, 0.007, 0.90))
	gradient.set_color(1, Color(0.005, 0.008, 0.007, 0.02))
	gradient.add_point(0.28, Color(0.005, 0.008, 0.007, 0.78))
	gradient.add_point(0.57, Color(0.005, 0.008, 0.007, 0.18))
	var texture = GradientTexture2D.new(); texture.gradient = gradient; texture.width = 1280; texture.height = 4
	texture.fill_from = Vector2.ZERO; texture.fill_to = Vector2.RIGHT
	shade.texture = texture; shade.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(shade)
	canvas = Control.new(); canvas.size = Vector2(1280, 720); add_child(canvas)
	resized.connect(func(): S.fit(canvas, size)); S.fit(canvas, size)
	S.label(canvas, "CHAPTER 01", Rect2(108, 45, 400, 24), 17)
	var logo = S.label(canvas, "KALA", Rect2(103, 72, 510, 128), 93, S.WHITE, true)
	logo.add_theme_font_override("font", S.LOGO)
	S.label(canvas, "J A L A N   K A R T I N I", Rect2(110, 199, 450, 24), 18, S.WHITE, true)
	S.rule(canvas, Rect2(110, 234, 358, 1))
	var body = S.label(canvas, "Setiap cerita menyimpan seseorang yang disalahkan. Ikuti kesaksian yang bertentangan, sampai ke pabrik tua di Jalan Kartini.", Rect2(110, 253, 370, 90), 14, Color("bdbfb9"))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var entries = [["LANJUTKAN", "continue"], ["PERMAINAN BARU", "new"], ["MUAT GAME", "load_menu"], ["PENGATURAN", "settings"], ["KREDIT", "credits"], ["KELUAR", "quit"]]
	for i in range(entries.size()):
		var entry: Array = entries[i]
		var button = S.text_button(canvas, entry[0], Rect2(140, 384 + i * 43, 342, 38), 20)
		button.name = "Action_" + entry[1]
		button.disabled = entry[1] == "continue" and State.read_save().is_empty()
		button.pressed.connect(func(): hud.action_requested.emit(entry[1], ""))
	var version = str(ProjectSettings.get_setting("application/config/version", ""))
	S.label(canvas, "KALA  /  " + version, Rect2(1090, 679, 155, 20), 10, Color("757b75"))
	var background = S.text_button(canvas, "GANTI LATAR", Rect2(1070, 637, 175, 30), 12)
	background.pressed.connect(func(): hud.action_requested.emit("title_background", ""))
	S.grain(self)
