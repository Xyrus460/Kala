class_name KalaLevel
extends Node3D

signal passage_entered(next_room: String)
@export_enum("home", "schoolyard", "neighborhood", "school", "street", "loading", "relay", "pursuit", "production", "office", "ritual", "corridor", "daisy", "hallucination") var room_id = "school"
@export var spawn = Vector3.ZERO
@export var spawn_yaw = 0.0
@export var width = 24.0
@export var depth = 30.0
@export var obstacles: Array[Rect2] = []
var grid = AStarGrid2D.new()
var rotors: Array[Node3D] = []
var marks: Array[Node3D] = []
var candles: Array[Node3D] = []
var door_pivots: Array[Node3D] = []
var routes: Array[Vector3] = []
var cabinet_hinge: Node3D
var doll: Node3D
var time = 0.0
var definition: Dictionary
var all_doors: Dictionary = {}
var props: Dictionary = {}
var passage_authorized = false
var fan_stop_time = 0.0
var safety = preload("res://scripts/systems/room_safety.gd").new()
var presentation = preload("res://scripts/systems/room_presentation.gd").new()
var escape_puzzle: RefCounted
var factory_route: RefCounted
var relay_world: Node3D
var refinement: Node3D
var chapter_world: RefCounted
var nav_extra: Array[Rect2] = []
var brake_cooldowns: Dictionary = {}
static var source_data: Dictionary = {}
const ANNEX_LOCKS = {"guard": "", "maintenance": "maintenanceKey", "relay_archive": "archiveOpen", "generator": "", "workshop": "workshopKey", "infirmary": "", "records": "", "monitor": ""}
const ITEMS = {"Kunci suku cadang": "maintenanceKey", "Sekering operator": "panelFuse", "Kontak generator": "generatorContact", "Kunci bengkel": "workshopKey", "Pita audit": "tapeReel"}

static func reference_data() -> Dictionary:
	if source_data.is_empty(): source_data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/source_layout.json"))
	return source_data

func _ready() -> void:
	if room_id == "hallucination":
		var dream = preload("res://scripts/systems/hallucination_world.gd").new()
		definition = dream.definition(); width = definition.width; depth = definition.depth; spawn = _vector(definition.spawn)
		dream.build(self); safety.setup(self)
		for mesh in get_node("MapBoundary").find_children("*", "MeshInstance3D", false, false): mesh.hide()
		_setup_navigation()
		return
	if room_id in ["home", "schoolyard", "neighborhood"]:
		chapter_world = preload("res://scripts/systems/chapter_world.gd").new()
		definition = chapter_world.definition(room_id)
		spawn = _vector(definition.spawn); spawn_yaw = definition.yaw
		chapter_world.build(self)
		safety.setup(self)
		for mesh in get_node("MapBoundary").find_children("*", "MeshInstance3D", false, false):
			mesh.hide()
		_setup_navigation()
		return
	definition = reference_data().rooms[room_id]
	width = definition.width
	depth = definition.depth
	spawn = _vector(definition.spawn)
	spawn_yaw = definition.yaw
	if not has_meta("source_geometry_revision"):
		_build_source()
		set_meta("source_geometry_revision", 2)
	_refresh_characters()
	_restore_references()
	if room_id == "daisy":
		var portrait = OmniLight3D.new(); portrait.name = "DaisyPortraitLight"; portrait.position = doll.position + Vector3(0.2, 1.4, 1.0)
		portrait.light_color = Color("f1ddc2"); portrait.light_energy = 0.7; portrait.omni_range = 3.5; add_child(portrait)
	if room_id == "ritual": _ritual_refuges()
	_setup_npc_contacts()
	safety.setup(self)
	presentation.apply(self)
	preload("res://scripts/systems/world_detail.gd").new().apply(self)
	if room_id in ["loading","relay","production","office","ritual"]:
		factory_route=preload("res://scripts/systems/factory_route.gd").new();factory_route.apply(self)
	if room_id == "relay":
		relay_world = preload("res://scripts/systems/relay_rebuild.gd").new()
		relay_world.apply(self)
	_setup_navigation()
	if room_id == "pursuit":
		escape_puzzle = preload("res://scripts/interaction/escape_puzzle.gd").new()
		escape_puzzle.setup(self)
	if room_id in ["pursuit", "production", "office"]:
		refinement = preload("res://scripts/systems/factory_refinement.gd").new()
		refinement.apply(self)
		_setup_navigation()
	if room_id == "relay" and not has_node("RelayWatcher"):
		var watcher = preload("res://scripts/enemies/relay_watcher.gd").new()
		watcher.name = "RelayWatcher"
		add_child(watcher)

func _refresh_characters() -> void:
	var names = ["NPC_Danu", "NPC_Raka", "NPC_Adit", "NPC_Sari"] if room_id == "school" else ["NativeDaisy"] if room_id == "daisy" else []
	for title in names:
		var old = get_node_or_null(NodePath(title)) as Node3D
		if old == null: continue
		var identity = "actor_daisy" if title == "NativeDaisy" else "npc_" + title.trim_prefix("NPC_")
		var fresh = preload("res://scripts/systems/model_factory.gd").make(identity)
		fresh.position = old.position; fresh.rotation = old.rotation; fresh.name = title
		remove_child(old); old.queue_free(); add_child(fresh)

func _ritual_refuges() -> void:
	for i in range(3):
		var p = [Vector3(-9, 0.17, -6), Vector3(9, 0.17, -6), Vector3(0, 0.17, 10)][i]
		var platform = KalaGeometry.cylinder(self, p, 1.35, 0.34, KalaGeometry.material("concrete", Color("858580")))
		platform.name = "RitualRefuge%d" % i
		var body = StaticBody3D.new(); var collider = CollisionShape3D.new(); var shape = CylinderShape3D.new(); shape.radius = 1.35; shape.height = 0.34
		collider.shape = shape; body.add_child(collider); platform.add_child(body)
		nav_extra.append(Rect2(p.x - 1.35, p.z - 1.35, 2.7, 2.7))

func _setup_npc_contacts() -> void:
	if room_id != "school": return
	for name_value in ["Danu", "Raka", "Adit", "Sari"]:
		var npc = get_node_or_null("NPC_" + name_value) as Node3D
		if npc == null or npc.has_node("ContactBody"): continue
		var body = StaticBody3D.new()
		body.name = "ContactBody"
		body.collision_layer = 16
		body.collision_mask = 0
		var collision = CollisionShape3D.new()
		var shape = CapsuleShape3D.new()
		shape.radius = 0.28
		shape.height = 1.75
		collision.shape = shape
		collision.position.y = 0.875
		body.add_child(collision)
		npc.add_child(body)

func _vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

func _build_source() -> void:
	var world = load("res://assets/models/source/%s.glb" % room_id).instantiate() as Node3D
	world.name = "SourceWorld"
	add_child(world)
	# Original static mesh silhouettes supply actual floors, walls and stairs.
	# Small paper/paint/light surfaces do not become physical blockers.
	for node in world.find_children("*", "MeshInstance3D", true, false):
		var mesh = node as MeshInstance3D
		var bounds: AABB = mesh.global_transform * mesh.get_aabb()
		var size = bounds.size
		var sorted = [size.x, size.y, size.z]
		sorted.sort()
		var horizontal_surface = size.y < 0.035 and size.x > 2.0 and size.z > 2.0
		if sorted[2] < 0.55 or sorted[1] < 0.11 or (sorted[0] < 0.035 and not horizontal_surface): continue
		var material = mesh.get_active_material(0)
		if material is BaseMaterial3D and material.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED: continue
		if mesh.name.begins_with("Flame") or mesh.name.begins_with("FireLight"): continue
		mesh.create_trimesh_collision()
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for lamp in definition.lights:
		if lamp.power <= 0: continue
		var light = OmniLight3D.new()
		light.name = "Practical_" + str(lamp.name)
		light.position = _vector(lamp.position)
		light.light_color = Color(lamp.color[0], lamp.color[1], lamp.color[2]).linear_to_srgb()
		light.light_energy = clampf(lamp.power / 65.0, 0.07, 1.5) * (0.20 if room_id == "school" else 0.38)
		light.omni_range = maxf(3, lamp.range)
		light.omni_attenuation = 1.7
		add_child(light)
	var lighting = reference_data().lighting
	if lighting["keys"].has(room_id):
		var key: Array = lighting["keys"][room_id]
		var spot = SpotLight3D.new()
		spot.name = "RoomKey"
		spot.position = Vector3(key[0] - definition.cx, key[1], key[2])
		add_child(spot)
		spot.look_at(Vector3(key[3] - definition.cx, key[4], key[5]), Vector3.FORWARD)
		spot.light_color = Color.hex(int(key[7]) * 256 + 255)
		spot.light_energy = 0.85
		spot.spot_range = 35
		spot.spot_angle = 55
		spot.shadow_enabled = true
	if room_id == "school":
		for name_value in reference_data().characters:
			var info: Dictionary = reference_data().characters[name_value]
			var npc = preload("res://scripts/systems/model_factory.gd").make("npc_" + name_value) as Node3D
			npc.name = "NPC_" + name_value
			npc.position = _vector(info.position)
			npc.rotation.y = info.yaw
			add_child(npc)
	if room_id == "relay":
		var sun = DirectionalLight3D.new()
		sun.name = "DiscoverySun"
		sun.position = Vector3(-3, 19.54, 8.1)
		add_child(sun)
		sun.look_at(Vector3(3, 0.88, 12))
		sun.light_color = Color("ffe8bd")
		sun.light_energy = 1.7
		sun.shadow_enabled = true
		sun.directional_shadow_max_distance = 42
	if room_id == "daisy":
		var actor = preload("res://scripts/systems/model_factory.gd").make("actor_daisy") as Node3D
		actor.name = "NativeDaisy"
		actor.position = _vector(reference_data().doll_position)
		add_child(actor)
	# Keep annex indices stable for gameplay and saved interaction parameters.
	for record in definition.interactions:
		if record.get("annex", "") != "": _add_interaction(record, "door", str(door_pivots.size()))
		else: _map_interaction(record)
	for tool in definition.tools: _map_tool(tool)
	if room_id == "ritual":
		for i in range(3):
			var point = [Vector3(-9, 1.5, -6), Vector3(9, 1.5, -6), Vector3(0, 1.5, 10)][i]
			interact(point, "candle", "Tarik lilin " + str(i + 1), str(i), true)
	if room_id == "pursuit":
		interact(Vector3(89, -6.6, -128), "rescue", "Akses pengaman", "", false, Vector3(5, 3, 4))
		var barrier = StaticBody3D.new()
		barrier.name = "FanSafetyBarrier"
		barrier.position = Vector3(74.5, -4.45, -107)
		var collision = CollisionShape3D.new()
		var shape = BoxShape3D.new()
		shape.size = Vector3(0.3, 2.7, 3)
		collision.shape = shape
		barrier.add_child(collision)
		add_child(barrier)

func _add_interaction(record: Dictionary, action: String, parameter = "", tool = false) -> KalaInteractable:
	var object = interact(Vector3(record.x, record.get("y", 1.35), record.z), action, record.label, parameter, tool)
	if action == "door":
		var pivot = find_child("DoorPivot_annex_" + record.annex, true, false) as Node3D
		if pivot != null:
			pivot.set_meta("lock", ANNEX_LOCKS[record.annex])
			pivot.set_meta("opened", false)
			door_pivots.append(pivot)
	return object

func _map_interaction(record: Dictionary) -> void:
	var label: String = record.label
	if record.get("note_id", "") != "": _add_interaction(record, "note", record.note_id)
	elif label.begins_with("bicara dengan "): _add_interaction(record, "npc", label.trim_prefix("bicara dengan "))
	elif label.contains("Bu Ratna"): _add_interaction(record, "ratna")
	elif label.contains("loker Raka"): _add_interaction(record, "puzzle", "locker")
	elif label.contains("periksa foto"): _add_interaction(record, "evidence", "op1")
	elif label == "agenda Sari": _add_interaction(record, "evidence", "op2")
	elif label == "album dan perjanjian Danu": _add_interaction(record, "evidence", "B")
	elif label.contains("kotak sekering"): _add_interaction(record, "puzzle", "fuse")
	elif label.contains("panel kontrol"): _add_interaction(record, "puzzle", "panel")
	elif label.contains("tiga katup"): _add_interaction(record, "puzzle", "valve")
	elif label.contains("panel saklar"): _add_interaction(record, "puzzle", "breaker")
	elif label.contains("LENTERA-G"): _add_interaction(record, "tool")
	elif label.contains("catu generator"): _add_interaction(record, "generator")
	elif label.contains("pemutar pita"): _add_interaction(record, "audit")
	elif label.contains("jalur servis"): _add_interaction(record, "service")
	elif label.contains("D–08"): _add_interaction(record, "hidden")
	elif label.contains("lemari kaca"): _add_interaction(record, "daisy")
	elif label.contains("mural"): _add_interaction(record, "mural")
	elif label.begins_with("ambil "):
		for title in ITEMS:
			if label.contains(title): _add_interaction(record, "item", ITEMS[title]); return
	elif label.begins_with("rem "): _add_interaction(record, "brake", label.trim_prefix("rem "))
	elif label.contains("kisi") or label.contains("pengunci ventilasi"): _add_interaction(record, "grate", "", true)
	elif label.contains("rem kipas"): _add_interaction(record, "fan", "", true)
	elif not label.contains("terkunci dari luar"): _add_interaction(record, "exit")

func _map_tool(record: Dictionary) -> void:
	var action = ""
	var parameter = ""
	match str(record.label):
		"RELAI I": action = "rotor"; parameter = "0"
		"RELAI II": action = "rotor"; parameter = "1"
		"RELAI III": action = "rotor"; parameter = "2"
		"UNIT R-17": action = "cell"
		"SOKET R-17": action = "socket"
		"TUAS ARSIP": action = "lever"
		"PENGUNCI ARSIP": action = "latch"
		"RODA KATUP II": action = "item"; parameter = "valveWheel"
		"REM KONVEYOR": action = "brake"; parameter = "konveyor"
		"REM SALURAN": action = "brake"; parameter = "saluran"
		"BUKA KISI VENTILASI": action = "grate"
		"REM KIPAS": action = "fan"
	if action != "": interact(_vector(record.point), action, record.label, parameter, true)

func interact(pos: Vector3, action: String, caption: String, parameter = "", tool = false, size = Vector3(0.85, 0.85, 0.85)) -> KalaInteractable:
	var object = preload("res://scenes/interactables/interactable.tscn").instantiate() as KalaInteractable
	object.action_id = action
	object.caption = caption
	object.parameter = str(parameter)
	object.tool_only = tool
	object.position = pos
	var collision = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	object.add_child(collision)
	add_child(object)
	return object

func _restore_references() -> void:
	rotors.clear(); marks.clear(); candles.clear(); door_pivots.clear()
	for i in range(3):
		var rotor = find_child("RotorPivot%d" % i, true, false) as Node3D
		var mark = find_child("RelayMark%d" % i, true, false) as Node3D
		var candle = find_child("Candle%d" % i, true, false) as Node3D
		if rotor != null: rotors.append(rotor)
		if mark != null: marks.append(mark)
		if candle != null:
			var flame = candle.find_child("Flame*", true, false)
			var glow = candle.find_child("FireLight*", true, false)
			if flame != null: flame.name = "Flame"
			if glow != null: glow.name = "FireLight"
			candles.append(candle)
	for record in definition.interactions:
		if record.get("annex", "") == "": continue
		var pivot = find_child("DoorPivot_annex_" + record.annex, true, false) as Node3D
		if pivot != null:
			pivot.set_meta("lock", ANNEX_LOCKS[record.annex])
			pivot.set_meta("opened", State.flag("door_%s_%d" % [room_id, door_pivots.size()]))
			door_pivots.append(pivot)
	for door in definition.doors:
		var pivot = find_child(door.pivot, true, false) as Node3D
		if pivot != null: all_doors[door.key] = {"node": pivot, "angle": door.angle}
	cabinet_hinge = find_child("CabinetHinge", true, false)
	doll = get_node_or_null("NativeDaisy")
	for id in ["maintenanceKey", "panelFuse", "generatorContact", "workshopKey", "valveWheel", "tapeReel", "installedTape"]:
		var prop = find_child("Item_" + id, true, false)
		if prop != null: props[id] = prop
	if room_id == "pursuit":
		for p in reference_data().pursuit_route + reference_data().extended_route: routes.append(_vector(p))

func _setup_navigation() -> void:
	obstacles.clear()
	for c in definition.colliders: obstacles.append(Rect2(c[0] - 0.48, c[1] - 0.48, c[2] + 0.96, c[3] + 0.96))
	for c in safety.blockers: obstacles.append(Rect2(c[0] - 0.48, c[1] - 0.48, c[2] + 0.96, c[3] + 0.96))
	for rect in nav_extra: obstacles.append(rect.grow(0.40))
	grid.region = Rect2i(Vector2i(floori(safety.extent.position.x * 2) - 2, floori(safety.extent.position.y * 2) - 2), Vector2i(ceili(safety.extent.size.x * 2) + 5, ceili(safety.extent.size.y * 2) + 5))
	grid.cell_size = Vector2(0.5, 0.5)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for x in range(grid.region.position.x, grid.region.end.x):
		for z in range(grid.region.position.y, grid.region.end.y):
			if not safety.contains(Vector3(float(x) * 0.5, 0, float(z) * 0.5), 0.60): grid.set_point_solid(Vector2i(x, z))
	for rect in obstacles:
		var a = Vector2i(floori(rect.position.x * 2), floori(rect.position.y * 2))
		var b = Vector2i(ceili(rect.end.x * 2), ceili(rect.end.y * 2))
		grid.fill_solid_region(Rect2i(a, b - a + Vector2i.ONE), true)

func actor_path(from: Vector3, to: Vector3) -> PackedVector2Array:
	var a = nearest_nav_point(Vector2i(roundi(from.x * 2), roundi(from.z * 2)))
	var b = nearest_nav_point(Vector2i(roundi(to.x * 2), roundi(to.z * 2)))
	if not grid.is_in_boundsv(a) or not grid.is_in_boundsv(b): return PackedVector2Array()
	return grid.get_point_path(a, b, true)

func nearest_nav_point(point: Vector2i) -> Vector2i:
	if grid.is_in_boundsv(point) and not grid.is_point_solid(point): return point
	for radius in range(1, 9):
		for x in range(-radius, radius + 1):
			for z in range(-radius, radius + 1):
				if absi(x) != radius and absi(z) != radius: continue
				var candidate = point + Vector2i(x, z)
				if grid.is_in_boundsv(candidate) and not grid.is_point_solid(candidate): return candidate
	return point

func route_projection(point: Vector3) -> float:
	var distance = INF
	var progress = 0.0
	var best = 0.0
	for i in range(1, routes.size()):
		var start = routes[i - 1]
		var vector = routes[i] - start
		var t = clampf((point - start).dot(vector) / maxf(0.001, vector.length_squared()), 0, 1)
		var error = point.distance_to(start + vector * t)
		if error < distance: distance = error; best = progress + vector.length() * t
		progress += vector.length()
	return best

func route_point(progress: float) -> Vector3:
	for i in range(1, routes.size()):
		var length = routes[i].distance_to(routes[i - 1])
		if progress < length: return routes[i - 1].lerp(routes[i], progress / maxf(0.001, length))
		progress -= length
	return routes.back()

func in_vent(point: Vector3) -> bool:
	for passage in reference_data().chase_passages:
		if not passage.vent: continue
		var a = _vector(passage.a)
		var b = _vector(passage.b)
		var p = Vector2(point.x, point.z)
		var start = Vector2(a.x, a.z)
		var end = Vector2(b.x, b.z)
		var forward = (end - start).normalized()
		# Fold before the capsule reaches the low lintel, including when returning.
		start -= forward * 1.6; end += forward * 1.6
		if Geometry2D.get_closest_point_to_segment(p, start, end).distance_to(p) < passage.width / 2 and p.distance_to(start) + p.distance_to(end) < start.distance_to(end) + 0.5: return true
	return false

func pursuit_speed(point: Vector3) -> float:
	var result = 0.62 if in_vent(point) else 1.0
	if (point - Vector3(42, -5.8, -113.5)).length() < 1.55 or (point - Vector3(53, -5.8, -109.8)).length() < 0.95: result *= 0.65
	if point.x > 77 and point.z < -112: result *= 0.56
	for entry in [[-8, 12, 0.0], [8, -7, 2.3], [-8, -26, 1.1]]:
		if Vector2(point.x - entry[0], point.z - entry[1]).length() < 1.0 and fmod(time + entry[2], 5.8) < 1.4: result *= 0.65
	return result

func _process(delta: float) -> void:
	if chapter_world != null:
		chapter_world.update(delta)
		return
	time += delta
	for i in range(rotors.size()): rotors[i].rotation.z = -float(State.data.rotors[i]) * PI / 2
	for pivot in door_pivots:
		var key = str(pivot.name).trim_prefix("DoorPivot_")
		pivot.rotation.y = lerp_angle(pivot.rotation.y, float(all_doors[key].angle) if pivot.get_meta("opened") else 0.0, minf(1, delta * 5))
	var open_passage = false
	match room_id:
		"school": open_passage = State.flag("invited")
		"street": open_passage = State.solved("fuse")
		"loading": open_passage = State.flag("overseerDefeated")
		"relay": open_passage = State.flag("relaySolved") and State.flag("memorySolved")
		"production": open_passage = State.flag("handsDefeated")
		"office": open_passage = State.solved("breaker")
		"ritual": open_passage = State.flag("tumbalDefeated")
	for key in [room_id, "streetLeft", "streetRight", "schoolExit"]:
		if all_doors.has(key) and (key == room_id or room_id == "street" or room_id == "school"):
			var record: Dictionary = all_doors[key]
			record.node.rotation.y = lerp_angle(record.node.rotation.y, float(record.angle) if open_passage else 0.0, minf(1, delta * 4))
	var gate = find_child("StairGate_" + room_id, true, false)
	if gate != null:
		gate.visible = not open_passage
		for body in gate.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0 if open_passage else 1
	for id in props: props[id].visible = State.data.installed.has("tapeReel") if id == "installedTape" else not State.owns(id)
	var tool = find_child("LenteraPickup", true, false)
	if tool != null: tool.visible = not State.flag("lenteraOwned")
	var photo = find_child("EvidencePhoto", true, false)
	if photo != null: photo.visible = not State.flag("prologueVersion") and not State.data.evidence.has("op1")
	var latch = find_child("ArchiveLatch", true, false)
	if latch != null: latch.visible = not State.flag("archiveOpen")
	var cell = find_child("RelayCell", true, false) as Node3D
	if cell != null:
		cell.visible = not State.flag("relayCellHeld")
		if State.flag("relayPower"): cell.global_position = to_global(Vector3(8, 1.45, -1.7))
	var player = get_tree().get_first_node_in_group("kala_player") as KalaPlayer
	if room_id == "pursuit":
		escape_puzzle.update(delta)
		var grate = find_child("VentGrate", true, false) as Node3D
		if grate != null: grate.rotation.y = lerp_angle(grate.rotation.y, -1.55 if State.flag("ventGrateOpen") else 0.0, minf(1, delta * 6))
		fan_stop_time = maxf(0, fan_stop_time - delta)
		var near_fan = player != null and absf(player.position.x - 74.5) < 0.8 and absf(player.position.z + 107) < 1.6
		var fan_active = fan_stop_time <= 0 and fmod(time, 7.5) < 4.5 and not near_fan
		var fan = find_child("FanBlades", true, false) as Node3D
		if fan != null:
			fan.rotation.x += delta * (9 if fan_active else 0.3)
			for body in fan.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0
		var barrier = get_node_or_null("FanSafetyBarrier") as StaticBody3D
		if barrier != null: barrier.collision_layer = 1 if fan_active else 0
		for i in range(3):
			var mist = find_child("Steam_%d" % i, true, false)
			var phase = [0.0, 2.3, 1.1][i]
			if mist != null: mist.visible = fmod(time + phase, 5.8) < 1.4
		if player != null and player.position.x > 85 and player.position.z < -122 and State.flag("escapePuzzleSolved") and not State.flag("handsPursuitComplete"):
			get_parent().get_parent()._rescue()
	if factory_route!=null:
		factory_route.update()
		if player!=null and open_passage:factory_route.check_transition(player)
