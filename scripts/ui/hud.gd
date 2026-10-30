class_name KalaHUD
extends CanvasLayer

signal action_requested(action: String, value: String)
var root: Control
var hud: Control
var chapter: Label
var objective: Label
var health: ProgressBar
var vitals: Label
var heat: ProgressBar
var prompt: Label
var boss: Label
var boss_bar: ProgressBar
var boss_detail: Label
var subtitle: Label
var overlay: ColorRect
var panel: VBoxContainer
var panel_title: Label
var content: VBoxContainer
var mode = ""
var puzzle_id = ""
var photo_back = false
var photo_inspector: Control
var crosshair: Label
var toast_time = 0.0
var fade: ColorRect
var evidence_list: Label
var heat_label: Label
var cinematic_hint: Label
var title_menu: Control
var panel_center: CenterContainer
var tutorial: Control
var pause_menu: Control
var dialogue_card: Control
var wiring_board: Control
var keypad_board: Control

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var theme = Theme.new()
	var ui_font = SystemFont.new()
	ui_font.font_names = PackedStringArray(["Segoe UI", "Noto Sans", "sans-serif"])
	ui_font.font_weight = 300
	theme.default_font = ui_font
	theme.default_font_size = 18
	var style = StyleBoxFlat.new()
	style.bg_color = Color("121612")
	style.border_color = Color("726b50")
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	theme.set_stylebox("normal", "Button", style)
	var hover = style.duplicate()
	hover.bg_color = Color("35483b")
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("focus", "Button", hover)
	theme.set_color("font_color", "Label", Color("ded6be"))
	theme.set_color("font_color", "Button", Color("ede3c8"))
	root.theme = theme
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	chapter = _label("", 11)
	hud.add_child(chapter)
	_pin(chapter, Vector2.ZERO, Rect2(26, 24, 280, 20))
	objective = _label("", 12)
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hud.add_child(objective)
	_pin(objective, Vector2.ZERO, Rect2(26, 140, 270, 65))
	objective.modulate.a = 0.66
	evidence_list = _label("", 11)
	hud.add_child(evidence_list)
	_pin(evidence_list, Vector2.ZERO, Rect2(26, 50, 260, 85))
	evidence_list.modulate.a = 0.84
	health = _bar(Vector2.ZERO, Vector2(96, 3), Color("cfc8b6"))
	_pin(health, Vector2(1, 0), Rect2(-122, 65, 96, 3))
	heat = _bar(Vector2.ZERO, Vector2(112, 3), Color("c9a86a"))
	_pin(heat, Vector2.ONE, Rect2(-138, -43, 112, 3))
	heat_label = _label("Panas", 10)
	heat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(heat_label)
	_pin(heat_label, Vector2.ONE, Rect2(-188, -65, 162, 18))
	vitals = _label("", 10)
	vitals.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hud.add_child(vitals)
	_pin(vitals, Vector2(1, 0), Rect2(-188, 24, 162, 38))
	var help = _label("J · Jurnal     Esc · Jeda", 10)
	hud.add_child(help)
	_pin(help, Vector2(0, 1), Rect2(26, -30, 240, 18))
	help.modulate.a = 0.55
	crosshair = _label("·", 20)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(crosshair)
	_pin(crosshair, Vector2(0.5, 0.5), Rect2(-8, -14, 16, 28))
	prompt = _label("", 18)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(prompt)
	_pin(prompt, Vector2(0.5, 1), Rect2(-380, -138, 760, 40))
	boss = _label("", 11)
	boss.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss.add_theme_color_override("font_color", Color("cd9f81"))
	hud.add_child(boss)
	_pin(boss, Vector2(0.5, 0), Rect2(-220, 24, 440, 18))
	boss_bar = _bar(Vector2.ZERO, Vector2(270, 3), Color("ae6455"))
	_pin(boss_bar, Vector2(0.5, 0), Rect2(-135, 46, 270, 3))
	boss_detail = _label("", 10)
	boss_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud.add_child(boss_detail)
	_pin(boss_detail, Vector2(0.5, 0), Rect2(-240, 58, 480, 30))
	subtitle = _label("", 19)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(subtitle)
	_pin(subtitle, Vector2(0.5, 1), Rect2(-440, -102, 880, 65))
	cinematic_hint = _label("E / SPASI / ESC · LEWATI", 12)
	cinematic_hint.visible = false
	root.add_child(cinematic_hint)
	_pin(cinematic_hint, Vector2.ONE, Rect2(-260, -32, 234, 20))
	overlay = ColorRect.new()
	overlay.color = Color(0.012, 0.014, 0.017, 0.94)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)
	var center = CenterContainer.new()
	panel_center = center
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(850, 650)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	center.add_child(scroll)
	panel = VBoxContainer.new()
	panel.custom_minimum_size.x = 810
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_constant_override("separation", 14)
	scroll.add_child(panel)
	panel_title = _label("KALA", 28)
	panel.add_child(panel_title)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	panel.add_child(content)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(fade)
	hud.visible = false

func _label(text: String, size: int) -> Label:
	var label = Label.new()
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	return label

func _pin(control: Control, anchor: Vector2, rect: Rect2) -> void:
	control.anchor_left = anchor.x; control.anchor_right = anchor.x
	control.anchor_top = anchor.y; control.anchor_bottom = anchor.y
	control.offset_left = rect.position.x; control.offset_top = rect.position.y
	control.offset_right = rect.end.x; control.offset_bottom = rect.end.y
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE

func _bar(pos: Vector2, dimensions: Vector2, color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = pos
	bar.size = dimensions
	bar.show_percentage = false
	var style = StyleBoxFlat.new()
	style.bg_color = color
	bar.add_theme_stylebox_override("fill", style)
	var background = StyleBoxFlat.new()
	background.bg_color = Color("28362f")
	bar.add_theme_stylebox_override("background", background)
	hud.add_child(bar)
	bar.size = dimensions
	return bar

func clear_panel(title: String, next_mode: String) -> void:
	dialogue_card = null; wiring_board = null; keypad_board = null
	_clear_tutorial()
	_clear_pause()
	if is_instance_valid(title_menu): title_menu.queue_free(); title_menu = null
	panel_center.show()
	overlay.color = Color(0.012, 0.014, 0.017, 0.94)
	mode = next_mode
	overlay.visible = true
	panel_title.text = title
	panel_title.show()
	panel_title.add_theme_font_size_override("font_size", 28)
	panel_title.add_theme_font_override("font", preload("res://assets/fonts/embedded_001.ttf"))
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func paragraph(text: String) -> void:
	var label = _label(text, 18)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(label)

func button(text: String, action: String, value = "", disabled = false) -> Button:
	var result = Button.new()
	result.text = text
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT
	result.custom_minimum_size.y = 43
	result.disabled = disabled
	result.pressed.connect(func(): action_requested.emit(action, value))
	content.add_child(result)
	return result

func close_panel() -> void:
	_clear_tutorial()
	_clear_pause()
	# SubViewport rendering must end when its puzzle is closed, even when no
	# other panel is opened afterwards. Do not keep an off-screen 3D board alive.
	for control in [wiring_board, dialogue_card, keypad_board]:
		if is_instance_valid(control):
			if control.get_parent() != null: control.get_parent().remove_child(control)
			control.queue_free()
	wiring_board = null; dialogue_card = null; keypad_board = null
	if is_instance_valid(title_menu): title_menu.queue_free(); title_menu = null
	mode = ""
	overlay.visible = false
	if is_instance_valid(photo_inspector):
		photo_inspector.queue_free()
		photo_inspector = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func title_screen() -> void:
	clear_panel("KALA", "title")
	panel_center.hide()
	overlay.color = Color(0, 0, 0, 0)
	title_menu = preload("res://scripts/ui/title_menu.gd").new()
	overlay.add_child(title_menu)
	title_menu.build(self)

func show_pause(current_objective: String) -> void:
	clear_panel("", "pause")
	panel_center.hide()
	overlay.color = Color(0, 0, 0, 0)
	pause_menu = preload("res://scripts/ui/pause_menu.gd").new()
	overlay.add_child(pause_menu)
	pause_menu.build(self, current_objective)

func _clear_pause() -> void:
	if is_instance_valid(pause_menu):
		overlay.remove_child(pause_menu)
		pause_menu.queue_free()
		pause_menu = null

func show_note(title: String, body: String) -> void:
	clear_panel(title, "note")
	panel_title.hide()
	var sheet = preload("res://scripts/ui/field_note.gd").new()
	sheet.heading = title; sheet.body = body; content.add_child(sheet)
	button("SIMPAN & TUTUP  ·  E / ESC", "close")

func show_dialogue(speaker: String, body: String) -> void:
	clear_panel("", "dialogue"); panel_title.hide(); overlay.color.a = 0.74
	dialogue_card = preload("res://scripts/ui/dialogue_card.gd").new(); content.add_child(dialogue_card)
	dialogue_card.build(speaker, body)
	dialogue_card.finished.connect(func(): action_requested.emit("close", ""))

func show_photo() -> void:
	photo_back = false
	clear_panel("FOTO DANU–RAKA / KEMARIN", "photo")
	photo_inspector = preload("res://scripts/ui/photo_inspector.gd").new()
	content.add_child(photo_inspector)
	photo_inspector.side_changed.connect(func(revealed):
		photo_back = revealed
		if revealed: action_requested.emit("photo_back", ""))
	paragraph("Klik dan tahan foto, lalu geser mouse untuk memutar kertas dan melihat bagian belakangnya.")
	button("SIMPAN & TUTUP  ·  E / ESC", "close")

func show_puzzle(id: String, status = "") -> void:
	puzzle_id = id
	clear_panel({"locker": "LOKER RAKA", "panel": "PANEL BANGSAL MUAT", "fuse": "RANGKAIAN PENERANGAN", "valve": "KATUP TEKANAN", "breaker": "SAKLAR RUANG RITUAL"}[id], "puzzle")
	var p: Dictionary = State.data.puzzles[id]
	if id == "fuse":
		paragraph("Sambungkan sendiri kabel M → K → B. Tahan ujung kiri dan tarik ke terminal kanan dengan label yang sama.")
		wiring_board = preload("res://scripts/ui/wiring_board.gd").new(); wiring_board.completed = p.current.duplicate(); content.add_child(wiring_board)
		var connection_status = _label("Terhubung %d / 3 • Terminal berlabel; warna sebagai penanda tambahan." % p.current.size(), 15)
		connection_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; content.add_child(connection_status); wiring_board.status = connection_status
		wiring_board.connected.connect(func(index): action_requested.emit("puzzle_order", str(index)))
	elif id in ["locker", "panel"]:
		overlay.color.a = 0.72
		panel_title.add_theme_font_size_override("font_size", 20)
		keypad_board = preload("res://scripts/ui/keypad_board.gd").new()
		keypad_board.entered = str(p.entered); keypad_board.feedback = status; content.add_child(keypad_board)
		keypad_board.key_pressed.connect(func(key): action_requested.emit("puzzle_key", key))
		var instructions = _label("Klik tombol / ketik 4 angka · Enter: konfirmasi · C: hapus · Backspace: koreksi", 14)
		instructions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; content.add_child(instructions)
	elif id == "valve":
		paragraph("Semua panah harus mengarah ke atas. Posisi tersimpan ketika panel ditutup.")
		for i in range(3): button("KATUP %s    %s" % [["I", "II", "III"][i], ["↑", "→", "↓", "←"][int(p.pos[i])]], "puzzle_order", str(i))
	else:
		paragraph("Satu jalur setiap kali. Sambungan salah mengulang rangkaian.\nTerhubung: %d / %d" % [p.current.size(), 3 if id == "fuse" else 4])
		var labels = ["M · MERAH", "K · KUNING", "B · BIRU"] if id == "fuse" else ["TERMINAL 1", "TERMINAL 2", "TERMINAL 3", "TERMINAL 4"]
		for i in range(labels.size()): button(labels[i], "puzzle_order", str(i))
	if status != "": paragraph(status)
	button("BUTUH PETUNJUK?", "hint", id)
	button("TUTUP  ·  ESC", "close")

func show_journal() -> void:
	clear_panel("JURNAL PENYELIDIKAN", "journal")
	paragraph("BUKTI %d/4 · SANITY %d\n\nBARANG: %s\nTERPASANG: %s" % [State.data.evidence.size(), int(State.data.sanity), ", ".join(State.data.items.keys()), ", ".join(State.data.installed.keys())])
	if State.data.evidence.has("op1"): button("PERIKSA KEMBALI FOTO", "photo")
	if State.flag("lenteraOwned"): button("PANDUAN VIDEO LENTERA-G", "tutorial")
	for id in State.data.notes:
		button(str(State.data.notes[id].title), "journal_note", id)
	button("KEMBALI  ·  J / ESC", "close")

func notify(text: String, duration = 4.0) -> void:
	subtitle.text = text
	toast_time = duration

func _process(delta: float) -> void:
	toast_time = maxf(0, toast_time - delta)
	if toast_time <= 0: subtitle.text = ""

func _input(event: InputEvent) -> void:
	if mode == "dialogue" and event.is_action_pressed("interact"):
		if is_instance_valid(dialogue_card): dialogue_card.advance()
		get_viewport().set_input_as_handled()
	if mode == "puzzle" and event is InputEventKey and event.pressed and not event.echo:
		if puzzle_id in ["locker", "panel"]:
			if is_instance_valid(keypad_board): keypad_board.handle_key(event)
	if mode in ["note", "photo", "tutorial"] and event.is_action_pressed("interact"):
		action_requested.emit("close", "")
		get_viewport().set_input_as_handled()

func show_tutorial() -> void:
	clear_panel("", "tutorial")
	panel_center.hide()
	overlay.color = Color(0, 0, 0, 0.68)
	tutorial = preload("res://scripts/ui/lentera_tutorial.gd").new()
	overlay.add_child(tutorial)
	tutorial.continued.connect(func(): action_requested.emit("close", ""))

func _clear_tutorial() -> void:
	if is_instance_valid(tutorial):
		tutorial.stop()
		tutorial.queue_free()
		tutorial = null
