class_name KalaPlayer
extends CharacterBody3D

signal interaction_requested(target: KalaInteractable, tool: bool)
signal journal_requested
signal pause_requested
signal footstep
@onready var camera: Camera3D = $Head/Camera3D
@onready var lamp: SpotLight3D = $Head/Camera3D/Flashlight
@onready var viewmodel: Node3D = $Head/Camera3D/Viewmodel
@onready var ray: RayCast3D = $Head/Camera3D/InteractionRay
var active = false
var lamp_on = false
var heat = 0.0
var cooldown = 0.0
var speed_multiplier = 1.0
var bound = false
var bind_grace = 0.0
var struggle = 0
var time = 0.0
var step_distance = 0.0
var target: KalaInteractable
var cable: MeshInstance3D
var claw_muzzle: Marker3D
var claw_head: Node3D
var claw_head_rest=Transform3D.IDENTITY
var reach_time = 0.0
var reach_point = Vector3.ZERO
var anchored = false
var last_safe_position = Vector3.ZERO
var tool_raising = false
var crouched = false
var sprinting = false
var noise = 1.0
var pulse_cooldown = 0.0
var pulse_flash = 0.0
var equip_blend = 1.0
var reveal_tick = 0.0

func _ready() -> void:
	add_to_group("kala_player")
	$Collider.shape = $Collider.shape.duplicate()
	floor_snap_length = 0.45
	_build_viewmodel()
	cable = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.012
	mesh.bottom_radius = 0.012
	mesh.radial_segments = 6
	cable.mesh = mesh
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color("777d68")
	cable.material_override = mat
	add_child(cable)
	cable.top_level = true
	cable.visible = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_requested.emit()
		return
	if event.is_action_pressed("journal"):
		journal_requested.emit()
		return
	if not active: return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		look(event.relative)
	if event.is_action_pressed("flashlight"):
		if lamp_available():
			lamp_on = not lamp_on
			get_parent().audio.effect("click")
	if event.is_action_pressed("pulse"): trigger_pulse()
	if event.is_action_pressed("interact"):
		if bound:
			struggle += 1
			if struggle >= 7: release_bind()
		elif target != null and not target.tool_only and camera.global_position.distance_to(target.global_position) <= 2.7: interaction_requested.emit(target, false)
	if event.is_action_pressed("claw") and can_use_claw():
		if bound:
			release_bind()
		elif reach_time > 0:
			reach_time = 0
			anchored = false
		else:
			var combat: Dictionary = get_parent().claw_combat_target(camera.global_position, -camera.global_basis.z)
			var target_distance = camera.global_position.distance_to(target.global_position) if is_instance_valid(target) else INF
			if not combat.is_empty() and combat.distance < target_distance:
				if not get_parent().resolve_claw_combat(combat): return
				reach_point = combat.point
			elif target != null:
				reach_point = target.global_position
				interaction_requested.emit(target, true)
			else:
				ray.force_raycast_update()
				reach_point = ray.get_collision_point() if ray.is_colliding() else camera.global_position - camera.global_basis.z * 12
				anchored = ray.is_colliding() and ray.get_collider() is StaticBody3D
			reach_time = 0.65 if not anchored else 8.0

func _physics_process(delta: float) -> void:
	if active:
		pulse_cooldown = maxf(0, pulse_cooldown - delta)
		pulse_flash = maxf(0, pulse_flash - delta)
		_update_reveal(delta)
	_update_equip(delta)
	lamp.visible = lamp_on and lamp_available() and cooldown <= 0
	if pulse_flash > 0: lamp.visible = true
	lamp.light_energy = (0.099 if State.data.room == "daisy" else 2.05) + pulse_flash * 19.0
	lamp.shadow_enabled = bool(State.settings.shadows)
	viewmodel.get_node("Handle").visible = lamp_available() and not State.flag("lenteraOwned")
	viewmodel.get_node("Claw").visible = State.flag("lenteraOwned") and not tool_raising
	if not active:
		cable.hide()
		if is_instance_valid(claw_head):claw_head.transform=claw_head_rest
		velocity = Vector3.ZERO
		return
	time += delta
	bind_grace = maxf(0, bind_grace - delta)
	update_lamp_temperature(delta)
	var look_axis = Input.get_axis("look_right", "look_left")
	rotation.y += look_axis * delta * 2.3
	var input = Input.get_vector("left", "right", "forward", "back")
	var direction = (global_basis * Vector3(input.x, 0, input.y)).normalized()
	var level = get_parent().get("level") as KalaLevel
	var forced_low = level != null and level.room_id == "pursuit" and level.in_vent(position)
	var wants_low = forced_low or Input.is_action_pressed("crouch")
	if not wants_low and crouched: wants_low = not can_stand()
	crouched = wants_low
	var body_shape = $Collider.shape as CapsuleShape3D
	body_shape.height = 0.98 if crouched else 1.75
	$Collider.position.y = body_shape.height / 2
	sprinting = Input.is_action_pressed("sprint") and not crouched and input.length() > 0
	noise = 0.18 if crouched else 1.8 if sprinting else 0.7
	var speed = (1.8 if crouched else 5.6 if sprinting else 3.4) * speed_multiplier
	if level != null and level.room_id == "pursuit": speed *= level.pursuit_speed(position)
	if bound: speed = 0
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if not is_on_floor(): velocity.y -= 20 * delta
	else: velocity.y = -0.2
	if anchored and reach_time > 0 and Input.is_action_pressed("sprint") and not bound:
		var pull = reach_point - global_position
		pull.y = 0
		if pull.length() > 1: velocity += pull.normalized() * 6.8
	var before = position
	preload("res://scripts/systems/body_motion.gd").move(self, delta)
	if level != null:
		if not level.safety.contains(position, 0.14) or position.y < level.safety.floor_limit(position) - 3.5:
			position = last_safe_position
			velocity = Vector3.ZERO
		elif is_on_floor(): last_safe_position = position
	step_distance += Vector2(position.x - before.x, position.z - before.z).length()
	if step_distance >= (2.5 if crouched else 1.7):
		step_distance = 0
		if not crouched: footstep.emit()
	$Head.position.y = lerpf($Head.position.y, 0.84 if crouched else 1.62, minf(1, delta * 12)) + sin(time * speed * 2) * (0.01 if input.length() > 0 and State.settings.head_bob else 0.0)
	ray.target_position.z = -32 if State.flag("lenteraOwned") else -2.5
	ray.force_raycast_update()
	target = null
	if ray.is_colliding():
		var hit = ray.get_collider()
		if hit is KalaInteractable and hit.available():
			if hit.tool_only or camera.global_position.distance_to(hit.global_position) <= 2.7 or (State.flag("lenteraOwned") and hit.action_id in ["puzzle", "recall"]):
				target = hit
	if target == null: target = _near_focus()
	if State.flag("lenteraOwned"):
		var tool_focus = _tool_focus()
		if tool_focus != null: target = tool_focus
	reach_time = maxf(0, reach_time - delta)
	cable.visible = can_use_claw() and reach_time > 0
	if cable.visible:
		var start = claw_muzzle.global_position
		var end = reach_point
		var difference = end - start
		cable.global_position = (start + end) * 0.5
		(cable.mesh as CylinderMesh).height=maxf(0.001,difference.length())
		cable.scale = Vector3.ONE
		cable.quaternion = Quaternion(Vector3.UP, difference.normalized())
		# The imported three-jaw head leaves its actual barrel and follows the cable.
		claw_head.global_position=end
		var forward=(end-start).normalized()
		claw_head.global_basis=Basis.looking_at(forward,Vector3.UP if absf(forward.dot(Vector3.UP))<0.98 else Vector3.RIGHT)
	elif is_instance_valid(claw_head):claw_head.transform=claw_head_rest
	viewmodel.get_node("Claw").visible = State.flag("lenteraOwned") and not tool_raising
	viewmodel.get_node("Handle").visible = lamp_available() and not State.flag("lenteraOwned")
	viewmodel.visible = State.data.room not in ["home", "school", "schoolyard", "neighborhood"]

func can_use_claw() -> bool:
	return active and State.flag("lenteraOwned") and State.data.room not in ["home", "school", "schoolyard", "neighborhood"]

func can_stand() -> bool:
	var standing = CapsuleShape3D.new(); standing.radius = 0.29; standing.height = 1.70
	var query = PhysicsShapeQueryParameters3D.new(); query.shape = standing
	query.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * 0.91)
	query.collision_mask = 17; query.exclude = [get_rid()]; query.margin = 0.005
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _tool_focus() -> KalaInteractable:
	# Match the source's tool candidate spheres and 0.75 m surface tolerance.
	# This lets the claw catch a mounted control on its metal housing.
	var origin = camera.global_position
	var direction = -camera.global_basis.z
	var query = PhysicsRayQueryParameters3D.create(origin, origin + direction * 32, 1)
	var surface = get_world_3d().direct_space_state.intersect_ray(query)
	var surface_distance = origin.distance_to(surface.position) if not surface.is_empty() else 32.0
	var nearest: KalaInteractable
	var best = 32.0
	for object in get_tree().get_nodes_in_group("interactables"):
		if not object.is_inside_tree() or not object.available(): continue
		if not object.tool_only and object.action_id not in ["puzzle", "recall"]: continue
		var difference: Vector3 = object.global_position - origin
		var along = difference.dot(direction)
		var side_squared = difference.length_squared() - along * along
		var radius = 0.5
		if along < 0 or side_squared > radius * radius: continue
		var distance = maxf(0, along - sqrt(maxf(0, radius * radius - side_squared)))
		if distance < best and surface_distance >= distance - 0.75:
			nearest = object
			best = distance
	return nearest

func _near_focus() -> KalaInteractable:
	# Aim assistance for small documents and pickups. Visibility is tested
	# against the actual world, so this never collects through a closed wall.
	var origin=camera.global_position
	var forward=-camera.global_basis.z
	var nearest: KalaInteractable
	var best=INF
	for object in get_tree().get_nodes_in_group("interactables"):
		if not object.is_inside_tree() or not object.available() or object.tool_only: continue
		if object.action_id not in ["item","note","evidence","chapter"]:continue
		var d: Vector3=object.global_position-origin
		if d.length()>2.7 or d.dot(forward)<=0:continue
		var off=d.cross(forward).length()
		if off>0.18:continue
		var surface=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(origin,object.global_position,1))
		if not surface.is_empty() and surface.position.distance_to(object.global_position)>0.10:continue
		var score=d.length()+off*3
		if score<best:best=score;nearest=object
	return nearest

func look(relative: Vector2) -> void:
	rotation.y -= relative.x * 0.0021 * float(State.settings.sensitivity)
	camera.rotation.x = clampf(camera.rotation.x - relative.y * 0.0021 * float(State.settings.sensitivity), -1.25, 1.25)

func lamp_available() -> bool:
	return not State.flag("oldFlashBroken") or State.flag("lenteraOwned")

func add_beam_heat(delta: float) -> void:
	# Cooling in _physics_process is compensated while the beam hits a target.
	heat = minf(1, heat + delta * 0.55)
	if heat >= 1: cooldown = 2.2

func update_lamp_temperature(delta: float) -> void:
	if cooldown > 0:
		cooldown = maxf(0, cooldown - delta)
		heat = maxf(0, heat - delta / 2.2)
	else: heat = maxf(0, heat - delta * 0.34)

func bind_player() -> void:
	if bound or bind_grace > 0: return
	bound = true
	struggle = 0

func release_bind() -> void:
	bound = false
	struggle = 0
	bind_grace = 1.4

func _build_viewmodel() -> void:
	var handle = load("res://assets/models/source/flashlight.glb").instantiate() as Node3D
	handle.name = "Handle"
	handle.position = Vector3(0.25, -0.245, -0.49)
	viewmodel.add_child(handle)
	var claw = load("res://assets/models/source/lentera.glb").instantiate() as Node3D
	claw.name = "Claw"
	claw.position = Vector3(0.32, -0.255, -0.66)
	claw.rotation.z = -0.045
	viewmodel.add_child(claw)
	claw_head=claw.find_child("LENTERA_G_three_jaw_head",true,false)
	claw_head_rest=claw_head.transform
	claw_muzzle=Marker3D.new();claw_muzzle.name="ClawMuzzle"
	# The housing aperture ends at -0.197; the jaw's own pivot (-0.235)
	# already sits beyond it and would leave a gap behind the deployed cable.
	claw_muzzle.position=Vector3(0,0,-0.197)
	claw.add_child(claw_muzzle)
	for group in [handle, claw]:
		for mesh in group.find_children("*", "MeshInstance3D", true, false): mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _update_equip(delta: float) -> void:
	if tool_raising: return # Pickup/break cinematics own their explicit animation.
	var raised = lamp_on or reach_time > 0 or pulse_flash > 0
	var target_blend = 1.0 if raised else 0.45 if State.flag("lenteraOwned") else 0.0
	equip_blend = lerpf(equip_blend, target_blend, 1.0-exp(-delta*10.0))
	viewmodel.position = Vector3(0, -(1.0 - equip_blend) * 0.43 + sin(time * 3) * 0.003, (1.0 - equip_blend) * 0.12)
	viewmodel.rotation = Vector3((1.0 - equip_blend) * -0.48, 0, sin(time * 3) * 0.012 + pulse_flash * 0.12)
	var claw = viewmodel.get_node_or_null("Claw")
	if claw != null:
		var reach = sin(minf(reach_time, 0.65) / 0.65 * PI)
		claw.position.z = -0.66 - reach * 0.12
		claw.rotation.x = -reach * 0.12 - pulse_flash * 0.25

func trigger_pulse() -> bool:
	if not can_use_claw() or tool_raising or pulse_cooldown > 0 or cooldown > 0 or heat > 0.74: return false
	pulse_cooldown = 6.0; pulse_flash = 0.28
	heat = minf(1, heat + 0.26)
	get_parent().audio.effect("pulse")
	for enemy in get_tree().get_nodes_in_group("light_enemies"):
		if not enemy.enabled or enemy.scripted_motion: continue
		var point: Vector3 = enemy.global_position + enemy.target_offset
		var to_target = point - camera.global_position
		if to_target.length() > 10.0 or (-camera.global_basis.z).dot(to_target.normalized()) < 0.65: continue
		var query = PhysicsRayQueryParameters3D.create(camera.global_position, point, 1)
		if get_world_3d().direct_space_state.intersect_ray(query).is_empty(): enemy.receive_pulse()
	return true

func _update_reveal(delta: float) -> void:
	reveal_tick += delta
	if reveal_tick < 0.1: return
	var step = reveal_tick; reveal_tick = 0
	for mark in get_tree().get_nodes_in_group("light_reveal"):
		var difference: Vector3 = mark.global_position - camera.global_position
		var valid = State.flag("lenteraOwned") and lamp_on and cooldown <= 0 and difference.length() < 12 and (-camera.global_basis.z).dot(difference.normalized()) > 0.93
		if valid:
			# Stop at the marked wall face rather than treating that wall as an occluder.
			var end: Vector3 = mark.global_position - difference.normalized() * 0.09
			valid = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(camera.global_position, end, 1)).is_empty()
		var amount = float(mark.get_meta("exposure", 0.0))
		var next = clampf(amount + step * (1.8 if valid else -1.0), 0, 1)
		if amount < 0.95 and next >= 0.95 and not mark.has_meta("heard"):
			get_parent().audio.effect("reveal"); mark.set_meta("heard", true)
		mark.set_meta("exposure", next); mark.modulate.a = next
