extends Node
var game: Node3D
func _ready() -> void:
	get_window().unfocusable = true; State.save_enabled = false; State.reset()
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen")
	await room("home")
	await view("bedroom", Vector3(-3.4, 3.25, 1.3), Vector3(-4.9, 4.1, -1.6))
	await view("nursery", Vector3(4.4, 3.25, 1.7), Vector3(4.3, 4.15, -1.2))
	if OS.get_cmdline_user_args().has("--rooms-only"):
		await finish(); return
	await room("schoolyard")
	await view("school", Vector3(0, 0.05, 7), Vector3(0, 3, -22))
	await view("school_slab", Vector3(6.7, 0.05, -12.5), Vector3(0, 2.9, -18))
	await view("entrance_open", Vector3(0, 0.05, -12.5), Vector3(0, 1.5, -18))
	var door = game.level.get_node("SchoolCampus/OperableEntranceDoors")
	door.toggle()
	for i in range(100): door._physics_process(1.0 / 60)
	await shot("entrance_closed")
	await room("loading")
	await view("maintenance_door", Vector3(11.5, 0.05, -10), Vector3(15, 1.5, -10))
	await view("fuse_pickup", Vector3(23.3, 0.05, -11.7), Vector3(23.3, 0.97, -13.1))
	await view("keypad_world", Vector3(11.7, 0.05, -15), Vector3(13.55, 1.5, -15))
	game.ui.show_puzzle("panel"); await shot("keypad"); game.ui.close_panel()
	await room("relay")
	await view("grille", Vector3(-10.4, 0.05, 11), Vector3(-10.4, 1.4, 6.4))
	await room("ritual")
	game.player.position = Vector3(0, 0.05, 3); game.boss.position = Vector3(0, 0.05, -2)
	game.player.camera.look_at(Vector3(0, 1.6, -2)); game.boss.rotation.y = 0
	for i in range(60): game.boss.hands_rig.animate(1.0 / 60, 2.7 / 60, false, 0)
	await shot("boss_walk")
	await finish()

func finish() -> void:
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.3).timeout; get_tree().quit()

func room(id: String) -> void:
	game.cinematic = false; game.ui.fade.color.a = 0; game.boss_revision.cancel(); game.boss_revision.set_process(false)
	await game.enter_room(id, false, false); game.player.active = false; game.level.set_process(false)
	if is_instance_valid(game.boss): game.boss.enabled = false
	game.player.lamp_on = id not in ["home", "schoolyard", "school"]
	await get_tree().physics_frame

func view(label: String, point: Vector3, target: Vector3) -> void:
	game.player.position = point; game.player.camera.look_at(target); await shot(label)

func shot(label: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.3).timeout
	await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	print("CAPTURE10 ", label, " ", get_viewport().get_texture().get_image().save_png("res://docs/screenshots/" + label + "_10.png"))
