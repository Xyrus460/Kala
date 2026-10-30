extends Node

func _ready() -> void:
	State.save_enabled = false
	State.reset()
	var game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	var room_id = "school"
	var sari = false
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--review="): room_id = argument.trim_prefix("--review=")
		if argument == "--sari": sari = true
	game.playing = true
	game.test_mode = true
	game.ui.close_panel()
	if room_id != "school": await game.enter_room(room_id, false, false)
	if sari:
		game.player.position = Vector3(-1.3, 0.05, -12.1)
		game.player.camera.look_at(Vector3(0.5, 1.15, -12.1))
	game._sync_active()
	game.player.active = false
	if is_instance_valid(game.boss): game.boss.enabled = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	DisplayServer.window_set_title("KALA — Source visual review: " + ("Sari" if sari else room_id))
