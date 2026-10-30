extends RefCounted

const G = preload("res://scripts/systems/geometry.gd")
var level: Node3D
var doors: Dictionary = {}
var clock = 0.0
var materials: Dictionary = {}

static func definition(id: String) -> Dictionary:
	var spawn = {"home": [-4.4, 3.25, -1.0], "schoolyard": [0, 0.05, 19], "neighborhood": [0, 0.05, -8]}[id]
	return {"width": 60, "depth": 70, "spawn": spawn, "yaw": 0, "cx": 0, "colliders": [], "doors": [], "interactions": [], "tools": []}

func build(owner_level: Node3D) -> void:
	level = owner_level
	match level.room_id:
		"home": _home()
		"schoolyard": _yard()
		"neighborhood": _neighborhood()

func mat(kind: String, tint: String) -> Material:
	var key = kind + tint
	if materials.has(key): return materials[key]
	if kind == "burlap":
		var wood = ShaderMaterial.new(); wood.shader = preload("res://assets/materials/wood.gdshader"); wood.set_shader_parameter("wood_color", Color(tint))
		materials[key] = wood; return wood
	if kind == "plaster" and level.room_id == "home":
		var clean = G.material("plain", Color(tint)).duplicate(); clean.roughness = 0.92
		materials[key] = clean; return clean
	if kind in ["concrete", "ceramic", "cotton"] and level.room_id == "home":
		var clean = ShaderMaterial.new(); clean.shader = preload("res://assets/materials/interior.gdshader")
		clean.set_shader_parameter("tint", Color(tint)); clean.set_shader_parameter("tiled", 1.0 if kind == "ceramic" else 0.0)
		materials[key] = clean; return clean
	return G.material(kind, Color(tint))

func box(p: Vector3, s: Vector3, m: Material, solid = true, parent: Node3D = null) -> MeshInstance3D:
	return G.box(level if parent == null else parent, p, s, m, solid)

func text(value: String, p: Vector3, size = 20, yaw = 0.0) -> Label3D:
	var label = G.sign_text(level, value, p, size, yaw)
	label.modulate = Color("433e33") if level.room_id == "home" else Color("e4dec5")
	label.outline_size = 0
	return label

func light(p: Vector3, color: String, energy: float, radius: float, shadow = false) -> void:
	var lamp = OmniLight3D.new()
	lamp.position = p; lamp.light_color = Color(color); lamp.light_energy = energy
	lamp.omni_range = radius; lamp.shadow_enabled = shadow
	level.add_child(lamp)

func _sun(color: String, energy: float, angle: Vector3) -> void:
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = angle; sun.light_color = Color(color); sun.light_energy = energy
	sun.shadow_enabled = true; sun.directional_shadow_max_distance = 90
	level.add_child(sun)

func _door(id: String, p: Vector3, yaw: float, title: String, opened = false, locked = false) -> void:
	if not locked: opened = State.flag("home_door_" + id)
	var pivot = Node3D.new()
	pivot.name = "HomeDoor_" + id; pivot.position = p; pivot.rotation.y = yaw
	level.add_child(pivot)
	preload("res://scripts/systems/free_assets.gd").door(pivot, Vector3(0.55, 0, 0))
	doors[id] = {"node": pivot, "yaw": yaw, "open": opened, "locked": locked}
	level.interact(p + Vector3(0.52, 1.2, 0), "chapter", title, "door_" + id, false, Vector3(1.25, 2, 0.48))
	pivot.rotation.y = yaw + (0.58 if id == "mother" else -1.4) * float(opened)

func _room_shell(cx: float, cy: float, cz: float, w: float, d: float, opening = 1.0) -> void:
	var plaster = mat("plaster", "d9cfb9")
	var floor_material: Material = mat("concrete", "c9c5b5")
	if cy > 0:
		floor_material = ShaderMaterial.new(); floor_material.shader = preload("res://assets/materials/home_floor.gdshader")
	box(Vector3(cx, cy + 0.006, cz), Vector3(w, 0.012, d), floor_material, false)
	# The shared floor/roof supplies the ceiling; no coincident room ceiling.
	for side in [-1, 1]:
		box(Vector3(cx + side * w / 2, cy + 1.45, cz), Vector3(0.15, 2.9, d), plaster)
	box(Vector3(cx, cy + 1.45, cz - d / 2), Vector3(w, 2.9, 0.15), plaster)
	var part = (w - opening) / 2
	for side in [-1, 1]:
		box(Vector3(cx + side * (opening / 2 + part / 2), cy + 1.45, cz + d / 2), Vector3(part, 2.9, 0.16), plaster)
	box(Vector3(cx, cy + 2.57, cz + d / 2), Vector3(opening, 0.66, 0.16), plaster)
	var frame = mat("plain", "9b896e")
	for side in [-1, 1]:
		box(Vector3(cx + side * (opening / 2 + 0.015), cy + 1.1, cz + d / 2), Vector3(0.08, 2.2, 0.23), frame, false)
	box(Vector3(cx, cy + 2.20, cz + d / 2), Vector3(opening + 0.11, 0.08, 0.23), frame, false)
	# Skirting and crown trim give every room a finished edge.
	for y in [0.09, 2.82]:
		box(Vector3(cx, cy + y, cz - d / 2 + 0.1), Vector3(w, 0.12, 0.08), mat("burlap", "8a7256"), false)
		for side in [-1, 1]: box(Vector3(cx + side * (w / 2 - 0.1), cy + y, cz), Vector3(0.08, 0.12, d), mat("burlap", "8a7256"), false)

func _home() -> void:
	_sun("fff0d4", 0.75, Vector3(-32, -42, 0))
	var plaster = mat("plaster", "d9cfb9")
	var wood = mat("burlap", "806449")
	# One continuous shell. The only ceiling opening is the real stairwell.
	box(Vector3(0, -0.15, 3.8), Vector3(16.4, 0.3, 19.6), mat("ceramic", "c9c5b5"))
	for side in [-1, 1]:
		box(Vector3(side * 8.1, 3.15, 3.8), Vector3(0.2, 6.3, 19.6), plaster)
		box(Vector3(side * 4.65, 3.08, 3.8), Vector3(6.9, 0.24, 19.6), plaster).name = "ContinuousCeilingSide" + str(side)
	box(Vector3(0, 3.08, -0.8), Vector3(2.4, 0.24, 10.6), plaster)
	box(Vector3(0, 3.08, 11.85), Vector3(2.4, 0.24, 3.5), plaster)
	box(Vector3(0, 3.15, -5.9), Vector3(16.4, 6.3, 0.2), plaster)
	box(Vector3(0, 6.25, 3.8), Vector3(16.6, 0.24, 19.9), plaster).name = "ContinuousRoof"
	_room_shell(-4.4, 3.2, -0.5, 6.4, 6.0, 1.1)
	_room_shell(4.4, 3.2, -0.5, 6.4, 6.0, 1.1)
	box(Vector3(0, 4.7, -0.55), Vector3(2.24, 3, 5.9), plaster).name = "SealedUpstairsServiceCore"
	for side in [-1, 1]:
		box(Vector3(side * 7.87, 4.7, -0.55), Vector3(0.38, 3, 5.9), plaster)
	_door("bedroom", Vector3(-4.95, 3.2, 2.5), 0, "Buka pintu kamar")
	_door("nursery", Vector3(3.85, 3.2, 2.5), 0, "Kamar calon adik")
	text("KAMARKU", Vector3(-4.4, 5.55, 2.62), 15)
	text("UNTUK ADIK", Vector3(4.4, 5.55, 2.62), 15)
	box(Vector3(0, 3.075, 3.95), Vector3(16.2, 0.25, 1.1), wood).name = "UpstairsLanding"
	box(Vector3(0, 3.215, 3.5), Vector3(16.1, 0.02, 2.0), wood, false).name = "LandingFinish"
	var stair_start = 4.5
	var run = 5.4
	var rise = 3.2
	for i in range(18):
		var top = rise * (1.0 - float(i + 1) / 18)
		if top > 0.01:
			box(Vector3(0, top / 2 - 0.04, stair_start + (i + 0.5) * 0.3), Vector3(2.1, top + 0.08, 0.30), wood, true).name = "StairTread%d" % i
	var angle = atan2(rise, run)
	var ramp = box(Vector3(0, rise / 2 - cos(angle) * 0.1, stair_start + run / 2 - sin(angle) * 0.1), Vector3(2.1, 0.20, Vector2(run, rise).length()), wood, false)
	ramp.name = "StairRamp"; ramp.rotation.x = angle; ramp.hide()
	for side in [-1, 1]:
		for i in range(18):
			var z = stair_start + (i + 0.5) * 0.3
			var y = rise * (1 - float(i + 1) / 18)
			box(Vector3(side * 0.98, y + 0.49, z), Vector3(0.075, 1.0, 0.075), wood, false).name = "AnchoredBaluster_%s_%d" % [side, i]
		var rail = box(Vector3(side * 0.98, 2.51, 7.2), Vector3(0.12, 0.12, Vector2(run, rise).length()), wood, false)
		rail.rotation.x = angle
		var guard = StaticBody3D.new(); guard.name = "StairGuardLeft" if side < 0 else "StairGuardRight"
		var collider = CollisionShape3D.new(); var shape = ConvexPolygonShape3D.new()
		var points = PackedVector3Array()
		for dx in [-0.06, 0.06]:
			for end in [0, 1]:
				for dy in [0.0, 0.96]: points.append(Vector3(side * 1.14 + dx, rise * (1 - end) + dy, stair_start + run * end))
		shape.points = points; collider.shape = shape; guard.add_child(collider); level.add_child(guard)
		box(Vector3(side * 4.7, 4.7, 4.55), Vector3(6.9, 3.0, 0.18), plaster).name = "LandingEnclosure" + str(side)
		box(Vector3(side * 1.23, 4.7, 7.3), Vector3(0.14, 3, 5.4), plaster)
	box(Vector3(0, 4.7, 10.1), Vector3(2.5, 3, 0.2), plaster)
	# Rooms meet the exterior walls; no narrow strips behind or beside them.
	_room_shell(5.0, 0, 3.0, 6, 5.2, 1.1)
	_room_shell(-5.0, 0, 2.0, 5.5, 5.2, 1.1)
	box(Vector3(0, 1.5, -0.65), Vector3(16, 3, 0.18), plaster)
	box(Vector3(0, 1.5, -3.3), Vector3(16, 3, 5.1), plaster).name = "ClosedGroundServiceRooms"
	box(Vector3(-7.9, 1.5, 2), Vector3(0.45, 3, 5.4), plaster)
	# Fill the unusable strip between bathroom wall and the house shell.
	box(Vector3(-7.92, 1.5, 4.3), Vector3(0.45, 3, 10.4), plaster).name = "SealedBathroomServiceStrip"
	# Close the dead-end slots between the staircase and both ground rooms.
	box(Vector3(-1.62, 1.49, 2.0), Vector3(1.16, 2.98, 5.2), plaster).name = "ClosedBathroomStairGap"
	box(Vector3(1.50, 1.49, 2.50), Vector3(0.94, 2.98, 6.2), plaster).name = "ClosedMotherStairGap"
	_door("father", Vector3(-0.55, 0, -0.49), 0, "Pintu kamar Bapak", false, true)
	_door("mother", Vector3(4.45, 0, 5.6), 0, "Ibu sedang bersiap", true, true)
	_door("bathroom", Vector3(-5.55, 0, 4.6), 0, "Buka kamar mandi")
	text("KAMAR BAPAK", Vector3(0, 2.42, -0.45), 15)
	text("KAMAR IBU", Vector3(5, 2.42, 5.73), 15)
	text("KAMAR MANDI", Vector3(-5, 2.42, 4.73), 15)
	# The front door sits inside a properly sized opening and faces the room.
	for side in [-1, 1]: box(Vector3(side * 4.375, 1.5, 13.6), Vector3(7.65, 3, 0.2), plaster)
	box(Vector3(0, 2.65, 13.6), Vector3(1.1, 0.7, 0.2), plaster)
	preload("res://scripts/systems/free_assets.gd").door(level, Vector3(0, 0, 13.56), PI, "FrontDoor")
	for side in [-1, 1]: box(Vector3(side * 0.57, 1.1, 13.5), Vector3(0.10, 2.2, 0.21), wood, false)
	box(Vector3(0, 2.2, 13.5), Vector3(1.24, 0.1, 0.21), wood, false)
	level.interact(Vector3(0, 1.2, 13.25), "chapter", "Berangkat ke sekolah", "leave_home", false, Vector3(1.05, 2.15, 0.4))
	text("06.12  /  RUMAH", Vector3(-1.45, 2.25, 13.4), 14, PI)
	preload("res://scripts/systems/home_detail.gd").new().build(self)

func _desk(p: Vector3, yaw: float) -> void:
	var root = Node3D.new(); root.position = p; root.rotation.y = yaw; level.add_child(root)
	var wood = mat("burlap", "806249")
	box(Vector3(0, 0.79, 0), Vector3(1.5, 0.12, 0.7), wood, true, root)
	for x in [-0.65, 0.65]:
		for z in [-0.25, 0.25]: box(Vector3(x, 0.38, z), Vector3(0.07, 0.76, 0.07), wood, true, root)

func _flower(p: Vector3) -> void:
	var assets = preload("res://scripts/systems/free_assets.gd")
	var arrangement = Node3D.new(); arrangement.name = "DaisyArrangement%d" % roundi(p.y * 100); arrangement.position = p; level.add_child(arrangement)
	var pot = assets.place(arrangement, "res://assets/vendor/poly/flower_pot_base.glb", Vector3.ZERO, Vector3(0.22, 0.20, 0.22), 0, false, "TerracottaPot")
	for mesh in pot.find_children("*", "MeshInstance3D", true, false):
		for i in range(mesh.mesh.get_surface_count()):
			var material = mesh.get_active_material(i).duplicate()
			material.albedo_color = Color("a07853") if i == 0 else Color("403529"); material.metallic = 0; material.roughness = 0.92
			mesh.set_surface_override_material(i, material)
	G.cylinder(arrangement, Vector3(0, 0.17, 0), 0.082, 0.025, mat("plain", "3c3229"))
	assets.place(arrangement, "res://assets/vendor/poly/daisy.glb", Vector3(0, 0.13, 0), Vector3(0.18, 0.34, 0.17), 0.4, false, "DaisyStems")

func _tree(p: Vector3, height = 5.0) -> void:
	var choices = ["tree_oak", "tree_detailed", "tree_pineTallA_detailed", "tree_default"]
	var index = posmod(int(p.x * 7 + p.z * 3), choices.size())
	preload("res://scripts/systems/free_assets.gd").place(level, "res://assets/vendor/kenney_nature/" + choices[index] + ".glb", p, Vector3(-1, height, -1), p.x + p.z, false, "FreeTree")

func _yard() -> void:
	var afternoon = State.flag("schoolDismissed")
	_sun("ffd5a1" if afternoon else "fff1cc", 0.95, Vector3(-27 if afternoon else -48, -35, 0))
	box(Vector3(0, -0.16, 4), Vector3(44, 0.3, 40), mat("concrete", "aaa991"))
	box(Vector3(0, 0.04, -13.5), Vector3(34, 0.08, 5), mat("ceramic", "bdbfa9"))
	preload("res://scripts/systems/school_detail.gd").new().yard(self)
	for side in [-1, 1]:
		box(Vector3(side * 21.6, 1.25, 4), Vector3(0.3, 2.5, 40), mat("plaster", "8e9b84"))
		box(Vector3(side * 12.0, 0.12, 22.5), Vector3(18, 0.24, 2.5), mat("concrete", "b2b09b"))
		for i in range(4): _tree(Vector3(side * 19.0, 0, -9.0 + i * 8))
		for i in range(25): box(Vector3(side * (3.0 + i * 0.74), 1.7, 23), Vector3(0.055, 2.5, 0.055), mat("steel", "394c40"))
		box(Vector3(side * 11.7, 0.6, 23), Vector3(18, 1.0, 0.3), mat("plaster", "92997f"))
	for side in [-1, 1]:
		box(Vector3(side * 2.6, 1.6, 22.8), Vector3(0.5, 3.2, 0.6), mat("plaster", "d0c6a5"))
	box(Vector3(0, 3.25, 22.8), Vector3(5.7, 0.45, 0.65), mat("plaster", "b4b69d"))
	text("SMA KARTINI", Vector3(0, 3.3, 23.18), 25, PI)
	level.interact(Vector3(0, 1.4, 21.8), "chapter", "Gerbang sekolah", "school_gate", false, Vector3(4, 2.5, 1.0))
	level.interact(Vector3(0, 1.3, -14), "chapter", "Masuk gedung · kelas XI A", "enter_school", false, Vector3(3.2, 2.5, 1.4))
	# Court markings, flagpole, planter borders, benches and outdoor evidence.
	for x in [-7, 7]: box(Vector3(x, 0.006, 3.0), Vector3(0.07, 0.018, 18), mat("plain", "dfd9ba"), false)
	for z in [-6, 3, 12]: box(Vector3(0, 0.006, z), Vector3(14, 0.018, 0.07), mat("plain", "dfd9ba"), false)
	G.cylinder(level, Vector3(-12, 3.8, 1), 0.05, 7.6, mat("steel", "b0b7a7"))
	box(Vector3(-11.36, 7.0, 1), Vector3(1.2, 0.42, 0.025), mat("cotton", "a54232"), false)
	box(Vector3(-11.36, 6.58, 1), Vector3(1.2, 0.42, 0.025), mat("cotton", "e7dfc8"), false)
	var bin = G.cylinder(level, Vector3(13.3, 0.48, 13), 0.4, 0.95, mat("steel", "45594b"))
	bin.name = "EvidenceBin"
	for i in range(6):
		var paper = box(Vector3(13.2 + sin(i * 2.0) * 0.22, 0.98, 13 + cos(i * 2.0) * 0.22), Vector3(0.2, 0.012, 0.15), mat("cotton", "bdb59a"), false)
		paper.rotation.y = i
	level.interact(Vector3(13.3, 1.12, 13), "chapter", "Periksa tong sampah", "trash_photo", false, Vector3(0.95, 1.0, 0.95))
	text("PILAH SAMPAH\nJAGA YANG BERHARGA", Vector3(13.3, 1.9, 12.8), 16)
	level.interact(Vector3(-15, 1.0, -7), "chapter", "Catatan piket gerbang", "gate_note")
	light(Vector3(0, 3, -13), "d7e6db", 1.1, 12)
	preload("res://scripts/systems/street_connection.gd").new().build(self)

func _neighborhood() -> void:
	preload("res://scripts/systems/neighborhood_backdrop.gd").new().build(level, 0)
	_sun("ffc38b", 0.95, Vector3(-16, -60, 0))
	box(Vector3(0, -0.16, 2), Vector3(58, 0.3, 24), mat("concrete", "6c7066"))
	box(Vector3(21, -0.16, -19), Vector3(4, 0.3, 34), mat("concrete", "777366"))
	for z in [-5.5, 9.5]: box(Vector3(0, 0.1, z), Vector3(58, 0.2, 2.5), mat("ceramic", "aaa48d"))
	for x in range(-26, 28, 5): box(Vector3(x, 0.008, 2), Vector3(2.2, 0.02, 0.1), mat("plain", "d0bc8e"), false)
	text("← RUMAH   /   JALAN KARTINI →", Vector3(0, 2.5, -5.8), 26)
	for x in [-24, -15, -6, 6, 15, 27]:
		for side in [-1, 1]:
			var z = -10 if side < 0 else 14
			box(Vector3(x, 2, z), Vector3(7, 4, 5), mat("plaster", ["9b9580", "9faaa0", "8d8374"][absi(x) % 3]))
			box(Vector3(x, 4.1, z), Vector3(7.4, 0.25, 5.5), mat("burlap", "735a47"))
			for dx in [-2, 2]: box(Vector3(x + dx, 2.2, z - side * 2.55), Vector3(1.3, 1.5, 0.08), mat("steel", "4e655e"), false)
	for x in [18.8, 23.2]:
		box(Vector3(x, 1.2, -20), Vector3(0.22, 2.4, 30), mat("plaster", "a29e89"))
		for z in [-12, -21, -30]:
			box(Vector3(x, 1.2, z), Vector3(0.4, 0.08, 1.3), mat("steel", "8e7958"), false)
	box(Vector3(21, 2.0, -35.3), Vector3(4.4, 4.0, 0.3), mat("steel", "403f34"))
	text("GUDANG KARTINI\nAKSES BELAKANG", Vector3(21, 2.5, -35.1), 21)
	text("DANU: lewat kanan.\nJangan lewat rumahmu dulu.", Vector3(19, 1.6, -8.0), 17)
	level.interact(Vector3(21, 1.4, -34.5), "chapter", "Masuk gang Gudang Kartini", "alley", false, Vector3(3.3, 2.5, 1.2))
	level.interact(Vector3(-26.0, 1.2, 1), "chapter", "Jalan menuju rumah", "go_home", false, Vector3(2, 2.5, 8))
	light(Vector3(21, 3.4, -29), "f6bd6e", 1.7, 9, true)
	for x in [-19, -9, 9, 26]: _tree(Vector3(x, 0, 9), 4.5)

func update(delta: float) -> void:
	clock += delta
	if level.room_id == "schoolyard":
		var street = level.get_node_or_null("ConnectedStreet")
		if street != null:
			for npc in street.get_children():
				if not npc.has_meta("start_x"): continue
				npc.position.x = float(npc.get_meta("start_x")) + sin(clock * 0.14 + npc.get_meta("start_x")) * 2.1
				npc.rotation.y = PI / 2 if cos(clock * 0.14 + npc.get_meta("start_x")) > 0 else -PI / 2
				npc.animate_walk(clock * 3.8, 0.25)
	for id in doors:
		var door: Dictionary = doors[id]
		var angle = 0.58 if id == "mother" else -1.4
		door.node.rotation.y = lerp_angle(door.node.rotation.y, door.yaw + angle * float(door.open), minf(1, delta * 5))
	var mother = level.get_node_or_null("Mother") as Node3D
	if mother != null:
		mother.rotation.z = sin(clock * 1.2) * 0.012
		for joint in mother.find_children("*", "Node3D", true, false):
			if joint is MeshInstance3D: continue
			if absf(joint.position.x - 0.27) < 0.03 and absf(joint.position.y - 1.38) < 0.04:
				joint.rotation.x = -2.05 + sin(clock * 1.8) * 0.10
