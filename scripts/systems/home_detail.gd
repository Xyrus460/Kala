extends RefCounted
const G = preload("res://scripts/systems/geometry.gd")
const A = preload("res://scripts/systems/free_assets.gd")
var w: RefCounted
var root: Node3D

func prop(id: String, p: Vector3, size: Vector3, yaw = 0.0, solid = true, title = "") -> Node3D:
	var replacements = {"bedSingle":"bed_single", "bedDouble":"bed_double", "bookcaseClosedDoors":"wardrobe", "desk":"desk", "chairDesk":"task_chair", "cabinetBedDrawer":"chest", "loungeChairRelax":"armchair", "rugRounded":"wool_rug", "rugRound":"jute_rug", "sideTable":"nightstand", "lampRoundFloor":"floor_lamp", "lampRoundTable":"table_lamp"}
	if replacements.has(id):
		var item = A.place(root, "res://assets/vendor/revision10/%s.glb" % replacements[id], p, size, yaw, solid, title if title != "" else id)
		if id == "bedSingle": _rest_pillow(item)
		_finish(item)
		return item
	return A.furniture(root, id, p, size, yaw, solid, title)

func _rest_pillow(bed: Node3D) -> void:
	var pillow = bed.find_child("single-bed-timber_3", true, false) as MeshInstance3D
	var mattress = bed.find_child("single-bed-timber_2", true, false) as MeshInstance3D
	if pillow == null or mattress == null: return
	# The source cushion has a baked incline. Level its long axis before
	# seating it into the duvet, rather than only lowering one of its corners.
	var vertices: PackedVector3Array = pillow.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var center = Vector3.ZERO
	for vertex in vertices: center += vertex
	center /= vertices.size()
	var yy = 0.0; var zz = 0.0; var yz = 0.0
	for vertex in vertices:
		var offset = vertex - center
		yy += offset.y * offset.y; zz += offset.z * offset.z; yz += offset.y * offset.z
	pillow.rotation.x = 0.5 * atan2(2.0 * yz, zz - yy)
	var support = _surface_bounds(mattress)
	var bounds = _surface_bounds(pillow)
	pillow.global_position += Vector3(0, support.end.y - bounds.position.y - 0.016, 0.10)
	pillow.set_meta("rests_on_mattress", true)

func _surface_bounds(mesh: MeshInstance3D) -> AABB:
	var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var bounds = AABB(mesh.global_transform * vertices[0], Vector3.ZERO)
	for vertex in vertices: bounds = bounds.expand(mesh.global_transform * vertex)
	return bounds

func _finish(item: Node3D) -> void:
	for mesh in item.find_children("*", "MeshInstance3D", true, false):
		if mesh.mesh == null: continue
		for surface in range(mesh.mesh.get_surface_count()):
			var original = mesh.get_active_material(surface)
			if not original is StandardMaterial3D or original.albedo_texture != null: continue
			var kind = str(original.resource_name).to_lower()
			if kind not in ["oak", "walnut", "linen", "sage", "fabricgrey", "fabricblue", "mustard"]: continue
			var finish = ShaderMaterial.new(); finish.shader = preload("res://assets/materials/furniture_surface.gdshader")
			finish.set_shader_parameter("tint", original.albedo_color)
			finish.set_shader_parameter("fabric", kind not in ["oak", "walnut"])
			mesh.set_surface_override_material(surface, finish)

func mirror(p: Vector3, size: Vector2) -> void:
	prop("bathroomMirror", p - Vector3(0, size.y / 2 + 0.06, 0.02), Vector3(size.x + 0.12, size.y + 0.12, 0.10), 0, false)
	var glass = preload("res://scripts/systems/planar_mirror.gd").new()
	glass.position = p; glass.dimensions = size; root.add_child(glass)

func build(world: RefCounted) -> void:
	w = world; root = Node3D.new(); root.name = "FurnishedHome"; w.level.add_child(root)
	prop("loungeSofa", Vector3(-6.9, 0, 10.6), Vector3(2.8, 0.95, 1.0), PI / 2, true, "LivingSofa")
	prop("rugRectangle", Vector3(-5.3, 0.015, 10.6), Vector3(3.0, 0.025, 3.6), 0, false)
	prop("tableCoffee", Vector3(-5.2, 0.04, 12.1), Vector3(1.2, 0.43, 0.70))
	prop("books", Vector3(-5.15, 0.48, 12), Vector3(0.32, 0.11, 0.30), 0.2, false)
	prop("sideTableDrawers", Vector3(-6.9, 0, 8.6), Vector3(0.65, 0.63, 0.6))
	prop("lampRoundTable", Vector3(-6.9, 0.63, 8.6), Vector3(-1, 0.48, -1), 0, false)
	prop("pottedPlant", Vector3(-7.25, 0, 12.8), Vector3(-1, 1.3, -1))
	prop("cabinetTelevisionDoors", Vector3(-2.7, 0, 9.0), Vector3(1.8, 0.62, 0.42), -PI / 2)
	prop("televisionVintage", Vector3(-2.7, 0.62, 9.0), Vector3(0.85, 0.6, 0.4), -PI / 2, false)
	prop("bookcaseOpenLow", Vector3(2.8, 0, 13.12), Vector3(2.1, 1.12, 0.4), PI)
	for i in range(4):
		prop("books", Vector3(2.05 + i * 0.45, 0.48, 13.12), Vector3(0.32, 0.35, 0.25), PI, false)
	prop("tableRound", Vector3(4.7, 0, 10.6), Vector3(2.1, 0.78, 1.6))
	for i in range(4):
		var angle = i * PI / 2
		var p = Vector3(4.7 + sin(angle) * 1.15, 0, 10.6 + cos(angle) * 1.15)
		prop("chairCushion", p, Vector3(0.49, 0.91, 0.53), angle + PI)
	for i in range(3):
		var z = 9.4 + i * 1.15
		prop(["kitchenStove", "kitchenCabinetDrawer", "kitchenSink"][i], Vector3(7.45, 0, z), Vector3(1.05, 0.94, 0.65), -PI / 2)
		prop("kitchenCabinetUpperDouble", Vector3(7.72, 1.65, z), Vector3(1.05, 0.66, 0.37), -PI / 2)
	prop("kitchenFridge", Vector3(7.4, 0, 7.55), Vector3(0.82, 1.85, 0.77), -PI / 2)
	prop("kitchenCoffeeMachine", Vector3(7.45, 0.94, 10.5), Vector3(-1, 0.30, -1), -PI / 2, false)
	w._flower(Vector3(4.7, 0.785, 10.6))
	prop("bedSingle", Vector3(-6.2, 3.215, -0.8), Vector3(1.20, 1.05, 2.20))
	prop("bookcaseClosedDoors", Vector3(-2.2, 3.215, -2.65), Vector3(1.15, 2.2, 0.56))
	prop("desk", Vector3(-3.7, 3.215, -2.5), Vector3(1.75, 0.79, 0.72))
	prop("chairDesk", Vector3(-3.6, 3.215, -1.6), Vector3(0.52, 1.0, 0.52), PI)
	A.place(root, "res://assets/vendor/poly/radio.glb", Vector3(-3.6, 4.01, -2.48), Vector3(0.50, 0.32, 0.23), 0, false, "VintageRadio")
	w.level.interact(Vector3(-3.6, 4.2, -2.3), "chapter", "Dengarkan radio", "radio")
	w._flower(Vector3(-2.98, 4.01, -2.5))
	w.level.interact(Vector3(-2.98, 4.27, -2.5), "chapter", "Bunga daisy dari Ibu", "daisy_home", false, Vector3(0.32, 0.5, 0.32))
	prop("sideTable", Vector3(-7.15, 3.215, 0.8), Vector3(0.55, 0.53, 0.55))
	prop("lampRoundTable", Vector3(-7.15, 3.75, 0.8), Vector3(-1, 0.46, -1), 0, false)
	prop("rugRounded", Vector3(-4.5, 3.22, 0.0), Vector3(1.9, 0.025, 1.6), 0, false, "WovenBedroomRug")
	window(Vector3(-5, 4.85, -3.36), Vector2(2.1, 1.45))
	A.place(root, "res://assets/vendor/innerscene/crib.glb", Vector3(5.8, 3.215, -1.8), Vector3(-1, 1.05, -1), PI / 2, true, "BabyCrib")
	prop("cabinetBedDrawer", Vector3(2.2, 3.215, -2.6), Vector3(1.5, 0.88, 0.65), 0, true, "ChangingStation")
	G.box(root, Vector3(2.2, 4.13, -2.6), Vector3(1.25, 0.1, 0.55), w.mat("cotton", "dcd9c0"))
	# A folded linen changing mat, instead of the bright pink block pillow.
	var mat_pad = G.sphere(root, Vector3(2.2, 4.19, -2.6), Vector3(1.08, 0.12, 0.45), w.mat("cotton", "d7d6c4"))
	mat_pad.name = "ChangingMat"
	prop("loungeChairRelax", Vector3(6.5, 3.215, 0.7), Vector3(0.8, 1.0, 0.86), -0.5)
	prop("lampRoundFloor", Vector3(7.05, 3.215, 1.4), Vector3(-1, 1.65, -1), 0, false)
	prop("rugRound", Vector3(4.4, 3.22, -0.1), Vector3(2.3, 0.025, 2.3), 0, false)
	prop("bookcaseOpenLow", Vector3(2.0, 3.215, 0.4), Vector3(1.15, 1.0, 0.34), PI / 2)
	prop("bear", Vector3(2.05, 4.22, 0.4), Vector3(-1, 0.3, -1), PI / 2, false)
	prop("cardboardBoxOpen", Vector3(2.7, 3.215, 1.65), Vector3(0.44, 0.35, 0.44))
	prop("books", Vector3(2.13, 3.75, 0.4), Vector3(-1, 0.2, -1), PI / 2, false)
	window(Vector3(4.4, 4.85, -3.36), Vector2(2.0, 1.45))
	for x in [2.5, 6.5]: framed(Vector3(x, 4.95, 2.38), Vector2(0.58, 0.63), "b8a0a0", PI)
	w.level.interact(Vector3(2.3, 4.20, -2.3), "chapter", "Daftar persiapan adik", "nursery_note", false, Vector3(0.8, 0.5, 0.5))
	G.box(root, Vector3(2.3, 4.2, -2.3), Vector3(0.30, 0.015, 0.23), w.mat("cotton", "f5edd5"))
	prop("desk", Vector3(5.2, 0, 2.0), Vector3(1.4, 0.78, 0.66))
	prop("chairCushion", Vector3(6.1, 0, 4.2), Vector3(0.52, 0.92, 0.52), PI, false)
	prop("bedDouble", Vector3(7, 0, 3.1), Vector3(1.55, 0.85, 2.15))
	mirror(Vector3(5.2, 1.65, 1.65), Vector2(0.9, 1.05))
	var mother = A.place(w.level, "res://assets/vendor/poly/mother.glb", Vector3(5.3, 0, 2.9), Vector3(-1, 1.67, -1), PI, false, "Mother")
	for mesh in mother.find_children("*", "MeshInstance3D", true, false):
		for i in range(mesh.mesh.get_surface_count()):
			var original = mesh.get_active_material(i)
			if not original is StandardMaterial3D: continue
			var material = original.duplicate()
			if str(original.resource_name).begins_with("Hair_"): material.albedo_color = Color("302a25")
			elif str(original.resource_name) == "Orange": material.albedo_color = Color("77646a")
			material.roughness = 0.86; mesh.set_surface_override_material(i, material)
	for animation in mother.find_children("*", "AnimationPlayer", true, false):
		for clip in animation.get_animation_list():
			if str(clip).ends_with("Idle_Neutral"):
				animation.get_animation(clip).loop_mode = Animation.LOOP_LINEAR; animation.play(clip); break
	G.box(root, Vector3(-5, 0.012, 2), Vector3(5.25, 0.024, 4.9), w.mat("ceramic", "b1c6c4"))
	prop("toilet", Vector3(-6.9, 0.025, 0.4), Vector3(0.60, 0.87, 0.76), 0, true, "Toilet")
	prop("bathroomSinkSquare", Vector3(-5, 0.025, -0.15), Vector3(1.05, 0.95, 0.6), 0, true, "BathroomSink")
	mirror(Vector3(-5, 1.78, -0.44), Vector2(0.9, 1.0))
	var shower = preload("res://scripts/systems/bathroom_shower.gd").new()
	shower.name = "BathroomShower"; shower.position = Vector3(-3.1, 0.025, 0.45); root.add_child(shower)
	prop("rugRectangle", Vector3(-4.5, 0.03, 3.4), Vector3(1.2, 0.025, 0.75), 0, false)
	prop("trashcan", Vector3(-7, 0.025, 2.1), Vector3(-1, 0.45, -1))
	w.level.interact(Vector3(-3.1, 1.05, 0.80), "chapter", "Nyalakan shower · mandi dan bersiap", "wash", false, Vector3(0.85, 1.4, 0.4))
	for i in range(3): framed(Vector3(-5.8 + i * 1.35, 1.9, 13.43), Vector2(0.75, 0.55), ["9bab95", "c8aa7e", "b99b8a"][i], PI)
	prop("coatRackStanding", Vector3(-1.4, 0, 12.9), Vector3(-1, 1.65, -1))
	prop("rugDoormat", Vector3(0, 0.02, 12.95), Vector3(1.35, 0.025, 0.6), 0, false)
	prop("rugRectangle", Vector3(0, 3.23, 3.8), Vector3(11, 0.025, 0.6), 0, false)
	# Frames mount on the enclosed side walls, away from either bedroom opening.
	for x in [-6.5, -2.4, 2.4, 6.5]: framed(Vector3(x, 4.85, 4.43), Vector2(0.70, 0.55), "a0b5a4", PI)
	for p in [Vector3(-5.2, 2.8, 10.5), Vector3(4.8, 2.8, 10.5), Vector3(-4.4, 5.9, -0.5), Vector3(4.4, 5.9, -0.5), Vector3(0, 5.9, 3.8), Vector3(-5, 2.7, 2), Vector3(5, 2.7, 3)]:
		prop("lampSquareCeiling", p, Vector3(0.40, 0.1, 0.40), 0, false, "CeilingFixture")
		w.light(p - Vector3.UP * 0.15, "fff0d5", 0.65, 6)

func framed(p: Vector3, size: Vector2, color: String, yaw: float) -> void:
	var frame = Node3D.new(); frame.position = p; frame.rotation.y = yaw; root.add_child(frame)
	G.box(frame, Vector3.ZERO, Vector3(size.x, size.y, 0.055), w.mat("burlap", "826649"))
	G.box(frame, Vector3(0, 0, 0.033), Vector3(size.x - 0.09, size.y - 0.09, 0.014), w.mat("plain", color))
	G.sphere(frame, Vector3(-size.x * 0.1, 0.02, 0.045), Vector3(size.x * 0.30, size.y * 0.40, 0.01), w.mat("plain", "e5d5aa"))

func window(p: Vector3, size: Vector2) -> void:
	G.box(root, p, Vector3(size.x, size.y, 0.05), w.mat("plain", "adc9d1"))
	for side in [-1, 1]:
		G.box(root, p + Vector3(side * size.x / 2, 0, 0.04), Vector3(0.06, size.y + 0.1, 0.08), w.mat("burlap", "e1d6be"))
	var curtains = A.place(root, "res://assets/vendor/revision10/curtains.glb", p + Vector3(0, -size.y / 2 - 0.20, 0.16), Vector3(size.x + 0.55, size.y + 0.48, 0.18), 0, false, "LinenCurtains")
	_finish(curtains)
	for y in [-size.y / 2, 0.0, size.y / 2]: G.box(root, p + Vector3(0, y, 0.04), Vector3(size.x, 0.06, 0.08), w.mat("burlap", "e1d6be"))
	w.light(p + Vector3(0, 0, 0.6), "e1edf0", 0.6, 4)
