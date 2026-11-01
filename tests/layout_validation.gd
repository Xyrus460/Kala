extends Node

var checks = 0
var failures = 0
var game: Node3D

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures += 1; push_error("LAYOUT FAIL: " + label)
	else: print("LAYOUT PASS: " + label)

func _ready() -> void:
	State.save_enabled = false
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.test_mode = true
	for id in KalaLevel.reference_data().rooms:
		State.reset()
		game.playing = true
		game.ui.close_panel()
		await game.enter_room(id, false, false)
		game.player.active = false
		if is_instance_valid(game.boss): game.boss.enabled = false
		await get_tree().physics_frame
		var level: KalaLevel = game.level
		var data: Dictionary = KalaLevel.reference_data().rooms[id]
		check(level.width == data.width and level.depth == data.depth, id + " exact authored dimensions")
		check(level.spawn.distance_to(Vector3(data.spawn[0], data.spawn[1], data.spawn[2])) < 0.01, id + " authored spawn")
		var floor_query = PhysicsRayQueryParameters3D.create(level.spawn + Vector3.UP * 0.3, level.spawn - Vector3.UP * 0.8, 1)
		if id == "street" and game.get_world_3d().direct_space_state.intersect_ray(floor_query).is_empty():
			for mesh in level.get_node("SourceWorld").find_children("*", "MeshInstance3D", true, false):
				var aabb: AABB = mesh.global_transform * mesh.get_aabb()
				if aabb.position.x < level.spawn.x and aabb.end.x > level.spawn.x and aabb.position.z < level.spawn.z and aabb.end.z > level.spawn.z:
					print("STREET FLOOR DEBUG ", mesh.name, " ", aabb, " bodies=", mesh.find_children("*", "StaticBody3D", true, false).map(func(b): return b.collision_layer))
		check(not game.get_world_3d().direct_space_state.intersect_ray(floor_query).is_empty(), id + " spawn has physical floor")
		var count = level.get_node("SourceWorld").find_children("*", "MeshInstance3D", true, false).size()
		print("SOURCE MESH NODES ", id, " ", count)
		for object in get_tree().get_nodes_in_group("interactables"):
			if not level.is_ancestor_of(object) or object.tool_only or not object.available(): continue
			check(reachable(object), id + " aim access: " + object.caption)
		if id == "school":
			check(level.get_node("NPC_Sari").female and level.get_node("NPC_Sari").skeleton!=null, "Sari uses imported female character with a skirt")
			check(level.get_node("NPC_Sari").find_child("SariHead",true,false)!=null, "Sari has the imported styled hair and face")
		if id == "relay":
			check(level.marks.size() == 3 and level.marks.all(func(node): return node.is_inside_tree()), "three relay marks are live native nodes")
		if id == "pursuit":
			check(level.find_child("VentGrate", true, false) != null, "original vent gate present")
			check(level.find_child("FanBlades", true, false) != null, "original machine fan present")
			check(level.in_vent(Vector3(40, -4, -90)), "descending vent uses crouch")
		if id == "ritual":
			check(level.candles.size() == 3 and level.candles.all(func(node): return node.get_node_or_null("Flame") != null), "three actual candle meshes linked")
	game.audio.shutdown()
	await get_tree().create_timer(0.2).timeout
	game.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	print("KALA LAYOUT: %d checks, %d failures" % [checks, failures])
	Node.print_orphan_nodes()
	get_tree().quit(0 if failures == 0 else 1)

func reachable(object: KalaInteractable) -> bool:
	var space = game.get_world_3d().direct_space_state
	for radius in [1.05, 1.7, 2.2]:
		for step in range(24):
			var angle = float(step) * TAU / 24
			var eye_y = floorf(object.global_position.y / 3.4) * 3.4 + 1.62 if game.level.room_id == "school" else 1.62
			if game.level.room_id == "relay" and object.global_position.y < -1: eye_y = -4.0 + 1.62
			var origin = Vector3(object.global_position.x + cos(angle) * radius, eye_y, object.global_position.z + sin(angle) * radius)
			var ray = PhysicsRayQueryParameters3D.create(origin, object.global_position, 3)
			ray.collide_with_areas = true
			var hit = space.intersect_ray(ray)
			if not hit.is_empty() and hit.collider == object: return true
	return false
