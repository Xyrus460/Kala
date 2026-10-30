extends Control
signal key_pressed(value: String)
var view: SubViewport
var camera: Camera3D
var model: Node3D
var display: Label3D
var entered = ""
var feedback = ""
var pressed_key: MeshInstance3D
var release_time = 0.0

func _ready() -> void:
	custom_minimum_size = Vector2(810, 420)
	mouse_filter = Control.MOUSE_FILTER_STOP
	view = SubViewport.new(); view.size = Vector2i(810, 420); view.own_world_3d = true
	view.transparent_bg = true; view.render_target_update_mode = SubViewport.UPDATE_ALWAYS; view.msaa_3d = Viewport.MSAA_4X; add_child(view)
	var world = Node3D.new(); view.add_child(world)
	var environment = WorldEnvironment.new(); var env = Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color(0,0,0,0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("b5b6cd"); env.ambient_light_energy = 0.5
	environment.environment = env; world.add_child(environment)
	model = preload("res://scripts/systems/keypad_model.gd").create(world, true)
	display = model.get_node("CodeDisplay"); refresh(entered, feedback)
	var light = OmniLight3D.new(); light.position = Vector3(-0.7, 0.5, 1); light.light_energy = 1.3; light.omni_range = 4; light.light_color = Color("b6a7e3"); world.add_child(light)
	var fill = OmniLight3D.new(); fill.position = Vector3(0.7, -0.1, 0.8); fill.light_energy = 0.8; fill.omni_range = 3; fill.light_color = Color("e2d7bb"); world.add_child(fill)
	camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 1.06; camera.position = Vector3(0,0,2); world.add_child(camera)
	var texture = TextureRect.new(); texture.texture = view.get_texture(); texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); texture.mouse_filter = Control.MOUSE_FILTER_IGNORE; texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; add_child(texture)

func refresh(code: String, status = "") -> void:
	entered = code; feedback = status
	if not is_instance_valid(display): return
	display.text = code + "_".repeat(maxi(0, 4 - code.length()))
	if status != "" and not status.begins_with("Kode"): return
	display.modulate = Color("df8d8d") if status.begins_with("Kode") else Color("b8d6c8")
	if status.begins_with("Kode"): display.text = "SALAH"

func press(key: String) -> void:
	if is_instance_valid(pressed_key): pressed_key.position.z = 0.082
	pressed_key = model.get_node_or_null("Key_" + key)
	if pressed_key != null: pressed_key.position.z = 0.076; release_time = 0.12
	key_pressed.emit(key)

func _process(delta: float) -> void:
	if release_time > 0:
		release_time -= delta
		if release_time <= 0 and is_instance_valid(pressed_key): pressed_key.position.z = 0.082

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var pixel = event.position / size * Vector2(view.size)
		var origin = camera.project_ray_origin(pixel)
		var ray = PhysicsRayQueryParameters3D.create(origin, origin + camera.project_ray_normal(pixel) * 5, 2)
		ray.collide_with_areas = true; ray.collide_with_bodies = false
		var hit = camera.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			accept_event()
			press(str(hit.collider.get_meta("key")))

func handle_key(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo: return
	var key = ""
	if event.keycode >= KEY_0 and event.keycode <= KEY_9: key = str(event.keycode - KEY_0)
	elif event.keycode >= KEY_KP_0 and event.keycode <= KEY_KP_9: key = str(event.keycode - KEY_KP_0)
	elif event.keycode in [KEY_ENTER, KEY_KP_ENTER]: key = "OK"
	elif event.keycode == KEY_BACKSPACE: key = "BACK"
	elif event.keycode in [KEY_C, KEY_DELETE]: key = "C"
	if key != "":
		get_viewport().set_input_as_handled()
		press(key)
