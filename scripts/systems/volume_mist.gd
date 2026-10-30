extends RefCounted

static func add(parent: Node3D, title: String, p: Vector3, size: Vector3, density: float, tint = Color("879ba4")) -> FogVolume:
	var volume = FogVolume.new(); volume.name = title; volume.position = p
	volume.shape = RenderingServer.FOG_VOLUME_SHAPE_BOX; volume.size = size
	# Compatibility uses Environment distance fog; never compile an unsupported
	# fog shader there. The headless dummy renderer still allows structural tests.
	if RenderingServer.get_current_rendering_method() != "forward_plus" and DisplayServer.get_name() != "headless":
		volume.visible = false; parent.add_child(volume); return volume
	var mat = ShaderMaterial.new(); mat.shader = load("res://assets/materials/volume_mist.gdshader")
	mat.set_shader_parameter("density", density); mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	volume.material = mat; parent.add_child(volume); return volume
