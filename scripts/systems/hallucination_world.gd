extends RefCounted
const G = preload("res://scripts/systems/geometry.gd")
const MEMORY_IDS = ["op1", "op2", "A", "B"]
const MEMORY_NAMES = ["FOTO / TANGGAL ASLI", "AGENDA / KESAKSIAN SARI", "SURAT / SUARA RAKA", "ALBUM / PERJANJIAN"]

static func definition() -> Dictionary:
	return {"width": 18, "depth": 116, "cx": 0, "spawn": [0, 0.05, 3], "yaw": 0, "colliders": [], "doors": [], "interactions": [], "tools": []}

func build(level: Node3D) -> void:
	var root = Node3D.new(); root.name = "FracturedMemories"; level.add_child(root)
	var plaster = G.material("plaster", Color("8c9293"))
	var dark = G.material("steel", Color("45525b"))
	var wood = G.material("burlap", Color("8f6e51"))
	var floor_mat = G.material("ceramic", Color("939d9c"))
	G.box(root, Vector3(0, -0.16, -46), Vector3(18, 0.32, 116), floor_mat, true)
	for side in [-1, 1]: G.box(root, Vector3(side * 9, 2.5, -46), Vector3(0.3, 5, 116), plaster, true)
	G.box(root, Vector3(0, 2.5, 12), Vector3(18, 5, 0.3), plaster, true)
	G.box(root, Vector3(0, 5.1, -46), Vector3(18, 0.2, 116), dark)
	for i in range(14):
		var z = 6 - i * 8
		var theme = i / 4
		for side in [-1, 1]:
			G.box(root, Vector3(side * 8.7, 2.1, z), Vector3(0.25, 4.2, 0.32), wood if theme == 0 else dark)
			G.box(root, Vector3(side * 8.8, 0.15, z - 3.8), Vector3(0.12, 0.25, 7.8), dark)
			if i < 4:
				G.box(root, Vector3(side * 8.75, 2.1, z - 3), Vector3(0.10, 1.1, 1.8), G.material("cotton", Color("c4b899")))
			elif i < 9:
				for j in range(3):
					G.box(root, Vector3(side * 8.25, 1.05, z - j * 0.8), Vector3(0.7, 2.1, 0.7), G.material("steel", Color("415d65")), true)
			else:
				var pipe = G.cylinder(root, Vector3(side * 8.2, 3.8, z), 0.13, 7.7, dark); pipe.rotation.x = PI / 2
		var fixture = G.material("plain", Color("f4d6ad")).duplicate(); fixture.emission_enabled = true; fixture.emission = Color("d6b8aa"); fixture.emission_energy_multiplier = 2
		G.box(root, Vector3(0, 4.8, z), Vector3(1.7, 0.08, 0.30), fixture)
		var light = OmniLight3D.new(); light.position = Vector3(0, 3.8, z); light.light_color = [Color("dfc29c"), Color("9fc4cf"), Color("bf8999")][mini(2, i / 5)]; light.light_energy = 2.2; light.omni_range = 10; root.add_child(light)
		# Staggered solid islands force the player to change lanes, without a jump key.
		if i in [2, 4, 7, 9, 11]:
			var x = -2.0 if i % 2 == 0 else 2.0
			G.box(root, Vector3(x, 0.6, z), Vector3(6.5, 1.2, 1.4), wood, true).name = "MemoryObstacle"
			level.nav_extra.append(Rect2(x - 3.25, z - 0.7, 6.5, 1.4))
			G.sign_text(root, "LARI  →" if x < 0 else "←  LARI", Vector3(x, 1.6, z + 0.75), 26)
		# The route uses a broken warm guide line rather than empty black space.
		for dz in [0, -2, -4, -6]: G.box(root, Vector3(sin(float(i) * 1.4) * 2, 0.012, z + dz), Vector3(0.12, 0.02, 0.9), fixture)
	for i in range(4):
		var p = Vector3(-5.9 if i % 2 == 0 else 5.9, 0, -17 - i * 23)
		var pedestal = Node3D.new(); pedestal.name = "MemoryAltar%d" % i; pedestal.position = p; root.add_child(pedestal)
		G.box(pedestal, Vector3(0, 0.5, 0), Vector3(1.2, 1, 0.7), dark, true)
		var paper = G.box(pedestal, Vector3(0, 1.07, 0), Vector3(0.55, 0.025, 0.38), G.material("cotton", Color("eee2b8"))); paper.name = "EvidenceProjection"
		G.sign_text(pedestal, MEMORY_NAMES[i] + "\nE · INGAT KEBENARANNYA", Vector3(0, 1.8, 0), 19)
		level.interact(p + Vector3(0, 1.2, 0.5), "memory", "Gunakan " + MEMORY_NAMES[i], str(i), false, Vector3(1.5, 1.4, 1.3))
		var glow = OmniLight3D.new(); glow.name = "MemoryGlow"; glow.position = Vector3(0, 1.7, 0.5); glow.light_color = Color("72d9d5"); glow.light_energy = 2; glow.omni_range = 6; pedestal.add_child(glow)
		level.nav_extra.append(Rect2(p.x - 0.6, p.z - 0.35, 1.2, 0.7))
	for i in range(7):
		var phantom = preload("res://scripts/systems/model_factory.gd").make("npc_Danu")
		phantom.name = "FalseDanu%d" % i; phantom.position = Vector3((-1 if i % 2 else 1) * 7.4, 0, -9 - i * 13); phantom.rotation.y = 0; root.add_child(phantom)
	for i in range(3):
		var shutter = Node3D.new(); shutter.name = "MemoryShutter%d" % i; shutter.position = Vector3(0, 7.2, -28 - i * 23); shutter.set_meta("threshold", shutter.position.z); root.add_child(shutter)
		# A spectral shutter can be crossed again to retrieve a missed memory.
		var m = G.material("steel", Color("544950")).duplicate(); m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; m.albedo_color.a = 0.62
		for j in range(12): G.box(shutter, Vector3(0, -2.2 + j * 0.4, 0), Vector3(17.7, 0.37, 0.12), m)
	G.sign_text(root, "EMPAT INGATAN\nSATU KEBENARAN", Vector3(0, 3, -101), 44)
	G.box(root, Vector3(0, 2.5, -103), Vector3(18, 5, 0.3), plaster, true)
