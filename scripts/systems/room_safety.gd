extends RefCounted

var regions: Array = []
var blockers: Array = []
var extent = Rect2()
static var definitions: Dictionary = {}

func setup(level: Node3D) -> void:
	if definitions.is_empty(): definitions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/walkable_bounds.json"))
	regions = definitions[level.room_id].rects
	blockers = definitions[level.room_id].blockers
	for i in range(regions.size()):
		var r = regions[i]
		var rect = Rect2(r.x, r.z, r.w, r.d)
		extent = rect if i == 0 else extent.merge(rect)
	if not level.has_node("MapBoundary"): _build_perimeter(level)

func contains(point: Vector3, radius = 0.0) -> bool:
	if not _inside(Vector2(point.x, point.z)): return false
	if radius > 0:
		for i in range(8):
			var offset = Vector2.from_angle(float(i) * TAU / 8) * radius
			if not _inside(Vector2(point.x, point.z) + offset): return false
	return true

func _inside(point: Vector2) -> bool:
	for r in regions:
		if point.x >= r.x - 0.001 and point.x <= r.x + r.w + 0.001 and point.y >= r.z - 0.001 and point.y <= r.z + r.d + 0.001: return true
	return false

func floor_limit(point: Vector3) -> float:
	var lowest = INF
	for r in regions:
		if Rect2(r.x, r.z, r.w, r.d).grow(0.05).has_point(Vector2(point.x, point.z)): lowest = minf(lowest, r.y)
	return lowest if lowest < INF else -20.0

func _build_perimeter(level: Node3D) -> void:
	var body = StaticBody3D.new()
	body.name = "MapBoundary"
	body.collision_layer = 1
	body.collision_mask = 0
	level.add_child(body)
	var xs: Array[float] = []
	var zs: Array[float] = []
	var low = 0.0
	var high = 3.4
	for r in regions:
		for x in [r.x, r.x + r.w]:
			if not xs.has(float(x)): xs.append(float(x))
		for z in [r.z, r.z + r.d]:
			if not zs.has(float(z)): zs.append(float(z))
		low = minf(low, r.y - 1.5)
		high = maxf(high, r.y + r.h)
	xs.sort(); zs.sort()
	var wall_material = StandardMaterial3D.new()
	wall_material.albedo_color = Color("363b38")
	wall_material.roughness = 0.95
	for xi in range(xs.size() - 1):
		for zi in range(zs.size() - 1):
			var x = (xs[xi] + xs[xi + 1]) * 0.5
			var z = (zs[zi] + zs[zi + 1]) * 0.5
			if not _inside(Vector2(x, z)): continue
			for side in [-1, 1]:
				var ex = xs[xi] if side < 0 else xs[xi + 1]
				if not _inside(Vector2(ex + side * 0.02, z)):
					_wall(body, Vector3(ex + side * 0.09, (low + high) / 2, z), Vector3(0.18, high - low, zs[zi + 1] - zs[zi] + 0.1), wall_material)
				var ez = zs[zi] if side < 0 else zs[zi + 1]
				if not _inside(Vector2(x, ez + side * 0.02)):
					_wall(body, Vector3(x, (low + high) / 2, ez + side * 0.09), Vector3(xs[xi + 1] - xs[xi] + 0.1, high - low, 0.18), wall_material)

func _wall(parent: Node3D, position_value: Vector3, size_value: Vector3, material: Material) -> void:
	var collider = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size_value
	collider.shape = shape
	collider.position = position_value
	parent.add_child(collider)
	var mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size_value
	mesh.mesh = box
	mesh.position = position_value
	mesh.material_override = material
	parent.add_child(mesh)
