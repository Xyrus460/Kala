extends SceneTree
## Offline panorama: smooth atmosphere and continuous 3D-noise cloud banks.
func _initialize() -> void:
	var image = Image.create(2048, 1024, false, Image.FORMAT_RGB8)
	var cloud = FastNoiseLite.new(); cloud.seed = 6149; cloud.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH; cloud.frequency = 1.0; cloud.fractal_octaves = 6
	for y in range(1024):
		var latitude = PI * float(y) / 1023
		var elevation = cos(latitude)
		var base = Color("cdd9dc").lerp(Color("547ca2"), pow(maxf(0, elevation), 0.5))
		if elevation < 0: base = Color("a9bcae").lerp(Color("647e6b"), -elevation)
		for x in range(2048):
			var longitude = TAU * float(x) / 2048
			var d = Vector3(sin(latitude) * cos(longitude), elevation, sin(latitude) * sin(longitude))
			var p = d * 3.8
			var n = cloud.get_noise_3dv(p) * 0.5 + 0.5
			var amount = smoothstep(0.46, 0.66, n) * smoothstep(0.015, 0.20, elevation)
			var shade = cloud.get_noise_3dv(p + Vector3(0.15, 0.09, 0.08)) * 0.5 + 0.5
			image.set_pixel(x, y, base.lerp(Color("a3b3c0").lerp(Color("fff7e5"), smoothstep(0.35, 0.65, shade)), amount * 0.93))
	print("CLOUD PANORAMA ", image.save_png("res://assets/textures/kartini_clouds.png"))
	quit()
