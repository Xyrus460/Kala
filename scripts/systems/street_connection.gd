extends RefCounted
const G = preload("res://scripts/systems/geometry.gd")

func build(w: RefCounted) -> void:
	var level: Node3D = w.level
	var root = Node3D.new(); root.name = "ConnectedStreet"; level.add_child(root)
	G.box(root, Vector3(0, -0.36, 15), Vector3(200, 0.25, 200), w.mat("plain", "7d8b70"))
	G.box(root, Vector3(0, -0.15, 30.5), Vector3(58, 0.3, 15), w.mat("concrete", "737b7d"), true)
	G.box(root, Vector3(26, -0.15, 48), Vector3(4, 0.3, 26), w.mat("concrete", "7c827e"), true)
	for z in [24.2, 36.8]: G.box(root, Vector3(0, 0.06, z), Vector3(58, 0.12, 1.9), w.mat("ceramic", "b6b7a7"), true)
	# The curb has a flush ramp directly opposite the school gate.
	for x in range(-27, 28, 5): G.box(root, Vector3(x, 0.014, 30.5), Vector3(2.4, 0.02, 0.10), w.mat("plain", "ddd1ac"))
	for z in range(26, 35, 2): G.box(root, Vector3(0, 0.016, z), Vector3(3.0, 0.024, 0.7), w.mat("plain", "d5d6c6"))
	for x in [-24, -15, -6, 5, 14]:
		G.box(root, Vector3(x, 2.1, 40.7), Vector3(7.5, 4.2, 5.0), w.mat("plaster", ["b6b7a5", "b3bfb4", "c2b39b"][absi(x) % 3]), true)
		G.box(root, Vector3(x, 4.35, 40.7), Vector3(8, 0.3, 5.6), w.mat("ceramic", "956950"))
		G.box(root, Vector3(x, 1.1, 38.14), Vector3(1.0, 2.2, 0.10), w.mat("burlap", "645547"))
		for dx in [-2.1, 2.1]:
			G.box(root, Vector3(x + dx, 2, 38.13), Vector3(1.3, 1.4, 0.08), w.mat("plain", "688b96"))
			for offset in [-0.65, 0, 0.65]: G.box(root, Vector3(x + dx + offset, 2, 38.06), Vector3(0.045, 1.48, 0.06), w.mat("plain", "e0d3b8"))
	for x in [-25, -12, 12, 23]:
		G.cylinder(root, Vector3(x, 2.8, 24.7), 0.055, 5.6, w.mat("steel", "55615e"))
		G.box(root, Vector3(x + 0.55, 5.6, 24.7), Vector3(1.2, 0.14, 0.23), w.mat("steel", "63716c"))
		w._tree(Vector3(x, 0, 36.6), 4.3)
	# Street-facing walls terminate at the curb and retain a human-scale height.
	for x in [23.8, 28.2]:
		G.box(root, Vector3(x, 1.15, 48.6), Vector3(0.20, 2.3, 23.2), w.mat("plaster", "a7a18d"), true).name = "AlleyBoundary"
		G.box(root, Vector3(x, 2.32, 48.6), Vector3(0.29, 0.10, 23.2), w.mat("concrete", "817e70"))
		for z in [38.0, 43.5, 49, 54.5, 60]:
			G.box(root, Vector3(x, 1.18, z), Vector3(0.32, 2.36, 0.32), w.mat("concrete", "989580"), true)
	for i in range(11):
		var x = -65 + i * 12
		if x > 18 and x < 35: continue # Keep the complete alley footprint clear.
		G.box(root, Vector3(x, 3, 52), Vector3(9, 6, 9), w.mat("plain", ["a4afa4", "8b9a94", "b6b29d"][i % 3]))
		G.box(root, Vector3(x, 6.15, 52), Vector3(10, 0.3, 10), w.mat("plain", "856d5b"))
	# Downloaded CC0 motorcycles replace the primitive bike shapes.
	for i in range(3):
		preload("res://scripts/systems/free_assets.gd").place(root, "res://assets/vendor/innerscene/motorcycle.glb", Vector3(-14 + i * 2.2, 0.02, 25.7), Vector3(-1, 1.16, -1), 0.35, true, "ParkedMotorcycle%d" % i)
	preload("res://scripts/systems/neighborhood_backdrop.gd").new().build(level)
	G.box(root, Vector3(26, 2, 60), Vector3(4.4, 4, 0.22), w.mat("steel", "485952"), true)
	w.text("JALAN KARTINI    → GANG GUDANG", Vector3(20.9, 2.4, 35.9), 23, PI)
	w.text("AKSES BELAKANG\nGUDANG KARTINI", Vector3(26, 2.7, 59.8), 23, PI)
	level.interact(Vector3(26, 1.4, 59), "chapter", "Susul Danu ke gudang", "alley", false, Vector3(3.6, 2.6, 1.5))
	# Pedestrians stay on the pavement; deterministic patrols never block the gate.
	for i in range(5):
		var npc = preload("res://scripts/systems/model_factory.gd").make("npc_" + ["Adit", "Sari", "Raka"][i % 3])
		npc.name = "Pedestrian%d" % i; npc.position = Vector3(-21 + i * 9, 0.12, 36.3); npc.rotation.y = PI / 2; root.add_child(npc)
		npc.set_meta("start_x", npc.position.x)
