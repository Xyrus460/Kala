extends RefCounted
const A = preload("res://scripts/systems/free_assets.gd")
const G = preload("res://scripts/systems/geometry.gd")

func build(level: Node3D, center_z = 28.0) -> void:
	var root = Node3D.new(); root.name = "RepeatingNeighborhood"; level.add_child(root)
	var ground = G.material("plain", Color("819076"))
	G.box(root, Vector3(0, -0.4, center_z), Vector3(340, 0.2, 340), ground)
	G.box(root, Vector3(0, -0.16, 30.5 if level.room_id == "schoolyard" else 2.0), Vector3(310, 0.16, 11.0), G.material("concrete", Color("767d78")))
	for side in [-1, 1]:
		G.box(root, Vector3(0, -0.03, (30.5 if level.room_id == "schoolyard" else 2.0) + side * 6.3), Vector3(310, 0.12, 1.5), G.material("plain", Color("b6b7a7")))
	# Repeat fixed blocks outside the invisible playable perimeter on every side.
	for row in range(-5, 6):
		for col in range(-7, 8):
			var x = col * 14.0
			var z = center_z + row * 17.0
			if row == 0: continue
			if absf(x) < 38 and z > -92 and z < 72: continue
			var id = ["a", "b", "c", "d", "e", "f", "g", "h"][posmod(col * 3 + row, 8)]
			A.place(root, A.SUBURBAN + "building-type-" + id + ".glb", Vector3(x, -0.1, z), Vector3(-1, 5.3 + posmod(row + col, 3) * 0.65, -1), 0 if row % 2 == 0 else PI, false)
	# Continuous side streets lead the eye into the repeating blocks.
	for side in [-1, 1]:
		G.box(root, Vector3(side * 52, -0.15, center_z), Vector3(8, 0.14, 180), G.material("concrete", Color("767d78")))
