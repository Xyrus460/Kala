extends Node
var game: Node3D
func _ready() -> void:
	get_window().unfocusable = true; State.save_enabled = false
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen"); State.set_flag("lenteraOwned")
	await room("home"); game.player.position = Vector3(-4.4, 3.25, 3.3); game.player.camera.look_at(Vector3(0, 3.4, 5.5)); await shot("landing")
	game.player.position = Vector3(2, 0.05, 11.8); game.player.camera.look_at(Vector3(0, 2.7, 6)); await shot("stairs")
	await room("school"); game.player.position = Vector3(-3.7, 0.05, 12.7); game.player.camera.look_at(Vector3(-8, 1.2, 9)); await shot("classroom")
	State.data.flags.erase("lessonSeen"); game.narrative.start("lesson"); game.narrative.set_process(false)
	game.narrative.advance(3); await shot("lesson")
	game.narrative.advance(20); await shot("incident"); game.narrative.finish()
	await room("production"); game._start_fight("hands"); game.boss.enabled = false
	game.player.position = Vector3(0, 0.05, 4); game.boss.position = Vector3(0, 0.05, -2); game.player.camera.look_at(Vector3(0, 1.35, -2)); await shot("hands")
	await room("ritual"); game.player.position = Vector3(0, 0.05, 4); game.boss.position = Vector3(0, 0.05, -3); game.player.camera.look_at(Vector3(0, 1.7, -3)); await shot("final")
	game.boss.begin_phase(3); game.boss_revision.update_scene(8); game.boss_revision.update_scene(1.8); await shot("surrounded")
	await room("relay"); game.show_lentera_guide(); await get_tree().create_timer(2.5).timeout; await shot("tutorial"); game._close()
	await room("daisy"); game.player.position = game.level.spawn; game.player.camera.look_at(game.level.doll.position + Vector3.UP); await shot("fog")
	await room("hallucination"); game.player.position = Vector3(0, 0.05, 3); game.player.camera.look_at(game.boss_revision.nightmare.position + Vector3.UP * 1.7); await shot("nightmare")
	game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.3).timeout; get_tree().quit()

func room(id: String) -> void:
	game.boss_revision.cancel(); game.boss_revision.set_process(false); game.cinematic = false; game.ui.fade.color.a = 0
	await game.enter_room(id, false, false); game.player.active = false; game.level.set_process(false)
	if is_instance_valid(game.boss): game.boss.enabled = false
	await get_tree().physics_frame

func shot(label: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.35).timeout
	await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	print("CAPTURE07 ", label, " ", get_viewport().get_texture().get_image().save_png("res://docs/screenshots/" + label + "_07.png"))
