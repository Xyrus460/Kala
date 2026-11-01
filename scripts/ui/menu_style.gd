extends RefCounted

const WHITE = Color("e5e4df")
const MUTED = Color("969894")
const FONT = preload("res://assets/fonts/embedded_001.ttf")
const LOGO = preload("res://assets/fonts/embedded_000.ttf")
const INK = preload("res://assets/materials/menu_ink.gdshader")

static func menu_theme() -> Theme:
	var result = Theme.new()
	result.default_font = FONT
	result.default_font_size = 16
	for type in ["Label", "Button", "CheckButton"]:
		result.set_color("font_color", type, WHITE)
	result.set_color("font_hover_color", "Button", Color.WHITE)
	result.set_color("font_focus_color", "Button", Color.WHITE)
	result.set_color("font_pressed_color", "Button", Color.WHITE)
	result.set_color("font_disabled_color", "Button", Color("666965"))
	result.set_stylebox("normal", "Button", box())
	result.set_stylebox("hover", "Button", box(true))
	result.set_stylebox("focus", "Button", box(true))
	result.set_stylebox("pressed", "Button", box(true))
	result.set_stylebox("disabled", "Button", box())
	var rail = StyleBoxFlat.new(); rail.bg_color = Color(1, 1, 1, 0.05)
	var grip = StyleBoxFlat.new(); grip.bg_color = Color("9d9f9a"); grip.set_content_margin_all(3)
	result.set_stylebox("scroll", "VScrollBar", rail)
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]: result.set_stylebox(state, "VScrollBar", grip)
	return result

static func box(active = false) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color = Color(0.02, 0.024, 0.022, 0.75 if active else 0.46)
	result.border_color = WHITE if active else Color(0.55, 0.57, 0.54, 0.38)
	result.set_border_width_all(2 if active else 1)
	result.set_content_margin_all(10)
	return result

static func ink(control: CanvasItem) -> void:
	var material = ShaderMaterial.new(); material.shader = INK; control.material = material

static func label(parent: Node, text: String, rect: Rect2, font_size = 16, color = WHITE, distressed = false) -> Label:
	var result = Label.new(); result.clip_text = true; result.text = text; result.position = rect.position; result.size = rect.size
	result.add_theme_font_size_override("font_size", font_size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if distressed: ink(result)
	parent.add_child(result)
	return result

static func text_button(parent: Node, text: String, rect: Rect2, font_size = 18) -> Button:
	var result = Button.new(); result.text = text; result.position = rect.position; result.size = rect.size
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT
	result.add_theme_font_size_override("font_size", font_size)
	for state in ["normal", "disabled"]: result.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	var hover = StyleBoxFlat.new(); hover.bg_color = Color(1, 1, 1, 0.045)
	hover.border_color = WHITE; hover.border_width_left = 2; hover.content_margin_left = 12
	for state in ["hover", "focus", "pressed"]: result.add_theme_stylebox_override(state, hover)
	parent.add_child(result)
	return result

static func rule(parent: Node, rect: Rect2) -> void:
	var line = ColorRect.new(); line.color = Color(0.86, 0.87, 0.83, 0.65)
	line.position = rect.position; line.size = rect.size; line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ink(line); parent.add_child(line)

static func backdrop(parent: Control, darkness = 0.76) -> void:
	var blur = ColorRect.new(); blur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material = ShaderMaterial.new(); material.shader = preload("res://assets/materials/pause_blur.gdshader")
	blur.material = material; blur.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(blur)
	var tint = ColorRect.new(); tint.color = Color(0.015, 0.017, 0.016, darkness)
	tint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); tint.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(tint)

static func grain(parent: Control) -> void:
	var overlay = ColorRect.new(); overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var material = ShaderMaterial.new(); material.shader = preload("res://assets/materials/menu_grain.gdshader")
	overlay.material = material; overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE; parent.add_child(overlay)

static func fit(canvas: Control, dimensions: Vector2) -> void:
	var factor = minf(dimensions.x / 1280.0, dimensions.y / 720.0)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (dimensions - Vector2(1280, 720) * factor) / 2
