extends Control
const S = preload("res://scripts/ui/menu_style.gd")

func build(ui: CanvasLayer, objective: String) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = S.menu_theme()
	var backdrop = ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material = ShaderMaterial.new(); material.shader = preload("res://assets/materials/pause_blur.gdshader")
	backdrop.material = material; add_child(backdrop)
	var heading = Label.new(); heading.text = "PAUSED"
	heading.position = Vector2(28, 16); heading.add_theme_font_size_override("font_size", 32)
	heading.add_theme_color_override("font_color", S.WHITE); S.ink(heading); add_child(heading)
	var underline = ColorRect.new(); underline.color = S.WHITE; S.ink(underline)
	underline.position = Vector2(28, 56); underline.size = Vector2(138, 2); add_child(underline)
	var goals = VBoxContainer.new(); goals.name = "PauseObjectives"
	goals.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	goals.offset_left = -490; goals.offset_right = -36; goals.offset_top = 38
	goals.add_theme_constant_override("separation", 14); add_child(goals)
	var goal_title = Label.new(); goal_title.text = "TUJUAN SAAT INI  ◇"
	goal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	goal_title.add_theme_font_size_override("font_size", 21)
	goal_title.add_theme_color_override("font_color", S.WHITE); goals.add_child(goal_title)
	var description = Label.new(); description.text = objective
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = 454
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	description.add_theme_font_size_override("font_size", 16); goals.add_child(description)
	var progress = Label.new(); progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	for id in ["op1", "op2", "A", "B"]:
		progress.text += ("◆  " if State.data.evidence.has(id) else "◇  ") + {"op1": "Foto Danu–Raka", "op2": "Agenda Sari", "A": "Surat Raka", "B": "Album & perjanjian"}[id] + "\n"
	progress.add_theme_font_size_override("font_size", 14)
	progress.add_theme_color_override("font_color", Color("aaa99e")); goals.add_child(progress)
	var options = VBoxContainer.new(); options.name = "PauseActions"
	options.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	options.offset_left = 105; options.offset_right = 445; options.offset_top = -312; options.offset_bottom = -40
	options.add_theme_constant_override("separation", 3); add_child(options)
	var entries = [["LANJUTKAN", "close"], ["ULANG CHECKPOINT", "retry"], ["MUAT GAME", "load_menu"], ["SIMPAN CHECKPOINT", "save"], ["PENGATURAN", "settings"], ["MENU UTAMA", "title"]]
	for entry in entries:
		var button = Button.new(); button.text = entry[0]; button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(320, 40)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		var hover = StyleBoxFlat.new(); hover.bg_color = Color(0.6, 0.65, 0.6, 0.08)
		hover.border_color = S.WHITE; hover.border_width_left = 2
		hover.content_margin_left = 12
		button.add_theme_stylebox_override("hover", hover); button.add_theme_stylebox_override("focus", hover)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
		button.disabled = entry[1] == "retry" and State.checkpoint.is_empty()
		var action: String = entry[1]
		button.pressed.connect(func(): ui.action_requested.emit(action, ""))
		options.add_child(button)
	var status = Label.new(); status.name = "SaveStatus"
	status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	status.offset_left = -450; status.offset_right = -36; status.offset_top = -45
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	status.add_theme_font_size_override("font_size", 16)
	status.add_theme_color_override("font_color", S.WHITE); add_child(status)
	S.grain(self)

func show_status(value: String) -> void:
	get_node("SaveStatus").text = value
