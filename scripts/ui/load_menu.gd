extends Control

signal requested(action: String, value: String)
signal closed
const S = preload("res://scripts/ui/menu_style.gd")
const C = preload("res://scripts/systems/checkpoint_catalog.gd")
var canvas: Control
var rows: VBoxContainer
var scroll: ScrollContainer
var records: Array = []
var row_buttons: Array[Button] = []
var selected = -1
var category = "saves"
var confirming_delete = false
var preview: TextureRect
var no_preview: Label
var detail_title: Label
var detail_date: Label
var detail_level: Label
var detail_time: Label
var detail_body: Label
var detail_progress: Label
var count_label: Label
var empty_label: Label
var load_button: Button
var delete_button: Button
var save_tab: Button
var section_tab: Button
var texture_cache: Dictionary = {}

func build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = S.menu_theme(); S.backdrop(self, 0.78)
	canvas = Control.new(); canvas.size = Vector2(1280, 720); add_child(canvas)
	resized.connect(func(): S.fit(canvas, size)); S.fit(canvas, size)
	S.label(canvas, "MUAT GAME", Rect2(38, 36, 550, 48), 34, S.WHITE, true)
	S.rule(canvas, Rect2(39, 86, 213, 2))
	save_tab = S.text_button(canvas, "SIMPANAN", Rect2(94, 100, 188, 30), 16)
	section_tab = S.text_button(canvas, "PILIH BAGIAN", Rect2(296, 100, 220, 30), 16)
	save_tab.pressed.connect(func(): show_category("saves"))
	section_tab.pressed.connect(func(): show_category("sections"))
	count_label = S.label(canvas, "", Rect2(548, 103, 177, 24), 11, S.MUTED)
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	scroll = ScrollContainer.new(); scroll.position = Vector2(91, 143); scroll.size = Vector2(650, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; canvas.add_child(scroll)
	rows = VBoxContainer.new(); rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 10); scroll.add_child(rows)
	empty_label = S.label(canvas, "Belum ada simpanan.\n\nBuka PILIH BAGIAN untuk langsung\nmemainkan bagian cerita.", Rect2(140, 280, 500, 155), 18, S.MUTED)
	# A slightly tilted, worn photograph mirrors the reference's preview card.
	var photograph = Panel.new(); photograph.position = Vector2(825, 131); photograph.size = Vector2(362, 214)
	photograph.rotation = -0.035
	var frame = S.box(true); frame.bg_color = S.WHITE; frame.border_color = S.WHITE; frame.set_border_width_all(3)
	photograph.add_theme_stylebox_override("panel", frame); canvas.add_child(photograph)
	preview = TextureRect.new(); preview.position = Vector2(8, 8); preview.size = Vector2(346, 198)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE; photograph.add_child(preview)
	no_preview = S.label(photograph, "KALA\nARSIP PERJALANAN", Rect2(20, 65, 320, 90), 21, Color("434a46"), true)
	no_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var card = Panel.new(); card.position = Vector2(824, 359); card.size = Vector2(364, 245)
	var card_style = StyleBoxFlat.new(); card_style.bg_color = Color(0, 0, 0, 0.36)
	card.add_theme_stylebox_override("panel", card_style); canvas.add_child(card)
	S.rule(canvas, Rect2(839, 363, 330, 1))
	detail_title = S.label(canvas, "", Rect2(840, 376, 324, 54), 23, S.WHITE, true)
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_date = S.label(canvas, "", Rect2(840, 432, 330, 24), 12, S.MUTED)
	S.rule(canvas, Rect2(839, 462, 330, 1))
	S.label(canvas, "AREA", Rect2(840, 481, 83, 25), 13, S.MUTED)
	detail_level = S.label(canvas, "", Rect2(926, 481, 239, 28), 12)
	detail_level.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	S.label(canvas, "WAKTU MAIN", Rect2(840, 518, 160, 23), 13, S.MUTED)
	detail_time = S.label(canvas, "", Rect2(1004, 518, 160, 23), 13)
	detail_time.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	detail_body = S.label(canvas, "", Rect2(840, 552, 325, 58), 12, S.MUTED)
	detail_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_progress = S.label(canvas, "", Rect2(94, 631, 640, 35), 12, S.MUTED)
	load_button = S.text_button(canvas, "ENTER  MUAT CHECKPOINT", Rect2(839, 617, 351, 38), 16)
	load_button.pressed.connect(activate)
	delete_button = S.text_button(canvas, "DEL  HAPUS SIMPANAN", Rect2(815, 671, 265, 29), 12)
	delete_button.pressed.connect(toggle_delete)
	var back = S.text_button(canvas, "ESC  KEMBALI", Rect2(1090, 671, 165, 29), 12)
	back.pressed.connect(func(): closed.emit())
	S.grain(self)
	show_category("saves" if not State.archive.entries(State).is_empty() else "sections")

func show_category(value: String) -> void:
	category = value; confirming_delete = false; texture_cache.clear()
	records.clear(); row_buttons.clear()
	for child in rows.get_children(): rows.remove_child(child); child.queue_free()
	if category == "sections": records = C.entries()
	else:
		for record in State.archive.entries(State):
			records.append({"id": record.id, "room": record.data.room, "title": C.title_for(record.data), "objective": C.objective_for(record.data), "saved_at": record.saved_at, "kind": record.kind, "data": record.data})
	save_tab.modulate = Color.WHITE if category == "saves" else Color("858b85")
	section_tab.modulate = Color.WHITE if category == "sections" else Color("858b85")
	count_label.text = "%02d %s" % [records.size(), "BAGIAN" if category == "sections" else "SIMPANAN"]
	for i in range(records.size()): add_row(i)
	empty_label.visible = records.is_empty(); scroll.scroll_vertical = 0
	select(0 if not records.is_empty() else -1)

func texture_for(record: Dictionary) -> Texture2D:
	var key = str(record.id)
	if texture_cache.has(key): return texture_cache[key]
	var result: Texture2D
	if category == "saves":
		var path: String = State.archive.thumbnail_path(State, record.id)
		if not path.is_empty() and FileAccess.file_exists(path):
			var image = Image.load_from_file(ProjectSettings.globalize_path(path))
			if image != null: result = ImageTexture.create_from_image(image)
	if result == null:
		var path = "res://assets/ui/checkpoints/" + str(record.id if category == "sections" else record.room) + ".jpg"
		if ResourceLoader.exists(path): result = load(path)
	texture_cache[key] = result
	return result

func add_row(index: int) -> void:
	var record: Dictionary = records[index]
	var button = Button.new(); button.name = "Checkpoint_" + str(record.id)
	button.custom_minimum_size = Vector2(630, 70); button.clip_contents = true
	rows.add_child(button); row_buttons.append(button)
	var image = TextureRect.new(); image.position = Vector2(12, 9); image.size = Vector2(94, 52)
	image.texture = texture_for(record); image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED; image.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(image)
	var title = S.label(button, record.title, Rect2(125, 13, 337, 19), 13)
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var objective = S.label(button, record.objective, Rect2(125, 39, 337, 19), 11, S.MUTED)
	objective.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var right = S.label(button, "BAGIAN %02d" % record.number if category == "sections" else C.playtime(record.data.elapsed), Rect2(475, 13, 140, 19), 12)
	right.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var date = S.label(button, "SIAP DIMAINKAN" if category == "sections" else C.date_label(record.saved_at), Rect2(455, 40, 160, 18), 10, S.MUTED)
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	button.pressed.connect(func(): select(index))
	button.focus_entered.connect(func(): select(index))
	button.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and event.double_click:
			get_viewport().set_input_as_handled(); select(index); activate())

func select(index: int) -> void:
	selected = index; confirming_delete = false
	for i in range(row_buttons.size()): row_buttons[i].add_theme_stylebox_override("normal", S.box(i == selected))
	load_button.disabled = selected < 0; delete_button.disabled = selected < 0 or category == "sections"
	load_button.text = "ENTER  MULAI BAGIAN" if category == "sections" else "ENTER  MUAT CHECKPOINT"
	delete_button.text = "DEL  HAPUS SIMPANAN"
	if selected < 0:
		preview.texture = null; no_preview.show()
		for label in [detail_title, detail_date, detail_level, detail_time, detail_body, detail_progress]: label.text = ""
		return
	_reveal_selection()
	var record: Dictionary = records[selected]
	preview.texture = texture_for(record); no_preview.visible = preview.texture == null
	detail_title.text = record.title; detail_level.text = State.TITLES[State.ROOMS.find(record.room)]
	detail_level.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	detail_date.text = "BAGIAN %02d / CHAPTER 01" % record.number if category == "sections" else C.date_label(record.saved_at)
	detail_time.text = "MULAI DARI BAGIAN INI" if category == "sections" else C.playtime(record.data.elapsed)
	detail_body.text = record.description if category == "sections" else record.objective
	detail_progress.text = "Langsung ke bagian cerita. Perlengkapan awal disiapkan." if category == "sections" else ("SIMPANAN MANUAL" if record.kind == "manual" else "CHECKPOINT OTOMATIS") + "   /   BUKTI %d/4   /   CATATAN %d" % [record.data.evidence.size(), record.data.notes.size()]

func _reveal_selection() -> void:
	# New VBox rows receive their real positions during the next layout pass.
	await get_tree().process_frame
	if is_inside_tree() and selected >= 0 and selected < row_buttons.size(): scroll.ensure_control_visible(row_buttons[selected])

func activate() -> void:
	if selected < 0: return
	if confirming_delete:
		var error: Error = State.archive.delete_slot(State, records[selected].id)
		if error != OK: detail_body.text = "Simpanan gagal dihapus. Kode: " + str(error); return
		var previous = selected; show_category(category)
		if not records.is_empty(): select(mini(previous, records.size() - 1))
		return
	requested.emit("load_section" if category == "sections" else "load_slot", str(records[selected].id))

func toggle_delete() -> void:
	if selected < 0 or category != "saves": return
	if confirming_delete: select(selected); return
	confirming_delete = true
	detail_body.text = "Hapus simpanan ini? Tindakan ini tidak dapat dibatalkan."
	load_button.text = "ENTER  YA, HAPUS"
	delete_button.text = "DEL  BATAL"

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode not in [KEY_ESCAPE, KEY_ENTER, KEY_KP_ENTER, KEY_DELETE, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN]: return
	# Closing/loading removes this Control immediately, so consume the event first.
	get_viewport().set_input_as_handled()
	match event.keycode:
		KEY_ESCAPE:
			if confirming_delete: select(selected)
			else: closed.emit()
		KEY_ENTER, KEY_KP_ENTER: activate()
		KEY_DELETE: toggle_delete()
		KEY_LEFT: show_category("saves")
		KEY_RIGHT: show_category("sections")
		KEY_UP, KEY_DOWN:
			if not records.is_empty():
				select(clampi(selected + (-1 if event.keycode == KEY_UP else 1), 0, records.size() - 1))
				scroll.ensure_control_visible(row_buttons[selected])
		_: return
