extends Node

var host: Node3D
var clips: Dictionary
var running = false
var clip = ""
var step = 0
var step_time = 0.0
var elapsed = 0.0
var player_pose: Transform3D
var camera_pose: Transform3D
var npc_poses: Dictionary = {}
var head_poses: Array[Dictionary] = []
var actor: Node3D
var joints: Array[Dictionary] = []
var slammed = false
var latched = false
var last_footstep = -1
var expansion = preload("res://scripts/systems/expansion_cinematics.gd").new()
var chapter = preload("res://scripts/systems/chapter_cinematics.gd").new()

func _ready() -> void:
	host = get_parent()
	expansion.host = host
	expansion.timeline = self
	chapter.host = host; chapter.timeline = self
	clips = JSON.parse_string(FileAccess.get_file_as_string("res://assets/cinematics.json"))
	set_process(false)

func start(id: String) -> bool:
	if running or not clips.has(id) or host.entering or not host.playing: return false
	if State.data.room != clips[id].room or State.flag(clips[id].flag): return false
	clip = id
	running = true
	step = 0
	step_time = 0
	elapsed = 0
	slammed = false
	latched = false
	last_footstep = -1
	player_pose = host.player.transform
	camera_pose = host.player.camera.transform
	host.player.velocity = Vector3.ZERO
	host.player.get_node("Head").position.y = 1.62
	host.cinematic = true
	host.ui.close_panel()
	host.ui.cinematic_hint.visible = true
	host._sync_active()
	_prepare()
	_show_step()
	set_process(true)
	return true

func _input(event: InputEvent) -> void:
	if not running or not event.is_pressed() or event.is_echo(): return
	if event.is_action_pressed("interact") or event.is_action_pressed("flip") or event.is_action_pressed("pause"):
		finish()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if not running: return
	if not is_instance_valid(host.level) or not host.level.is_inside_tree() or State.data.room != clips[clip].room:
		cancel()
		return
	elapsed += delta
	step_time += delta
	if chapter.handles(clip): chapter.animate(elapsed, delta)
	elif expansion.handles(clip): expansion.animate(elapsed, delta)
	else: _animate()
	while running and step_time >= float(clips[clip].steps[step][1]):
		step_time -= float(clips[clip].steps[step][1])
		step += 1
		if step >= clips[clip].steps.size(): finish()
		else: _show_step()

func _prepare() -> void:
	if chapter.handles(clip):
		chapter.prepare(clip)
		return
	if expansion.handles(clip):
		expansion.prepare(clip)
		return
	match clip:
		"intro":
			for name_value in ["Danu", "Raka", "Adit", "Sari"]:
				var npc = host.level.get_node("NPC_" + name_value) as Node3D
				npc_poses[name_value] = npc.transform
				var head = _head(npc)
				if head != null: head_poses.append({"node": head, "pose": head.transform})
			host.player.position = Vector3(1.8, 0, -4.2)
			host.player.camera.look_at(Vector3(-1.3, 1.25, -8.5))
		"warehouse":
			host.player.position = Vector3(1, 0, 23.8)
			host.player.rotation = Vector3(0, PI, 0)
			host.player.camera.rotation = Vector3(-0.035, 0, 0)
			_spawn_actor(Vector3(1, 0, 27.3), PI)
			_door("streetLeft", 0); _door("streetRight", 0)
		"office":
			_spawn_actor(Vector3(3, 0, -7), 0)
			host.player.camera.look_at(actor.position + Vector3.UP * 1.35)
			_open_stairs()
		"corridor":
			host.player.position = Vector3(0, 0, 17)
			host.player.rotation = Vector3.ZERO
			host.player.camera.rotation = Vector3(-0.035, 0, 0)
			host.player.lamp_on = true
			_spawn_actor(Vector3(0.12, 0, 11.5), PI)
			_door("corridor", 1)

func _spawn_actor(position_value: Vector3, yaw: float) -> void:
	actor = preload("res://scripts/systems/model_factory.gd").make("npc_Danu") as Node3D
	actor.name = "StoryDanu"
	actor.position = position_value
	actor.rotation.y = yaw
	host.level.add_child(actor)
	joints.clear()
	for node in actor.find_children("*", "Node3D", true, false):
		if node is MeshInstance3D: continue
		var arm = is_equal_approx(absf(node.position.x), 0.27) and is_equal_approx(node.position.y, 1.38)
		var leg = is_equal_approx(absf(node.position.x), 0.09) and is_equal_approx(node.position.y, 0.66)
		if arm or leg: joints.append({"node": node, "rest": node.rotation, "arm": arm, "side": signf(node.position.x)})

func _show_step() -> void:
	host.ui.notify(clips[clip].steps[step][0], float(clips[clip].steps[step][1]) + 1)
	if clip == "intro" and step == 1:
		var raka = host.level.get_node("NPC_Raka") as Node3D
		var danu = host.level.get_node("NPC_Danu") as Node3D
		raka.position = Vector3(-0.5, 0, -8.5)
		danu.position = Vector3(-1.1, 0, -9)
		danu.rotation.z = -0.1
		host.audio.effect("impact")
	if clip == "intro" and step == 4:
		var head = _head(host.level.get_node("NPC_Danu"))
		if head != null: head.rotation.y = 0.7

func _head(root: Node3D) -> Node3D:
	for node in root.find_children("*", "Node3D", true, false):
		if not node is MeshInstance3D and is_equal_approx(node.position.y, 1.6) and absf(node.position.x) < 0.01: return node
	return null

func _animate() -> void:
	match clip:
		"warehouse":
			var progress = clampf((elapsed - 5.4) / 3.8, 0, 1)
			actor.position.z = 27.3 + progress * 8
			actor.rotation.y = PI * (1 - clampf((elapsed - 4.6) / 0.65, 0, 1))
			_gait(elapsed * 10, 0.38 if progress > 0 and progress < 1 else 0.0)
			var opening = clampf((elapsed - 2.4) / 0.8, 0, 1)
			_door("streetLeft", opening); _door("streetRight", opening)
		"office":
			if elapsed > 9:
				var progress = clampf((elapsed - 9) / 3, 0, 1)
				actor.position = Vector3(3, 0, -7).lerp(Vector3(0, 0, -19.15), progress)
				_gait(elapsed * 9, 0.36)
		"corridor":
			var progress = clampf(elapsed / 8.5, 0, 1)
			var stop = 1 - clampf((elapsed - 8.1) / 0.6, 0, 1)
			host.player.position = Vector3(sin(elapsed * 1.3) * 0.11 * stop, 0, 17 - 34.55 * progress)
			host.player.get_node("Head").position.y = 1.62 + sin(elapsed * 16) * 0.027 * stop
			actor.position = Vector3(0.12 + sin(elapsed * 1.7) * 0.14, 0, 11.5 - 32.5 * clampf(elapsed / 7.8, 0, 1))
			actor.rotation = Vector3(-0.13, PI + sin(elapsed * 1.7) * 0.035, sin(elapsed * 16) * 0.018)
			_gait(elapsed * 16, 0.60 if elapsed < 7.8 else 0.0)
			var head = _head(actor)
			if head != null: head.rotation.y = 0.64 if elapsed > 4.7 and elapsed < 5.7 else 0.0
			if elapsed >= 7.8: actor.position = Vector3(0.82, 0, -21)
			actor.visible = elapsed < 9.25
			_door("corridor", 1 - clampf((elapsed - 8.2) / 0.55, 0, 1))
			if elapsed >= 8.75 and not slammed:
				slammed = true
				host.audio.effect("impact")
			if elapsed >= 9.25 and not latched:
				latched = true
				host.audio.effect("click")
	if clip in ["warehouse", "corridor"]:
		var stride = int(elapsed / 0.29)
		if stride != last_footstep and ((clip == "corridor" and elapsed < 7.9) or (clip == "warehouse" and elapsed > 5.4 and elapsed < 9.2)):
			last_footstep = stride
			host.audio.effect("step")

func _gait(phase: float, amount: float) -> void:
	if actor != null and actor.has_method("animate_walk"):
		actor.animate_walk(phase, amount)
		return
	for joint in joints:
		if not is_instance_valid(joint.node): continue
		var swing = sin(phase + (PI if joint.side > 0 else 0)) * amount
		joint.node.rotation.x = joint.rest.x + swing * (-1.2 if joint.arm else 1.0)

func _door(key: String, amount: float) -> void:
	if host.level.all_doors.has(key):
		var door: Dictionary = host.level.all_doors[key]
		door.node.rotation.y = float(door.angle) * amount

func _open_stairs() -> void:
	_door(State.data.room, 1)
	var gate = host.level.find_child("StairGate_" + State.data.room, true, false)
	if gate != null:
		gate.visible = false
		for body in gate.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0

func finish() -> void:
	if not running: return
	var completed = clip
	State.set_flag(clips[completed].flag)
	if chapter.handles(completed):
		chapter.finish()
		_clear(true)
		host._save()
		if completed == "lesson": host.ui.notify("Selidiki sebelum menyimpulkan. Dua bukti cukup untuk menanyakan cerita Danu.", 7)
		return
	if expansion.handles(completed):
		var next = expansion.finish()
		_clear(true)
		host._save()
		if completed == "pickup": host.show_lentera_guide()
		if next != "": host._travel(next)
		return
	if completed == "corridor":
		if not slammed: host.audio.effect("impact")
		State.set_flag("exitLocked")
		State.data.sanity = maxf(1, State.data.sanity - 5)
		_door("corridor", 0)
		host.player.position = Vector3(0, 0.05, -17.55)
		host.player.get_node("Head").position.y = 1.62
		host.player.camera.rotation = Vector3(-0.035, 0, 0)
	elif completed == "warehouse":
		_door("streetLeft", 1); _door("streetRight", 1)
	elif completed == "office": _open_stairs()
	_clear(completed in ["intro", "office"])
	host._save()
	if completed == "corridor": host.ui.notify("Terkunci dari luar. Dari sambungan logam di timur lorong terasa hembusan udara.", 6)

func cancel() -> void:
	if running: _clear(true)

func _clear(restore_player: bool) -> void:
	running = false
	set_process(false)
	expansion.clear()
	chapter.clear()
	for name_value in npc_poses:
		var npc = host.level.get_node_or_null("NPC_" + name_value) as Node3D
		if npc != null: npc.transform = npc_poses[name_value]
	npc_poses.clear()
	for head in head_poses:
		if is_instance_valid(head.node): head.node.transform = head.pose
	head_poses.clear()
	if restore_player:
		host.player.transform = player_pose
		host.player.camera.transform = camera_pose
	if is_instance_valid(actor): actor.queue_free()
	actor = null
	joints.clear()
	host.player.velocity = Vector3.ZERO
	host.player.last_safe_position = host.player.position
	host.ui.notify("", 0)
	host.ui.cinematic_hint.visible = false
	host.cinematic = false
	host._sync_active()
