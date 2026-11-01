extends Node3D
## Physical relay equipment and the two connected basement wings.
const G = preload("res://scripts/systems/geometry.gd")
const A = preload("res://scripts/systems/free_assets.gd")
const KIT = "res://assets/vendor/kenney_factory/"
const MEMORY_CENTER = Vector3(-8, -4, 42)
var level: Node3D
var memory: Node3D
var generator_status: Label3D
var socket_status: Label3D
var lever_status: Label3D
var generator_lamp: MeshInstance3D
var installed_contact: Node3D

func apply(owner_level: Node3D) -> void:
	level = owner_level; name = "RelayRebuild"; level.add_child(self)
	_socket_and_cell()
	_archive()
	_generator()
	_relay_bank()
	_lever()
	_basement()
	memory = preload("res://scripts/systems/memory_chamber.gd").new()
	memory.setup(level, self, MEMORY_CENTER)

func worn(color: String) -> ShaderMaterial:
	var mat = ShaderMaterial.new(); mat.shader = preload("res://assets/materials/factory_metal.gdshader")
	mat.set_shader_parameter("paint", Color(color)); mat.set_shader_parameter("decay", 0.12)
	mat.set_shader_parameter("grain_strength", 0.035); return mat

func metal(color = "34484d") -> Material:
	return G.material("steel", Color(color))

func glow(color: String, power = 1.0) -> StandardMaterial3D:
	var mat = G.material("plain", Color(color)).duplicate()
	mat.emission_enabled = true; mat.emission = Color(color); mat.emission_energy_multiplier = power
	return mat

func retire(title: String) -> void:
	var node = level.find_child(title, true, false)
	if node == null: return
	node.hide()
	for body in node.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0

func box(parent: Node3D, p: Vector3, size: Vector3, mat: Material, solid = false, title = "") -> MeshInstance3D:
	var mesh = G.box(parent, p, size, mat, solid)
	if title != "": mesh.name = title
	return mesh

func label(parent: Node3D, text: String, p: Vector3, pixel = 0.0035, yaw = 0.0, color = Color("d5cfb7")) -> Label3D:
	var text_node = G.sign_text(parent, text, p, 32, yaw)
	text_node.pixel_size = pixel; text_node.outline_size = 0; text_node.modulate = color
	return text_node

func panel_sign(parent: Node3D, text: String, p: Vector3, width: float, yaw = 0.0) -> Node3D:
	var panel = Node3D.new(); parent.add_child(panel); panel.position = p; panel.rotation.y = yaw
	box(panel, Vector3.ZERO, Vector3(width, 0.50, 0.07), metal("23363e"))
	box(panel, Vector3(0, 0.24, 0.043), Vector3(width, 0.025, 0.012), G.material("plain", Color("be9856")))
	label(panel, text, Vector3(0, 0, 0.042), minf(0.0042, width / maxf(32, text.length() * 20)))
	return panel

func light_at(p: Vector3, color: String, energy = 1.0, radius = 6.0) -> void:
	var lamp = OmniLight3D.new(); lamp.position = p; lamp.light_color = Color(color)
	lamp.light_energy = energy; lamp.omni_range = radius; add_child(lamp)

func workbench(title: String, point: Vector3, dimensions: Vector2, height = 0.90) -> void:
	var bench = Node3D.new(); bench.name = title; bench.position = point; add_child(bench)
	var steel = metal("3d514e"); var timber = G.material("plain", Color("796448"))
	box(bench, Vector3(0, height - 0.045, 0), Vector3(dimensions.x, 0.09, dimensions.y), timber, true)
	for x in [-dimensions.x / 2 + 0.10, dimensions.x / 2 - 0.10]:
		for z in [-dimensions.y / 2 + 0.10, dimensions.y / 2 - 0.10]:
			box(bench, Vector3(x, (height - 0.09) / 2, z), Vector3(0.065, height - 0.09, 0.065), steel, true)
	box(bench, Vector3(0, 0.20, -dimensions.y / 2 + 0.10), Vector3(dimensions.x - 0.1, 0.07, 0.07), steel)
	box(bench, Vector3(dimensions.x * 0.25, height - 0.23, 0), Vector3(dimensions.x * 0.34, 0.28, dimensions.y * 0.8), steel)
	box(bench, Vector3(dimensions.x * 0.25, height - 0.23, dimensions.y * 0.41), Vector3(0.22, 0.027, 0.04), metal("8d9a91"))

func interaction(action: String, point: Vector3, caption: String, parameter = "", size = Vector3(0.65, 0.65, 0.45)) -> void:
	for object in level.get_children():
		if object is KalaInteractable and object.action_id == action and (parameter == "" or object.parameter == parameter):
			object.position = point; object.caption = caption
			for child in object.get_children():
				if child is CollisionShape3D: child.shape = child.shape.duplicate(); child.shape.size = size

func reveal(parent: Node3D, text: String, point: Vector3, yaw = 0.0, pixel = 0.0037) -> Label3D:
	var mark = label(parent, text, point, pixel, yaw, Color(0.10, 0.65, 1.0, 0))
	mark.name = "BlueInspectionMark"; mark.add_to_group("light_reveal"); mark.set_meta("exposure", 0.0)
	return mark

func _socket_and_cell() -> void:
	for id in range(1433, 1436): retire("Source_%d" % id)
	var dock = Node3D.new(); dock.name = "R17SocketCabinet"; dock.position = Vector3(8, 0, -2.15); add_child(dock)
	var paint = worn("466b70"); var dark = metal("18272c"); var copper = G.material("brass", Color("b77643"))
	box(dock, Vector3(0, 0.08, 0), Vector3(1.18, 0.16, 1.0), dark, true)
	box(dock, Vector3(0, 0.64, -0.10), Vector3(0.95, 1.12, 0.62), paint, true)
	box(dock, Vector3(0, 1.50, -0.16), Vector3(1.18, 1.34, 0.52), paint, true)
	box(dock, Vector3(0, 1.47, 0.114), Vector3(0.68, 0.87, 0.035), dark)
	for x in [-0.41, 0.41]:
		box(dock, Vector3(x, 1.48, 0.22), Vector3(0.13, 0.98, 0.22), metal("82918b"))
		for y in [1.05, 1.92]: G.sphere(dock, Vector3(x, y, 0.34), Vector3.ONE * 0.055, dark)
	for y in [1.11, 1.84]:
		box(dock, Vector3(0, y, 0.21), Vector3(0.63, 0.08, 0.18), copper)
	for x in [-0.17, 0, 0.17]: box(dock, Vector3(x, 1.47, 0.16), Vector3(0.055, 0.33, 0.08), copper)
	panel_sign(dock, "R-17 / DOK RELAI", Vector3(0, 2.26, 0.05), 1.45)
	socket_status = label(dock, "○ KOSONG", Vector3(0, 0.72, 0.224), 0.0031)
	reveal(dock, "┌   R-17   ┐\n  MASUKKAN\n└    ↓    ┘", Vector3(0, 1.49, 0.38))
	interaction("socket", Vector3(8, 1.46, -1.70), "Pasang R-17 ke dok relai")
	var cell = level.find_child("RelayCell", true, false) as Node3D
	for child in cell.get_children(): cell.remove_child(child); child.queue_free()
	cell.global_transform = Transform3D(Basis.IDENTITY, level.to_global(Vector3(-7.15, 1.28, 7)))
	box(cell, Vector3.ZERO, Vector3(0.36, 0.57, 0.30), worn("d8c691"))
	for y in [-0.32, 0.32]: box(cell, Vector3(0, y, 0), Vector3(0.41, 0.12, 0.34), copper)
	for y in [-0.17, -0.08, 0.08, 0.17]: box(cell, Vector3(0, y, 0), Vector3(0.41, 0.028, 0.34), dark)
	label(cell, "R-17", Vector3(0, 0, 0.156), 0.0027)
	var service_dock = level.find_child("RelayServiceDock", true, false)
	if service_dock != null:
		service_dock.material_override = paint
		box(self, Vector3(-7.15, 0.99, 7), Vector3(0.72, 0.08, 0.78), dark)
	interaction("cell", Vector3(-7.15, 1.28, 7), "Ambil unit R-17")

func _clipboard(title: String, text: String, point: Vector3, yaw = 0.0) -> Node3D:
	var board = Node3D.new(); board.name = title; board.position = point; board.rotation.y = yaw; add_child(board)
	box(board, Vector3.ZERO, Vector3(0.43, 0.57, 0.035), G.material("burlap", Color("6c523d")))
	box(board, Vector3(0, -0.01, 0.023), Vector3(0.37, 0.48, 0.007), G.material("plain", Color("d8cba9")))
	box(board, Vector3(0, 0.23, 0.034), Vector3(0.18, 0.065, 0.026), metal("94998b"))
	label(board, text, Vector3(0, 0, 0.030), 0.00125, 0, Color("3c4038"))
	return board

func _archive() -> void:
	for prop in level.get_node("FactoryRevision09").get_children():
		if str(prop.name).begins_with("screen-panel-flat"):
			prop.hide()
			for body in prop.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0
	for id in [1565, 1566, 1567, 1568, 1571, 1572, 1630, 1632, 1634]: retire("Source_%d" % id)
	retire("Item_generatorContact")
	var rack = Node3D.new(); rack.name = "RelayArchiveShelves"; rack.position = Vector3(-23.3, 0, -1.5); rack.rotation.y = PI / 2; add_child(rack)
	var steel = metal("405451"); var board = G.material("burlap", Color("6a5843"))
	for x in [-2.15, 2.15]:
		for z in [-0.34, 0.34]: box(rack, Vector3(x, 1.35, z), Vector3(0.075, 2.70, 0.075), steel)
	for row in range(4):
		var y = 0.16 + row * 0.65
		box(rack, Vector3(0, y, 0), Vector3(4.40, 0.07, 0.77), board)
		for i in range(6):
			var x = -1.80 + i * 0.71
			var carton = box(rack, Vector3(x, y + 0.25, 0), Vector3(0.58, 0.43, 0.59), G.material("plain", Color("95815f")))
			carton.rotation.y = (i % 3 - 1) * 0.03
			box(rack, Vector3(x, y + 0.25, 0.303), Vector3(0.035, 0.43, 0.008), G.material("plain", Color("776347")))
			box(rack, Vector3(x, y + 0.468, 0), Vector3(0.035, 0.006, 0.59), G.material("plain", Color("776347")))
			label(rack, "ARSIP %02d\nKARTINI" % (row * 6 + i + 1), Vector3(x, y + 0.23, 0.313), 0.0013)
	box(rack, Vector3(0, 1.36, 0), Vector3(4.4, 2.72, 0.72), G.material("plain", Color("3d4540")), true).hide()
	workbench("ArchiveContactWorkbench", Vector3(-20.1, 0, -5.6), Vector2(3.8, 1.05))
	var case_root = Node3D.new(); case_root.name = "GeneratorContactCase"; case_root.position = Vector3(-20.8, 0.91, -5.6); add_child(case_root)
	box(case_root, Vector3(0, 0.025, 0), Vector3(0.63, 0.05, 0.42), metal("26373d"))
	box(case_root, Vector3(0, 0.25, -0.2), Vector3(0.63, 0.46, 0.055), worn("4d6864"))
	var contact = Node3D.new(); contact.name = "SingleGeneratorContact"; contact.position.y = 0.052; case_root.add_child(contact)
	box(contact, Vector3(0, 0.055, 0), Vector3(0.39, 0.11, 0.24), G.material("ceramic", Color("c9c2a4")))
	for x in [-0.12, 0.12]:
		box(contact, Vector3(x, 0.17, 0), Vector3(0.075, 0.18, 0.09), G.material("brass", Color("b97e42")))
	box(contact, Vector3(0, 0.255, 0), Vector3(0.32, 0.045, 0.14), metal("354744"))
	level.props.generatorContact = contact
	label(case_root, "KONTAK / G-02", Vector3(0, 0.29, -0.169), 0.0016)
	interaction("item", Vector3(-20.8, 1.12, -5.6), "Ambil kontak generator G-02", "generatorContact", Vector3(0.48, 0.38, 0.42))
	_clipboard("ArchiveNamesClipboard", "BERKAS R\n\nPENERIMAAN\n17 / KARTINI\n________________\nSHIFT MALAM", Vector3(-18.5, 1.40, -7.82))
	interaction("note", Vector3(-18.5, 1.40, -7.65), "Baca berkas penerimaan", "archive_names")
	_clipboard("MotherPromiseClipboard", "JANJI YANG\nTIDAK DIHAPUS\n\nAku akan pulang.\nSimpan namaku.\n________________", Vector3(-23.83, 1.50, 1.3), PI / 2)
	interaction("note", Vector3(-23.64, 1.50, 1.3), "Baca JANJI YANG TIDAK DIHAPUS", "mother_promise", Vector3(0.28, 0.58, 0.46))
	light_at(Vector3(-20.5, 2.9, -3.4), "b7b8a0", 0.9)

func _generator() -> void:
	var floor_mesh = level.find_child("Source_1592", true, false)
	var floor_mat = ShaderMaterial.new(); floor_mat.shader = preload("res://assets/materials/relay_service_floor.gdshader")
	retire(str(floor_mesh.name))
	box(self, Vector3(20, -0.13, 8), Vector3(12, 0.26, 12), floor_mat, true, "GeneratorConcreteFloor")
	for id in range(1597, 1605): retire("Source_%d" % id)
	for id in [1639, 1641]: retire("Source_%d" % id)
	var body = Node3D.new(); body.name = "DieselGeneratorG02"; body.position = Vector3(22, 0, 7.7); body.rotation.y = -PI / 2; add_child(body)
	var steel = metal("25353a"); var paint = worn("657b66"); var silver = metal("9a9f92"); var copper = metal("846a42")
	box(body, Vector3(0, 0.10, 0), Vector3(4.6, 0.20, 2.05), steel, true, "GroundedSkid")
	for z in [-0.87, 0.87]: box(body, Vector3(0, 0.32, z), Vector3(4.30, 0.24, 0.14), steel)
	for x in [-1.65, 1.65]:
		for z in [-0.67, 0.67]:
			box(body, Vector3(x, 0.36, z), Vector3(0.40, 0.25, 0.35), G.material("plain", Color("192326")))
	box(body, Vector3(-0.25, 0.94, 0), Vector3(2.20, 1.12, 1.18), paint, true, "EngineBlock")
	box(body, Vector3(-0.25, 1.56, 0), Vector3(2.25, 0.18, 1.02), silver)
	for x in [-0.98, -0.5, -0.02, 0.46]:
		G.cylinder(body, Vector3(x, 1.75, 0), 0.19, 0.29, paint)
		box(body, Vector3(x, 1.96, 0), Vector3(0.30, 0.10, 0.58), steel)
		for z in [-0.64, 0.64]:
			var tube = G.cylinder(body, Vector3(x, 1.15, z), 0.045, 0.86, copper); tube.rotation.z = 0.08
	var alternator = G.cylinder(body, Vector3(1.34, 1.0, 0), 0.62, 1.05, paint); alternator.rotation.z = PI / 2; alternator.name = "Alternator"
	for x in [1.01, 1.16, 1.31, 1.46, 1.61]:
		var rib = G.cylinder(body, Vector3(x, 1.0, 0), 0.65, 0.045, steel); rib.rotation.z = PI / 2
	box(body, Vector3(-1.74, 1.20, 0), Vector3(0.28, 1.64, 1.55), steel, true, "Radiator")
	for y in range(12): box(body, Vector3(-1.90, 0.53 + y * 0.115, 0), Vector3(0.05, 0.035, 1.40), silver)
	box(body, Vector3(-0.85, 2.30, -0.4), Vector3(0.95, 0.43, 0.60), paint)
	G.cylinder(body, Vector3(-0.85, 2.56, -0.4), 0.10, 0.10, steel)
	G.cylinder(body, Vector3(0.40, 2.24, -0.38), 0.11, 0.61, steel)
	var muffler = G.cylinder(body, Vector3(0.40, 2.76, -0.38), 0.23, 0.56, silver); muffler.rotation.z = PI / 2
	G.cylinder(body, Vector3(0.71, 3.03, -0.38), 0.075, 0.65, steel)
	box(body, Vector3(0.45, 1.20, 0.79), Vector3(1.15, 1.13, 0.34), paint, true, "GeneratorControlPanel")
	for x in [0.10, 0.64]:
		var rim = G.cylinder(body, Vector3(x, 1.45, 0.98), 0.155, 0.05, steel); rim.rotation.x = PI / 2
		var dial = G.cylinder(body, Vector3(x, 1.45, 1.011), 0.129, 0.012, G.material("plain", Color("8b9b8c"))); dial.rotation.x = PI / 2
		box(body, Vector3(x + 0.035, 1.46, 1.01), Vector3(0.10, 0.018, 0.009), steel).rotation.z = 0.6
		label(body, "0   50   100", Vector3(x, 1.40, 1.021), 0.00065, 0, Color("202f2d"))
	box(body, Vector3(0.40, 1.03, 0.98), Vector3(0.50, 0.26, 0.025), steel)
	for x in [0.25, 0.55]: box(body, Vector3(x, 1.03, 1.015), Vector3(0.07, 0.19, 0.04), copper)
	installed_contact = Node3D.new(); installed_contact.name = "InstalledGeneratorContact"; body.add_child(installed_contact)
	box(installed_contact, Vector3(0.40, 1.03, 1.045), Vector3(0.39, 0.18, 0.065), G.material("plain", Color("a9b39e")))
	for x in [0.28, 0.52]: box(installed_contact, Vector3(x, 1.03, 1.087), Vector3(0.05, 0.15, 0.025), G.material("brass", Color("b97e42")))
	installed_contact.hide()
	generator_lamp = G.sphere(body, Vector3(0.83, 1.20, 1.0), Vector3.ONE * 0.09, glow("d4954e"))
	generator_status = label(body, "G-02 / KONTAK KOSONG", Vector3(0.36, 0.77, 0.98), 0.0017)
	panel_sign(body, "G-02 / CATU DARURAT", Vector3(-0.15, 2.32, 0.40), 2.45)
	for x in [-1.1, 0.8]: box(body, Vector3(x, 2.06, 0.36), Vector3(0.045, 0.48, 0.045), steel)
	interaction("generator", Vector3(20.88, 1.14, 8.10), "Pasang kontak / nyalakan generator G-02", "", Vector3(0.42, 0.85, 0.9))
	# Diagnostic ink sits in front of the panel; the equipment cannot occlude it.
	reveal(body, "◌  G-02\nKONTAK → RELAI\n2  ·  1  ·  3", Vector3(-0.68, 1.23, 0.81), 0, 0.003)
	workbench("GeneratorServiceDesk", Vector3(23.8, 0, 12.5), Vector2(2.5, 0.85), 0.86)
	_clipboard("GeneratorLogClipboard", "G-02 / SERVIS\n\nCEK KONTAK\nARAHKAN LENTERA\nPADA PANEL RELAI\n________________", Vector3(24.2, 1.45, 13.80), PI)
	interaction("note", Vector3(24.2, 1.45, 13.6), "Baca CATATAN PUTARAN MESIN", "generator_log")
	A.place(self, KIT + "pipe-large-long.glb", Vector3(25.45, 2.42, 3.4), Vector3(0.30, 0.30, 9.3), 0, false, "GeneratorWallConduit")
	for x in [16.0, 19.0, 25.0]:
		box(self, Vector3(x, 0.018, 8), Vector3(0.055, 0.014, 10), G.material("plain", Color("b39b50")))
	panel_sign(self, "G-02 / GENERATOR", Vector3(25.80, 2.65, 8), 3.2, -PI / 2)
	for i in range(16): box(self, Vector3(25.48, 0.014, 4 + i * 0.5), Vector3(0.58, 0.018, 0.045), metal("172b30"))
	panel_sign(self, "PERAWATAN / G-02\nKUNCI KONTAK SEBELUM MENYALA", Vector3(17.2, 1.65, 2.19), 3.6)
	light_at(Vector3(19.0, 2.85, 7.2), "a6c1b8", 0.65, 8)
	light_at(Vector3(24.1, 2.8, 12), "bd985f", 0.65, 5)

func _relay_bank() -> void:
	for i in range(3):
		var x = -8 + i * 8
		for id in [1436 + i * 14, 1438 + i * 14]: retire("Source_%d" % id)
		var rotor = level.rotors[i]; rotor.position.y -= 1.10
		for mesh in rotor.find_children("*", "MeshInstance3D", true, false): mesh.show()
		box(self, Vector3(x, 1.65, -10.13), Vector3(2.5, 3.3, 0.7), worn("485e63"), true)
		box(self, Vector3(x, 0.09, -10.13), Vector3(2.75, 0.18, 1.16), metal("26373a"), true)
		panel_sign(self, "RELAI " + ["I", "II", "III"][i], Vector3(x, 3.60, -10.1), 2.5)
		for offset in [-0.9, 0.9]: box(self, Vector3(x + offset, 3.4, -10.12), Vector3(0.04, 0.35, 0.04), metal())
		label(self, "R · PUTAR 90°", Vector3(x, 1.17, -9.76), 0.0028)
		for object in level.get_children():
			if object is KalaInteractable and object.action_id == "rotor" and object.parameter == str(i): object.position.y -= 1.1
		var mark = level.marks[i]
		# Old brass ticks were swallowed by the dial and had no blue emission.
		for child in mark.get_children(): mark.remove_child(child); child.queue_free()
		mark.global_transform = Transform3D(Basis.IDENTITY, level.to_global(Vector3(x, 2.55, -9.55)))
		label(mark, ["↓  2", "→  1", "←  3"][i], Vector3(0, -0.90, 0.12), 0.008, 0, Color("25aaff"))
	for x in [-4, 4]:
		box(self, Vector3(x, 0.015, -10), Vector3(0.055, 0.012, 9), G.material("plain", Color("b09b59")))

func _lever() -> void:
	for id in range(1478, 1491): retire("Source_%d" % id)
	var console = Node3D.new(); console.name = "ArchiveLeverConsole"; console.position = Vector3(3.2, 0, -13.8); add_child(console)
	box(console, Vector3(0, 0.08, 0), Vector3(1.13, 0.16, 1.0), metal("263639"), true)
	box(console, Vector3(0, 0.66, 0), Vector3(0.85, 1.16, 0.7), worn("566c60"), true)
	box(console, Vector3(0, 1.24, -0.12), Vector3(0.99, 0.72, 0.42), worn("62796b"), true)
	var lever = A.place(console, KIT + "lever-single.glb", Vector3(0, 1.16, 0.12), Vector3(0.44, 0.64, 0.34), 0, false, "FreeAssetArchiveLever")
	for mesh in lever.find_children("*", "MeshInstance3D", true, false): mesh.material_override = metal("74857a")
	box(console, Vector3(0, 1.71, 0.18), Vector3(0.115, 0.20, 0.13), G.material("plain", Color("9d5546")))
	panel_sign(console, "ARSIP / PENGUNCI", Vector3(0, 2.01, 0.05), 1.8)
	lever_status = label(console, "SELARASKAN 3 RELAI", Vector3(0, 0.80, 0.365), 0.0020)
	interaction("lever", Vector3(3.2, 1.51, -13.32), "Tarik tuas arsip")

func _shell(parent: Node3D, center: Vector3, size: Vector2, entrance: float, room_title: String) -> void:
	var wall = ShaderMaterial.new(); wall.shader = preload("res://assets/materials/toy_factory_wall.gdshader")
	wall.set_shader_parameter("paint", Color("335a61")); wall.set_shader_parameter("plaster", Color("909b8d"))
	wall.set_shader_parameter("floor_origin", center.y)
	var floor_mat = G.material("concrete", Color("515d59"))
	box(parent, center - Vector3.UP * 0.12, Vector3(size.x, 0.24, size.y), floor_mat, true, room_title + "Floor")
	box(parent, center + Vector3.UP * 4.73, Vector3(size.x, 0.20, size.y), metal("273a3e"), true)
	for side in [-1, 1]: box(parent, center + Vector3(side * size.x / 2, 2.3, 0), Vector3(0.20, 4.6, size.y), wall, true)
	var segment = (size.x - entrance) / 2
	for side in [-1, 1]:
		for end in [-1, 1]:
			box(parent, center + Vector3(side * (entrance / 2 + segment / 2), 2.3, end * size.y / 2), Vector3(segment, 4.6, 0.22), wall, true)
	for end in [-1, 1]: box(parent, center + Vector3(0, 4.12, end * size.y / 2), Vector3(entrance, 1.0, 0.22), wall, true)

func _stairs(x: float, text: String) -> void:
	var stair = Node3D.new(); stair.name = "BasementStairs" + ("Memory" if x < 0 else "Service"); add_child(stair)
	var dark = metal("33484c"); var trim = G.material("plain", Color("bba565"))
	for i in range(20):
		var top = -0.20 * (i + 1); var z = 17.0 + (i + 0.5) * 0.5
		box(stair, Vector3(x, top - 0.12, z), Vector3(3.4, 0.24, 0.51), dark, true, "Tread%02d" % i)
		box(stair, Vector3(x, top + 0.006, z - 0.21), Vector3(3.30, 0.012, 0.045), trim)
		if i % 3 == 0:
			for side in [-1, 1]:
				box(stair, Vector3(x + side * 1.57, top + 0.5, z), Vector3(0.045, 1.0, 0.045), dark)
		for side in [-1, 1]:
			var rail = box(stair, Vector3(x + side * 1.57, top + 1.02, z), Vector3(0.055, 0.06, 0.55), trim)
			rail.rotation.x = atan(0.4)
			box(stair, Vector3(x + side * 1.79, (top + 2.5) / 2, z), Vector3(0.18, 3.1 - top, 0.51), dark, true)
	box(stair, Vector3(x, 2.8, 22), Vector3(3.7, 0.16, 10.1), metal("263b40"), true)
	panel_sign(self, text + " / B1 ↓", Vector3(x, 2.7, 16.68), 3.7, PI)
	for z in [17.8, 22.0, 26.3]: light_at(Vector3(x, 0.75 - (z - 17) * 0.25, z), "679a9f", 0.48, 4)

func _basement() -> void:
	# Retire only the two south wall segments. The original central entrance stays.
	for title in ["Source_1310", "Source_1311"]: retire(title)
	var wall = G.material("plaster", Color("657f72"))
	for side in [-1, 1]:
		for entry in [[1.68, 6.23], [9.77, 14.0]]:
			box(self, Vector3(side * (entry[0] + entry[1]) / 2, 3.5, 17), Vector3(entry[1] - entry[0], 7, 0.3), wall, true)
		box(self, Vector3(side * 8, 5.06, 17), Vector3(3.54, 3.88, 0.3), wall, true)
	_stairs(-8, "01 / MEMORI")
	_stairs(8, "02 / JALUR SERVIS")
	panel_sign(self, "MEMORI / SERVIS B1   ↶", Vector3(-4.6, 2.8, -16.65), 4.0)
	_shell(self, Vector3(2, -4, 29.5), Vector2(23.6, 5.0), 3.4, "BasementLanding")
	# Replace the landing's north/south walls with openings aligned to both stairs.
	for mesh in get_children():
		if not mesh is MeshInstance3D or not mesh.mesh is BoxMesh: continue
		if absf(mesh.position.y + 1.7) < 0.01 and absf(mesh.position.z - 29.5) > 2.4 and absf(mesh.position.z - 29.5) < 2.6 and mesh.mesh.size.x > 5:
			for collider in mesh.find_children("*", "StaticBody3D", true, false): collider.collision_layer = 0
			mesh.hide()
	_shell(self, MEMORY_CENTER, Vector2(18, 20), 4.8, "MemoryChamber")
	_shell(self, Vector3(12, -4, 42), Vector2(18, 20), 4.8, "ServiceRoom")
	# Close the unused openings in the landing and link its right doorway to x=12.
	box(self, Vector3(0, -2.3, 27), Vector3(12.4, 3.4, 0.20), wall, true)
	box(self, Vector3(12, -2.3, 27), Vector3(4.0, 3.4, 0.20), wall, true)
	box(self, Vector3(2, -1.7, 32), Vector3(2.0, 4.6, 0.20), wall, true)
	panel_sign(self, "B1 / GEMA ARSIP ←     SERVIS →", Vector3(1.0, -1.1, 31.83), 5.6, PI)
	light_at(Vector3(0, -0.7, 29.5), "6e9e9c", 0.75, 10)
	_service_room()
	var regions = level.safety.regions.duplicate(true)
	for x in [-9.8, 6.2]: regions.append({"x":x,"z":16.7,"w":3.6,"d":10.5,"y":-4.0,"h":7.0})
	regions.append({"x":-9.8,"z":27.0,"w":23.6,"d":5.1,"y":-4.0,"h":4.7})
	regions.append({"x":-17.1,"z":31.8,"w":18.2,"d":20.3,"y":-4.0,"h":4.7})
	regions.append({"x":2.9,"z":31.8,"w":18.2,"d":20.3,"y":-4.0,"h":4.7})
	regions.append({"x":-10.4,"z":51.9,"w":4.8,"d":10.2,"y":-4.0,"h":4.7})
	level.safety.regions = regions
	level.safety.extent = Rect2()
	for region in regions:
		var rect = Rect2(region.x, region.z, region.w, region.d)
		level.safety.extent = rect if level.safety.extent.size == Vector2.ZERO else level.safety.extent.merge(rect)
	var old = level.get_node("MapBoundary"); level.remove_child(old); old.free()
	level.safety._build_perimeter(level)
	for mesh in level.get_node("MapBoundary").find_children("*", "MeshInstance3D", false, false): mesh.hide()

func _service_room() -> void:
	panel_sign(self, "JALUR SERVIS / B1", Vector3(12, -0.7, 51.80), 4.6, PI)
	for x in [4.7, 19.2]:
		for z in [36, 42, 48]:
			A.place(self, KIT + "machine-connection-pipe.glb", Vector3(x, -4, z), Vector3(1.5, 2.0, 2.4), PI / 2, true, "ServicePump")
		A.place(self, KIT + "pipe-large-long.glb", Vector3(x, -0.50, 34), Vector3(0.26, 0.26, 16), 0, false, "ServicePipe")
	for z in [35, 41, 48]:
		light_at(Vector3(12, -0.4, z), "749797", 0.75, 6.5)
		box(self, Vector3(12, -3.985, z), Vector3(0.12, 0.012, 2.3), G.material("plain", Color("bb9c58")))
	box(self, Vector3(12, -2.35, 51.3), Vector3(4.6, 3.3, 0.23), worn("3c5155"), true, "MemoryServiceShutter")
	level.interact(Vector3(12, -2.65, 50.95), "recall", "Buka jalur pemeliharaan", "service", false, Vector3(1.0, 1.5, 0.35))
	label(self, "GEMA ARSIP → PENGUNCI SERVIS\nSELESAIKAN UJI MEMORI", Vector3(12, -2.1, 51.15), 0.0045, PI).name = "ServiceShutterReadout"

func _process(_delta: float) -> void:
	if generator_status == null: return
	var powered = State.data.installed.has("generatorContact")
	installed_contact.visible = powered
	generator_status.text = "G-02 / CATU AKTIF" if powered else "G-02 / KONTAK KOSONG"
	var indicator_material = generator_lamp.material_override as StandardMaterial3D
	indicator_material.albedo_color = Color("79bf98" if powered else "d4954e")
	indicator_material.emission = indicator_material.albedo_color
	socket_status.text = "● TERHUBUNG" if State.flag("relayPower") else "○ MASUKKAN R-17"
	lever_status.text = "● TERBUKA" if State.flag("relaySolved") else "R · TARIK" if State.data.rotors == [2, 1, 3] else "SELARASKAN 3 RELAI"
	var sun = level.get_node_or_null("DiscoverySun")
	if sun != null: sun.visible = level.get_parent().get_parent().player.position.y > -1.0
