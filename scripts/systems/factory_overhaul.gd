extends RefCounted
const A = preload("res://scripts/systems/free_assets.gd")
const G = preload("res://scripts/systems/geometry.gd")
const KIT = "res://assets/vendor/kenney_factory/"
var level: Node3D
var root: Node3D

func apply(owner_level: Node3D) -> void:
	level = owner_level
	if level.room_id in ["school", "home", "schoolyard", "neighborhood", "hallucination"]: return
	root = Node3D.new(); root.name = "FactoryRevision09"; level.add_child(root)
	if level.room_id == "street":
		_street(); preload("res://scripts/systems/factory_art_direction.gd").new().apply(level); return
	_retire_blockout_props()
	if level.room_id == "loading": _operator_fuse()
	if level.room_id == "relay": _archive_cage()
	match level.room_id:
		"loading":
			for side in [-1, 1]:
				prop("conveyor-long-sides", Vector3(side * 6.8, 0, -1.5), Vector3(1.6, 0.85, 7.0), 0)
				prop("machine-window", Vector3(side * 6.8, 0, -7.0), Vector3(2.2, 2.7, 2.4), PI if side < 0 else 0)
				practical(Vector3(side * 6.8, 4.0, -2.5), Color("b6c6b9"))
			for side in [-1, 1]:
				prop("machine-fortified", Vector3(side * 11.2, 0, 2), Vector3(2.1, 2.8, 2.6), side * PI / 2)
				for i in range(3): prop("box-large", Vector3(side * 9, 0, 7 + i * 2.0), Vector3(1.1, 0.9 + (i % 2) * 0.65, 1.15), i * 0.2)
			prop("crane", Vector3(-10, 0, -10), Vector3(4, 3.7, 3), 0, false)
		"relay":
			for side in [-1, 1]:
				prop("machine-connection-pipe", Vector3(side * 6.6, 0, -3), Vector3(2.5, 2.5, 2.6), side * PI / 2)
				practical(Vector3(side * 6.6, 4.8, -3), Color("a6bdc8"))
			for z in [-9, -3, 3]: prop("machine-window", Vector3(10.8, 0, z), Vector3(2.1, 2.5, 2.0), -PI / 2)
			prop("screen-panel-wide", Vector3(-10.5, 0.3, 6), Vector3(2.5, 1.7, 0.6), PI / 2)
			prop("pipe-large-valve", Vector3(11.3, 0.1, 9), Vector3(1.7, 2, 1.8), 0)
		"production":
			for side in [-1, 1]:
				prop("conveyor-long-stripe-sides", Vector3(side * 6.5, 0, 1), Vector3(1.5, 0.9, 9), 0)
				prop("machine-connection-pipe", Vector3(side * 6.5, 0, -7), Vector3(2.6, 2.8, 2.8), side * PI / 2)
				prop("robot-arm-a", Vector3(side * 6.5, 0, 8), Vector3(2.4, 2.8, 2.4), side * PI / 2)
				practical(Vector3(side * 6.5, 4, 0), Color("d6bf89"))
			for side in [-1, 1]:
				prop("hopper-high-round", Vector3(side * 15.5, 0, -8), Vector3(3.4, 4.1, 3.4), 0)
				prop("conveyor-long-sides", Vector3(side * 12.5, 0, 5), Vector3(2, 1.0, 6), PI / 2)
				prop("machine-fortified", Vector3(side * 15, 0, 12), Vector3(2.5, 3.2, 2.4), 0)
		"office":
			for side in [-1, 1]:
				A.furniture(root, "desk", Vector3(side * 4.6, 0, -0.7), Vector3(2.2, 0.82, 0.9), side * PI / 2)
				A.furniture(root, "computerScreen", Vector3(side * 4.6, 0.82, -0.7), Vector3(0.6, 0.45, 0.18), side * PI / 2, false)
				practical(Vector3(side * 4.6, 2.9, -0.7), Color("dfc392"))
			for z in [-5, 0, 5]: A.furniture(root, "bookcaseClosed", Vector3(-8.5, 0, z), Vector3(0.6, 2.4, 1.8), PI / 2)
			prop("screen-panel-wide", Vector3(7.2, 0.8, -5.5), Vector3(2, 1.2, 0.3), -PI / 2)
			A.furniture(root, "rugRectangle", Vector3(0, 0.025, 0), Vector3(5, 0.018, 6), 0, false)
		"ritual":
			for side in [-1, 1]:
				prop("pipe-large-valve", Vector3(side * 12.8, 0.3, 0), Vector3(1.7, 3.2, 3.6), side * PI / 2, false)
				practical(Vector3(side * 11, 4.0, -5), Color("aabbbc"))
		"corridor":
			for z in [-12, 0, 12]: practical(Vector3(0, 2.9, z), Color("9bacab"), 0.65)
			for z in [-14, 3, 14]: prop("pipe-large-long", Vector3(-2.62, 1.9, z), Vector3(0.3, 0.3, 4.2), 0, false)
		"daisy":
			practical(Vector3(-3, 3.7, -0.5), Color("c4b7a1"), 0.8)
			for side in [-1, 1]:
				A.furniture(root, "bookcaseOpen", Vector3(side * 5.4, 0, -3.8), Vector3(1.2, 2.7, 0.5), side * PI / 2)
				prop("box-small", Vector3(side * 4, 0, 3.2), Vector3(0.8, 0.65, 0.9), side * 0.2)
		"pursuit":
			for z in [44, 18, -8, -34]: prop("screen-hanging-small", Vector3(-10.6, 2.5, z), Vector3(0.2, 0.65, 0.8), PI / 2, false)
	if level.room_id in ["loading", "relay", "production", "office"]:
		_annexes()
		var name_value = {"loading":"01 / PENERIMAAN BARANG", "relay":"02 / DISTRIBUSI DAYA", "production":"03 / LINI PERAKITAN", "office":"04 / ADMINISTRASI SHIFT"}[level.room_id]
		G.sign_text(root, name_value, Vector3(0, 3.05, level.depth * 0.5 - 0.8), 26, PI)
		# Structural bays and overhead services leave the combat floor open.
		for side in [-1, 1]:
			for z in range(-int(level.depth / 2) + 5, int(level.depth / 2), 8):
				var point = Vector3(side * (level.width / 2 - 0.55), 0, z)
				if not _at_doorway(point): prop("structure-high", point, Vector3(0.55, 3.9, 0.55), 0, false)
			prop("pipe-large-long", Vector3(side * (level.width / 2 - 1.1), 3.8, 0), Vector3(0.3, 0.3, level.depth - 4), 0, false)
	_reveal_mark()
	if level.room_id in ["loading", "relay", "production"]:
		var paint = G.material("plain", Color("a89f6c"))
		for x in [-2.0, 2.0]: G.box(root, Vector3(x, 0.017, 0), Vector3(0.06, 0.012, level.depth - 6), paint)
		for z in range(-int(level.depth / 2) + 4, int(level.depth / 2), 6):
			var line = G.box(root, Vector3(0, 0.019, z), Vector3(0.07, 0.01, 0.9), paint); line.rotation.y = 0.5
	preload("res://scripts/systems/factory_art_direction.gd").new().apply(level)

func practical(point: Vector3, color: Color, energy = 2.0) -> void:
	A.furniture(root, "lampSquareCeiling", point, Vector3(0.8, 0.12, 0.35), 0, false)
	var light = SpotLight3D.new(); light.position = point - Vector3.UP * 0.15; light.rotation.x = -PI / 2
	light.spot_range = 8; light.spot_angle = 58; light.light_color = color; light.light_energy = energy
	light.shadow_enabled = true; light.shadow_normal_bias = 0.7; root.add_child(light)
	var bounce = OmniLight3D.new(); bounce.position = point - Vector3.UP * 1.5 + Vector3(0, 0, 1.8)
	bounce.light_color = color; bounce.light_energy = energy * 0.35; bounce.omni_range = 7.0; root.add_child(bounce)

func _at_doorway(point: Vector3) -> bool:
	for record in level.definition.interactions:
		if record.get("annex", "") == "": continue
		if Vector2(point.x - record.x, point.z - record.z).length() < 2.3: return true
	return false

func _retire(node: Node3D) -> void:
	if node == null: return
	node.hide()
	for body in node.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0

func _operator_fuse() -> void:
	# Two coincident source cylinders and a floating item card made one fuse
	# look like a pile. Replace the complete pickup, including its old label.
	for label in ["Source_2000", "Source_2001", "Source_2033"]: _retire(level.find_child(label, true, false))
	if level.props.has("panelFuse"): _retire(level.props.panelFuse)
	var holder = Node3D.new(); holder.name = "OperatorFusePickup"; holder.position = Vector3(23.3, 0.91, -13.1); root.add_child(holder)
	var fuse = A.place(holder, "res://assets/vendor/revision10/cartridge_fuse.glb", Vector3.ZERO, Vector3(-1, 0.32, -1), 0, false, "CartridgeFuse")
	# Real cartridge axis is Y. Lay it on the workbench and rest the cap on it.
	fuse.rotation.z = PI / 2; fuse.position = Vector3(0.16, 0.045, 0)
	level.props.panelFuse = holder
	for object in level.get_children():
		if object is KalaInteractable and object.action_id == "item" and object.parameter == "panelFuse":
			object.position = holder.position + Vector3(0, 0.09, 0)
	# Mount the same physical keypad seen in its close-up on the control box.
	for label in ["Source_1887", "Source_1888"]: _retire(level.find_child(label, true, false))
	var keypad = preload("res://scripts/systems/keypad_model.gd").create(root)
	keypad.name = "LoadingKeypad"; keypad.position = Vector3(13.55, 1.5, -15); keypad.rotation.y = -PI / 2

func _archive_cage() -> void:
	# Frame the existing archive grille with rails and a clear service opening;
	# it should read as a fenced equipment bay instead of loose black sticks.
	var grille = Node3D.new(); grille.name = "ArchiveGrille"; root.add_child(grille)
	var metal = G.material("plain", Color("394b49")); metal.metallic = 0.7; metal.roughness = 0.5
	for mesh in level.get_node("SourceWorld").find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		if b.position.x > -13.15 and b.end.x < -7.65 and b.position.z > 3.85 and b.end.z < 9.15 and b.size.y > 2.7: _retire(mesh)
	for x in [-13.0, -7.8]:
		for z in [4.0, 9.0]: G.box(grille, Vector3(x, 1.55, z), Vector3(0.10, 3.1, 0.10), metal, true)
	for y in [0.12, 1.15, 3.05]:
		for z in [4.0, 9.0]: G.box(grille, Vector3(-10.4, y, z), Vector3(5.3, 0.07, 0.08), metal, true)
		for x in [-13.0, -7.8]: G.box(grille, Vector3(x, y, 6.5), Vector3(0.08, 0.07, 5.0), metal, true)
	for i in range(18):
		for z in [4.0, 9.0]: G.box(grille, Vector3(-12.85 + i * 0.29, 1.55, z), Vector3(0.025, 2.86, 0.025), metal, true)
		for x in [-13.0, -7.8]: G.box(grille, Vector3(x, 1.55, 4.14 + i * 0.278), Vector3(0.025, 2.86, 0.025), metal, true)

func _retire_blockout_props() -> void:
	if level.room_id not in ["loading", "relay", "production", "office"]: return
	for mesh in level.get_node("SourceWorld").find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		var p = b.get_center()
		if absf(p.x) > level.width / 2 - 2 or absf(p.z) > level.depth / 2 - 2: continue
		if b.position.y < 0.03 or b.end.y > 3.2 or maxf(b.size.x, b.size.z) > 7: continue
		var important = false
		for record in level.definition.interactions:
			if Vector2(p.x, p.z).distance_to(Vector2(record.x, record.z)) < 1.8: important = true; break
		if important: continue
		mesh.hide()
		for body in mesh.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0

func prop(id: String, point: Vector3, dimensions: Vector3, yaw = 0.0, solid = true) -> Node3D:
	var asset = A.place(root, KIT + id + ".glb", point, dimensions, yaw, solid)
	for mesh in asset.find_children("*", "MeshInstance3D", true, false):
		var mat = ShaderMaterial.new(); mat.shader = preload("res://assets/materials/factory_metal.gdshader")
		mat.set_shader_parameter("paint", Color("64776e") if id.begins_with("machine") else Color("a39a75"))
		mesh.material_override = mat
	if solid: level.nav_extra.append(Rect2(point.x - dimensions.x / 2, point.z - dimensions.z / 2, dimensions.x, dimensions.z))
	return asset

func _annexes() -> void:
	for i in range(1, level.safety.regions.size()):
		var r: Dictionary = level.safety.regions[i]
		if r.w < 6 or r.d < 6: continue
		var p = Vector3(r.x + r.w * 0.5, r.y, r.z + 0.65)
		if level.room_id == "office":
			A.furniture(root, "bookcaseOpen", p, Vector3(2.2, 2.2, 0.45), 0)
		elif level.room_id == "production" and r.x > 0:
			A.furniture(root, "bathroomCabinet", p, Vector3(2.0, 1.1, 0.5))
		else: prop("screen-panel-flat", p, Vector3(2.2, 1.4, 0.5))

func _reveal_mark() -> void:
	if level.room_id not in ["loading", "relay", "production", "corridor"]: return
	var mark = G.sign_text(root, "JALUR INSPEKSI  →" if level.room_id != "relay" else "ARAHKAN CAHAYA • TAHAN • LEPASKAN", Vector3(-level.width / 2 + 0.18, 1.7, 1.0), 21, PI / 2)
	mark.name = "LightRevealMark"; mark.modulate = Color(0.72, 0.77, 0.59, 0)
	mark.add_to_group("light_reveal"); mark.set_meta("exposure", 0.0)

func _street() -> void:
	# Remove the old clipped electrical sign and block housing before remounting.
	for mesh in level.get_node("SourceWorld").find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		if b.get_center().distance_to(Vector3(-4, 1.6, 15)) < 2.1 and b.size.length() < 3.1:
			mesh.hide()
			for body in mesh.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0
	var cabinet = Node3D.new(); cabinet.name = "FuseCabinet"; cabinet.position = Vector3(-4, 0, 15); cabinet.rotation.y = PI / 2; root.add_child(cabinet)
	G.box(cabinet, Vector3(0, 1.3, 0), Vector3(1.0, 1.25, 0.24), G.material("steel", Color("4c5b55")), true)
	A.place(cabinet, KIT + "lever-single.glb", Vector3(-0.22, 1.05, 0.13), Vector3(0.30, 0.42, 0.18), 0, false)
	var sign_plate = G.box(cabinet, Vector3(0, 2.12, 0.07), Vector3(1.15, 0.27, 0.035), G.material("plain", Color("262f2b")))
	sign_plate.name = "FlushElectricalSign"
	var caption = G.sign_text(cabinet, "PENERANGAN", Vector3(0, 2.12, 0.095), 23); caption.pixel_size = 0.0042; caption.outline_size = 0
	for i in range(3):
		G.cylinder(cabinet, Vector3(-0.23 + i * 0.23, 0.47, 0), 0.025, 0.55, G.material("plain", [Color("9f4038"), Color("b5a45b"), Color("526e88")][i]))
	for object in level.get_children():
		if object is KalaInteractable and object.action_id == "puzzle" and object.parameter == "fuse": object.position = Vector3(-3.7, 1.3, 15)
	# Open-front neighbourhood kiosk with stock, preparation and customer areas.
	var shop = Node3D.new(); shop.name = "WarungKartini"; shop.position = Vector3(5.8, 0, 2.8); shop.rotation.y = -PI / 2; root.add_child(shop)
	var wood = G.material("burlap", Color("66503c")); var paint = G.material("plain", Color("7d8f7c"))
	G.box(shop, Vector3(0, -0.02, 0), Vector3(4.6, 0.14, 3.3), G.material("concrete", Color("8d8a75")), true)
	G.box(shop, Vector3(0, 1.35, -1.42), Vector3(4.6, 2.7, 0.12), paint, true)
	G.box(shop, Vector3(0, 2.8, 0), Vector3(5.1, 0.13, 3.8), G.material("steel", Color("686f6b")), true)
	for side in [-1, 1]: G.box(shop, Vector3(side * 2.18, 1.35, 1.4), Vector3(0.10, 2.7, 0.10), wood, true)
	A.furniture(shop, "kitchenBar", Vector3(-0.5, 0.05, 0.45), Vector3(2.7, 0.95, 0.55), 0)
	A.furniture(shop, "kitchenFridgeSmall", Vector3(1.5, 0.05, -0.85), Vector3(0.7, 1.25, 0.7), 0)
	A.furniture(shop, "bookcaseOpen", Vector3(-0.8, 0.05, -1.12), Vector3(2.5, 2.2, 0.36), 0)
	for row in range(3):
		for col in range(7):
			var p = Vector3(-1.7 + col * 0.31, 0.48 + row * 0.59, -1.02)
			if row % 2 == 0:
				G.cylinder(shop, p, 0.055, 0.22, G.material("plain", [Color("a26440"),Color("74794b"),Color("858c86")][col % 3]))
			else: G.box(shop, p, Vector3(0.17, 0.25, 0.11), G.material("plain", [Color("a89d65"),Color("9a5548"),Color("657e75")][col % 3]))
	A.furniture(shop, "kitchenCoffeeMachine", Vector3(-1.0, 1.0, 0.45), Vector3(0.3, 0.35, 0.28), 0, false)
	A.furniture(shop, "stoolBar", Vector3(-1.35, 0.04, 1.7), Vector3(0.42, 0.75, 0.42), 0)
	A.furniture(shop, "stoolBar", Vector3(0.2, 0.04, 1.7), Vector3(0.42, 0.75, 0.42), 0)
	G.box(shop, Vector3(0, 2.40, 1.5), Vector3(4, 0.48, 0.04), G.material("plain", Color("34493d")))
	var title = G.sign_text(shop, "WARUNG BU TINI", Vector3(0, 2.40, 1.53), 28); title.outline_size = 0
	G.sign_text(shop, "KOPI  3.000\nTEH HANGAT  2.000\nMIE REBUS  7.000", Vector3(1.57, 1.65, -1.30), 13)
	level.interact(Vector3(4.65, 1.12, 3.0), "note", "Baca buku utang warung", "warung_log")
