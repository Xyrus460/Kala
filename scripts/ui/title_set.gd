extends Node3D

const G = preload("res://scripts/systems/geometry.gd")
var camera: Camera3D
var school: Node3D
var factory: Node3D
var time = 0.0
var variant = 0

func _ready() -> void:
	name = "TitleSet"
	camera = Camera3D.new(); camera.fov = 68; camera.far = 90; add_child(camera)
	school = _corridor(false)
	factory = _corridor(true)
	factory.hide()
	set_process(false)

func _corridor(industrial: bool) -> Node3D:
	var root = Node3D.new(); add_child(root)
	root.position.x = 150 if industrial else 90
	var wall = ShaderMaterial.new(); wall.shader = preload("res://assets/materials/aged_wall.gdshader")
	wall.set_shader_parameter("plaster", Color("a29e88") if industrial else Color("c2c3af"))
	wall.set_shader_parameter("paint", Color("543e31") if industrial else Color("365c4c"))
	wall.set_shader_parameter("decay", 0.75 if industrial else 0.3)
	wall.set_shader_parameter("pattern", 1.0 if industrial else 0.0)
	var floor_mat = G.material("concrete", Color("84867c") if not industrial else Color("605d50"))
	G.box(root, Vector3(0, -0.15, -13), Vector3(6.4, 0.3, 66), floor_mat)
	G.box(root, Vector3(0, 3.35, -13), Vector3(6.4, 0.2, 66), floor_mat)
	for side in [-1, 1]:
		G.box(root, Vector3(side * 3.15, 1.6, -13), Vector3(0.25, 3.2, 66), wall)
		G.box(root, Vector3(side * 3.0, 0.1, -13), Vector3(0.08, 0.18, 66), G.material("ceramic", Color("333e35")))
	for i in range(12):
		var z = 12 - i * 4.6
		var housing = G.material("steel", Color("343e38"))
		G.box(root, Vector3(0, 3.18, z), Vector3(1.5, 0.12, 0.28), housing)
		var tube = StandardMaterial3D.new(); tube.albedo_color = Color("e0e5d1"); tube.emission_enabled = true; tube.emission = Color("becfbf"); tube.emission_energy_multiplier = 1.4
		G.box(root, Vector3(0, 3.10, z), Vector3(1.3, 0.025, 0.19), tube)
		var spot = SpotLight3D.new(); spot.position = Vector3(0, 3.05, z); spot.rotation.x = -PI / 2
		spot.spot_angle = 65; spot.spot_range = 9; spot.light_energy = 2.3; spot.shadow_enabled = i < 5
		spot.light_color = Color("da7b40") if industrial else Color("c6d9d0"); root.add_child(spot)
		for j in range(3):
			var x = 2.64
			var cabinet = G.material("steel", Color("4b4c3e") if industrial else Color("2e5143"))
			G.box(root, Vector3(x, 1.1, z + j * 0.7), Vector3(0.62, 2.15, 0.64), cabinet)
			G.box(root, Vector3(2.29, 1.15, z + j * 0.7), Vector3(0.035, 0.13, 0.045), housing)
			for y in [1.8, 1.87, 1.94]: G.box(root, Vector3(2.32, y, z + j * 0.7), Vector3(0.018, 0.015, 0.34), housing)
		G.box(root, Vector3(-3, 1.14, z), Vector3(0.1, 2.3, 1.3), G.material("burlap", Color("2b3b32")))
	var poster = G.box(root, Vector3(3.0, 1.9, 10), Vector3(0.03, 1.35, 0.9), G.material("cotton", Color("c3bfa2")))
	poster.name = "NoticeBoard"
	var sign_node = G.sign_text(root, "PEKAN LITERASI\n\nSatu fakta.\nBanyak cerita.\n\n17 — 21 MARET", Vector3(2.97, 1.9, 10), 17, -PI / 2)
	sign_node.modulate = Color("4b594b"); sign_node.outline_size = 0
	if industrial:
		var monster = preload("res://scripts/systems/model_factory.gd").make("hands") as Node3D
		monster.position = Vector3(1.0, 0, 10); monster.scale *= 1.36; monster.rotation.y = -0.15; root.add_child(monster)
		var rim = OmniLight3D.new(); rim.position = Vector3(1.5, 2.1, 4.8); rim.light_color = Color("d93c19"); rim.light_energy = 5; rim.omni_range = 10; root.add_child(rim)
		var eye = OmniLight3D.new(); eye.position = Vector3(1.1, 2.8, 8.4); eye.light_color = Color("a3c2b0"); eye.light_energy = 0.45; eye.omni_range = 4; root.add_child(eye)
	return root

func show_set(factory_background = false) -> void:
	var environment: Environment = get_parent().get_node("WorldEnvironment").environment
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_energy = 0.16; environment.fog_density = 0.002
	variant = int(factory_background)
	visible = true; school.visible = not factory_background; factory.visible = factory_background
	camera.make_current(); set_process(true)
	_process(0)

func hide_set() -> void:
	hide(); set_process(false)

func _process(delta: float) -> void:
	time += delta
	var base = 150 if variant == 1 else 90
	camera.position = Vector3(base - 1.0 + sin(time * 0.10) * 0.08, 1.67 + sin(time * 0.18) * 0.018, 15.3)
	camera.look_at(Vector3(base + 0.45, 1.55, -22))
