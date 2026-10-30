extends Node

var game: Node3D

func _ready() -> void:
	get_window().unfocusable = true
	State.save_enabled = false
	State.reset()
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.test_mode = true
	game.playing = true
	game.ui.close_panel()
	if OS.get_cmdline_user_args().has("--showcase"):
		State.set_flag("lenteraOwned")
		await shot("relay_watcher_close", "relay", Vector3(-11, 0.05, -9), Vector3(-11, 5.5, -14.1))
		await game.enter_room("ritual", false, false)
		game.story_origin = Vector3.ZERO
		game.narrative.start("reversion")
		game.narrative.set_process(false)
		game.narrative.advance(3.4)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/screenshots/reversion_04_final.png")
		await game.quit_game()
		return
	await shot("school_spawn", "school", Vector3(1.1, 0.05, -24), Vector3(1.1, 1.6, -12))
	await shot("school_center", "school", Vector3(0, 0.05, -5), Vector3(3, 1.6, 12))
	await shot("school_overview", "school", Vector3(0, 11, 0), Vector3(0, 0, -14))
	await shot("relay_bench", "relay", Vector3(0, 0.05, 14), Vector3(3, 1.3, 12))
	await shot("relay_roof", "relay", Vector3(0, 0.05, 14), Vector3(1, 6, 10.7))
	await shot("pursuit_exit", "pursuit", Vector3(8, 0.05, -55), Vector3(12, 1.5, -57))
	await game.quit_game()

func shot(label: String, room: String, location: Vector3, aim: Vector3) -> void:
	await game.enter_room(room, false, false)
	game.player.active = false
	if is_instance_valid(game.boss): game.boss.enabled = false
	game.player.position = location
	game.player.camera.look_at(aim)
	if label == "relay_watcher_close":
		var watcher = game.level.get_node("RelayWatcher")
		watcher.set_process(false)
		watcher.actor.position = Vector3(-11, 3.7, -14.1)
		watcher.actor.visible = true
		var toward = location - watcher.actor.position
		watcher.actor.rotation.y = atan2(toward.x, toward.z)
		watcher.rig.animate(0.1, 0.0)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var suffix = "after" if OS.get_cmdline_user_args().has("--after") else "before"
	var path = "res://docs/screenshots/" + label + "_04_" + suffix + ".png"
	print("CAPTURE ", path, " result=", get_viewport().get_texture().get_image().save_png(path))
