extends RefCounted

# Both areas remain in memory. A shared rigid rebase keeps existing story/local
# coordinates and saves valid while crossing the doorway without a loading cut.
var host: Node3D
var rooms: Dictionary = {}
const OFFSET = Vector3(0, 0, -46.3)

func clear(current: Node3D) -> void:
	for room in rooms.values():
		if is_instance_valid(room) and room != current: room.queue_free()
	rooms.clear()

func prepare(current: Node3D) -> void:
	if current.room_id not in ["school", "schoolyard"] or not State.flag("prologueVersion"): return
	rooms[current.room_id] = current
	var other = "school" if current.room_id == "schoolyard" else "schoolyard"
	var resident = load("res://scenes/levels/%s.tscn" % other).instantiate()
	host.get_node("Level").add_child(resident)
	resident.position = OFFSET; resident.rotation.y = PI
	resident.set_process(false)
	resident.passage_entered.connect(host._travel)
	rooms[other] = resident
	_open_boundary(current)
	_open_boundary(resident)

func _open_boundary(room: Node3D) -> void:
	var boundary = room.get_node("MapBoundary")
	# Safety volumes of the two resident areas overlap at the vestibule. Their
	# front perimeter colliders must have the same real opening as the meshes.
	for shape in boundary.get_children():
		if room.room_id == "school" and shape is MeshInstance3D: shape.hide()
		if not shape is CollisionShape3D or not shape.shape is BoxShape3D: continue
		var p: Vector3 = shape.position
		var size: Vector3 = shape.shape.size
		if room.room_id == "schoolyard" and p.z < -16.8 and absf(p.x) < 1.5 and size.z < 0.5: shape.disabled = true
		if room.room_id == "school" and p.z < -30 and absf(p.x) < 1.5 and size.z < 0.5: shape.disabled = true

func cross(id: String, save: bool) -> bool:
	if not rooms.has(id) or id == State.data.room: return false
	var previous: Node3D = host.level
	previous.set_process(false)
	var next: Node3D = rooms[id]
	var player = host.player
	player.position = Vector3(-player.position.x, player.position.y, -player.position.z) + OFFSET
	# E on an entrance/exit can be used before physically reaching the threshold.
	# Land on the destination side so the automatic crossing cannot bounce back.
	if id == "schoolyard" and (player.position.z < -15.9 or absf(player.position.x) > 1.2): player.position = Vector3(0, 0.05, -15.7)
	elif id == "school" and (player.position.z < -30.4 or absf(player.position.x) > 1.2): player.position = Vector3(0, 0.05, -30.25)
	player.rotation.y += PI
	player.last_safe_position = player.position
	player.target = null
	previous.position = OFFSET; previous.rotation.y = PI
	next.position = Vector3.ZERO; next.rotation = Vector3.ZERO
	host.level = next; State.data.room = id
	if id == "schoolyard" and State.flag("schoolDismissed"):
		for child in next.get_children():
			if child is DirectionalLight3D:
				child.rotation_degrees = Vector3(-27, -35, 0); child.light_color = Color("ffd5a1")
	host._sync_active()
	if save: host._save()
	if id == "school" and not State.flag("lessonSeen") and not host.test_mode:
		host.narrative.start("lesson")
	return true
