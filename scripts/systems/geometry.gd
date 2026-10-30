class_name KalaGeometry
extends RefCounted

static var materials: Dictionary = {}
const MAPS = {"plaster": 8, "concrete": 11, "steel": 14, "ceramic": 17, "burlap": 20, "sinew": 23, "brass": 26, "cotton": 29}

static func material(kind: String, tint = Color.WHITE) -> StandardMaterial3D:
	var key = kind + str(tint)
	if materials.has(key): return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.roughness = 0.85
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if MAPS.has(kind):
		var index: int = MAPS[kind]
		mat.albedo_texture = load("res://assets/textures/embedded_%03d.jpg" % index)
		mat.normal_enabled = true
		mat.normal_texture = load("res://assets/textures/embedded_%03d.webp" % (index + 1))
		mat.normal_scale = 0.5
		mat.roughness_texture = load("res://assets/textures/embedded_%03d.webp" % (index + 2))
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3.ONE * 0.6
	if kind in ["steel", "brass"]: mat.metallic = 0.45
	materials[key] = mat
	return mat

static func box(parent: Node3D, pos: Vector3, size: Vector3, mat: Material, solid = false) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = mat
	mesh.position = pos
	parent.add_child(mesh)
	if solid:
		var body = StaticBody3D.new()
		var collision = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = size
		collision.shape = box_shape
		body.add_child(collision)
		mesh.add_child(body)
	return mesh

static func sphere(parent: Node3D, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = SphereMesh.new()
	shape.radial_segments = 20
	shape.rings = 12
	mesh.mesh = shape
	mesh.scale = size
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

static func cylinder(parent: Node3D, pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh = MeshInstance3D.new()
	var shape = CylinderMesh.new()
	shape.top_radius = radius
	shape.bottom_radius = radius
	shape.height = height
	shape.radial_segments = 20
	mesh.mesh = shape
	mesh.position = pos
	mesh.material_override = mat
	parent.add_child(mesh)
	return mesh

static func sign_text(parent: Node3D, text: String, pos: Vector3, size = 28, yaw = 0.0) -> Label3D:
	var sign_node = Label3D.new()
	sign_node.text = text
	sign_node.font_size = size
	sign_node.pixel_size = 0.008
	sign_node.modulate = Color("dbd2b4")
	sign_node.outline_size = 4
	sign_node.position = pos
	sign_node.rotation.y = yaw
	sign_node.no_depth_test = false
	parent.add_child(sign_node)
	return sign_node

static func humanoid(parent: Node3D, pos: Vector3, kind: String) -> Node3D:
	# Articulated primitive blockout, deliberately not claimed as a finished model.
	var rig = Node3D.new()
	rig.position = pos
	parent.add_child(rig)
	var skin = material("plain", Color("c4aa90"))
	var cloth = material("cotton", Color("abb9c6")) if kind == "Daisy" else material("plain", Color("b8b5a5"))
	var dark = material("plain", Color("242d2c"))
	box(rig, Vector3(0, 1.05, 0), Vector3(0.42, 0.6, 0.24), cloth)
	sphere(rig, Vector3(0, 1.6, 0), Vector3(0.35, 0.42, 0.34), skin)
	sphere(rig, Vector3(0, 1.73, -0.025), Vector3(0.37, 0.22, 0.34), material("plain", Color("b39a5f")) if kind == "Daisy" else dark)
	for side in [-1, 1]:
		sphere(rig, Vector3(side * 0.075, 1.62, 0.162), Vector3(0.035, 0.04, 0.018), dark)
		var arm = Node3D.new()
		arm.name = "ArmL" if side == -1 else "ArmR"
		arm.position = Vector3(side * 0.29, 1.3, 0)
		rig.add_child(arm)
		box(arm, Vector3(0, -0.25, 0), Vector3(0.13, 0.55, 0.15), cloth)
		sphere(arm, Vector3(0, -0.56, 0), Vector3(0.12, 0.15, 0.12), skin)
		var leg = Node3D.new()
		leg.name = "LegL" if side == -1 else "LegR"
		leg.position = Vector3(side * 0.12, 0.77, 0)
		rig.add_child(leg)
		box(leg, Vector3(0, -0.35, 0), Vector3(0.16, 0.7, 0.17), dark)
		box(leg, Vector3(0, -0.71, 0.055), Vector3(0.19, 0.12, 0.3), dark)
	return rig
