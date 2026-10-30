extends RefCounted

const FURNITURE = "res://assets/vendor/kenney_furniture/"
const SUBURBAN = "res://assets/vendor/kenney_suburban/"

static func _bounds(node: Node3D, transform_value = Transform3D.IDENTITY) -> AABB:
	var combined = AABB()
	var started = false
	for child in node.get_children():
		if not child is Node3D: continue
		var child_transform: Transform3D = transform_value * child.transform
		if child is MeshInstance3D:
			var bounds: AABB = child_transform * child.get_aabb()
			combined = combined.merge(bounds) if started else bounds
			started = true
		if child.get_child_count() > 0:
			var nested = _bounds(child, child_transform)
			if nested.size.length() > 0:
				combined = combined.merge(nested) if started else nested
				started = true
	return combined

static func place(parent: Node3D, path: String, point: Vector3, dimensions: Vector3, yaw = 0.0, solid = true, title = "", source_yaw = 0.0) -> Node3D:
	var prop = Node3D.new()
	prop.name = title if title != "" else path.get_file().get_basename().validate_node_name()
	parent.add_child(prop)
	var source = load(path)
	var model: Node3D
	if source is PackedScene: model = source.instantiate()
	else:
		model = MeshInstance3D.new()
		model.mesh = source
	var orient = Node3D.new()
	prop.add_child(orient); orient.add_child(model); model.rotation.y = source_yaw
	var bounds = _bounds(orient)
	var scale_value = Vector3.ONE * (dimensions.y / maxf(bounds.size.y, 0.001))
	for axis in range(3):
		if dimensions[axis] > 0: scale_value[axis] = dimensions[axis] / maxf(bounds.size[axis], 0.001)
	orient.scale = scale_value
	orient.position = -Vector3(bounds.get_center().x, bounds.position.y, bounds.get_center().z) * scale_value
	prop.position = point; prop.rotation.y = yaw
	prop.set_meta("asset_source", path)
	prop.set_meta("dimensions", bounds.size * scale_value)
	if path.contains("kenney_nature"):
		for mesh in prop.find_children("*", "MeshInstance3D", true, false):
			for i in range(mesh.mesh.get_surface_count()):
				var source_material = mesh.get_active_material(i)
				if not source_material is StandardMaterial3D: continue
				var material = source_material.duplicate(); material.metallic = 0; material.roughness = 0.96
				var key = str(source_material.resource_name).to_lower()
				if "leaf" in key: material.albedo_color = Color("506c44") if i % 2 == 0 else Color("617c4b")
				elif "wood" in key: material.albedo_color = Color("665640")
				mesh.set_surface_override_material(i, material)
	if solid:
		var body = StaticBody3D.new(); body.name = "ContactBody"
		var collider = CollisionShape3D.new(); var shape = BoxShape3D.new()
		shape.size = bounds.size * scale_value
		collider.shape = shape; collider.position.y = shape.size.y / 2
		body.add_child(collider); prop.add_child(body)
	return prop

static func furniture(parent: Node3D, id: String, point: Vector3, dimensions: Vector3, yaw = 0.0, solid = true, title = "") -> Node3D:
	return place(parent, FURNITURE + id + ".glb", point, dimensions, yaw, solid, title)

static func door(parent: Node3D, point: Vector3, yaw = 0.0, title = "DoorLeaf") -> Node3D:
	# Model the slab separately from the stationary jamb. The imported asset
	# included trim in its bounds; rotating/scaling that trim cut into plaster.
	var leaf = Node3D.new(); leaf.name = title; parent.add_child(leaf)
	leaf.position = point; leaf.rotation.y = yaw
	var g = preload("res://scripts/systems/geometry.gd")
	var wood = g.material("plain", Color("866444"))
	var inset = g.material("plain", Color("97734f"))
	var brass = g.material("plain", Color("b6a170"))
	g.box(leaf, Vector3(0, 1.08, 0), Vector3(1.04, 2.14, 0.065), wood, true).name = "SolidDoorSlab"
	for side in [-1, 1]:
		for y in [0.48, 1.47]:
			g.box(leaf, Vector3(0, y, side * 0.039), Vector3(0.74, 0.73, 0.013), inset)
		g.box(leaf, Vector3(0.37, 1.02, side * 0.048), Vector3(0.07, 0.22, 0.018), brass)
		g.box(leaf, Vector3(0.30, 1.04, side * 0.082), Vector3(0.19, 0.035, 0.035), brass)
	return leaf
