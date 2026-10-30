extends RefCounted

static func apply(host: Node3D, id: String) -> void:
	var env: Environment = host.get_node("WorldEnvironment").environment
	var daylight = id in ["home", "school", "schoolyard", "neighborhood"]
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b6c4ce") if daylight else Color("9daeb9")
	env.ambient_light_energy = 0.43 if daylight else 0.20 if id == "daisy" else 0.14
	env.ambient_light_sky_contribution = 0.0
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_density = 0.0008 if daylight else 0.0045
	env.fog_light_color = Color("b8cad1") if daylight else Color("4b5e69")
	env.fog_sky_affect = 0.1
	env.volumetric_fog_enabled = RenderingServer.get_current_rendering_method() == "forward_plus" and not daylight
	env.volumetric_fog_density = 0.012 if id == "daisy" else 0.003
	env.volumetric_fog_albedo = Color("8e9ba2")
	env.volumetric_fog_length = 40 if id == "daisy" else 64
	env.volumetric_fog_detail_spread = 2.0
	env.volumetric_fog_temporal_reprojection_enabled = true
	env.volumetric_fog_temporal_reprojection_amount = 0.85
	env.background_mode = Environment.BG_SKY
	var sky = Sky.new(); var mat = PanoramaSkyMaterial.new()
	mat.panorama = load("res://assets/textures/kartini_clouds.png")
	mat.energy_multiplier = 1.0 if daylight else 0.12
	sky.sky_material = mat; sky.process_mode = Sky.PROCESS_MODE_QUALITY
	env.sky_rotation.y = -0.25 if State.flag("schoolDismissed") else 0.5
	env.sky = sky
	if not daylight:
		var fill = OmniLight3D.new(); fill.name = "ReadableFill"
		fill.position = Vector3(0, 3.4, -2); fill.omni_range = minf(28, maxf(15, host.level.width * 0.65))
		fill.light_color = Color("9fbbc9"); fill.light_energy = 0.65 if id == "ritual" else 0.32
		host.level.add_child(fill)
	if id == "hallucination": env.fog_density = 0.018; env.fog_light_color = Color("604e69")
	if id == "daisy":
		env.fog_density = 0.012
		var mist = preload("res://scripts/systems/volume_mist.gd")
		mist.add(host.level, "DaisyRoomVolume", Vector3(0, 1.5, 0), Vector3(host.level.width, 3.7, host.level.depth), 0.26)
		mist.add(host.level, "DaisyFloorVolume", Vector3(0, 0.3, 0), Vector3(host.level.width, 1.5, host.level.depth), 0.50)
