extends Node3D

var level: Node3D
var actor: Node3D
var rig: RefCounted
var stage = -1
var wait_time = 0.0
var watch_time = 0.0
var retreat = false
var inside = false
var door_key = ""
var waypoints: Array[Vector3] = []
var waypoint = 0

func _ready() -> void:
	level = get_parent()
	actor = get_node_or_null("WatcherBody")
	if actor == null:
		actor = preload("res://scripts/systems/model_factory.gd").make("hands")
		actor.name = "WatcherBody"
		add_child(actor)
	actor.visible = false
	rig = preload("res://scripts/enemies/hands_rig.gd").new()
	rig.bind(actor)
	# The source watcher has pale unlit eyes, visible even on the dark loft.
	var head = actor.find_child("HandsHead", true, false)
	if head != null:
		var eyes = StandardMaterial3D.new()
		eyes.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		eyes.albedo_color = Color("bacdbd")
		for mesh in head.find_children("*", "MeshInstance3D", true, false):
			var material = mesh.get_active_material(0)
			if material is BaseMaterial3D and material.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED:
				mesh.material_override = eyes

func _process(delta: float) -> void:
	var player = get_tree().get_first_node_in_group("kala_player") as KalaPlayer
	if player == null or not player.active or not State.flag("lenteraOwned") or State.flag("handsPursuitComplete"): return
	var wanted = 2 if State.flag("relayPower") else 1 if State.data.installed.has("generatorContact") else 0
	if not actor.visible:
		if wanted <= int(State.data.flags.get("handsWatchStage", -1)): return
		wait_time += delta
		if wait_time < 3: return
		stage = wanted
		actor.position = Vector3(-11, 3.7, -14.1) if stage == 0 else Vector3(11, 0, -15.7)
		var direction = (actor.global_position + Vector3.UP * 1.8 - player.camera.global_position).normalized()
		if (-player.camera.global_basis.z).dot(direction) > 0.72: return
		actor.visible = true
		watch_time = 0
		retreat = false; inside = false; waypoint = 0
		level.get_parent().get_parent().audio.effect("click")
	watch_time += delta
	var previous = actor.position
	if not retreat:
		var toward = player.global_position - actor.global_position
		actor.rotation.y = lerp_angle(actor.rotation.y, atan2(toward.x, toward.z), minf(1, delta * 2))
		var target = (actor.global_position + Vector3.UP * 1.9 - player.camera.global_position).normalized()
		var noticed = (-player.camera.global_basis.z).dot(target) > 0.94
		if (noticed and watch_time > 0.8) or toward.length() < 6 or watch_time > 8: _retreat()
	else:
		var door: Dictionary = level.all_doors.get(door_key, {})
		if not door.is_empty(): door.node.rotation.y = lerp_angle(door.node.rotation.y, 0.0 if inside else float(door.angle), minf(1, delta * 5))
		if not inside and (door.is_empty() or absf(door.node.rotation.y) > 1.1):
			var goal = waypoints[waypoint]
			var toward = goal - actor.position
			actor.position = actor.position.move_toward(goal, delta * 3.7)
			actor.rotation.y = lerp_angle(actor.rotation.y, atan2(toward.x, toward.z), minf(1, delta * 6))
			if actor.position.distance_to(goal) < 0.05:
				waypoint += 1
				inside = waypoint >= waypoints.size()
		if inside and (door.is_empty() or absf(door.node.rotation.y) < 0.06):
			actor.visible = false
			State.data.flags.handsWatchStage = stage
			wait_time = 0
			level.get_parent().get_parent()._save()
	rig.animate(delta, actor.position.distance_to(previous), false, 0.12)

func _retreat() -> void:
	retreat = true
	var side = -1 if stage == 0 else 1
	var floor_y = 3.7 if stage == 0 else 0.0
	var z = -14.8 if stage == 0 else -15.7
	door_key = "watch_left" if stage == 0 else "watch_right"
	waypoints = [Vector3(side * 13.1, floor_y, z), Vector3(side * 16.2, floor_y, z)]
