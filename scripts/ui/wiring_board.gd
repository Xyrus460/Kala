extends Control
signal connected(index: int)
const G = preload("res://scripts/systems/geometry.gd")
const A = preload("res://scripts/systems/free_assets.gd")
const COLORS = [Color("a74938"), Color("c7ac55"), Color("587f9d")]
const ROWS = [1, 0, 2]
var view: SubViewport
var camera: Camera3D
var assembly: Node3D
var wire: Node3D
var selected = -1
var completed: Array = []
var status: Label

func _ready() -> void:
	custom_minimum_size = Vector2(810, 340); mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	view = SubViewport.new(); view.size = Vector2i(1215, 510); view.own_world_3d = true; view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; view.msaa_3d = Viewport.MSAA_2X; add_child(view)
	camera = Camera3D.new(); camera.position = Vector3(0, 0, 8); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 3.6; view.add_child(camera)
	assembly = Node3D.new(); view.add_child(assembly)
	G.box(assembly, Vector3(0, 0, -0.10), Vector3(8.4, 3.5, 0.18), G.material("steel", Color("4e5b56")))
	G.box(assembly, Vector3(0, 0, 0.015), Vector3(2, 3.1, 0.03), G.material("plain", Color("29312d")))
	var light = DirectionalLight3D.new(); light.rotation_degrees = Vector3(-25, -25, 0); light.light_energy = 1.4; view.add_child(light)
	var fill = OmniLight3D.new(); fill.position = Vector3(0, 1, 4); fill.light_energy = 2.5; fill.omni_range = 12; view.add_child(fill)
	var title = G.sign_text(assembly, "CATU LAMPU\nM  →  K  →  B", Vector3(0, 1.14, 0.08), 23); title.pixel_size = 0.009; title.outline_size = 0
	for y in [-0.65, 0.05, 0.65]:
		G.box(assembly, Vector3(0, y - 0.4, 0.11), Vector3(0.85, 0.26, 0.09), G.material("plain", Color("aaa58d")))
	for x in [-3.9, 3.9]:
		for y in [-1.48, 1.48]:
			G.sphere(assembly, Vector3(x, y, 0.05), Vector3(0.09, 0.09, 0.035), G.material("steel", Color("8d9387")))
	for i in range(3):
		for side in [-1, 1]:
			var socket = socket_point(i, side)
			G.box(assembly, socket - Vector3(0, 0, 0.06), Vector3(0.48, 0.48, 0.10), G.material("plain", Color("272c29")))
			A.place(assembly, "res://assets/vendor/kenney_factory/lever-single.glb", socket - Vector3(0, 0.12, 0), Vector3(0.22, 0.26, 0.14), 0, false)
			var terminal = G.sphere(assembly, socket + Vector3(0, 0, 0.06), Vector3(0.14, 0.14, 0.08), G.material("plain", COLORS[i]))
			terminal.name = "Terminal_%d_%d" % [i, side]
			var label = G.sign_text(assembly, ["M / MERAH", "K / KUNING", "B / BIRU"][i], socket + Vector3(side * 0.72, 0, 0.1), 19)
			label.pixel_size = 0.008; label.outline_size = 0
	for i in completed:
		_make_wire(socket_point(i, -1), socket_point(i, 1), COLORS[i], false)
	var display = TextureRect.new(); display.texture = view.get_texture(); display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; display.stretch_mode = TextureRect.STRETCH_SCALE
	display.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); display.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(display)

func socket_point(index: int, side: int) -> Vector3:
	var row = index if side < 0 else ROWS[index]
	return Vector3(side * 2.5, 0.95 - row * 0.95, 0.20)

func mouse_point(p: Vector2) -> Vector3:
	var pixel = p / size * Vector2(view.size)
	var from = camera.project_ray_origin(pixel); var direction = camera.project_ray_normal(pixel)
	return from + direction * ((0.27 - from.z) / direction.z)

func nearest_socket(point: Vector3, side: int) -> int:
	for i in range(3):
		if point.distance_to(socket_point(i, side)) < 0.36: return i
	return -1

func attempt_connection(from: int, to: int) -> bool:
	if from < 0 or to < 0 or from != to or completed.has(from):
		if status != null: status.text = "Terminal berbeda. Ikuti label M, K, B; kabel belum dipasang."
		return false
	var next_index = completed.size()
	if from != next_index:
		if status != null: status.text = "Catu belum stabil. Mulai M, lanjut K, terakhir B."
		return false
	connected.emit(from)
	return true

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p = mouse_point(event.position)
		if event.pressed:
			selected = nearest_socket(p, -1)
			if completed.has(selected): selected = -1
			if selected >= 0:
				if status != null: status.text = "Tahan lalu tarik ujung kabel ke terminal dengan label yang sama."
				_make_wire(socket_point(selected, -1), p, COLORS[selected], true)
		else:
			var from = selected; selected = -1
			if is_instance_valid(wire): wire.queue_free(); wire = null
			if from >= 0: attempt_connection(from, nearest_socket(p, 1))
		accept_event()
	elif event is InputEventMouseMotion and selected >= 0:
		if is_instance_valid(wire): wire.free()
		_make_wire(socket_point(selected, -1), mouse_point(event.position), COLORS[selected], true)
		accept_event()

func _make_wire(start: Vector3, end: Vector3, color: Color, moving: bool) -> void:
	var cable = Node3D.new(); cable.name = "DraggedCable" if moving else "ConnectedCable"; assembly.add_child(cable)
	var previous = start
	for i in range(1, 25):
		var t = float(i) / 24
		var p = start.lerp(end, t) + Vector3(0, -sin(t * PI) * 0.4, sin(t * PI) * 0.2)
		var segment = G.cylinder(cable, (p + previous) / 2, 0.035, p.distance_to(previous), G.material("plain", color))
		segment.quaternion = Quaternion(Vector3.UP, (p - previous).normalized()); previous = p
	if moving: wire = cable
