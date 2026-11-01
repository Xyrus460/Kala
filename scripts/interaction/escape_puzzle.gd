extends RefCounted

const PIECES = ["sun", "moon", "star"]
const LOCATIONS = [Vector3(-9.84, 0.73, 40.5), Vector3(10.18, 1.15, -16.8), Vector3(-10.18, 0.66, -36.5)]
const COLORS = [Color("e2b55a"), Color("a6c5d9"), Color("c9b9dd")]
const FURNITURE = [
	["operator", Vector3(-10.5, 0, 40.5), "desk", "sun", "Laci meja operator"],
	["piket", Vector3(10.5, 0, 31), "locker", "", "Loker piket"],
	["arsip", Vector3(-10.5, 0, 16), "cabinet", "", "Lemari arsip"],
	["istirahat", Vector3(10.5, 0, -16.8), "locker", "moon", "Loker shift malam"],
	["absen", Vector3(-10.5, 0, -21.0), "desk", "", "Laci absensi"],
	["perkakas", Vector3(-10.5, 0, -36.5), "cabinet", "star", "Lemari perkakas terakhir"],
	["suku_cadang", Vector3(10.5, 0, -44.5), "cabinet", "", "Lemari suku cadang"]]
var root: Node3D
var gate: StaticBody3D
var level: Node3D
var containers: Dictionary = {}

func setup(owner_level: Node3D) -> void:
	level = owner_level
	root = level.get_node_or_null("EscapePuzzle")
	# Baked 0.4 scenes contain the obsolete glowing pickup nodes. Migrate those
	# nodes before building the searchable version, including old Area3D rays.
	if root != null:
		for object in level.get_tree().get_nodes_in_group("interactables"):
			if level.is_ancestor_of(object) and (object.action_id in ["fragment", "escape_lock", "search"] or (object.action_id == "note" and object.parameter == "service_clue")): object.free()
		var old_sockets=level.all_doors.pursuitEscape.node.get_node_or_null("Sockets")
		if old_sockets!=null:old_sockets.free()
		root.free(); root = null
	if root == null:
		root = Node3D.new()
		root.name = "EscapePuzzle"
		root.set_meta("furniture_revision", 5)
		level.add_child(root)
		for i in range(3):
			var prop = Node3D.new()
			prop.name = PIECES[i]
			prop.position = LOCATIONS[i]
			prop.rotation.y = PI / 2 if LOCATIONS[i].x < 0 else -PI / 2
			root.add_child(prop)
			_icon(prop, PIECES[i], COLORS[i])
			prop.scale *= 0.65
			level.interact(LOCATIONS[i], "fragment", "Ambil potongan " + PIECES[i].capitalize(), PIECES[i], false, Vector3(0.85, 0.85, 0.85))
		for furniture in FURNITURE: _container(furniture)
		level.interact(Vector3(1.2, 1.15, 55), "note", "Catatan tiga shift", "service_clue")
		KalaGeometry.box(root, Vector3(1.2, 0.95, 55), Vector3(0.5, 0.08, 0.36), KalaGeometry.material("cotton", Color("bfb391")))
		var panel = Node3D.new()
		panel.name = "Sockets"
		panel.position = Vector3(11.89, 1.3, -57)
		panel.rotation.y = -PI / 2
		root.add_child(panel)
		var backing = MeshInstance3D.new()
		var board = BoxMesh.new()
		board.size = Vector3(1.1, 0.62, 0.09)
		backing.mesh = board
		var metal = StandardMaterial3D.new()
		metal.albedo_color = Color("232d2c")
		metal.metallic = 0.7
		metal.roughness = 0.7
		backing.material_override = metal
		panel.add_child(backing)
		for x in [-0.47,0.47]:
			for y in [-0.24,0.24]:
				var screw=KalaGeometry.cylinder(panel,Vector3(x,y,0.056),0.018,0.022,KalaGeometry.material("steel",Color("8a8a72")));screw.rotation.x=PI/2
		for i in range(3):
			var socket = Node3D.new()
			socket.name = PIECES[i]
			socket.position = Vector3((i - 1) * 0.35, 0, 0.07)
			socket.scale = Vector3.ONE * 0.5
			panel.add_child(socket)
			_icon(socket, PIECES[i], COLORS[i] * 0.25)
		var lock_target = level.interact(Vector3(11.53, 1.3, -57), "escape_lock", "Pasang Sun · Moon · Star", "", false, Vector3(0.32, 0.75, 1.2))
		# Both the visible lock and its interaction must inherit the real hinge.
		var hinge: Node3D = level.all_doors.pursuitEscape.node
		panel.reparent(hinge, true)
		lock_target.reparent(hinge, true)
		gate = StaticBody3D.new()
		gate.name = "LockBarrier"
		gate.position = Vector3(12.05, 1.55, -57)
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.22, 3.1, 2.65)
		collision.shape = shape
		gate.add_child(collision)
		root.add_child(gate)
	gate = root.get_node("LockBarrier")
	update(0.0)
	level._setup_navigation()

func _container(record: Array) -> void:
	var id = str(record[0]); var point: Vector3 = record[1]; var kind = str(record[2])
	var furniture = Node3D.new(); furniture.name = "Furniture_" + id; furniture.position = point
	furniture.rotation.y = PI / 2 if point.x < 0 else -PI / 2; root.add_child(furniture)
	var wood = ShaderMaterial.new(); wood.shader = preload("res://assets/materials/wood.gdshader"); wood.set_shader_parameter("wood_color", Color("726348"))
	var steel = KalaGeometry.material("steel", Color("4e5a50"))
	var width = 1.65 if kind == "desk" else 1.1
	var height = 0.86 if kind == "desk" else 2.05 if kind == "locker" else 1.3
	for side in [-1, 1]:
		KalaGeometry.box(furniture, Vector3(side * (width / 2 - 0.05), height / 2, 0), Vector3(0.08, height, 0.65), steel, true)
	for y in [0.05, height]: KalaGeometry.box(furniture, Vector3(0, y, 0), Vector3(width, 0.08, 0.7), wood, true)
	KalaGeometry.box(furniture, Vector3(0, height / 2, -0.32), Vector3(width, height, 0.06), steel, true)
	var lid = Node3D.new(); furniture.add_child(lid)
	if kind == "desk":
		lid.position = Vector3(0, 0.63, 0.12)
		KalaGeometry.box(lid, Vector3(0, -0.1, 0), Vector3(width - 0.2, 0.04, 0.55), wood)
		KalaGeometry.box(lid, Vector3(0, -0.025, 0.275), Vector3(width - 0.2, 0.13, 0.05), wood)
		for side in [-1, 1]: KalaGeometry.box(lid, Vector3(side * (width / 2 - 0.12), -0.025, 0), Vector3(0.04, 0.13, 0.55), wood)
		KalaGeometry.box(lid, Vector3(0, -0.025, 0.315), Vector3(0.25, 0.035, 0.04), steel)
	else:
		lid.position = Vector3(-width / 2 + 0.05, 0, 0.36)
		KalaGeometry.box(lid, Vector3(width / 2 - 0.05, height / 2, 0), Vector3(width - 0.1, height - 0.1, 0.06), wood)
		KalaGeometry.box(lid, Vector3(width - 0.24, height * 0.55, 0.06), Vector3(0.04, 0.13, 0.04), steel)
		if str(record[3]) != "":
			var shelf_y = 0.94 if str(record[3]) == "moon" else 0.45
			KalaGeometry.box(furniture, Vector3(0, shelf_y, 0), Vector3(width - 0.16, 0.04, 0.62), wood)
	containers[id] = {"node": lid, "kind": kind, "piece": str(record[3]), "origin": lid.position}
	var piece = str(record[3])
	if piece != "":
		var pickup = root.get_node(piece) as Node3D
		pickup.reparent(lid if kind == "desk" else furniture, false)
		pickup.position = Vector3(0, -0.065, 0.02) if kind == "desk" else Vector3(0, (0.94 if piece == "moon" else 0.45) + 0.19, 0.04)
		pickup.rotation = Vector3(-PI / 2, 0, 0) if kind == "desk" else Vector3.ZERO
		containers[id].pickup = pickup
		for target in level.get_children():
			if target is KalaInteractable and target.action_id == "fragment" and target.parameter == piece:
				target.reparent(pickup, false)
				target.position = Vector3.ZERO
				target.scale = Vector3.ONE / pickup.scale
				target.get_child(0).shape.size = Vector3(0.48, 0.38, 0.40)
	var target = point + Vector3(0.58 if point.x < 0 else -0.58, 0.7 if kind != "locker" else 1.25, 0)
	level.interact(target, "search", "Buka dan periksa · " + str(record[4]), id, false, Vector3(0.7, 1.2, 1.45))
	level.nav_extra.append(Rect2(point.x - 0.43, point.z - width / 2, 0.86, width))

func search(id: String) -> String:
	if not containers.has(id): return ""
	State.set_flag("searched_" + id)
	for object in level.get_children():
		if object is KalaInteractable and object.action_id == "search" and object.parameter == id: object.collision_layer = 0
	var piece = str(containers[id].piece)
	if piece != "":
		State.set_flag("fragmentRevealed_" + piece)
		for object in level.get_tree().get_nodes_in_group("interactables"):
			if level.is_ancestor_of(object) and object.action_id == "fragment" and object.parameter == piece: object.collision_layer = 2
		return "Ada potongan %s di dalam. Ambil dengan E%s." % [piece.capitalize(), "; Ctrl untuk melihat laci bawah" if piece != "moon" else ""]
	return {"piket": "Loker kosong. Ada catatan: ‘Shift malam menaruhnya setelah sekat keempat.’", "arsip": "Hanya kuitansi. Sun disimpan di meja operator pertama.", "absen": "Di buku absen tertulis: ‘Star — lemari perkakas sebelum pintu servis.’", "suku_cadang": "Lemari ini kosong. Lemari perkakas yang dicari ada di sisi seberang."}.get(id, "Kosong.")

func update(delta: float) -> void:
	var opened = State.flag("escapePuzzleSolved")
	gate.collision_layer = 0 if opened else 1
	for i in range(3):
		var pickup = root.find_child(PIECES[i], true, false)
		pickup.visible = State.flag("fragmentRevealed_" + PIECES[i]) and not State.owns("fragment_" + PIECES[i])
		var socket = level.all_doors.pursuitEscape.node.get_node("Sockets/" + PIECES[i]) as Node3D
		for mesh in socket.get_children():
			if mesh is MeshInstance3D:
				mesh.material_override.emission_energy_multiplier = 0.6 if State.owns("fragment_" + PIECES[i]) else 0.02
	for id in containers:
		var record: Dictionary = containers[id]
		var opened_container = State.flag("searched_" + id)
		if record.kind == "desk": record.node.position.z = lerpf(record.node.position.z, record.origin.z + (0.48 if opened_container else 0.0), minf(1, delta * 6))
		else: record.node.rotation.y = lerp_angle(record.node.rotation.y, -1.65 if opened_container else 0.0, minf(1, delta * 5))
	if level.all_doors.has("pursuitEscape"):
		var door = level.all_doors.pursuitEscape
		door.node.rotation.y = lerp_angle(door.node.rotation.y, float(door.angle) if opened else 0.0, minf(1, delta * 4))

func missing() -> Array[String]:
	var result: Array[String] = []
	for piece in PIECES:
		if not State.owns("fragment_" + piece): result.append(piece.capitalize())
	return result

func unlock() -> bool:
	if not missing().is_empty(): return false
	for piece in PIECES: State.install("fragment_" + piece)
	State.set_flag("escapePuzzleSolved")
	return true

func _icon(parent: Node3D, kind: String, color: Color) -> void:
	var polygon = PackedVector2Array()
	if kind == "moon":
		var angle = acos(0.15 / (2 * 0.28))
		for i in range(25): polygon.append(Vector2.from_angle(angle + float(i) / 24 * (TAU - 2 * angle)) * 0.28)
		for i in range(1, 24): polygon.append(Vector2(0.15, 0) + Vector2.from_angle(PI + angle - float(i) / 24 * 2 * angle) * 0.28)
	else:
		var points = 10 if kind == "star" else 16
		for i in range(points): polygon.append(Vector2.from_angle(-PI / 2 + float(i) / points * TAU) * (0.29 if i % 2 == 0 else 0.13 if kind == "star" else 0.20))
	var indices = Geometry2D.triangulate_polygon(polygon)
	var mesh = SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0, 1.0]:
		for i in range(0, indices.size(), 3):
			for j in range(3):
				var point = polygon[indices[i + (2 - j if side > 0 else j)]]
				mesh.set_normal(Vector3(0, 0, side))
				mesh.add_vertex(Vector3(point.x, -point.y, side * 0.035))
	var item = MeshInstance3D.new()
	item.mesh = mesh.commit()
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.6
	material.roughness = 0.38
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 0.28
	item.material_override = material
	parent.add_child(item)
