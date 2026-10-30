extends Node

var game: Node3D

func _ready() -> void:
	get_window().unfocusable = true
	State.save_enabled = false
	State.reset()
	if OS.get_cmdline_user_args().has("--shadow-probe"): State.settings.shadows = false
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.test_mode = true
	game.playing = true
	game.ui.close_panel()
	game.player.active = false
	game.player.position = Vector3(-1.3, 0.05, -12.1)
	game.player.camera.look_at(Vector3(0.5, 1.15, -12.1))
	await capture("sari_0_3")
	await game.enter_room("street", false, false)
	State.data.puzzles.fuse.solved = true
	game.narrative.start("warehouse")
	game.narrative.set_process(false)
	game.narrative.advance(7.5)
	await capture("warehouse_0_3")
	game.narrative.finish()
	await game.enter_room("corridor", false, false)
	State.set_flag("lenteraOwned")
	game.narrative.start("corridor")
	game.narrative.set_process(false)
	game.narrative.advance(5.2)
	await capture("corridor_0_3")
	game.narrative.finish()
	await game.enter_room("daisy", false, false)
	game.player.active = false
	game.player.camera.look_at(game.level.doll.global_position + Vector3.UP * 1.04)
	await capture("daisy_0_3")
	await game.quit_game()

func capture(label: String) -> void:
	if OS.get_cmdline_user_args().has("--shadow-probe"): label += "_no_shadow"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image_data = get_viewport().get_texture().get_image()
	var error = image_data.save_png("res://docs/screenshots/" + label + ".png")
	print("CAPTURE ", label, " result=", error)
