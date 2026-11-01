class_name KalaEnemy
extends CharacterBody3D

signal defeated(kind: String)
signal damage_player(amount: float)
signal bind_player
signal spawn_projectile(origin: Vector3, direction: Vector3, kind: String)
signal ritual_summon
signal phase_changed(next: int)
@export_enum("overseer", "hands", "tumbal", "chase", "ash") var kind = "overseer"
var player: KalaPlayer
var level: KalaLevel
var hp = 60.0
var max_hp = 60.0
var phase = 1
var shield = false
var seals = [3, 3, 3]
var enabled = false
var elapsed = 0.0
var hit_timer = 1.7
var dash_timer = 4.5
var windup = 0.0
var dash_left = 0.0
var recovery = 1.5
var dash_direction = Vector3.ZERO
var nav_timer = 0.0
var path = PackedVector2Array()
var path_index = 0
var projectile_timer = 4.0
var bind_timer = 10.0
var ritual_timer = 10.0
var core_open = true
var gaze_bonus = 0.0
var stone = 0.0
var pause_time = 0.0
var visual: Node3D
var limbs: Array[Node3D] = []
var limb_rest: Array[Vector3] = []
var chase_progress = 0.0
var eye: MeshInstance3D
var target_offset = Vector3(0, 1.75, 0)
var stats: Dictionary
var hands_rig: RefCounted
var body_collision: CollisionShape3D
var last_target = Vector3.INF
var last_seen = Vector3.ZERO
var memory = 0.0
var searching = false
var stuck_seconds = 0.0
var avoid_left = 0.0
var avoid_side = 1.0
var scripted_motion = false
var light_exposure = 0.0
var disruption_left = 0.0
var pulse_immunity = 0.0
var reveal_marker: MeshInstance3D
const SPECS = {
	"overseer": {"hp": 60.0, "speed": 2.05, "dash": 9.0, "damage": 12.0, "seconds": 24.0, "label": "SI PENGAWAS"},
	"hands": {"hp": 180.0, "speed": 2.5, "dash": 10.5, "damage": 13.0, "seconds": 48.0, "label": "TANGAN-TANGAN"},
	"tumbal": {"hp": 260.0, "speed": 2.7, "dash": 11.5, "damage": 16.0, "seconds": 68.0, "label": "DANU / PEMEGANG"},
	"chase": {"hp": 180.0, "speed": 4.9, "dash": 4.9, "damage": 100.0, "seconds": 9999.0, "label": "PENGEJAR"},
	"ash": {"hp": 12.0, "speed": 1.65, "dash": 1.65, "damage": 6.0, "seconds": 1.0, "label": "ABU"}}

func _ready() -> void:
	add_to_group("light_enemies")
	collision_layer = 4
	collision_mask = 1
	stats = SPECS[kind]
	hp = stats.hp
	max_hp = hp
	_build_visual()
	if kind == "tumbal": begin_phase(1)
	if kind == "chase": recovery = 0
	last_seen = player.position if is_instance_valid(player) else position
	floor_snap_length = 0.48
	reveal_marker = MeshInstance3D.new(); reveal_marker.name = "RevealedWeakness"
	var ring = TorusMesh.new(); ring.inner_radius = 0.11; ring.outer_radius = 0.15; ring.rings = 16; ring.ring_segments = 8
	reveal_marker.mesh = ring; reveal_marker.position = target_offset; reveal_marker.rotation.x = PI / 2
	var material = StandardMaterial3D.new(); material.albedo_color = Color("cabd8e"); material.emission_enabled = true; material.emission = Color("786f48")
	reveal_marker.material_override = material; reveal_marker.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(reveal_marker); reveal_marker.hide()

func _physics_process(delta: float) -> void:
	if not enabled or scripted_motion or not is_instance_valid(player): return
	elapsed += delta
	hit_timer -= delta
	pause_time = maxf(0, pause_time - delta)
	pulse_immunity = maxf(0, pulse_immunity - delta)
	disruption_left = maxf(0, disruption_left - delta)
	var illuminated = _update_light_response(delta)
	if kind == "chase":
		_update_pursuit(delta)
		return
	var difference = player.global_position - global_position
	difference.y = 0
	var distance = difference.length()
	var direction = difference.normalized()
	var target_yaw = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_yaw, minf(1, delta * 7))
	player.speed_multiplier = 1.0
	var aimed = illuminated
	if kind == "overseer":
		var gaze = _aim_dot() > 0.975 and _line_of_sight() and disruption_left <= 0
		if gaze:
			player.speed_multiplier = 0.52
			var gain = minf(delta * 2.8, minf(20 - gaze_bonus, 80 - hp))
			if gain > 0: hp += gain; gaze_bonus += gain
		stone = clampf(stone + (delta / 4.5 if gaze else -delta * 0.65), 0, 1)
		if stone > 0.88 and gaze: damage_player.emit(delta * 2)
	if kind == "tumbal":
		core_open = phase != 3 or fmod(elapsed, 7.0) < 4.5
		if shield:
			ritual_timer -= delta
			if ritual_timer <= 0:
				ritual_timer = 10
				hp = minf(max_hp, hp + max_hp * 0.2)
				ritual_summon.emit()
	if kind != "chase" and aimed and player.lamp.visible and player.cooldown <= 0:
		player.add_beam_heat(delta)
		if not shield and core_open:
			hp -= (9.0 if kind == "ash" else float(stats.hp) / float(stats.seconds)) * delta
		if hp <= 0:
			enabled = false
			defeated.emit(kind)
			return
	if kind == "hands" and phase == 1 and hp <= max_hp * 0.6:
		phase = 2
		phase_changed.emit(2)
	if kind == "tumbal" and not shield and phase < 3 and hp <= max_hp * (2.0 / 3 if phase == 1 else 1.0 / 3):
		hp = max_hp * (2.0 / 3 if phase == 1 else 1.0 / 3)
		begin_phase(phase + 1)
		if scripted_motion: return
	if kind == "ash" and fmod(elapsed, 8.0) < delta:
		max_hp += 2
		hp += 2
	velocity.x = 0
	velocity.z = 0
	if pause_time > 0: pass
	elif recovery > 0: recovery = maxf(0, recovery - delta)
	elif windup > 0:
		windup -= delta
		# Keep the rig's feet planted; attack anticipation belongs to the spine.
		visual.rotation.x = -0.08 if hands_rig == null else 0.0
		if windup <= 0:
			dash_left = 0.6
			dash_direction = direction
	elif dash_left > 0:
		dash_left -= delta
		velocity = dash_direction * float(stats.dash)
		if dash_left <= 0: recovery = 1.3; dash_timer = 4.4
	else:
		visual.rotation.x = lerpf(visual.rotation.x, 0, delta * 5)
		if distance > (0.8 if kind == "chase" else 1.8):
			var light_speed = 0.56 if disruption_left > 0 else 1.18 if kind == "hands" and light_exposure > 1.8 else 1.0
			_steer(delta, float(stats.speed) * (0.55 if shield else 1) * light_speed)
		if kind not in ["chase", "ash"]:
			dash_timer -= delta
			if dash_timer <= 0: windup = 0.95
	velocity.y = -0.2 if is_on_floor() else velocity.y - 20 * delta
	var previous = global_position
	move_and_slide()
	if hands_rig != null:
		var travelled = global_position - previous; travelled.y = 0
		hands_rig.animate(delta, travelled.length(), false, 0.65 if windup > 0 or dash_left > 0 else 0.0)
	else:
		if visual.has_method("animate_walk"):visual.animate_walk(elapsed*7,0.45 if velocity.length()>0.5 else 0.0)
		for i in range(limbs.size()): limbs[i].rotation.x = limb_rest[i].x + sin(elapsed * 7 + i * PI) * (0.45 if velocity.length() > 1 else 0.06)
	if distance < 1.35 and hit_timer <= 0 and pause_time <= 0:
		hit_timer = 1.7
		damage_player.emit(stats.damage)
	if kind in ["hands", "tumbal"] and phase >= 2:
		projectile_timer -= delta
		if projectile_timer <= 0:
			projectile_timer = 4.0
			spawn_projectile.emit(global_position + Vector3.UP * 1.2, direction, "hand" if kind == "hands" else "slime")
	if kind == "hands" and phase >= 2:
		bind_timer -= delta
		if bind_timer <= 0:
			bind_timer = 11
			if distance < 9: spawn_projectile.emit(global_position + Vector3.UP * 1.2, direction, "hand")

func _steer(delta: float, speed: float, destination = Vector3.INF) -> void:
	if destination == Vector3.INF: destination = player.global_position
	nav_timer -= delta
	if nav_timer <= 0 or destination.distance_to(last_target) > 1.2:
		nav_timer = 0.24 if kind == "chase" else 0.45
		last_target = destination
		path = level.actor_path(global_position, destination)
		path_index = 1 if path.size() > 1 else 0
	var goal = destination
	while path_index < path.size() and Vector2(global_position.x, global_position.z).distance_to(path[path_index]) < 0.42:
		path_index += 1
	if path_index < path.size():
		goal = Vector3(path[path_index].x, 0, path[path_index].y)
	var direction = goal - global_position
	direction.y = 0
	direction = direction.normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func _aim_dot() -> float:
	var vector = global_position + target_offset - player.camera.global_position
	return (-player.camera.global_basis.z).dot(vector.normalized())

func _line_of_sight() -> bool:
	var query = PhysicsRayQueryParameters3D.create(player.camera.global_position, global_position + target_offset, 1)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func beam_visible() -> bool:
	if global_position.distance_to(player.global_position) > 19 or _aim_dot() < 0.9 or not _line_of_sight(): return false
	if kind == "overseer":
		var toward = player.global_position - global_position
		toward.y = 0
		return global_basis.z.dot(toward.normalized()) >= 0.65
	return true

func _update_light_response(delta: float) -> bool:
	var lit = player.lamp_on and player.lamp.visible and player.cooldown <= 0 and beam_visible()
	var old = light_exposure
	light_exposure = clampf(light_exposure + delta * (1.0 if lit else -1.8), 0, 3)
	if is_instance_valid(reveal_marker):
		reveal_marker.visible = State.flag("lenteraOwned") and light_exposure > 0.45 and kind in ["overseer", "hands"]
		reveal_marker.scale = Vector3.ONE * (0.9 + sin(elapsed * 4) * 0.06)
	if lit and State.flag("lenteraOwned"):
		if old < 0.5 and light_exposure >= 0.5:
			get_tree().get_first_node_in_group("kala_player").get_parent().audio.effect("disrupt")
		match kind:
			"overseer": if light_exposure > 0.5: disruption_left = 0.3
			"hands": if light_exposure < 1.8: disruption_left = 0.22
			"ash":
				disruption_left = 0.45
				if light_exposure > 0.6: projectile_timer = maxf(projectile_timer, 0.6)
			"chase": disruption_left = 0.16
	# Timers decay outside the beam; no permanent state or position changes.
	return lit

func receive_pulse() -> void:
	if not enabled or scripted_motion or pulse_immunity > 0: return
	pulse_immunity = 3.0
	match kind:
		"overseer":
			pause_time = maxf(pause_time, 1.15); disruption_left = 1.8
			stone = maxf(0, stone - 0.45); windup = 0; dash_left = 0; recovery = 0.7
		"hands":
			pause_time = maxf(pause_time, 0.65); disruption_left = 1.1
			windup = 0; dash_left = 0; recovery = 0.5
		"ash": pause_time = maxf(pause_time, 1.5); disruption_left = 2.2
		"chase": pause_time = maxf(pause_time, 0.45); disruption_left = 0.8
		"tumbal":
			if not shield and core_open: pause_time = maxf(pause_time, 0.35)

func begin_phase(next: int) -> void:
	phase = next
	shield = true
	seals = [3, 3, 3]
	ritual_timer = 10
	recovery = 2.2
	for candle in level.candles:
		candle.get_node("Flame").visible = true
		candle.get_node("FireLight").visible = true
	phase_changed.emit(next)

func pull_seal(index: int) -> void:
	if kind != "tumbal" or not shield or seals[index] <= 0: return
	seals[index] -= 1
	if seals[index] == 0:
		level.candles[index].get_node("Flame").visible = false
		level.candles[index].get_node("FireLight").visible = false
		State.data.sanity = minf(100, State.data.sanity + 4)
	if seals == [0, 0, 0]: shield = false; recovery = 2.5; elapsed = 0

func _build_visual() -> void:
	var model = "hands" if kind == "chase" else "overseer" if kind == "ash" else kind
	visual = preload("res://scripts/systems/model_factory.gd").make(model) as Node3D
	visual.name = "AuthoredModel"
	add_child(visual)
	if kind in ["hands", "chase", "tumbal"]:
		hands_rig = preload("res://scripts/enemies/final_rig.gd").new() if kind == "tumbal" else preload("res://scripts/enemies/hands_rig.gd").new()
		hands_rig.bind(visual)
		hands_rig.animate(0, 0)
	if kind == "ash": visual.scale *= 0.43
	target_offset = Vector3(0, 2.5, 0.2) if kind == "overseer" else Vector3(0,1.08,0.1) if kind=="ash" else Vector3(0, 1.65, 0)
	for joint in visual.find_children("*", "Node3D", true, false):
		if visual.has_method("animate_walk"):break
		if hands_rig != null: break
		if joint is MeshInstance3D: continue
		if absf(joint.position.x) > 0.18 and joint.position.y > 0.4 and joint.position.y < 2.3:
			limbs.append(joint)
			limb_rest.append(joint.rotation)
	var collision = CollisionShape3D.new()
	body_collision = collision
	var shape = CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 2.4
	collision.shape = shape
	collision.position.y = 1.2
	add_child(collision)

func _update_pursuit(delta: float) -> void:
	var low = level.in_vent(position) or _low_ceiling()
	var shape = body_collision.shape as CapsuleShape3D
	shape.height = 1.05 if low else 2.4
	body_collision.position.y = shape.height * 0.5
	var previous = position
	velocity.x = 0; velocity.z = 0
	if pause_time <= 0:
		var distance = position.distance_to(player.position)
		var sight_query = PhysicsRayQueryParameters3D.create(position + Vector3.UP * (0.7 if low else 1.5), player.position + Vector3.UP * (0.55 if player.crouched else 1.25), 1)
		var sees = get_world_3d().direct_space_state.intersect_ray(sight_query).is_empty() and distance < 33
		var hears = player.velocity.length() > 0.8 and distance < (16 if player.sprinting else 5 if not player.crouched else 1.8)
		if sees or hears:
			last_seen = player.position; memory = 7.0
		else: memory = maxf(0, memory - delta)
		searching = not sees and not hears and memory <= 0
		var destination = last_seen
		if searching and position.distance_to(last_seen) < 1.5:
			# Search around the last heard location instead of knowing a hidden player.
			var candidate = last_seen + Vector3(sin(elapsed * 0.4) * 5, 0, cos(elapsed * 0.4) * 4)
			if level.safety.contains(candidate, 0.5): destination = candidate
		var speed = 2.45 if searching else 5.4 if distance > 24 else 4.6
		if disruption_left > 0: speed *= 0.75
		speed *= level.pursuit_speed(position)
		_steer(delta, speed, destination)
		if avoid_left > 0:
			avoid_left -= delta
			var sideways = Vector3(velocity.x, 0, velocity.z).rotated(Vector3.UP, avoid_side * 0.9)
			var raised = global_transform; raised.origin.y += 0.12
			if not test_move(raised, sideways * delta * 2): velocity.x = sideways.x; velocity.z = sideways.z
		var direction = Vector3(velocity.x, 0, velocity.z)
		if direction.length() > 0.01: rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), minf(1, delta * 7))
	velocity.y = -0.2 if is_on_floor() else velocity.y - delta * 20
	preload("res://scripts/systems/body_motion.gd").move(self, delta, 0.44)
	if not level.safety.contains(position, 0.15): position = previous; velocity = Vector3.ZERO; nav_timer = 0
	var travel = Vector2(position.x - previous.x, position.z - previous.z).length()
	if pause_time <= 0 and travel < 0.004 and Vector2(velocity.x, velocity.z).length() > 0.5:
		stuck_seconds += delta
		if stuck_seconds > 0.6:
			nav_timer = 0; avoid_left = 0.65; avoid_side *= -1; stuck_seconds = 0
	else: stuck_seconds = 0
	if hands_rig != null: hands_rig.animate(delta, previous.distance_to(position), low, 0.6 if position.distance_to(player.position) < 5 else 0.12)
	if position.distance_to(player.position) < 1.3 and hit_timer <= 0 and pause_time <= 0:
		hit_timer = 2
		damage_player.emit(100)

func _low_ceiling() -> bool:
	var forward = player.position - position; forward.y = 0
	if forward.length_squared() > 0.01: forward = forward.normalized()
	var standing = CapsuleShape3D.new(); standing.radius = 0.39; standing.height = 2.4
	var check = PhysicsShapeQueryParameters3D.new(); check.shape = standing; check.collision_mask = 1
	check.transform = Transform3D(Basis.IDENTITY, position + forward * 0.60 + Vector3.UP * 1.27)
	check.exclude = [get_rid()]; check.margin = 0.005
	if not get_world_3d().direct_space_state.intersect_shape(check, 1).is_empty(): return true
	for offset in [Vector3.ZERO, Vector3(0.25, 0, 0), Vector3(-0.25, 0, 0), Vector3(0, 0, 0.25), Vector3(0, 0, -0.25)]:
		var origin = position + offset + Vector3.UP * 0.5
		var query = PhysicsRayQueryParameters3D.create(origin, position + offset + Vector3.UP * 2.52, 1)
		if not get_world_3d().direct_space_state.intersect_ray(query).is_empty(): return true
	return false
