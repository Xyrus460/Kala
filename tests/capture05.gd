extends Node

var game: Node3D

func _ready() -> void:
	get_window().unfocusable = true
	State.save_enabled = false
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame
	await shot("menu_school")
	game._ui_action("title_background", "")
	await shot("menu_factory")
	game.test_mode = true
	await game.new_game()
	game.player.active = false; game.level.set_process(false)
	game.player.camera.look_at(Vector3(-4.0, 4.55, -3.0))
	await shot("home_bedroom")
	game.player.position = Vector3(5.5, 0.05, 6.6); game.player.camera.look_at(Vector3(5.45, 1.3, 3.1))
	await shot("mother_door")
	game.player.position = Vector3(0, 0.05, 10.3); game.player.camera.look_at(Vector3(0, 3.1, 2.8))
	await shot("home_landing")
	await room("schoolyard")
	game.player.position = Vector3(0, 0.05, 17); game.player.camera.look_at(Vector3(0, 2.7, -12))
	await shot("schoolyard")
	await room("school")
	game.narrative.start("lesson"); game.narrative.set_process(false); game.narrative.advance(24)
	await shot("classroom")
	game.narrative.finish()
	await room("schoolyard")
	game.player.position = Vector3(11.3, 0.05, 13); game.player.camera.look_at(Vector3(13.3, 0.95, 13))
	await shot("photo_bin")
	await room("neighborhood")
	game.player.position = Vector3(20.8, 0.05, -5); game.player.camera.look_at(Vector3(21, 1.7, -25))
	await shot("right_alley")
	State.set_flag("lenteraOwned")
	await room("pursuit")
	game.player.position = Vector3(-8, 0.05, 40.5); game.player.camera.look_at(Vector3(-10.4, 0.8, 40.5)); game.player.lamp_on = true
	game.level.escape_puzzle.search("operator")
	for i in range(100): game.level.escape_puzzle.update(1.0 / 60)
	await shot("sun_drawer")
	game.player.position = Vector3(0, 0.05, 57); game.player.camera.look_at(Vector3(0, 1.7, 61))
	game.boss.position = Vector3(0, 0.05, 61); game.boss.rotation.y = PI
	await shot("pursuer")
	game.test_mode = false; game.playing = true; game.scare.start("caught"); game.scare.set_process(false); game.scare._process(0.32)
	await shot("jumpscare")
	game.scare.cancel()
	await game.quit_game()

func room(id: String) -> void:
	await game.enter_room(id, false, false)
	game.player.active = false; game.level.set_process(false)
	if is_instance_valid(game.boss): game.boss.enabled = false
	await get_tree().physics_frame

func shot(label: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	print("CAPTURE05 ", label, " ", get_viewport().get_texture().get_image().save_png("res://docs/screenshots/" + label + "_05.png"))
