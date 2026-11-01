extends RefCounted

var host: Node3D
var timeline: Node
var id = ""
var poses: Dictionary = {}
var teacher_pose: Transform3D
var teacher: Node3D
var caller: Node3D
var finished = false
var shower: Node3D
const SEATS = {"Danu": Vector3(-5.6, 0, 9.02), "Raka": Vector3(-5.6, 0, 10.72), "Sari": Vector3(-5.6, 0, 12.42), "Adit": Vector3(-8, 0, 12.42)}

func handles(value: String) -> bool:
	return value in ["wake_home", "wash", "lesson", "return_class"]

func prepare(value: String) -> void:
	id = value; finished = false
	if id == "wash":
		shower = host.level.get_node("FurnishedHome/BathroomShower")
		host.player.position = Vector3(-3.1, 0.10, 0.68)
		host.player.rotation = Vector3.ZERO
		host.player.camera.rotation = Vector3(-0.35, 0, 0)
	if id in ["lesson", "return_class"]:
		teacher = host.level.get_node("EnvironmentalDetail/Teacher")
		teacher_pose = teacher.transform
		for name_value in ["Danu", "Raka", "Adit", "Sari"]:
			var npc = host.level.get_node("NPC_" + name_value) as Node3D
			poses[name_value] = npc.transform
			npc.position = SEATS[name_value]
			npc.rotation = Vector3(0, PI, 0)
			npc.sit(); npc.get_node("ContactBody").collision_layer = 0
		host.player.position = Vector3(-3.0, 0.05, 12.9)
		host.player.camera.look_at(Vector3(-7.8, 1.6, 7.5))
		caller = preload("res://scripts/systems/model_factory.gd").make("npc_Adit") as Node3D
		caller.position = Vector3(-1.5, 0, 9.7); caller.rotation.y = -PI / 2; caller.visible = false
		host.level.add_child(caller)

func animate(time: float, delta: float) -> void:
	match id:
		"wake_home":
			host.player.camera.rotation.z = lerpf(0.22, 0.0, smoothstep(0, 7, time))
			host.player.get_node("Head").position.y = lerpf(0.94, 1.62, smoothstep(1, 7, time))
			host.ui.fade.color.a = 1 - smoothstep(0, 2, time)
		"wash":
			shower.set_running(time >= 1.6 and time < 13.6)
			var target = Vector3(-3.1, 2.06, 0.37) if time < 4.0 else Vector3(-3.1, 0.94, 0.22)
			_look(target, delta * 1.8)
			host.ui.fade.color.a = smoothstep(13.5, 14.5, time) * (1 - smoothstep(16.5, 18, time))
		"lesson":
			caller.visible = time > 10 and time < 18
			if time > 14:
				var corner = Vector3(-3, 0, 7.1)
				if time < 16: move_actor(teacher, teacher_pose.origin, corner, 14, 16, time)
				else: move_actor(teacher, corner, Vector3(-1.5, 0, 9.7), 16, 18, time)
				teacher.visible = time < 18
			var danu = host.level.get_node("NPC_Danu") as Node3D
			var raka = host.level.get_node("NPC_Raka") as Node3D
			if time >= 17:
				move_actor(danu, SEATS.Danu, Vector3(-4.35, 0, 9.65), 17, 18.3, time)
				move_actor(raka, SEATS.Raka, Vector3(-3.55, 0, 10.0), 17, 18.3, time)
				danu.rotation.y = PI / 2; raka.rotation.y = -PI / 2
				var grip = smoothstep(18, 18.6, time) * (1.0 - smoothstep(36, 38, time))
				raka.reach(grip); danu.torso.rotation.z = -grip * 0.07
				var sari = host.level.get_node("NPC_Sari") as Node3D
				var adit = host.level.get_node("NPC_Adit") as Node3D
				if time >= 23:
					move_actor(sari, SEATS.Sari, Vector3(-4.15, 0, 10.95), 23, 25, time)
					sari.rotation.y = PI; sari.reach(0.45)
				if time >= 27:
					if time < 29: move_actor(adit, SEATS.Adit, Vector3(-3.2, 0, 12.8), 27, 29, time)
					else: move_actor(adit, Vector3(-3.2, 0, 12.8), Vector3(-2.85, 0, 10.8), 29, 30.5, time)
					adit.rotation.y = -PI / 2
				_look(Vector3(-4, 1.5, 10), delta * 2)
			else: _look(teacher.position + Vector3.UP * 1.55, delta * 2)
		"return_class":
			host.ui.fade.color.a = sin(clampf(time / 11, 0, 1) * PI) * 0.8 if time < 11 else 0

func _look(point: Vector3, amount: float) -> void:
	var before = host.player.camera.global_basis.get_rotation_quaternion()
	host.player.camera.look_at(point)
	host.player.camera.global_basis = Basis(before.slerp(host.player.camera.global_basis.get_rotation_quaternion(), minf(1, amount)))

func move_actor(npc: Node3D, from: Vector3, to: Vector3, start: float, end: float, time: float) -> void:
	var progress = smoothstep(start, end, time)
	npc.stand(); npc.position = from.lerp(to, progress)
	var heading = to - from
	npc.rotation.y = atan2(heading.x, heading.z)
	npc.animate_walk(time * 8, 0.36 if progress > 0 and progress < 1 else 0.0)

func finish() -> void:
	finished = true
	if id == "lesson": State.set_flag("introSeen")
	if id == "wash": State.set_flag("homeReady")

func clear() -> void:
	if is_instance_valid(shower): shower.set_running(false)
	shower = null
	for name_value in poses:
		var npc = host.level.get_node_or_null("NPC_" + name_value) as Node3D
		if npc != null:
			npc.stand(); npc.torso.rotation = Vector3.ZERO; npc.transform = poses[name_value]
			npc.get_node("ContactBody").collision_layer = 16
	poses.clear()
	if is_instance_valid(teacher): teacher.stand(); teacher.transform = teacher_pose; teacher.visible = true
	if is_instance_valid(caller): caller.queue_free()
	teacher = null; caller = null
	host.ui.fade.color.a = 0
	host.player.get_node("Head").position.y = 1.62
