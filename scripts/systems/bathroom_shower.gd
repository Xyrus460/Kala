extends Node3D
const G = preload("res://scripts/systems/geometry.gd")
var water: MultiMeshInstance3D
var sound: AudioStreamPlayer3D
var running = false
var clock = 0.0
var valve: Node3D

func _ready() -> void:
	var tile = G.material("plain", Color("e1e4d8"))
	var metal = G.material("plain", Color("a1b2ad")).duplicate(); metal.metallic = 0.8; metal.roughness = 0.22
	G.box(self, Vector3(0, 0.035, 0), Vector3(1.24, 0.07, 1.32), tile, true).name = "ShowerTray"
	G.box(self, Vector3(0, 1.18, -0.60), Vector3(1.24, 2.36, 0.08), tile, true)
	G.box(self, Vector3(0.59, 1.10, 0), Vector3(0.06, 2.2, 1.2), tile, true)
	G.cylinder(self, Vector3(0, 1.55, -0.53), 0.025, 1.15, metal)
	G.box(self, Vector3(0, 2.12, -0.31), Vector3(0.045, 0.045, 0.48), metal)
	G.cylinder(self, Vector3(0, 2.08, -0.08), 0.16, 0.055, metal).name = "RainShowerHead"
	valve = G.box(self, Vector3(0, 1.02, -0.50), Vector3(0.22, 0.035, 0.08), metal)
	for i in range(6): G.box(self, Vector3(-0.09 + i * 0.036, 0.075, 0.26), Vector3(0.012, 0.008, 0.19), metal)
	var spray = StandardMaterial3D.new(); spray.albedo_color = Color(0.63, 0.83, 0.87, 0.48)
	spray.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; spray.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	water = MultiMeshInstance3D.new(); water.name = "ShowerWater"; add_child(water)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.multimesh = MultiMesh.new(); water.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var streak = BoxMesh.new(); streak.size = Vector3(0.009, 0.12, 0.009); streak.material = spray
	water.multimesh.mesh = streak; water.multimesh.instance_count = 100; water.hide()
	sound = AudioStreamPlayer3D.new(); sound.name = "RunningWater"; sound.unit_size = 2; sound.volume_db = -8; add_child(sound)
	var data = PackedByteArray(); data.resize(22050 * 4)
	var rng = RandomNumberGenerator.new(); rng.seed = 113
	var low = 0.0
	for i in range(44100):
		var noise = rng.randf_range(-1, 1); low = lerpf(low, noise, 0.13)
		data.encode_s16(i * 2, int((noise * 0.23 + low * 0.6) * 16000))
	var stream = AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = 22050
	stream.data = data; stream.loop_mode = AudioStreamWAV.LOOP_FORWARD; stream.loop_end = 44100; sound.stream = stream
	set_running(false)

func set_running(value: bool) -> void:
	running = value; water.visible = value
	valve.rotation.z = -0.7 if value else 0.0
	if value and not sound.playing: sound.play()
	elif not value: sound.stop()

func _process(delta: float) -> void:
	if not running: return
	clock += delta
	for i in range(water.multimesh.instance_count):
		var phase = fposmod(clock * 1.55 + i * 0.618, 1.0)
		var radius = 0.025 + (i % 11) * 0.012 + phase * 0.09
		var p = Vector3(sin(i * 2.4) * radius, 2.02 - phase * 1.94, -0.08 + cos(i * 2.4) * radius)
		water.multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, p))

func _exit_tree() -> void:
	if is_instance_valid(sound): sound.stop(); sound.stream = null
