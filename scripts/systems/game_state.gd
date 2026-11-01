extends Node

signal changed
const ROOMS = ["home", "schoolyard", "neighborhood", "school", "street", "loading", "relay", "pursuit", "production", "office", "ritual", "corridor", "daisy", "hallucination"]
const TITLES = ["RUMAH / PAGI", "HALAMAN SEKOLAH & JALAN", "SIMPANG KARTINI", "SEKOLAH", "JALAN KARTINI", "BANGSAL MUAT", "RUMAH RELAI", "JALUR PEMELIHARAAN", "RUANG PRODUKSI", "KANTOR DANU", "RUANG RITUAL", "LORONG BELAKANG", "RUANG DAISY", "HALUSINASI / EMPAT INGATAN"]
const SAVE = "user://kala_native_v1.json"
const LAYOUT_REVISION=17
const CODES = {"locker": "4729", "panel": "3268"}
const ORDERS = {"fuse": [0, 1, 2], "breaker": [2, 0, 3, 1]}
var data: Dictionary
var checkpoint: Dictionary = {}
var save_enabled = true
var save_path = SAVE
var archive = preload("res://scripts/systems/save_archive.gd").new()
const DEFAULT_SETTINGS = {"sensitivity": 1.0, "volume": 0.75, "music": 0.45, "shadows": true, "quality": 2, "scares": true, "fullscreen":false, "vsync":true, "fps_limit":60, "render_scale":1.0, "msaa":2, "ssao":true, "ssil":true, "bloom":true, "fov":75.0, "head_bob":true}
var settings = DEFAULT_SETTINGS.duplicate()

func _ready() -> void:
	reset()
	var cfg = ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		# Older profiles only stored a preset and a separate flashlight toggle.
		# Expand that preset first, then apply each saved override below.
		apply_quality_preset(int(cfg.get_value("settings", "quality", settings.quality)))
		for key in settings:
			settings[key] = cfg.get_value("settings", key, settings[key])

func apply_quality_preset(value: int) -> void:
	var quality = clampi(value, 0, 2)
	settings.quality = quality
	settings.msaa = quality
	settings.render_scale = 0.75 if quality == 0 else 1.0
	settings.shadows = quality > 0
	settings.ssao = quality > 0
	settings.ssil = quality == 2
	settings.bloom = quality > 0

func reset() -> void:
	data = fresh_data()
	checkpoint = {}
	changed.emit()

func fresh_data() -> Dictionary:
	var value = {"version": 1, "room": "school", "sanity": 100.0, "elapsed": 0.0, "flags": {}, "evidence": {}, "items": {}, "installed": {}, "notes": {}, "puzzles": {}, "rotors": [0, 0, 0], "position": []}
	for id in ["locker", "fuse", "panel", "valve", "breaker"]:
		value.puzzles[id] = {"solved": false, "entered": "", "current": [], "pos": [0, 1, 2]}
	return value

func flag(id: String) -> bool:
	return bool(data.flags.get(id, false))

func set_flag(id: String, value = true) -> void:
	data.flags[id] = value
	changed.emit()

func solved(id: String) -> bool:
	return bool(data.puzzles[id].solved)

func owns(id: String) -> bool:
	return data.items.has(id) or data.installed.has(id)

func give(id: String) -> void:
	if not owns(id):
		data.items[id] = true
	changed.emit()

func install(id: String) -> bool:
	if data.installed.has(id): return true
	if not data.items.has(id): return false
	data.items.erase(id)
	data.installed[id] = true
	changed.emit()
	return true

func add_note(id: String, title: String, body: String) -> void:
	data.notes[id] = {"title": title, "body": body}
	changed.emit()

func collect(id: String) -> void:
	if not data.evidence.has(id): data.sanity = minf(100, data.sanity + 5)
	data.evidence[id] = true
	changed.emit()

func keypad(id: String, value: String) -> bool:
	var p: Dictionary = data.puzzles[id]
	if p.solved: return true
	if value == "C": p.entered = ""
	elif value == "BACK": p.entered = str(p.entered).left(maxi(0, str(p.entered).length() - 1))
	elif value == "OK":
		p.solved = p.entered == CODES[id]
		if not p.solved: p.entered = ""
	elif value.is_valid_int() and value.length() == 1 and str(p.entered).length() < 4:
		p.entered += value
	changed.emit()
	return p.solved

func order_press(id: String, index: int) -> bool:
	var p: Dictionary = data.puzzles[id]
	if p.solved: return true
	var order: Array = ORDERS[id]
	if index == order[p.current.size()]:
		p.current.append(index)
		p.solved = p.current.size() == order.size()
	else: p.current.clear()
	changed.emit()
	return p.solved

func rotate_valve(index: int) -> bool:
	var p: Dictionary = data.puzzles.valve
	if index<0 or index>=p.pos.size():return false
	if not p.solved:
		p.pos[index] = (int(p.pos[index]) + 1) % 4
		p.solved = p.pos == [0, 0, 0]
	changed.emit()
	return p.solved

func turn_relay(index: int) -> void:
	data.rotors[index] = (int(data.rotors[index]) + 1) % 4
	if index < 2: data.rotors[index + 1] = (int(data.rotors[index + 1]) + 1) % 4
	changed.emit()

func save_game(position_data: Array = [], kind = "auto") -> Error:
	if not save_enabled: return OK
	if not position_data.is_empty(): data.position = position_data
	return archive.persist(self, kind)

func read_save() -> Dictionary:
	if not FileAccess.file_exists(save_path): return {}
	var json = JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK: return {}
	var parsed = json.data
	if not valid_save(parsed): return {}
	return parsed

func valid_save(value: Variant) -> bool:
	if not value is Dictionary: return false
	for key in ["version", "room", "sanity", "elapsed", "flags", "evidence", "items", "installed", "notes", "puzzles", "rotors", "position"]:
		if not value.has(key): return false
	if value.version != 1 or not ROOMS.has(value.room): return false
	for key in ["flags", "evidence", "items", "installed", "notes", "puzzles"]:
		if not value[key] is Dictionary: return false
	if not value.rotors is Array or value.rotors.size() != 3: return false
	if not (value.sanity is float or value.sanity is int) or not (value.elapsed is float or value.elapsed is int): return false
	for rotor in value.rotors:
		if not (rotor is int or rotor is float) or rotor < 0 or rotor > 3: return false
	for id in ["locker", "fuse", "panel", "valve", "breaker"]:
		if not value.puzzles.has(id) or not value.puzzles[id] is Dictionary: return false
		for key in ["solved", "entered", "current", "pos"]:
			if not value.puzzles[id].has(key): return false
		if not value.puzzles[id].entered is String or not value.puzzles[id].current is Array or not value.puzzles[id].pos is Array: return false
		if value.puzzles[id].pos.size() != 3: return false
	return value.position is Array and (value.position.is_empty() or value.position.size() == 5)

func load_game(retry = false) -> bool:
	var value = checkpoint.duplicate(true) if retry else read_save()
	if not valid_save(value): return false
	data = value
	if retry: data.sanity = maxf(85, data.sanity)
	changed.emit()
	return true

func save_settings() -> void:
	var cfg = ConfigFile.new()
	for key in settings: cfg.set_value("settings", key, settings[key])
	cfg.save("user://settings.cfg")
