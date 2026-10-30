extends RefCounted

var root: Node3D
var body: Node3D
var head: Node3D
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var wrists: Array[Node3D] = []
var legs: Array[Node3D] = []
var knees: Array[Node3D] = []
var feet: Array[Node3D] = []
var gait = 0.0
var clock = 0.0
var crouch = 0.0
var skeleton: Skeleton3D
var sculpt: Node3D
var bone_arms: Array[int] = []
var bone_legs: Array[int] = []
var bone_knees: Array[int] = []
var bone_feet: Array[int] = []
var pelvis_bone = -1
var spine_bone = -1
var bone_rest: Array[Transform3D] = []
var foot_floor = 0.0

func bone(label: String) -> int:
	var index = skeleton.find_bone(label)
	return skeleton.find_bone(label.replace(".", "_")) if index < 0 else index

func bind(model: Node3D) -> void:
	root = model
	var found = root.find_children("*", "Skeleton3D", true, false)
	if not found.is_empty():
		skeleton = found[0]; sculpt = root.get_node("RepairedSculpt")
		for i in range(skeleton.get_bone_count()): bone_rest.append(skeleton.get_bone_rest(i))
		for i in range(6):
			bone_arms.append(bone("upper_arm_%d.%s" % [i / 2 + 1, "L" if i % 2 == 0 else "R"]))
			arms.append(null)
		for side in ["L", "R"]:
			bone_legs.append(bone("thigh." + side)); bone_knees.append(bone("shin." + side)); bone_feet.append(bone("foot." + side))
		pelvis_bone = bone("pelvis"); spine_bone = bone("spine")
		foot_floor = minf(skeleton.get_bone_global_pose(bone_feet[0]).origin.y, skeleton.get_bone_global_pose(bone_feet[1]).origin.y)
		return
	body = root.find_child("HandsBody", true, false)
	head = root.find_child("HandsHead", true, false)
	for i in range(6):
		arms.append(root.find_child("HandsArm%d" % i, true, false))
		elbows.append(root.find_child("HandsElbow%d" % i, true, false))
		wrists.append(root.find_child("HandsWrist%d" % i, true, false))
	for i in range(2):
		legs.append(root.find_child("HandsLeg%d" % i, true, false))
		knees.append(root.find_child("HandsKnee%d" % i, true, false))
		feet.append(root.find_child("HandsFoot%d" % i, true, false))

func animate(delta: float, moved: float, low = false, reach = 0.0) -> void:
	clock += delta
	gait += moved * 5.4
	var walk = clampf(moved / maxf(delta, 0.001) / 3.8, 0, 1)
	crouch = move_toward(crouch, 1.0 if low else 0.0, delta * 5)
	if skeleton != null:
		if pelvis_bone >= 0: skeleton.set_bone_pose_position(pelvis_bone, bone_rest[pelvis_bone].origin + Vector3(0, -crouch * 0.20, 0))
		pose_bone(spine_bone, Vector3(crouch * 0.85 + reach * 0.10, 0, 0))
		for i in range(bone_arms.size()):
			if bone_arms[i] < 0: continue
			var side = -1.0 if i % 2 == 0 else 1.0
			var pose = Vector3(sin(gait + i * 1.1) * 0.22 * walk - reach * 0.6 - crouch * 0.7, side * reach * 0.2, sin(clock * 1.8 + i) * 0.045)
			pose_bone(bone_arms[i], pose)
		for i in range(bone_legs.size()):
			var swing = sin(gait + i * PI)
			var hip_angle = swing * walk * 0.38 - crouch * 0.9
			var knee_angle = maxf(0, -swing) * walk * 0.42 + crouch * 1.8
			pose_bone(bone_legs[i], Vector3(hip_angle, 0, 0))
			pose_bone(bone_knees[i], Vector3(knee_angle, 0, 0))
			pose_bone(bone_feet[i], Vector3(-hip_angle - knee_angle, 0, 0))
		# Restore the lowest sole after posing instead of sinking the whole sculpt.
		var lowest = minf(skeleton.get_bone_global_pose(bone_feet[0]).origin.y, skeleton.get_bone_global_pose(bone_feet[1]).origin.y)
		sculpt.position.y = foot_floor - lowest
		return
	if body != null:
		body.position.y = absf(sin(gait)) * 0.028 * walk + sin(clock * 1.7) * 0.01 - crouch * 0.34
		body.rotation.x = 0.14 * walk + crouch * 0.18
	if head != null:
		head.position.y = 1.9 - crouch * 0.78
		head.rotation = Vector3(-0.02, 0, sin(clock * 1.4) * 0.06)
	for i in range(2):
		var swing = sin(gait + i * PI)
		if legs[i] != null:
			legs[i].position.y = 0.87 - crouch * 0.32
			legs[i].rotation.x = swing * 0.45 * walk - crouch * 0.35
		if knees[i] != null: knees[i].rotation.x = maxf(0, -swing) * 0.4 * walk + crouch * 0.7
		if feet[i] != null and legs[i] != null and knees[i] != null: feet[i].rotation.x = -legs[i].rotation.x - knees[i].rotation.x
	for i in range(6):
		var arm = arms[i]
		if arm == null: continue
		var swing = sin(gait + i * 1.15)
		var side = 1.0 if i % 2 else -1.0
		arm.position.y = 1.55 - floorf(float(i) / 2) * 0.27 - crouch * 0.43
		arm.rotation.z = side * (0.22 + floorf(float(i) / 2) * 0.17) * (1 - crouch * 0.55)
		arm.rotation.y = -side * crouch * 0.65
		arm.rotation.x = -swing * 0.32 * walk - 0.18 * walk - reach * (1.0 if i < 2 else 0.5) - crouch * 0.85
		if elbows[i] != null: elbows[i].rotation.x = -0.25 - maxf(0, swing) * 0.36 * walk - crouch * 0.45
		if wrists[i] != null: wrists[i].rotation.x = sin(clock * 2.3 + i) * 0.1

func pose_bone(index: int, euler: Vector3) -> void:
	if index >= 0: skeleton.set_bone_pose_rotation(index, bone_rest[index].basis.get_rotation_quaternion() * Quaternion.from_euler(euler))
