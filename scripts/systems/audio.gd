class_name KalaAudio
extends Node

var music: AudioStreamPlayer
var voice: AudioStreamPlayer
var ambience: AudioStreamPlayer
var effects: AudioStreamPlayer
var tones: Dictionary = {}
var music_key = ""
const MUSIC = {"overseer": 36, "hands": 37, "tumbal": 38, "chase": 39, "daisy": 40}
const TRACKS = {"overseer": [0.0, 0.5, 103.2, 0.406], "hands": [0.0, 1.0, 132.0, 1.257], "tumbal": [100.0, 100.0, 306.0, 0.521], "chase": [0.0, 0.15, 104.5, 0.46], "daisy": [0.0, 10.0, 184.0, 0.607]}

func _ready() -> void:
	music = AudioStreamPlayer.new()
	voice = AudioStreamPlayer.new()
	ambience = AudioStreamPlayer.new()
	effects = AudioStreamPlayer.new()
	for node in [music, voice, ambience, effects]: add_child(node)
	tones.step = _tone(90, 0.09, 0.2)
	tones.click = _tone(220, 0.08, 0.3)
	tones.impact = _tone(42, 0.4, 0.55)
	tones.scare = _tone(73, 0.92, 0.95)
	tones.pulse = _tone(68, 0.32, 0.22)
	tones.reveal = _tone(510, 0.18, 0.025)
	tones.disrupt = _tone(125, 0.16, 0.08)
	tones.flash_burst = _battery_burst()
	var drone = _tone(49, 4.0, 0.13)
	drone.loop_mode = AudioStreamWAV.LOOP_FORWARD
	drone.loop_end = 22050 * 4
	ambience.stream = drone
	ambience.volume_db = -20
	ambience.play()

func play_music(key: String) -> void:
	if music_key == key: return
	music.stop()
	music_key = key
	if not MUSIC.has(key): return
	var source = "res://assets/audio/embedded_%03d.mp3" % MUSIC[key]
	if int(MUSIC[key]) in [36, 37, 38, 39]: source = "res://assets/audio/music_%03d.ogg" % MUSIC[key]
	var stream = load(source)
	if stream == null: return
	stream.loop = true
	music.stream = stream
	music.volume_db = linear_to_db(maxf(0.001, float(State.settings.music) * TRACKS[key][3]))
	music.play(TRACKS[key][0])

func _process(_delta: float) -> void:
	if TRACKS.has(music_key) and music.playing and not music.stream_paused:
		if music.get_playback_position() >= TRACKS[music_key][2]: music.seek(TRACKS[music_key][1])

func say(index: int) -> void:
	# All embedded dialogue tracks 32-35 are Danu voice recordings.
	if index in [32, 33, 34, 35]:
		voice.stop()
		voice.stream = null
		return
	voice.stream = load("res://assets/audio/embedded_%03d.mp3" % index)
	voice.play()

func effect(key: String) -> void:
	if not tones.has(key): return
	effects.stream = tones[key]
	effects.volume_db = -5 if key == "flash_burst" else -12
	effects.play()

func apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.001, float(State.settings.volume))))
	if music: music.volume_db = linear_to_db(maxf(0.001, float(State.settings.music) * (TRACKS[music_key][3] if TRACKS.has(music_key) else 0.45)))

func shutdown() -> void:
	for node in [music, voice, ambience, effects]:
		if is_instance_valid(node):
			node.stop()
			node.stream = null
	tones.clear()

func _exit_tree() -> void:
	shutdown()

func _tone(freq: float, length: float, noise: float) -> AudioStreamWAV:
	var bytes = PackedByteArray()
	var samples = int(22050 * length)
	bytes.resize(samples * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(freq * 13)
	for i in range(samples):
		var t = float(i) / 22050
		var envelope = 1.0 if length > 2 else pow(1.0 - float(i) / samples, 2)
		var value = (sin(t * freq * TAU) * 0.2 + rng.randf_range(-noise, noise)) * envelope
		bytes.encode_s16(i * 2, int(clampf(value, -1, 1) * 10000))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.data = bytes
	return stream

func _battery_burst() -> AudioStreamWAV:
	var samples=44100;var bytes=PackedByteArray();bytes.resize(samples*2)
	var rng=RandomNumberGenerator.new();rng.seed=1407
	var low=0.0
	for i in range(samples):
		var t=float(i)/22050.0
		var noise=rng.randf_range(-1,1);low=lerpf(low,noise,0.09)
		var blast=noise*exp(-t*15.0)*0.5+low*exp(-t*4.0)*1.4
		var thump=sin(TAU*(68.0*t-15.0*t*t))*exp(-t*10.0)*0.55
		var debris=0.0
		for onset in [0.13,0.21,0.34,0.56,0.79]:
			if t>onset:debris+=sin((t-onset)*TAU*(1820+onset*900))*exp(-(t-onset)*65)*0.13
		bytes.encode_s16(i*2,int(clampf(blast+thump+debris,-1,1)*26000))
	var stream=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.data=bytes
	return stream
