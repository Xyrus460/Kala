extends Node
var game: Node3D
func _ready() -> void:
	get_window().unfocusable = true; State.save_enabled = false; State.reset()
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen")
	await room("home")
	await view("home_props", Vector3(-3.4, 3.25, -1.1), Vector3(-3.3, 4.2, -2.5))
	if OS.get_cmdline_user_args().has("--props-only"):
		game.campus.clear(game.level); game.audio.shutdown(); game.queue_free()
		await get_tree().process_frame; await get_tree().physics_frame; get_tree().quit(); return
	await view("stairs_roof", Vector3(0, 0.05, 10.8), Vector3(0, 5.8, 12.5))
	await view("stairs_bottom", Vector3(1.1, 0.05, 11.7), Vector3(0, 0.4, 9.3))
	await view("mother", Vector3(4.8, 0.05, 5.0), Vector3(5.3, 1.15, 2.9))
	await view("landing", Vector3(-4.5, 3.25, 3.7), Vector3(1, 4.5, 3.6))
	game.level.chapter_world.doors.nursery.open = true
	for i in range(120): game.level.chapter_world.update(1.0 / 60)
	await view("nursery_door", Vector3(5.3, 3.25, 4.3), Vector3(4.4, 4.5, 1.2))
	await room("schoolyard")
	await view("school", Vector3(0, 0.05, 9), Vector3(0, 3.0, -20))
	await view("entrance", Vector3(0, 0.05, -12.4), Vector3(0, 1.5, -22))
	await view("forest", Vector3(-15, 0.05, -8), Vector3(-30, 3.4, -38))
	await view("alley", Vector3(26, 0.05, 39), Vector3(26, 1.5, 56))
	await room("street")
	await view("warung", Vector3(1.2, 0.05, 2.7), Vector3(5.8, 1.35, 2.8))
	await view("fuse", Vector3(-1.7, 0.05, 14.2), Vector3(-4, 1.6, 15))
	game.ui.show_puzzle("fuse"); await shot("wiring"); game.ui.close_panel()
	game.ui.show_puzzle("fuse"); await get_tree().process_frame
	game.ui.wiring_board.attempt_connection(0, 0); await get_tree().process_frame
	game.ui.wiring_board.attempt_connection(1, 1); await shot("wiring_connected"); game.ui.close_panel()
	game.ui.show_note("CATATAN TEKNISI / 017", game.story.notes.warung_log.body); await shot("note"); game.ui.close_panel()
	game._npc("Sari"); await get_tree().create_timer(4).timeout; await shot("dialogue"); game.ui.close_panel()
	for id in ["loading", "relay", "production", "office", "ritual", "corridor", "daisy"]:
		await room(id)
		await view(id, Vector3(0, 0.05, 8 if id not in ["daisy", "office"] else 4), Vector3(-4, 1.5, -3))
	await room("relay"); State.set_flag("lenteraOwned"); game.player.lamp_on = true
	await view("lentera", Vector3(0, 0.05, 8), Vector3(-4, 1.5, -3))
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.3).timeout; get_tree().quit()

func room(id: String) -> void:
	game.cinematic = false; game.ui.fade.color.a = 0; game.boss_revision.cancel()
	await game.enter_room(id, false, false); game.player.active = false; game.level.set_process(false)
	if is_instance_valid(game.boss): game.boss.enabled = false
	game.player.lamp_on = id not in ["home", "schoolyard", "school"]
	await get_tree().physics_frame

func view(label: String, p: Vector3, target: Vector3) -> void:
	game.player.position = p; game.player.camera.look_at(target)
	await shot(label)

func shot(label: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.45).timeout
	await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	print("CAPTURE09 ", label, " ", get_viewport().get_texture().get_image().save_png("res://docs/screenshots/" + label + "_09.png"))
