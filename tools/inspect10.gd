extends SceneTree
func _initialize() -> void:
	call_deferred("inspect")
func inspect() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://assets/source_layout.json"))
	for id in ["loading", "relay", "ritual"]:
		print("INTERACTIONS ", id, " ", data.rooms[id].interactions)
	for id in ["school", "loading", "ritual", "production", "relay", "office"]:
		var model = load("res://assets/models/source/%s.glb" % id).instantiate()
		root.add_child(model)
		for m in model.find_children("*", "MeshInstance3D", true, false):
			var b: AABB = m.global_transform * m.get_aabb()
			if (id == "school" and b.size.x > 15) or (id != "school" and b.size.y > 2.2 and b.size.x < 0.12 and b.size.z < 0.12):
				print("MESH ",id," ",m.name," ",b)
		model.free()
	var boss = load("res://assets/models/source/tumbal.glb").instantiate(); root.add_child(boss)
	for label in ["Source_1245", "Source_1267", "Source_1276", "Source_1249", "Source_1252", "Source_1255", "Source_1282", "Source_1285", "Source_1288"]:
		var part = boss.find_child(label,true,false)
		print("JOINT ",label," path=",part.get_path()," transform=",part.transform," global=",part.global_transform)
	boss.free()
	quit()
