extends Node

func _ready() -> void:
	State.save_enabled = false
	var game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	game.test_mode = true
	if OS.get_cmdline_user_args().has("--live"):
		game.playing = true; game.ui.close_panel()
	if OS.get_cmdline_user_args().has("--all"):
		for id in State.ROOMS:
			if OS.get_cmdline_user_args().has("--nohome") and id == "home": continue
			await game.enter_room(id, false, false)
			await get_tree().physics_frame
	if OS.get_cmdline_user_args().has("--daisy"):
		await game.enter_room("daisy", false, false)
		await game._daisy_sequence()
	if OS.get_cmdline_user_args().has("--menuquit"):
		print("SHUTDOWN PROBE: native quit action")
		await game.quit_game()
		return
	game.audio.shutdown()
	await get_tree().create_timer(0.2).timeout
	game.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	KalaGeometry.materials.clear()
	print("SHUTDOWN PROBE FINISHED")
	get_tree().quit()
