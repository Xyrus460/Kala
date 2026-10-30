extends SceneTree

func _initialize() -> void:
	_bake.call_deferred()

func own_children(node: Node, root: Node) -> void:
	for child in node.get_children():
		# Bake editable native nodes, rather than nested imported scene instances.
		child.scene_file_path = ""
		child.owner = root
		own_children(child, root)

func _bake() -> void:
	for id in ["school", "street", "loading", "relay", "pursuit", "production", "office", "ritual", "corridor", "daisy"]:
		var path = "res://scenes/levels/%s.tscn" % id
		var level = load("res://scripts/systems/level.gd").new()
		level.name = id.capitalize()
		level.room_id = id
		root.add_child(level)
		await process_frame
		level.set_process(false)
		level.set_meta("native_baked", true)
		own_children(level, level)
		var packed = PackedScene.new()
		var result = packed.pack(level)
		if result == OK: result = ResourceSaver.save(packed, path)
		if result != OK:
			push_error("Bake failed: " + path)
			quit(1)
			return
		print("BAKED: ", id, " direct children=", level.get_child_count())
		level.queue_free()
		await process_frame
	KalaGeometry.materials.clear()
	quit()
