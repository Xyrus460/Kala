extends Node3D
## Native articulated characters. All poses keep soles above the floor.
const G = preload("res://scripts/systems/geometry.gd")
var torso: Node3D
var head: Node3D
var hips: Array[Node3D] = []
var knees: Array[Node3D] = []
var arms: Array[Node3D] = []
var elbows: Array[Node3D] = []
var seated = false
var clock = 0.0
var doll = false

static func create(identity: String) -> Node3D:
	var rig = load("res://scripts/systems/character_model.gd").new()
	rig.name = identity
	rig.doll = identity == "Daisy"
	rig.build(identity)
	return rig

func paint(tint: String, rough = 0.7) -> StandardMaterial3D:
	var m = G.material("plain", Color(tint)).duplicate()
	m.roughness = rough
	return m

func joint(parent: Node3D, title: String, p: Vector3) -> Node3D:
	var n = Node3D.new(); n.name = title; n.position = p; parent.add_child(n); return n

func ell(parent: Node3D, title: String, p: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh = G.sphere(parent, p, size, mat); mesh.name = title; return mesh

func taper(parent: Node3D, p: Vector3, top: float, bottom: float, height: float, mat: Material) -> MeshInstance3D:
	var mesh = G.cylinder(parent, p, bottom, height, mat)
	(mesh.mesh as CylinderMesh).top_radius = top
	(mesh.mesh as CylinderMesh).radial_segments = 32
	return mesh

func build(identity: String) -> void:
	var girl = identity in ["Sari", "Mother", "Daisy", "Ratna"]
	var teacher = identity == "Ratna"
	set_meta("identity", identity)
	var skin = paint("ead9bb" if doll else "bd9475", 0.48 if doll else 0.73)
	var hair = paint("a37a36" if doll else "211c1b", 0.8)
	var shirt = paint("ad9472" if teacher else "9ab6d2" if doll else "c6a095" if identity == "Mother" else "e2e1d3")
	var uniform = paint("584e42" if teacher else "576b85" if doll else "647787")
	var dark = paint("252830", 0.48)
	var white = paint("f1e9dc", 0.26)
	var torso_height = 0.99 if doll else 1.13
	torso = joint(self, "TorsoRig", Vector3.ZERO)
	ell(torso, "TailoredShirt", Vector3(0, torso_height, 0), Vector3(0.46, 0.58, 0.29) if not doll else Vector3(0.39, 0.45, 0.25), shirt)
	ell(torso, "Neck", Vector3(0, 1.45 if not doll else 1.24, 0), Vector3(0.13, 0.19, 0.13), skin)
	head = joint(torso, "HeadRig", Vector3(0, 1.6 if not doll else 1.56, 0))
	var hs = Vector3(0.31, 0.40, 0.32) if not doll else Vector3(0.68, 0.64, 0.55)
	ell(head, "SculptedFace", Vector3.ZERO, hs, skin)
	ell(head, "HairCap", Vector3(0, hs.y * 0.25, -0.035), hs * Vector3(1.06, 0.72, 1.02), hair)
	for side in [-1, 1]:
		ell(head, "Ear", Vector3(side * hs.x * 0.48, -0.025, 0), Vector3(0.065, 0.10, 0.05), skin)
		var ex = side * (0.145 if doll else 0.065)
		var ey = -0.025 if doll else 0.01
		var ez = 0.241 if doll else 0.143
		var es = Vector3(0.22, 0.25, 0.10) if doll else Vector3(0.087, 0.045, 0.039)
		ell(head, "EyeSocket", Vector3(ex, ey, ez - 0.012), es * 1.18, paint("866a65"))
		ell(head, "EyeWhite", Vector3(ex, ey, ez), es, white)
		ell(head, "Iris", Vector3(ex, ey, ez + (0.047 if doll else 0.019)), Vector3(0.142, 0.17, 0.027) if doll else Vector3(0.032, 0.035, 0.012), paint("53799c" if doll else "604c39", 0.23))
		ell(head, "Pupil", Vector3(ex, ey, ez + (0.062 if doll else 0.026)), Vector3(0.072, 0.11, 0.012) if doll else Vector3(0.017, 0.023, 0.008), dark)
		ell(head, "Catchlight", Vector3(ex - 0.014, ey + 0.023, ez + (0.071 if doll else 0.029)), Vector3.ONE * (0.026 if doll else 0.009), white)
		var brow = ell(head, "Brow", Vector3(ex, ey + (0.15 if doll else 0.06), ez - 0.015), Vector3(0.17 if doll else 0.09, 0.022, 0.025), hair)
		brow.rotation.z = side * -0.13
		if doll:
			ell(head, "PaintedCheek", Vector3(side * 0.23, -0.14, 0.207), Vector3(0.14, 0.065, 0.018), paint("c5827d"))
			for i in range(5):
				var lash = G.cylinder(head, Vector3(ex + side * (0.055 + i * 0.013), 0.058 + i * 0.008, 0.28), 0.004, 0.055, dark)
				lash.rotation.z = -side * (0.2 + i * 0.13)
		else:
			for i in range(4): ell(head, "HairLock", Vector3(side * (0.025 + i * 0.035), 0.11 - i * 0.012, 0.117), Vector3(0.075, 0.13, 0.045), hair)
	ell(head, "Nose", Vector3(0, -0.045 if not doll else -0.10, 0.16 if not doll else 0.267), Vector3(0.048, 0.073, 0.073) if not doll else Vector3(0.07, 0.09, 0.065), skin)
	ell(head, "Mouth", Vector3(0, -0.12 if not doll else -0.222, 0.133 if not doll else 0.228), Vector3(0.083, 0.018, 0.022) if not doll else Vector3(0.12, 0.038, 0.03), paint("925b52"))
	if girl:
		if doll:
			for side in [-1, 1]:
				var tail = joint(head, "CurledPigtailL" if side < 0 else "CurledPigtailR", Vector3(side * 0.40, 0.18, -0.035))
				for strand in range(6):
					for i in range(7):
						var a = i * 1.8 + strand * 1.05
						ell(tail, "Ringlet", Vector3(sin(a) * 0.053 + side * strand * 0.018, -i * 0.047, cos(a) * 0.055), Vector3(0.09, 0.08, 0.07), hair)
				for direction in [-1, 1]:
					var bow = ell(tail, "BlueRibbon", Vector3(direction * 0.075, 0.07, 0.035), Vector3(0.17, 0.10, 0.07), uniform); bow.rotation.z = direction * 0.4
				ell(tail, "RibbonKnot", Vector3(0, 0.07, 0.07), Vector3(0.055, 0.065, 0.05), shirt)
			# Daisy keeps her original golden hair, porcelain skin and blue dress.
			for i in range(5):
				var lock = ell(head, "GoldenFringe", Vector3(-0.17 + i * 0.08, 0.20 - i * 0.012, 0.205), Vector3(0.14, 0.23, 0.095), hair); lock.rotation.z = -0.35
			var skirt = taper(torso, Vector3(0, 0.66, 0), 0.19, 0.47, 0.62, uniform); skirt.name = "DaisyDress"
			for i in range(32):
				var a = TAU * i / 32
				var pleat = ell(torso, "DressPleat", Vector3(sin(a) * 0.315, 0.65, cos(a) * 0.315), Vector3(0.042, 0.56, 0.044), shirt); pleat.rotation.z = sin(a) * 0.45; pleat.rotation.x = -cos(a) * 0.45
				ell(torso, "LaceHem", Vector3(sin(a) * 0.444, 0.365, cos(a) * 0.444), Vector3(0.092, 0.055, 0.065), white)
			ell(torso, "Pinafore", Vector3(0, 0.97, 0.117), Vector3(0.27, 0.33, 0.045), white)
			for side in [-1, 1]:
				var bow = ell(torso, "CollarBow", Vector3(side * 0.06, 1.16, 0.14), Vector3(0.13, 0.075, 0.055), uniform); bow.rotation.z = side * 0.25
		else:
			ell(torso, "RatnaHair" if teacher else "Sari_Long_Hair", Vector3(0, 1.40, -0.09), Vector3(0.35, 0.52, 0.21), hair)
			var skirt = taper(torso, Vector3(0, 0.62 if teacher else 0.80, 0), 0.18, 0.29 if teacher else 0.28, 0.74 if teacher else 0.40, uniform); skirt.name = "RatnaLongSkirt" if teacher else "Sari_School_Skirt"
			if teacher:
				ell(head, "HairBun", Vector3(0, 0.05, -0.19), Vector3(0.23, 0.23, 0.18), hair)
				G.box(torso, Vector3(0.115, 1.24, 0.155), Vector3(0.13, 0.045, 0.012), dark)
				for side in [-1, 1]:
					G.box(head, Vector3(side * 0.068, 0.035, 0.168), Vector3(0.098, 0.009, 0.013), dark)
					ell(head, "Earring", Vector3(side * 0.16, -0.075, 0.012), Vector3.ONE * 0.027, paint("c7ab68", 0.3))
	else:
		ell(torso, "TrouserWaist", Vector3(0, 0.88, 0), Vector3(0.36, 0.22, 0.25), uniform)
	if not doll:
		for side in [-1, 1]:
			var collar = G.box(torso, Vector3(side * 0.057, 1.37, 0.13), Vector3(0.1, 0.13, 0.018), white); collar.rotation.z = side * 0.35
		G.box(torso, Vector3(-0.115, 1.20, 0.146), Vector3(0.09, 0.075, 0.016), uniform)
		for i in range(3): ell(torso, "ShirtButton", Vector3(0, 1.27 - i * 0.10, 0.146), Vector3.ONE * 0.014, dark)
	for side in [-1, 1]:
		var hip = joint(torso, "HipL" if side < 0 else "HipR", Vector3(side * 0.105, 0.86 if not doll else 0.68, 0)); hips.append(hip)
		var thigh_length = 0.41 if not doll else 0.28
		ell(hip, "Thigh", Vector3(0, -thigh_length / 2, 0), Vector3(0.15, thigh_length + 0.04, 0.16), uniform if not doll else skin)
		var knee = joint(hip, "Knee", Vector3(0, -thigh_length, 0)); knees.append(knee)
		ell(knee, "Shin", Vector3(0, -0.19 if not doll else -0.14, 0), Vector3(0.125, 0.39 if not doll else 0.28, 0.13), uniform if not girl else white)
		ell(knee, "LeatherShoe", Vector3(0, -0.38 if not doll else -0.29, 0.05), Vector3(0.17, 0.12, 0.29), dark)
		var arm = joint(torso, "ArmL" if side < 0 else "ArmR", Vector3(side * (0.24 if not doll else 0.20), 1.38 if not doll else 1.12, 0)); arms.append(arm)
		ell(arm, "ShortSleeve", Vector3(0, -0.095, 0), Vector3(0.17, 0.24, 0.19), shirt)
		ell(arm, "UpperArm", Vector3(0, -0.19, 0), Vector3(0.10, 0.24, 0.11), skin)
		var elbow = joint(arm, "Elbow", Vector3(0, -0.27, 0)); elbows.append(elbow)
		ell(elbow, "Forearm", Vector3(0, -0.12, 0), Vector3(0.09, 0.25, 0.10), skin)
		ell(elbow, "Palm", Vector3(0, -0.27, 0.015), Vector3(0.09, 0.12, 0.055), skin)
		for i in range(4): ell(elbow, "Finger", Vector3(-0.031 + i * 0.021, -0.335, 0.02), Vector3(0.019, 0.079 - absf(i - 1.5) * 0.012, 0.021), skin)
		ell(elbow, "Thumb", Vector3(side * 0.055, -0.29, 0.028), Vector3(0.03, 0.08, 0.027), skin)
		arm.rotation.z = side * 0.07
	if doll: scale = Vector3.ONE * 0.72

func sit() -> void:
	seated = true
	torso.position.y = -0.34
	for i in range(2):
		hips[i].rotation.x = -PI / 2
		knees[i].rotation.x = PI / 2
		arms[i].rotation.x = -0.35
		elbows[i].rotation.x = -0.9

func stand() -> void:
	seated = false
	torso.position = Vector3.ZERO
	for i in range(2):
		hips[i].rotation = Vector3.ZERO; knees[i].rotation = Vector3.ZERO
		arms[i].rotation = Vector3(0, 0, -0.07 if i == 0 else 0.07)
		elbows[i].rotation = Vector3.ZERO

func animate_walk(time: float, strength = 0.55) -> void:
	if seated: return
	for i in range(2):
		var swing = sin(time + i * PI)
		hips[i].rotation.x = swing * strength
		knees[i].rotation.x = maxf(0, -swing) * strength * 0.7
		arms[i].rotation.x = -swing * strength * 0.7
		elbows[i].rotation.x = -0.12 - maxf(0, swing) * 0.25

func reach(amount: float) -> void:
	arms[1].rotation.x = -amount * 1.35
	elbows[1].rotation.x = -amount * 0.4

func _process(delta: float) -> void:
	clock += delta
	if head != null: head.rotation.z = sin(clock * 1.1) * 0.008
