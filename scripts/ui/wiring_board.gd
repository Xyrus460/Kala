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
	var steel=G.material("plain",Color("666c6b")).duplicate();steel.metallic=0.65;steel.roughness=0.6
	var dark=G.material("plain",Color("292e31"));var ivory=G.material("plain",Color("c6c5b4"))
	G.box(assembly,Vector3(0,0,-0.16),Vector3(8.4,3.5,0.22),dark)
	G.box(assembly,Vector3(0,0,-0.035),Vector3(8.08,3.2,0.04),steel)
	for x in [-4.12,4.12]:G.box(assembly,Vector3(x,0,0.05),Vector3(0.12,3.48,0.28),steel)
	for y in [-1.68,1.68]:G.box(assembly,Vector3(0,y,0.05),Vector3(8.3,0.12,0.28),steel)
	var light=DirectionalLight3D.new();light.rotation_degrees=Vector3(-25,-25,0);light.light_energy=0.9;view.add_child(light)
	var fill=OmniLight3D.new();fill.position=Vector3(0,1,4);fill.light_energy=1.1;fill.omni_range=12;view.add_child(fill)
	# Two DIN rails, enclosed wire ducts and numbered screw terminals.
	for x in [-2.5,2.5]:
		G.box(assembly,Vector3(x,0,0.015),Vector3(0.76,2.85,0.08),steel)
		for dx in [-0.34,0.34]:G.box(assembly,Vector3(x+dx,0,0.07),Vector3(0.045,2.85,0.04),ivory)
	for y in [-1.36,1.36]:
		G.box(assembly,Vector3(0,y,0.10),Vector3(6.9,0.22,0.16),ivory)
		for i in range(44):G.box(assembly,Vector3(-3.3+i*0.15,y,0.19),Vector3(0.025,0.15,0.01),dark)
	for x in [-3.9,3.9]:
		for y in [-1.48,1.48]:
			var screw=G.cylinder(assembly,Vector3(x,y,0.04),0.055,0.025,steel);screw.rotation.x=PI/2
			G.box(assembly,Vector3(x,y,0.06),Vector3(0.06,0.009,0.008),dark)
	G.box(assembly,Vector3(0,0.64,0.15),Vector3(1.65,0.85,0.25),ivory)
	G.box(assembly,Vector3(0,0.66,0.285),Vector3(1.34,0.46,0.035),dark)
	var title=G.sign_text(assembly,"AC   220 V",Vector3(0,0.66,0.315),25);title.pixel_size=0.007;title.outline_size=0;title.modulate=Color("a2b28b")
	for x in [-0.45,0,0.45]:
		G.box(assembly,Vector3(x,-0.38,0.16),Vector3(0.36,0.75,0.24),ivory)
		G.box(assembly,Vector3(x,-0.35,0.30),Vector3(0.20,0.29,0.10),dark)
	var plate=G.sign_text(assembly,"LP-01   /   PENERANGAN",Vector3(0,-1.04,0.10),17);plate.pixel_size=0.006;plate.outline_size=0
	for i in range(3):
		for side in [-1,1]:
			var socket=socket_point(i,side)
			G.box(assembly,socket-Vector3(0,0,0.07),Vector3(0.55,0.64,0.22),ivory)
			for dy in [-0.19,0.19]:
				var screw=G.cylinder(assembly,socket+Vector3(0,dy,0.06),0.063,0.03,steel);screw.rotation.x=PI/2
				G.box(assembly,socket+Vector3(0,dy,0.08),Vector3(0.07,0.012,0.012),dark)
			G.box(assembly,socket+Vector3(0,0,0.075),Vector3(0.32,0.13,0.025),dark)
			var terminal=G.cylinder(assembly,socket+Vector3(0,0,0.12),0.075,0.08,G.material("plain",COLORS[i]));terminal.rotation.x=PI/2
			terminal.name="Terminal_%d_%d"%[i,side]
			var label=G.sign_text(assembly,["M","K","B"][i],socket+Vector3(side*0.47,0,0.08),23);label.pixel_size=0.006;label.outline_size=0;label.modulate=Color("eee9d7")
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
		if status != null: status.text = "Sambungan tidak cocok."
		return false
	var next_index = completed.size()
	if from != next_index:
		if status != null: status.text = "Urutan catu belum sesuai catatan servis."
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
				if status != null: status.text = "Memasang kabel…"
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
