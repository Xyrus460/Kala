extends Node3D
var game: Node3D

func _ready() -> void:
	get_window().unfocusable = true; State.save_enabled = false; State.reset()
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen"); State.set_flag("lenteraOwned"); State.set_flag("archiveOpen")
	await game.enter_room("relay", false, false); game.player.active = false; game.player.set_physics_process(false)
	game.player.lamp_on = true; game.player._physics_process(0.001)
	for pivot in game.level.door_pivots: pivot.set_meta("opened", true)
	for i in range(100): game.level._process(1.0 / 60)
	for mesh in game.level.find_children("*", "MeshInstance3D", true, false):
		if not mesh.is_visible_in_tree() or game.level.relay_world.is_ancestor_of(mesh): continue
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		if b.get_center().x > 14 and b.get_center().z > 2 and b.get_center().z < 14:
			print("GENERATOR_SOURCE ", mesh.get_path(), " ", b)
	await view("relay", Vector3(0, 0.05, 6), Vector3(0, 2.4, -13))
	await view("relay_blue", Vector3(0, 0.05, -5), Vector3(0, 2.35, -9.55))
	await view("socket", Vector3(6.5, 0.05, 0.7), Vector3(8, 1.45, -2.0))
	await view("r17_unit", Vector3(-5.0, 0.05, 7.4), Vector3(-7.15, 1.28, 7.0))
	await view("lever", Vector3(3.2, 0.05, -10.6), Vector3(3.2, 1.4, -13.8))
	await view("generator", Vector3(16.0, 0.05, 10.7), Vector3(22, 1.3, 7.8))
	var mark = game.level.relay_world.get_node("DieselGeneratorG02").find_child("BlueInspectionMark", true, false)
	await pose(Vector3(18.9, 0.05, mark.global_position.z), mark.global_position)
	game.player._update_reveal(0.8); await shot("generator_blue")
	await view("contact", Vector3(-20.8, 0.05, -3.8), Vector3(-20.8, 1.03, -5.6))
	await view("archive", Vector3(-20.9, 0.05, 0.5), Vector3(-23.6, 1.35, -0.5))
	await view("stairs", Vector3(-8, 0.05, 14.6), Vector3(-8, -1.8, 24))
	await view("memory", Vector3(-8, -3.95, 38.4), Vector3(-8, -1.8, 48))
	await view("memory_console", Vector3(-7.7, -3.8, 44.0), Vector3(-8, -1.5, 35.6))
	var memory = game.level.relay_world.memory
	memory._display(2)
	await view("memory_signal", Vector3(-8, -3.95, 41.8), Vector3(-14, -1.7, 44))
	memory.mascot.position.z = 10.0
	await view("memory_mascot", Vector3(-8, -3.95, 48.8), Vector3(-8, -2.25, 52.5))
	await view("service", Vector3(12, -3.95, 34.5), Vector3(12, -2.0, 49))
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.4).timeout; get_tree().quit()

func pose(point: Vector3, look: Vector3) -> void:
	game.player.position = point; game.player.rotation = Vector3.ZERO; game.player.camera.look_at(look)
	game.player.lamp.visible = true; game.player.lamp_on = true
	await get_tree().physics_frame

func view(title: String, point: Vector3, look: Vector3) -> void:
	await pose(point, look); await shot(title)

func shot(title: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.18).timeout; await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	var suffix = "_15_compat.png" if RenderingServer.get_current_rendering_method() == "gl_compatibility" else "_15.png"
	print("CAPTURE15 ", title, " ", get_viewport().get_texture().get_image().save_png("res://docs/screenshots/" + title + suffix))
