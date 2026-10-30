extends RefCounted
const G = preload("res://scripts/systems/geometry.gd")

static func create(parent: Node3D, interactive = false) -> Node3D:
	var root = Node3D.new(); root.name = "PhysicalKeypad"; parent.add_child(root)
	var metal = G.material("plain", Color("686b74")).duplicate(); metal.metallic = 0.72; metal.roughness = 0.38
	var recess = G.material("plain", Color("181b25"))
	var purple = G.material("plain", Color("3c3059"))
	var housing = G.box(root, Vector3.ZERO, Vector3(0.56, 0.88, 0.095), metal)
	housing.name = "BrushedMetalHousing"
	G.box(root, Vector3(0, 0, 0.053), Vector3(0.47, 0.78, 0.02), recess)
	for x in [-0.245, 0.245]:
		for y in [-0.4, 0.4]:
			var screw = G.cylinder(root, Vector3(x, y, 0.057), 0.014, 0.009, metal); screw.rotation.x = PI / 2
			G.box(root, Vector3(x, y, 0.064), Vector3(0.016, 0.002, 0.002), recess)
	G.box(root, Vector3(0, 0.254, 0.07), Vector3(0.37, 0.14, 0.025), purple)
	G.box(root, Vector3(0, 0.254, 0.085), Vector3(0.31, 0.085, 0.01), recess)
	var display = G.sign_text(root, "_ _ _ _", Vector3(0, 0.256, 0.096), 30)
	display.name = "CodeDisplay"; display.pixel_size = 0.0017; display.modulate = Color("b8d6c8"); display.outline_size = 0
	var keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "OK"]
	for i in range(keys.size()):
		var point = Vector3((i % 3 - 1) * 0.117, 0.1 - floorf(i / 3.0) * 0.121, 0.082)
		var key = G.box(root, point, Vector3(0.095, 0.10, 0.028), purple)
		key.name = "Key_" + keys[i]
		var label = G.sign_text(key, keys[i], Vector3(0, 0, 0.017), 30 if keys[i] != "OK" else 21)
		label.pixel_size = 0.0017; label.modulate = Color("e0d8ef"); label.outline_size = 0
		if interactive:
			var area = Area3D.new(); area.collision_layer = 2; area.collision_mask = 0; area.set_meta("key", keys[i]); key.add_child(area)
			var collider = CollisionShape3D.new(); var shape = BoxShape3D.new(); shape.size = Vector3(0.106, 0.11, 0.04); collider.shape = shape; area.add_child(collider)
	var lamp = G.box(root, Vector3(0, -0.382, 0.065), Vector3(0.11, 0.023, 0.025), G.material("plain", Color("588777")))
	lamp.name = "StatusLight"
	return root
