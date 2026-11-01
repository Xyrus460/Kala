extends RefCounted

const G = preload("res://scripts/systems/geometry.gd")

func _seat(parent: Node3D, p: Vector3, yaw: float) -> void:
	var chair = Node3D.new(); chair.name = "SchoolChair"; chair.position = p; chair.rotation.y = yaw; parent.add_child(chair)
	var wood = G.material("burlap", Color("a08259"))
	var frame = G.material("steel", Color("67767a"))
	G.box(chair, Vector3(0, 0.45, 0), Vector3(0.45, 0.07, 0.43), wood)
	G.box(chair, Vector3(0, 0.82, -0.21), Vector3(0.44, 0.26, 0.055), wood)
	for x in [-0.18, 0.18]:
		for z in [-0.17, 0.17]: G.cylinder(chair, Vector3(x, 0.23, z), 0.018, 0.46, frame)
		G.cylinder(chair, Vector3(x, 0.68, -0.20), 0.018, 0.50, frame)

func apply(level: Node3D) -> void:
	if level.has_node("EnvironmentalDetail"): return
	var root = Node3D.new(); root.name = "EnvironmentalDetail"; level.add_child(root)
	preload("res://scripts/systems/factory_overhaul.gd").new().apply(level)
	var steel = G.material("steel", Color("626b60"))
	var rust = G.material("steel", Color("75624b"))
	var paper = G.material("cotton", Color("aca38a"))
	if level.room_id == "corridor":
		var seal = StaticBody3D.new(); seal.name = "ExitSecuritySeal"; seal.position = Vector3(0, 1.5, -20.05)
		var collision = CollisionShape3D.new(); var shape = BoxShape3D.new(); shape.size = Vector3(3.4, 4, 0.25)
		collision.shape = shape; seal.add_child(collision); root.add_child(seal)
	if level.room_id == "school":
		# Replace mismatched chairs and desks with one aligned layout.
		for mesh in level.get_node("SourceWorld").find_children("*", "MeshInstance3D", true, false):
			var bounds: AABB = mesh.global_transform * mesh.get_aabb()
			var center = bounds.get_center()
			if center.x > -13.5 and center.x < -2.4 and center.z > 6.2 and center.z < 13.8 and bounds.position.y > -0.08 and bounds.end.y < 1.5 and not (bounds.size.x > 3 and bounds.size.z > 3):
				mesh.hide()
				for body in mesh.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0
		for row in range(3):
			for col in range(3):
				var center = Vector3([-10.5, -8.0, -5.6][col], 0, 8.3 + row * 1.7)
				var desk = Node3D.new(); desk.name = "AlignedDesk%d%d" % [row, col]; root.add_child(desk); desk.position = center
				preload("res://scripts/systems/free_assets.gd").place(desk, "res://assets/vendor/school_furniture/MesaEscuela - School Table.obj", Vector3.ZERO, Vector3(1.05, 0.84, 0.65), 0, true, "SchoolDesk")
				preload("res://scripts/systems/free_assets.gd").place(root, "res://assets/vendor/school_furniture/SillaEscuela - School Chair.obj", center + Vector3(0, 0, 0.72), Vector3(0.45, 0.95, 0.43), PI, false, "SchoolChair")
		# The old rectangular footprint allowed walking behind entire classrooms.
		# A continuous floor under the actual room union also closes tiny source seams.
		# SchoolArchitecture owns all floor slabs; a second safety floor here
		# produced depth fighting at room joins and the entrance.
		preload("res://scripts/systems/school_detail.gd").new().interior(level)
		# The school exit now opens directly onto the resident outdoor campus.
		if State.flag("prologueVersion"):
			for mesh in level.get_node("MapBoundary").find_children("*", "MeshInstance3D", true, false):
				var bounds: AABB = mesh.global_transform * mesh.get_aabb()
				if bounds.get_center().z < -30.0 and absf(bounds.get_center().x) < 2.0:
					mesh.hide()
					for body in mesh.get_parent().get_children():
						if body is CollisionShape3D and absf(body.position.z - bounds.get_center().z) < 0.2: body.disabled = true
			for key in level.all_doors:
				if key == "schoolExit":
					var door = level.all_doors[key].node
					door.hide()
					for body in door.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0
		# A lit threshold gives the closed exit a believable destination.
		var glow = OmniLight3D.new(); glow.position = Vector3(0, 2.1, -29.1)
		glow.light_color = Color("c2dfb7"); glow.light_energy = 0.9; glow.omni_range = 5; root.add_child(glow)
		# Move the photograph from the old desk to the outdoor rubbish bin.
		var old_photo = level.find_child("EvidencePhoto", true, false)
		if old_photo != null and State.flag("prologueVersion"): old_photo.hide()
		for object in level.get_children():
			if State.flag("prologueVersion") and object is KalaInteractable and object.action_id == "evidence" and object.parameter == "op1":
				object.action_id = "chapter"; object.parameter = "photo_missing"; object.caption = "Bekas sobekan foto"
		level.interact(Vector3(-10.5, 0.93, 11.66), "evidence", "Agenda piket Sari", "op2")
		G.box(root, Vector3(-10.5, 0.88, 11.66), Vector3(0.28, 0.025, 0.34), G.material("cotton", Color("6d807e")))
		level.interact(Vector3(-1.65, 1.35, 9.7), "chapter", "Kembali ke kelas XI A", "return_class", false, Vector3(0.65, 1.8, 1.0))
		var seats = [Vector3(-10.5, 0, 9.02), Vector3(-8, 0, 9.02), Vector3(-10.5, 0, 10.72), Vector3(-8, 0, 10.72), Vector3(-10.5, 0, 12.42)]
		for i in range(seats.size()):
			var model = preload("res://scripts/systems/model_factory.gd").make("npc_" + ["Bima", "Nadia", "Fajar", "Intan", "Adit"][i]) as Node3D
			model.name = "Classmate_%d" % i; model.position = seats[i]
			model.rotation.y = PI; root.add_child(model)
			# Bend hips and knees; soles stay on the floor.
			model.sit()
		var teacher = preload("res://scripts/systems/model_factory.gd").make("npc_Ratna") as Node3D
		teacher.name = "Teacher"; teacher.position = Vector3(-8, 0, 6.9); root.add_child(teacher)
		G.sign_text(root, "BAHASA INDONESIA\nFAKTA  /  KESIMPULAN\nSiapa yang belum kita dengar?", Vector3(-8, 1.85, 6.2), 21)
		var daylight = OmniLight3D.new(); daylight.position = Vector3(-9, 2.6, 10)
		daylight.light_color = Color("d3ddd3"); daylight.light_energy = 1.0; daylight.omni_range = 9; root.add_child(daylight)
		return
	if level.room_id in ["daisy", "ritual"]: return
	# Service rails, small pipe brackets, water damage and discarded documents.
	var factory = level.room_id not in ["street"]
	if factory:
		var half = level.width / 2 - 0.3
		for side in [-1, 1]:
			for z in range(-int(level.depth / 2) + 4, int(level.depth / 2) - 2, 7):
				G.box(root, Vector3(side * half, 0.16, z), Vector3(0.09, 0.15, 6.8), rust)
				G.box(root, Vector3(side * (half - 0.15), 3.4, z), Vector3(0.12, 0.12, 6.8), steel)
				for y in [3.22, 3.58]: G.box(root, Vector3(side * (half - 0.15), y, z), Vector3(0.24, 0.035, 0.12), rust)
		for i in range(14):
			var z = -level.depth * 0.4 + fmod(i * 7.13, level.depth * 0.8)
			var x = sin(i * 2.17) * minf(level.width * 0.32, 7)
			var scrap = G.box(root, Vector3(x, 0.014, z), Vector3(0.21, 0.012, 0.3), paper)
			scrap.rotation.y = i * 1.27
		if level.room_id == "pursuit":
			# Retire the old forward-facing switch; Daisy presses the rear wall switch.
			for old_name in ["Source_3289", "Source_3290", "Source_3291", "Source_3292"]:
				var old_switch = level.find_child(old_name, true, false)
				if old_switch != null: old_switch.hide()
			for i in range(6):
				G.sign_text(root, "SEKTOR %02d\nAKSES SERVIS  ↓" % (i + 1), Vector3((-1 if i % 2 == 0 else 1) * 10.8, 2.6, 46 - i * 19), 23, PI / 2 if i % 2 == 0 else -PI / 2)
