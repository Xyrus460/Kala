extends Node3D
## Spatial recall with changing ordering rules and a horizontal duct threat.
const G = preload("res://scripts/systems/geometry.gd")
const SYMBOLS = ["RUMAH", "DAUN", "TETES", "MATA"]
const GLYPHS = ["⌂", "◇", "≋", "⊙"]
const COLORS = ["e4aa57", "75bda0", "68b7d3", "c58cae"]
const SEQUENCES = [[0,2,1], [1,3,0,2], [2,0,3,1,2]]
const NOTES = [261.63, 329.63, 392.0, 493.88]
var level: Node3D
var environment: Node3D
var host: Node3D
var center: Vector3
var status: Label3D
var rule: Label3D
var screens: Array[ShaderMaterial] = []
var screen_labels: Array[Label3D] = []
var keys: Array[MeshInstance3D] = []
var mascot: Node3D
var tone: AudioStreamPlayer3D
var tones: Array[AudioStreamWAV] = []
var phase = "idle"
var round_index = 0
var expected: Array = []
var response: Array = []
var playback_index = 0
var beat = 0.0
var last_cue = -1
var remaining = 0.0
var pressure = 0.0
var age = 0.0
var last_state = ""
var attack_left = 0.0

func setup(owner_level: Node3D, art: Node3D, origin: Vector3) -> void:
	level = owner_level; environment = art; center = origin
	name = "GemaArsip"; art.add_child(self); position = origin
	host = level.get_parent().get_parent()
	_build()
	for i in range(3):
		if State.flag("memoryRound%d" % i): round_index = i + 1
	if State.flag("memorySolved"): phase = "complete"
	refresh()

func _build() -> void:
	var steel = environment.metal("263a40")
	var stage = G.cylinder(self, Vector3(0, 0.08, -0.2), 2.7, 0.16, environment.metal("536663")); stage.name = "RecallStage"
	stage.create_trimesh_collision()
	G.cylinder(self, Vector3(0, 0.167, -0.2), 2.58, 0.014, G.material("plain", Color("aeb3a2")))
	var rim = MeshInstance3D.new(); var edge = TorusMesh.new()
	edge.inner_radius = 2.59; edge.outer_radius = 2.68; edge.rings = 64; edge.ring_segments = 8
	rim.mesh = edge; rim.material_override = environment.glow("6ca4a1", 0.6); rim.position = Vector3(0, 0.17, -0.2); add_child(rim)
	# A cut rectangular stage surround and radial floor marks guide the controls.
	for i in range(12):
		var a = i * TAU / 12
		var p = Vector3(sin(a) * 3.65, 0.012, cos(a) * 3.65)
		var mark = G.box(self, p, Vector3(0.05, 0.014, 0.30), G.material("plain", Color("b3a575"))); mark.rotation.y = a
	for side in [-1, 1]:
		for row in range(3):
			for col in range(4):
				var screen_root = Node3D.new(); screen_root.name = "RecallCRT"; add_child(screen_root)
				screen_root.position = Vector3(side * 8.14, 1.15 + row * 1.03, -4.5 + col * 2.70); screen_root.rotation.y = -side * PI / 2
				G.box(screen_root, Vector3.ZERO, Vector3(2.35, 0.94, 0.32), steel)
				var mat = ShaderMaterial.new(); mat.shader = preload("res://assets/materials/memory_crt.gdshader")
				mat.set_shader_parameter("signal_color", Color("487f7a")); mat.set_shader_parameter("intensity", 0.32)
				G.box(screen_root, Vector3(0, 0, 0.171), Vector3(2.09, 0.74, 0.02), mat)
				screens.append(mat)
				var caption = environment.label(screen_root, GLYPHS[col], Vector3(0, 0.03, 0.19), 0.009, 0, Color("527a73")); screen_labels.append(caption)
				G.sphere(screen_root, Vector3(1.02, -0.35, 0.18), Vector3.ONE * 0.035, environment.glow("95b69c", 0.5))
		# Steel uprights ground the banks; visible wiring runs above the monitors.
		for z in [-5.8, 5.1]: G.box(self, Vector3(side * 8.35, 1.85, z), Vector3(0.09, 3.7, 0.09), steel)
		G.box(self, Vector3(side * 7.95, 4.2, 0), Vector3(0.16, 0.14, 13.5), steel)
	for i in range(4):
		var p = [Vector3(-2.85,0,-1.9),Vector3(-2.85,0,1.9),Vector3(2.85,0,-1.9),Vector3(2.85,0,1.9)][i]
		G.box(self, p + Vector3(0, 0.53, 0), Vector3(0.69, 1.06, 0.62), environment.worn("4d6865"), true)
		var key = G.cylinder(self, p + Vector3(0, 1.12, 0), 0.32, 0.14, environment.glow(COLORS[i], 0.25)); keys.append(key)
		var caption = environment.label(self, "%s\n%s" % [GLYPHS[i], SYMBOLS[i]], p + Vector3(0, 1.45, 0), 0.0036)
		caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		level.interact(center + p + Vector3.UP * 1.15, "recall", "Tekan " + SYMBOLS[i], str(i), false, Vector3(0.70, 0.55, 0.70))
	G.box(self, Vector3(0, 0.65, -5.7), Vector3(2.8, 1.3, 0.70), environment.worn("556c67"), true)
	G.box(self, Vector3(0, 1.5, -5.83), Vector3(2.55, 0.58, 0.32), steel)
	environment.label(self, "E / MULAI UJI", Vector3(0, 1.49, -5.65), 0.004)
	level.interact(center + Vector3(0, 1.45, -5.45), "recall", "Mulai / ulang Gema Arsip", "start", false, Vector3(1.7, 0.7, 0.45))
	environment.panel_sign(self, "GEMA ARSIP / UJI REKAMAN", Vector3(0, 3.9, -7.4), 6.4)
	status = environment.label(self, "", Vector3(0, 2.9, -6.4), 0.0050)
	rule = environment.label(self, "", Vector3(0, 2.25, -6.4), 0.0035)
	G.box(self, Vector3(0, 2.64, -6.52), Vector3(4.7, 1.26, 0.15), steel)
	for x in [-2.2, 2.2]: G.box(self, Vector3(x, 1.5, -6.52), Vector3(0.08, 3.0, 0.10), steel)
	# Visible rules remain available without opening a modal over the room.
	environment.panel_sign(self, "DENGAR · INGAT · JAWAB", Vector3(-4.6, 3.5, 9.80), 3.7, PI)
	G.box(self, Vector3(-4.6, 2.13, 9.84), Vector3(3.7, 2.1, 0.07), steel)
	var instructions = environment.label(self, "Simbol dan nada menyimpan rekaman.\n\nURUT: ulangi dari awal.\nBALIK: mulai dari akhir.\nKilatan × adalah bising, abaikan.\n\nJawab dengan E / penjepit R.\nSalah membuatnya mendekat.", Vector3(-4.6, 2.13, 9.79), 0.0027, PI)
	instructions.name = "RecallRules"
	_tunnel()
	tone = AudioStreamPlayer3D.new(); tone.name = "RecallSpeaker"; tone.position = Vector3(0, 2.8, -5)
	tone.max_distance = 28; tone.volume_db = -9; add_child(tone)
	for hz in NOTES: tones.append(_tone(hz))
	for side in [-1, 1]:
		environment.light_at(center + Vector3(side * 5, 3.8, 0), "7caaa4", 0.8, 8)
	environment.light_at(center + Vector3(0, 3.4, -5), "c4b587", 0.85, 7)
	environment.light_at(center + Vector3(0, 3.6, 0), "a7c5b8", 0.95, 7)

func _tunnel() -> void:
	var dark = environment.metal("253c43")
	G.box(self, Vector3(0, -0.1, 15.0), Vector3(4.75, 0.2, 10.2), dark, true)
	for i in range(8):
		var z = 10.1 + i * 1.35
		var ring = MeshInstance3D.new(); ring.name = "ThreatDuctRib"
		var torus = TorusMesh.new(); torus.inner_radius = 1.97; torus.outer_radius = 2.14; torus.rings = 32; torus.ring_segments = 8
		ring.mesh = torus; ring.material_override = environment.metal("526b6a"); ring.position = Vector3(0, 2.08, z); ring.rotation.x = PI / 2; add_child(ring)
		for side in [-1, 1]: G.box(self, Vector3(side * 2.17, 2.08, z), Vector3(0.15, 4.25, 1.37), dark, true)
		G.box(self, Vector3(0, 4.22, z), Vector3(4.4, 0.15, 1.37), dark, true)
	G.box(self, Vector3(0, 2.0, 20.0), Vector3(4.5, 4.3, 0.20), dark, true)
	# The player sees the creature inside a physical duct; the guard rail stops falls.
	for x in [-2.25, 2.25]: G.box(self, Vector3(x, 0.53, 8.9), Vector3(0.07, 1.06, 0.07), dark)
	G.box(self, Vector3(0, 1.06, 8.9), Vector3(4.5, 0.07, 0.07), environment.metal("b09a61"))
	G.box(self, Vector3(0, 0.6, 9.3), Vector3(4.8, 1.2, 0.12), dark, true).hide()
	mascot = preload("res://scripts/systems/memory_mascot.gd").new(); mascot.name = "ArchiveBunny"
	mascot.position = Vector3(0, 0, 17.0); mascot.rotation.y = PI; add_child(mascot)
	environment.light_at(center + Vector3(0, 2.7, 15.5), "63bdb9", 1.1, 8)

func _tone(hz: float) -> AudioStreamWAV:
	var bytes = PackedByteArray(); var count = 17640; bytes.resize(count * 2)
	for i in range(count):
		var t = float(i) / 44100.0
		var envelope = minf(1, t * 80) * exp(-t * 8)
		var value = (sin(TAU * hz * t) + sin(TAU * hz * 2 * t) * 0.20) * envelope * 0.23
		bytes.encode_s16(i * 2, int(value * 32767))
	var stream = AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = 44100; stream.data = bytes
	return stream

func interact(parameter: String) -> void:
	if parameter == "service":
		if not State.flag("memorySolved"): host.ui.notify("Selesaikan Gema Arsip di ruang memori. Pengunci servis masih tertutup.", 5); return
		if not State.flag("relaySolved"): host.ui.notify("Tiga relai dan tuas arsip di atas belum selaras.", 5); return
		host._travel("pursuit"); return
	if parameter == "start":
		if phase == "complete": host.ui.notify("Rekaman pulih. Jalur servis di ruang sebelah sudah terbuka.", 5); return
		if not State.flag("relayPower"): host.ui.notify("Gema Arsip belum mendapat catu. Pasang kontak generator dan unit R-17 di atas.", 6); return
		if phase in ["playback", "response", "between", "attack"]: return
		_start_round(); return
	if phase != "response": return
	var key = int(parameter)
	if key < 0 or key > 3: return
	_display(key); tone.stream = tones[key]; tone.play()
	if key != int(expected[response.size()]):
		_fail("REKAMAN TIDAK COCOK"); return
	response.append(key)
	remaining = maxf(remaining, 4.5)
	if response.size() == expected.size():
		State.set_flag("memoryRound%d" % round_index); round_index += 1
		pressure = maxf(0, pressure - 0.25)
		if round_index >= 3:
			State.set_flag("memorySolved"); phase = "complete"; host.audio.effect("reveal"); host._save()
			host.ui.notify("Gema Arsip pulih. Pengunci jalur servis B1 terbuka.", 6)
		else: phase = "between"; beat = 2.0; host._save()
	refresh()

func _start_round() -> void:
	phase = "playback"; playback_index = 0; last_cue = -1; beat = 0.9
	response.clear(); expected = SEQUENCES[round_index].duplicate()
	if round_index == 1: expected.reverse()
	remaining = 14.0 + round_index * 3.0
	_display(-1); refresh()

func _fail(reason: String) -> void:
	pressure = minf(1.0, pressure + 0.26)
	phase = "failed"; status.text = reason; rule.text = "Kembali ke konsol untuk mengulang ronde ini."
	host.audio.effect("impact"); host.player.camera.v_offset = 0.03
	if pressure >= 0.95:
		host.hurt(12); phase = "attack"; attack_left = 0.9
		status.text = "REKAMAN PECAH"; rule.text = "Ia sudah sampai di kisi. Mundur dan mulai ulang."
	mascot.animate(false)

func _display(key: int) -> void:
	for i in range(screens.size()):
		var active = i % 4 == key
		screens[i].set_shader_parameter("signal_color", Color(COLORS[key]) if active else Color("365c5a"))
		screens[i].set_shader_parameter("intensity", 0.92 if active else 0.18)
		screen_labels[i].text = GLYPHS[i % 4] + ("\n" + SYMBOLS[i % 4] if active else "")
		screen_labels[i].modulate = Color(COLORS[key]) if active else Color("3c6660")
	for i in range(keys.size()):
		var mat = keys[i].material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 1.8 if i == key else 0.20

func refresh() -> void:
	if phase == "complete": status.text = "REKAMAN PULIH / 3 DARI 3"; rule.text = "Pengunci servis terbuka. Temukan pintu di ruang sebelah."
	elif phase == "idle": status.text = "GEMA ARSIP / SIAP"; rule.text = "Mulai di konsol. Kenali empat simbol di sekitar panggung."
	elif phase == "playback": status.text = "RONDE %d / DENGARKAN" % (round_index + 1); rule.text = "BALIK / jawab dari akhir" if round_index == 1 else "URUT / abaikan kilatan ×" if round_index == 2 else "URUT / jawab dari awal"
	elif phase == "response": status.text = "JAWAB %d / %d   ·   %02d dtk" % [response.size(), expected.size(), ceili(remaining)]
	elif phase == "between": status.text = "RONDE TERSIMPAN"; rule.text = "Rekaman berikutnya akan diputar…"
	var shutter = environment.get_node("MemoryServiceShutter")
	shutter.visible = not State.flag("memorySolved")
	for body in shutter.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0 if State.flag("memorySolved") else 1
	var readout = environment.get_node("ServiceShutterReadout")
	readout.text = "E / MASUK PEMELIHARAAN" if State.flag("memorySolved") else "SELESAIKAN GEMA ARSIP\nPENGUNCI SERVIS TERTUTUP"

func _process(delta: float) -> void:
	if host == null or not host.playing or not host.player.active or host.cinematic: return
	age += delta
	if host.player.position.distance_to(center) > 19:
		if phase in ["playback", "response", "between"]:
			phase = "idle"; _display(-1); refresh()
		return
	if phase == "playback":
		beat -= delta
		if beat <= 0:
			if playback_index >= SEQUENCES[round_index].size():
				phase = "response"; _display(-1); refresh()
			else:
				var key = int(SEQUENCES[round_index][playback_index]); _display(key); tone.stream = tones[key]; tone.play()
				playback_index += 1; beat = 1.05
		elif beat < 0.26: _display(-1)
		# Third-round static is visually distinct and never changes the real sequence.
		if round_index == 2 and beat > 0.28 and beat < 0.40:
			for i in range(0, screen_labels.size(), 4): screen_labels[i].text = "× BISING"; screen_labels[i].modulate = Color("7a8580")
	elif phase == "response":
		remaining -= delta; pressure = minf(1.0, pressure + delta * 0.007)
		if remaining <= 0: _fail("WAKTU REKAMAN HABIS")
		else: refresh()
	elif phase == "between":
		beat -= delta
		if beat <= 0: _start_round()
	if phase == "attack":
		attack_left -= delta; host.player.camera.v_offset = sin(age * 69) * 0.035
		if attack_left <= 0: phase = "failed"; pressure = 0.45; host.player.camera.v_offset = 0
	var target = 8.6 if phase == "attack" else 17.0 - pressure * 7.4 if phase != "complete" else 19.0
	mascot.position.z = move_toward(mascot.position.z, target, delta * (14.0 if phase == "attack" else 5.5 if phase == "failed" else 1.2))
	mascot.animate(absf(mascot.position.z - target) > 0.1)
	if phase == "failed": host.player.camera.v_offset = move_toward(host.player.camera.v_offset, 0.0, delta * 0.08)
