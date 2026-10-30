extends Control

signal side_changed(back: bool)
var card: Node3D
var view: SubViewport
var dragging = false
var drag_origin = 0.0
var drag_angle = 0.0
var back_visible = false
var settle: Tween

func _ready() -> void:
	custom_minimum_size = Vector2(760, 410)
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_DRAG
	view = SubViewport.new()
	view.size = Vector2i(1000, 540)
	view.own_world_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	view.msaa_3d = Viewport.MSAA_2X
	add_child(view)
	var camera = Camera3D.new()
	camera.position.z = 6.0
	camera.fov = 34
	view.add_child(camera)
	card = Node3D.new()
	card.rotation.z = -0.021
	view.add_child(card)
	var paper = MeshInstance3D.new()
	var paper_mesh = BoxMesh.new()
	paper_mesh.size = Vector3(4.82, 3.12, 0.016)
	paper.mesh = paper_mesh
	var paper_mat = StandardMaterial3D.new()
	paper_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paper_mat.albedo_color = Color("c3b597")
	paper.material_override = paper_mat
	card.add_child(paper)
	_face(preload("res://assets/textures/embedded_006.jpg"), false)
	var back = SubViewport.new()
	back.size = Vector2i(960, 620)
	back.disable_3d = true
	back.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(back)
	var background = ColorRect.new()
	background.color = Color("d6c6a4")
	background.size = Vector2(960, 620)
	back.add_child(background)
	var label = Label.new()
	label.text = "KELAS SATU A / ARSIP PRIBADI\n\nJangan percaya yang terlihat saja.\nMulai dari sini:\n\n4 7\n\nDua angka pertama.\nSari ingat dua angka berikutnya."
	label.add_theme_font_override("font", preload("res://assets/fonts/embedded_001.ttf"))
	label.add_theme_font_size_override("font_size", 37)
	label.add_theme_color_override("font_color", Color("352c27"))
	label.position = Vector2(42, 36)
	label.size = Vector2(876, 548)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	back.add_child(label)
	_face(back.get_texture(), true)
	var display = TextureRect.new()
	display.texture = view.get_texture()
	display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(display)

func _face(texture: Texture2D, back: bool) -> void:
	var face = MeshInstance3D.new()
	var mesh = QuadMesh.new()
	mesh.size = Vector2(4.7, 3.0)
	face.mesh = mesh
	face.position.z = -0.012 if back else 0.012
	face.rotation.y = PI if back else 0.0
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	face.material_override = material
	card.add_child(face)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if settle != null and settle.is_valid(): settle.kill()
			dragging = true
			drag_origin = event.position.x
			drag_angle = card.rotation.y
		else:
			dragging = false
			var nearest = roundf(card.rotation.y / PI) * PI
			settle = create_tween()
			settle.tween_property(card, "rotation:y", nearest, 0.18).set_trans(Tween.TRANS_SINE)
		accept_event()
	elif event is InputEventMouseMotion and dragging:
		card.rotation.y = drag_angle + clampf((event.position.x - drag_origin) / maxf(1, size.x) * TAU * 0.75, -PI, PI)
		_check_side()
		accept_event()

func _process(_delta: float) -> void:
	_check_side()

func _check_side() -> void:
	if not is_instance_valid(card): return
	var back = cos(card.rotation.y) < -0.15
	if back != back_visible:
		back_visible = back
		side_changed.emit(back)
