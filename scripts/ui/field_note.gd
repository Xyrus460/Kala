extends Control
## Original paper treatment inspired by the supplied reference; all text stays
## selectable/readable native UI, with scrolling for long evidence records.
var heading = ""
var body = ""

func _ready() -> void:
	custom_minimum_size = Vector2(810, 510)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sheet = MarginContainer.new(); sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.add_theme_constant_override("margin_left", 64); sheet.add_theme_constant_override("margin_right", 55)
	sheet.add_theme_constant_override("margin_top", 30); sheet.add_theme_constant_override("margin_bottom", 28); add_child(sheet)
	var stack = VBoxContainer.new(); stack.add_theme_constant_override("separation", 14); sheet.add_child(stack)
	var title = Label.new(); title.text = heading
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_override("font", preload("res://assets/fonts/Caveat.ttf")); title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("463b2e")); title.add_theme_constant_override("shadow_offset_x", 0); title.add_theme_constant_override("shadow_offset_y", 0)
	stack.add_child(title)
	var rule = HSeparator.new(); rule.modulate = Color("786649"); stack.add_child(rule)
	var scroll = ScrollContainer.new(); scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; stack.add_child(scroll)
	var text = RichTextLabel.new(); text.name = "HandwrittenText"; text.text = body
	text.fit_content = true; text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.selection_enabled = true; text.scroll_active = false
	text.add_theme_font_override("normal_font", preload("res://assets/fonts/Caveat.ttf"))
	text.add_theme_font_size_override("normal_font_size", 27); text.add_theme_color_override("default_color", Color("413b30"))
	text.add_theme_constant_override("line_separation", 3); scroll.add_child(text)
	resized.connect(queue_redraw)

func _draw() -> void:
	var rng = RandomNumberGenerator.new(); rng.seed = 915
	var corners = PackedVector2Array()
	var outline = PackedVector2Array([Vector2(16, 9), Vector2(size.x - 22, 12), Vector2(size.x - 18, size.y - 18), Vector2(24, size.y - 12)])
	for side in range(4):
		var start = outline[side]; var end = outline[(side + 1) % 4]
		var along = (end - start).normalized(); var normal = Vector2(along.y, -along.x)
		for i in range(16):
			corners.append(start.lerp(end, float(i) / 16) + normal * (0 if i == 0 else rng.randf_range(-1.5, 1.5)))
	draw_colored_polygon(corners, Color("bbae8f"))
	for i in range(1300):
		var p = Vector2(rng.randf_range(25, size.x - 25), rng.randf_range(16, size.y - 20))
		draw_line(p, p + Vector2(rng.randf_range(1, 16), 0.2), Color(0.28, 0.23, 0.14, rng.randf_range(0.015, 0.05)), 1)
	for i in range(25):
		var p = Vector2(rng.randf_range(30, size.x - 30), rng.randf_range(20, size.y - 25))
		draw_circle(p, rng.randf_range(6, 27), Color(0.31, 0.24, 0.12, 0.025))
	draw_line(Vector2(42, 20), Vector2(46, size.y - 20), Color(0.39, 0.25, 0.15, 0.24), 1)
	draw_line(Vector2(20, size.y * 0.51), Vector2(size.x - 15, size.y * 0.48), Color(0.28, 0.21, 0.13, 0.12), 2)
	draw_line(Vector2(size.x * 0.56, 14), Vector2(size.x * 0.55, size.y - 15), Color(0.95, 0.88, 0.69, 0.19), 2)
	for i in range(12):
		var p = Vector2(rng.randf_range(28, size.x - 35), rng.randf_range(25, size.y - 35))
		draw_colored_polygon(PackedVector2Array([p, p + Vector2(35, -13), p + Vector2(55, 17)]), Color(0.94, 0.86, 0.65, 0.028))
	draw_polyline(corners + PackedVector2Array([corners[0]]), Color(0.35, 0.29, 0.18, 0.4), 2, true)
