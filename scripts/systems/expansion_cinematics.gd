extends RefCounted

var host: Node3D
var timeline: Node
var id = ""
var root: Node3D
var prop: Node3D
var prop_pose: Transform3D
var actor: Node3D
var monster: Node3D
var hands: RefCounted
var light: OmniLight3D
var shadow: Node3D
var path: Array[Vector3] = []
var progress = 0.0
var flashed = false
var origin = Vector3.ZERO
var start_point = Vector3.ZERO
var throw_end = Vector3.ZERO
var burst: Node3D
var camera_offset = Vector2.ZERO
var enemy_path = PackedVector2Array()
var enemy_index = 0
var enemy_clock = 0.0
var rescue_button: Node3D
const RESCUE_BUTTON = Vector3(84.28, -6.4, -128.92)

func handles(value: String) -> bool:
	return value in ["discovery", "pickup", "flash_break", "ambush", "rescue", "reversion"]

func prepare(value: String) -> void:
	id = value
	progress = 0; flashed = false; enemy_clock = 0; enemy_index = 0
	path.clear()
	root = Node3D.new()
	root.name = "CinematicProps"
	host.level.add_child(root)
	origin = host.player.position
	match id:
		"discovery":
			host.player.lamp_on = false
		"pickup":
			State.set_flag("lenteraOwned")
			host.player.tool_raising = true
			host.player.lamp_on = false
			prop = host.level.find_child("LenteraPickup", true, false)
			prop_pose = prop.transform
			start_point = prop.global_position
			prop.visible = true
			State.add_note("lentera_inscription", "LENTERA-G / NOMOR INVENTARIS", "Gulungan inspeksi dan penyelamatan. Ada inisial R. di bawah nomor inventaris yang dihapus.")
		"flash_break":
			actor = _model("flashlight")
			actor.global_transform = host.player.viewmodel.get_node("Handle").global_transform
			start_point = actor.global_position
			# Freeze the throw in world space before the camera follows it. Using
			# the current camera basis here every frame creates a spinning target.
			var forward = -host.player.camera.global_basis.z
			forward.y = 0; forward = forward.normalized()
			var right = forward.cross(Vector3.UP)
			throw_end = host.player.global_position + forward*2.8 + right*0.6
			throw_end.y = start_point.y
			var space = host.get_world_3d().direct_space_state
			var obstruction = space.intersect_ray(PhysicsRayQueryParameters3D.create(start_point,throw_end,1))
			if not obstruction.is_empty(): throw_end = obstruction.position-forward*0.18
			var floor_hit = space.intersect_ray(PhysicsRayQueryParameters3D.create(throw_end+Vector3.UP,throw_end-Vector3.UP*5,1))
			throw_end.y = floor_hit.position.y+0.08 if not floor_hit.is_empty() else host.player.global_position.y+0.08
			camera_offset = Vector2(host.player.camera.h_offset,host.player.camera.v_offset)
			burst = preload("res://scripts/systems/flashlight_burst.gd").new();root.add_child(burst);burst.global_position=throw_end
			actor.visible = false
			light = OmniLight3D.new()
			light.light_color = Color("ffca7e")
			light.omni_range = 8
			light.light_energy = 0
			root.add_child(light)
		"ambush":
			var watcher = host.level.get_node_or_null("RelayWatcher")
			if watcher != null: watcher.actor.visible = false
			timeline._open_stairs()
			path.append(origin)
			if origin.y < -2.0:
				path.append(Vector3(12, -4, 50.0))
				path.append(Vector3(12, -4, 51.8))
			else:
				for point in host.level.actor_path(origin, Vector3(0, 0, -15)): path.append(Vector3(point.x, 0, point.y))
				path.append(Vector3(0, 0, -16.0))
				path.append(Vector3(0, 0, -25.1))
			var distance = 0.0
			for i in range(1, path.size()): distance += path[i - 1].distance_to(path[i])
			timeline.clips.ambush.steps[2][1] = maxf(0.8, distance / 5.2 - 0.85 + 0.12)
			monster = _model("hands")
			monster.position = Vector3(12, -4, 43) if origin.y < -2.0 else Vector3(0, 0, maxf(-6, origin.z + 8))
			hands = preload("res://scripts/enemies/hands_rig.gd").new()
			hands.bind(monster)
			host.audio.play_music("chase")
			host.audio.effect("impact")
		"rescue":
			host.player.position = Vector3(87, -7.95, -124)
			if is_instance_valid(host.boss): host.boss.visible = false
			monster = _model("hands")
			monster.position = Vector3(80, -8, -124)
			hands = preload("res://scripts/enemies/hands_rig.gd").new()
			hands.bind(monster)
			shadow = _model("actor_daisy")
			shadow.position = Vector3(84.29, -7.95, -121.5)
			shadow.rotation.y = PI / 2
			shadow.scale = Vector3.ONE * 1.4
			var black = StandardMaterial3D.new()
			black.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			black.albedo_color = Color("020403")
			for mesh in shadow.find_children("*", "MeshInstance3D", true, false): mesh.material_override = black; mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			shadow.visible = false
			# The button is on the wall behind the player's direction of escape.
			rescue_button = Node3D.new(); rescue_button.name = "DaisySafetyButton"; rescue_button.position = RESCUE_BUTTON; rescue_button.rotation.y = PI / 2; root.add_child(rescue_button)
			var g = preload("res://scripts/systems/geometry.gd")
			g.box(rescue_button, Vector3.ZERO, Vector3(0.42, 0.55, 0.06), g.material("steel", Color("777a6d")))
			var cap = g.cylinder(rescue_button, Vector3(0, 0, 0.07), 0.115, 0.09, g.material("plain", Color("bd4a35"))); cap.rotation.x = PI / 2; cap.name = "ButtonCap"
			g.sign_text(root, "PENGAMAN\nTEKAN UNTUK MENUTUP", RESCUE_BUTTON + Vector3(0.08, 0.61, 0), 16, PI / 2)
			prop = host.level.find_child("RescueShutter", true, false)
			if prop != null: prop_pose = prop.transform
		"reversion":
			if is_instance_valid(host.boss): host.boss.visible = false
			origin = Vector3(clampf(host.story_origin.x, -9, 9), 0, clampf(host.story_origin.z, -10, 6))
			monster = _model("tumbal")
			monster.position = origin
			timeline._spawn_actor(origin, 0)
			actor = timeline.actor
			actor.visible = false
			host.player.position = origin + Vector3(0, 0.05, 4.8)
			host.player.rotation.y = 0
			host.player.camera.look_at(origin + Vector3.UP * 1.8)
			timeline._open_stairs()

func _model(name_value: String) -> Node3D:
	var node = preload("res://scripts/systems/model_factory.gd").make(name_value) as Node3D
	root.add_child(node)
	return node

func animate(time: float, delta: float) -> void:
	match id:
		"discovery":
			_look(Vector3(1, 6.8, 10.7) if time < 2.1 else Vector3(3, 1.28, 12), delta * 2.7)
		"pickup":
			var u = clampf(time / 1.05, 0, 1)
			var ease = smoothstep(0.0, 1.0, u)
			var destination = host.player.camera.to_global(Vector3(0.32, -0.255, -0.66))
			prop.global_position = start_point.lerp(destination, ease)
			prop.rotation.x = -ease * 0.35
			prop.rotation.z = 0.2 - ease * 0.245
			prop.scale = Vector3.ONE * (1.7 - ease * 0.7)
		"flash_break":
			if time >= 4.0:
				if not State.flag("oldFlashBroken"): State.set_flag("oldFlashBroken")
				host.player.lamp_on = false
				var age = time - 4
				actor.global_position = start_point.lerp(throw_end, clampf(age / 0.78, 0, 1))
				actor.position.y += sin(clampf(age / 0.78, 0, 1) * PI) * 0.7
				actor.rotation = Vector3(age * 9, 0.3, age * 4)
				actor.visible = age < 1.05
				light.position = actor.position
				light.light_energy = 0.7 if age < 1.05 else 0.0
				_look(throw_end+Vector3.UP*0.20, 1.0-exp(-delta*3.0))
				if age >= 1.05 and not flashed:
					flashed = true;burst.trigger(host.player.camera);host.audio.effect("flash_burst")
				var trauma = maxf(0.0,1.0-(age-1.05)/0.62) if age>=1.05 else 0.0
				host.player.camera.h_offset=camera_offset.x+sin(age*83)*trauma*trauma*0.045
				host.player.camera.v_offset=camera_offset.y+sin(age*109)*trauma*trauma*0.030
		"ambush":
			var before = monster.position
			if time > 1.75:
				progress += delta * 5.2
				host.player.position = _point(progress)
				_look(_point(progress + 2.0) + Vector3.UP * 1.45, delta * 5.8)
			else: _look(monster.position + Vector3.UP * 1.78, delta * 3.2)
			enemy_clock -= delta
			if enemy_clock <= 0:
				enemy_clock = 0.3
				enemy_path = host.level.actor_path(monster.position, host.player.position)
				enemy_index = 1 if enemy_path.size() > 1 else 0
			if monster.position.distance_to(host.player.position) > 3.2 and enemy_index < enemy_path.size():
				var goal = Vector3(enemy_path[enemy_index].x, monster.position.y, enemy_path[enemy_index].y)
				monster.position = monster.position.move_toward(goal, delta * 5.0)
				if monster.position.distance_to(goal) < 0.1: enemy_index += 1
			var toward = host.player.position - monster.position
			monster.rotation.y = atan2(toward.x, toward.z)
			hands.animate(delta, before.distance_to(monster.position), false, 0.45)
		"rescue":
			var fall = clampf(time / 2.6, 0, 1)
			host.player.get_node("Head").position.y = 1.62 - fall * 0.8
			host.player.camera.rotation.z = sin(time * 1.7) * 0.028 + fall * 0.075
			var previous = monster.position
			var recoil = clampf((time - 8.45) / 0.45, 0, 1)
			monster.position = Vector3(80 + clampf(time / 3.6, 0, 1) * 5.8 - recoil * 4.2, -8, -124)
			monster.rotation.y = PI / 2
			monster.visible = time < 10.1
			hands.animate(delta, previous.distance_to(monster.position), false, clampf((time - 1.8) / 2, 0, 1))
			shadow.visible = time > 5.2 and time < 12.1
			shadow.position.z = lerpf(-121.5, -128.0, smoothstep(5.2, 7.9, time))
			if time < 7.8: shadow.animate_walk(time * 8, 0.27 * (1 - smoothstep(7.2, 7.8, time)))
			var press = smoothstep(7.8, 8.55, time) * (1 - smoothstep(9.1, 9.8, time))
			if rescue_button != null: rescue_button.get_node("ButtonCap").position.z = 0.07 - press * 0.045
			if time >= 7.8: shadow.reach_world(rescue_button.get_node("ButtonCap").global_position, press, delta)
			_look(monster.position + Vector3.UP * 1.35 if time < 5.2 else RESCUE_BUTTON + Vector3(0.35, 0, 0) if time < 9.7 else Vector3(84.1, -6.35, -124), delta * 2.4)
			if prop != null: prop.position.y = -3.6 - clampf((time - 8.7) / 0.5, 0, 1) * 2.65
			if time > 9.2 and not flashed: flashed = true; host.audio.effect("impact")
			host.ui.fade.color.a = clampf((time - 13) / 1.4, 0, 1)
		"reversion":
			monster.scale = Vector3.ONE * maxf(0.12, 1 - clampf(time / 2.9, 0, 1) * 0.88)
			monster.visible = time < 2.8
			actor.visible = time > 1.7 and time < 12
			actor.scale = Vector3.ONE * clampf((time - 1.7) / 1.1, 0.15, 1)
			if time > 6.3:
				actor.position = origin.lerp(Vector3(0, 0, -13.4), clampf((time - 6.3) / 2.2, 0, 1))
				actor.rotation.y = PI
				if time > 8.5: actor.position = Vector3(0, 0, -13.4 - clampf((time - 8.5) / 3.3, 0, 1) * 9.4)
				timeline._gait(time * 14, 0.55)
			_look(actor.position + Vector3.UP * 1.5, delta * 2)

func _point(distance: float) -> Vector3:
	for i in range(1, path.size()):
		var length = path[i - 1].distance_to(path[i])
		if distance < length: return path[i - 1].lerp(path[i], distance / maxf(length, 0.001))
		distance -= length
	return path.back()

func _look(point: Vector3, amount: float) -> void:
	var direction = point - host.player.camera.global_position
	# Hold the final view after a short route ends directly under the camera.
	if direction.length_squared() < 0.001 or absf(direction.normalized().dot(Vector3.UP)) > 0.999: return
	var previous = host.player.camera.global_basis.get_rotation_quaternion()
	host.player.camera.look_at(point)
	var target = host.player.camera.global_basis.get_rotation_quaternion()
	host.player.camera.global_basis = Basis(previous.slerp(target, clampf(amount, 0, 1)))

func finish() -> String:
	match id:
		"pickup": host.player.lamp_on = true
		"flash_break": State.set_flag("oldFlashBroken"); host.player.lamp_on = false
		"ambush": State.set_flag("handsPursuitStarted"); return "pursuit"
		"rescue":
			State.set_flag("handsPursuitComplete")
			State.set_flag("daisyRescueButtonPressed")
			return "production"
		"reversion": State.set_flag("danuHumanReturned"); timeline._open_stairs()
	return ""

func clear() -> void:
	if id == "flash_break":
		host.player.camera.h_offset=camera_offset.x;host.player.camera.v_offset=camera_offset.y
	if is_instance_valid(prop):
		prop.transform = prop_pose
		if id == "pickup": prop.visible = not State.flag("lenteraOwned")
	prop = null
	if is_instance_valid(root): root.queue_free()
	root = null; actor = null; monster = null; hands = null; light = null; shadow = null; rescue_button = null; burst = null
	host.player.tool_raising = false
	host.player.get_node("Head").position.y = 1.62
	host.ui.fade.color.a = 0
