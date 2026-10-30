extends RefCounted
const G = preload("res://scripts/systems/geometry.gd")

static func create() -> Node3D:
	var root = Node3D.new(); root.name = "SeekingHand"
	var flesh = G.material("sinew", Color("bfa694"))
	var nail = G.material("plain", Color("ded3b5"))
	G.sphere(root, Vector3.ZERO, Vector3(0.38, 0.45, 0.17), flesh)
	G.sphere(root, Vector3(0, -0.28, 0), Vector3(0.22, 0.30, 0.17), flesh)
	for i in range(5):
		var finger = Node3D.new(); finger.name = "Finger%d" % i; root.add_child(finger)
		finger.position = Vector3(-0.16 + i * 0.08, 0.13, 0)
		finger.rotation.z = (2 - i) * 0.13; finger.rotation.x = -0.4
		var length = 0.21 if i in [0, 4] else 0.31
		G.sphere(finger, Vector3(0, length * 0.4, 0), Vector3(0.07, length, 0.075), flesh)
		G.sphere(finger, Vector3(0, length * 0.86, 0.05), Vector3(0.065, length * 0.55, 0.07), flesh)
		var claw = G.cylinder(finger, Vector3(0, length * 1.11, 0.07), 0.027, 0.14, nail); (claw.mesh as CylinderMesh).top_radius = 0.001; claw.rotation.x = 0.65
	return root
