extends RefCounted
const A = preload("res://scripts/systems/free_assets.gd")
const G = preload("res://scripts/systems/geometry.gd")

func yard(w: RefCounted) -> void:
	var root = Node3D.new(); root.name = "SchoolCampus"; w.level.add_child(root)
	# The resident school's actual walls are its exterior. A second full building
	# mesh here would occupy classrooms after the campus coordinate rebase.
	var cream = w.mat("plain", "c5c8b4")
	var green = w.mat("plain", "3c5d54")
	G.box(root, Vector3(0, 3.35, -14.95), Vector3(6, 0.22, 3.3), cream, false).name = "EntranceCanopy"
	for side in [-1, 1]:
		G.box(root, Vector3(side * 2.65, 1.65, -13.65), Vector3(0.24, 3.3, 0.24), cream, true)
		A.furniture(root, "pottedPlant", Vector3(side * 3.8, 0.15, -14.4), Vector3(-1, 1.4, -1), 0)
	var entrance = preload("res://scripts/systems/campus_doors.gd").new()
	entrance.position = Vector3(0, 0.02, -15.4); root.add_child(entrance)
	G.box(root, Vector3(0, -0.10, -15.5), Vector3(2.7, 0.2, 4.0), w.mat("ceramic", "b7c0ae"), true).name = "ContinuousEntranceFloor"
	for side in [-1, 1]:
		G.box(root, Vector3(side * 1.42, 1.35, -15.2), Vector3(0.18, 2.7, 2.0), cream)
	G.box(root, Vector3(0, 2.73, -15.2), Vector3(3.0, 0.18, 2.0), cream)
	G.box(root, Vector3(0, 4.1, -14.8), Vector3(8.2, 1.10, 0.10), green)
	var sign_node = G.sign_text(root, "SMA KARTINI\nBERANI JUJUR · BERANI PEDULI", Vector3(0, 4.1, -14.73), 32)
	sign_node.pixel_size = 0.008; sign_node.outline_size = 0
	G.sign_text(root, "PINTU MASUK", Vector3(0, 2.97, -13.24), 22)
	for side in [-1, 1]:
		for z in [-7, 5, 16]:
			A.furniture(root, "bench", Vector3(side * 15.5, 0.015, z), Vector3(2.2, 0.85, 0.65), side * PI / 2)
		A.furniture(root, "trashcan", Vector3(side * 17, 0.15, -14.6), Vector3(-1, 0.85, -1), 0, false)
	var paving = ShaderMaterial.new(); paving.shader = preload("res://assets/materials/campus_ground.gdshader")
	G.box(root, Vector3(0, -0.028, 4), Vector3(42.5, 0.04, 36), paving)
	G.box(root, Vector3(0, -0.012, 3), Vector3(14.4, 0.012, 18.4), w.mat("plain", "687f78"))
	G.box(root, Vector3(0, -0.18, -51), Vector3(86, 0.3, 75), w.mat("plain", "65785a"))
	var forest = Node3D.new(); forest.name = "SchoolForest"; root.add_child(forest)
	for i in range(76):
		var side = -1 if i % 2 == 0 else 1
		var x = side * (26.0 + (i % 4) * 3.4 + sin(i * 2.3) * 1.4)
		var z = -18.0 - floorf(i / 4.0) * 3.6
		if i > 60: x = -30 + (i - 60) * 4; z = -84 - (i % 3) * 2
		A.place(forest, "res://assets/vendor/kenney_nature/" + ["tree_oak", "tree_detailed", "tree_pineTallA_detailed"][i % 3] + ".glb", Vector3(x, -0.025, z), Vector3(-1, 5.0 + (i % 5) * 0.48, -1), i * 1.7, false)
	for side in [-1, 1]:
		for z in [-12, -4, 5, 14]:
			G.box(root, Vector3(side * 18.8, 0.16, z), Vector3(2.4, 0.32, 2.4), w.mat("concrete", "888d7c"), true)
			A.place(root, "res://assets/vendor/kenney_nature/plant_bushDetailed.glb", Vector3(side * 18.8, 0.32, z), Vector3(2.1, 0.8, 2.1), 0, false)

func interior(level: Node3D) -> void:
	var root = Node3D.new(); root.name = "SchoolFurnishings"; level.add_child(root)
	# The source ceiling was a single 36 x 66 m plane. Seen from the resident
	# yard, that plane became a floating concrete slab across the whole facade.
	for label in ["Source_69", "Source_70"]:
		var old = level.find_child(label, true, false)
		if old == null: continue
		old.hide()
		for body in old.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0
	preload("res://scripts/systems/school_architecture.gd").new().build(level)
	# Source peeling plaster is replaced with maintained classroom plaster.
	var wall_material = G.material("plain", Color("d2d7cb"))
	for mesh in level.get_node("SourceWorld").find_children("*", "MeshInstance3D", true, false):
		var size: Vector3 = (mesh.global_transform * mesh.get_aabb()).size
		if size.y > 1.6 and minf(size.x, size.z) < 0.4 and maxf(size.x, size.z) > 1.8:
			mesh.material_override = wall_material
	# Imported shelving, cupboards and plants fill the teaching and public rooms.
	for p in [Vector3(-12.6, 0, -22), Vector3(-12.6, 0, -19), Vector3(10.8, 0, 15.7)]:
		A.furniture(root, "bookcaseOpen", p, Vector3(1.6, 2.05, 0.4), PI / 2)
	for p in [Vector3(1.3, 0, 1), Vector3(-1.3, 0, -26), Vector3(10.8, 0, -16.8)]:
		A.furniture(root, "pottedPlant", p, Vector3(-1, 1.15, -1))
	A.furniture(root, "bathroomCabinet", Vector3(10.6, 0, -11.0), Vector3(1.6, 1.0, 0.5))
	for z in [-2.8, 21]:
		A.furniture(root, "bench", Vector3(1.36, 0, z), Vector3(1.6, 0.75, 0.5), -PI / 2)
