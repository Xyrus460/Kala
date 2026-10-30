extends RefCounted

var root: Node3D
var parts: Dictionary = {}
var rest: Dictionary = {}
var gait = 0.0
var clock = 0.0
var locomotion = 0.0
var attack = 0.0
var foot_rest: Array[Vector3] = []

func bind(model: Node3D) -> void:
	root = model
	parts.clear(); rest.clear(); foot_rest.clear(); gait = 0; clock = 0; locomotion = 0; attack = 0
	for label in ["FinalBody", "FinalHead", "BackPortal", "FinalLeg0", "FinalLeg1", "FinalKnee0", "FinalKnee1", "FinalFoot0", "FinalFoot1", "FinalArm0", "FinalArm1", "FinalElbow0", "FinalElbow1", "FinalWrist0", "FinalWrist1"]:
		var node = root.find_child(label, true, false) as Node3D
		if node != null: parts[label] = node; rest[label] = node.transform
	for i in range(2):
		if parts.has("FinalFoot%d" % i): foot_rest.append(root.to_local(parts["FinalFoot%d" % i].global_position))

func turn(label: String, euler: Vector3) -> void:
	if parts.has(label): parts[label].basis = rest[label].basis * Basis.from_euler(euler)

func animate(delta: float, moved: float, _low = false, reach = 0.0) -> void:
	if not is_instance_valid(root): return
	clock += delta; gait = fmod(gait + maxf(0, moved) * TAU / 1.25, TAU)
	var blend = 1.0 - exp(-maxf(0, delta) * 12.0)
	locomotion = lerpf(locomotion, clampf(moved / maxf(delta, 0.001) / 2.7, 0, 1), blend)
	attack = lerpf(attack, clampf(reach, 0, 1), blend)
	var breath = sin(clock * 1.8) * 0.008 - locomotion * 0.07
	for label in ["FinalBody", "FinalHead", "BackPortal", "FinalArm0", "FinalArm1"]:
		if parts.has(label): parts[label].position = rest[label].origin + Vector3.UP * breath
	turn("FinalHead", Vector3(0, sin(clock * 0.7) * 0.05, sin(clock * 1.2) * 0.025))
	for i in range(2):
		if parts.has("FinalLeg%d" % i): parts["FinalLeg%d" % i].position = rest["FinalLeg%d" % i].origin - Vector3.UP * locomotion * 0.07
		var side = -1.0 if i == 0 else 1.0
		var swing = sin(gait + i * PI)
		if foot_rest.size() == 2:
			var target = foot_rest[i]
			# During stance the foot sweeps backwards as the body advances. The
			# opposite foot lifts only during swing; both never sink into the floor.
			target.z += cos(gait + i * PI) * 0.19 * locomotion
			target.y += maxf(0, swing) * 0.13 * locomotion
			_place_foot(i, target)
		turn("FinalArm%d" % i, Vector3(-attack * 0.8 - swing * locomotion * 0.18, 0, side * (0.18 + i * 0.08 + sin(clock * 1.1 + i) * 0.025)))
		turn("FinalElbow%d" % i, Vector3(-0.25 - attack * 0.45, 0, side * 0.10))
		turn("FinalWrist%d" % i, Vector3(-0.12, sin(clock + i) * 0.07, 0))

func _place_foot(index: int, target: Vector3) -> void:
	var hip_label = "FinalLeg%d" % index
	var knee_label = "FinalKnee%d" % index
	var foot_label = "FinalFoot%d" % index
	var hip: Node3D = parts[hip_label]
	var origin = root.to_local(hip.global_position)
	var upper: Vector3 = rest[knee_label].origin
	var lower: Vector3 = rest[foot_label].origin
	var a = Vector2(upper.z, upper.y).length()
	var b = Vector2(lower.z, lower.y).length()
	var distance = Vector2(target.z - origin.z, origin.y - target.y)
	var length_value = clampf(distance.length(), absf(a - b) + 0.001, a + b - 0.001)
	var angle = atan2(distance.x, distance.y)
	var first = angle - acos(clampf((a*a + length_value*length_value - b*b) / (2*a*length_value), -1, 1))
	var second = atan2(distance.x - a*sin(first), distance.y - a*cos(first))
	var hip_angle = atan2(upper.z, -upper.y) - first
	var knee_angle = atan2(lower.z, -lower.y) - hip_angle - second
	turn(hip_label, Vector3(hip_angle, 0, 0))
	turn(knee_label, Vector3(knee_angle, 0, 0))
	turn(foot_label, Vector3(-hip_angle - knee_angle, 0, 0))
