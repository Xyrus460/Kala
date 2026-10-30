extends RefCounted

static var definitions: Dictionary = {}
const WALLS = {
	"loading": ["888070", "454634", "75452d", 0.86, 1.0],
	"relay": ["7e827e", "30484a", "615644", 0.72, 2.0],
	"production": ["8d8271", "35443e", "623a26", 0.98, 1.0],
	"office": ["8e8573", "524239", "754f36", 0.52, 0.0],
	"ritual": ["626260", "373332", "443d38", 0.80, 2.0],
	"corridor": ["7c8988", "29454b", "604e40", 0.76, 0.0],
	"pursuit": ["72716c", "373c37", "5b3524", 0.94, 1.0],
	"street": ["807a70", "454c40", "74472e", 0.80, 1.0]}

func apply(level: Node3D) -> void:
	# Flat signs/papers exported from Three.js are visual planes. Old baked
	# scenes gave them triangle collision, creating invisible head-height bars.
	var source_world = level.get_node_or_null("SourceWorld")
	if source_world != null:
		for mesh in source_world.find_children("*", "MeshInstance3D", true, false):
			for surface in range(mesh.mesh.get_surface_count()):
				var material = mesh.get_active_material(surface)
				if material is BaseMaterial3D: material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			var bounds: AABB = mesh.global_transform * mesh.get_aabb()
			var size = bounds.size
			if size.y < 0.035 and size.x > 2.0 and size.z > 2.0:
				for body in mesh.get_children():
					if body is StaticBody3D: body.collision_layer = 1
				continue
			if minf(size.x, minf(size.y, size.z)) >= 0.035: continue
			for body in mesh.get_children():
				if body is StaticBody3D: body.collision_layer = 0
	if definitions.is_empty(): definitions = JSON.parse_string(FileAccess.get_file_as_string("res://assets/source_presentation.json"))
	var data: Dictionary = definitions[level.room_id]
	for effect in data.effects:
		var mesh = level.find_child(effect.name, true, false) as MeshInstance3D
		if mesh == null: continue
		mesh.set_meta("light_volume", true)
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for body in mesh.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0
		var mat = ShaderMaterial.new()
		mat.shader = preload("res://assets/materials/light_shaft.gdshader")
		mat.set_shader_parameter("shaft_color", Color(effect.color[0], effect.color[1], effect.color[2]).linear_to_srgb())
		mat.set_shader_parameter("intensity", float(effect.intensity))
		mat.set_shader_parameter("roof_beam", effect.type == "roof")
		mesh.set_surface_override_material(int(effect.surface), mat)
		mesh.visible = float(effect.intensity) > 0.0
	if WALLS.has(level.room_id):
		var profile: Array = WALLS[level.room_id]
		var mat = ShaderMaterial.new()
		mat.shader = preload("res://assets/materials/aged_wall.gdshader")
		mat.set_shader_parameter("plaster", Color(profile[0]))
		mat.set_shader_parameter("paint", Color(profile[1]))
		mat.set_shader_parameter("masonry", Color(profile[2]))
		mat.set_shader_parameter("decay", profile[3])
		mat.set_shader_parameter("pattern", profile[4])
		mat.set_shader_parameter("seed", float(State.ROOMS.find(level.room_id) + 1))
		for wall in data.walls:
			var mesh = level.find_child(wall.name, true, false) as MeshInstance3D
			if mesh != null: mesh.set_surface_override_material(int(wall.surface), mat)
		var boundary = level.get_node_or_null("MapBoundary")
		if boundary != null:
			for mesh in boundary.find_children("*", "MeshInstance3D", false, false): mesh.material_override = mat
	if not level.has_node("ContrastLighting"):
		var lights = Node3D.new()
		lights.name = "ContrastLighting"
		level.add_child(lights)
		for practical in level.get_children():
			if not practical is OmniLight3D or not str(practical.name).begins_with("Practical_"): continue
			practical.light_energy = 0.045 if level.room_id != "school" else 0.075
			practical.omni_range = 6.0
			var spot = SpotLight3D.new()
			spot.position = practical.position
			spot.rotation.x = -PI / 2
			spot.light_color = practical.light_color.lerp(Color("acbdc8"), 0.28)
			spot.light_energy = 1.45 if level.room_id == "school" else 2.5
			spot.spot_range = clampf(practical.position.y + 6.0, 7, 15)
			spot.spot_angle = 43
			spot.spot_angle_attenuation = 0.30
			spot.spot_attenuation = 0.7
			spot.shadow_enabled = true
			spot.shadow_bias = 0.08
			spot.shadow_normal_bias = 0.7
			lights.add_child(spot)
	var key = level.get_node_or_null("RoomKey") as SpotLight3D
	if key != null: key.light_energy = 0.38; key.spot_angle = 37
	var sun = level.get_node_or_null("DiscoverySun") as DirectionalLight3D
	if sun != null:
		sun.light_energy = 2.25
		sun.shadow_bias = 0.025
		sun.shadow_normal_bias = 0.6
