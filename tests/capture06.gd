extends Node
var game: Node3D
func _ready() -> void:
	get_window().unfocusable = true; State.save_enabled = false
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lenteraOwned")
	await room("home"); game.player.position = Vector3(-3.8, 3.25, 1.4); game.player.camera.look_at(Vector3(-5.1, 4.5, -2.3)); await shot("bedroom")
	game.player.position = Vector3(-1.8, 0.05, 12.2); game.player.camera.look_at(Vector3(-6.1, 0.9, 10.5)); await shot("living_room")
	await room("schoolyard"); game.player.position = Vector3(2, 0.05, 17); game.player.camera.look_at(Vector3(-1, 5.2, -14)); await shot("school_clouds")
	game.player.position = Vector3(0, 0.05, 21); game.player.camera.look_at(Vector3(15, 1.9, 34)); await shot("connected_road")
	await room("school"); game.player.position = Vector3(-3.7, 0.05, 12.7); game.player.camera.look_at(Vector3(-9.2, 1.2, 10)); await shot("seated_class")
	await room("ritual"); game.player.position = Vector3(0, 0.05, 3); game.boss.position = Vector3(0, 0.05, -3); game.player.camera.look_at(Vector3(0, 1.9, -3)); await shot("final_sculpt")
	game.boss.begin_phase(2); game.boss_revision.slime_wave(); game.boss_revision.update_hazards(2); await shot("slime_arena")
	game.boss.begin_phase(3); game.boss_revision.update_scene(8); game.boss_revision.update_scene(2.8); await shot("phase3_fog")
	await room("hallucination"); game.player.position = Vector3(0, 0.05, 3); game.player.camera.look_at(Vector3(0, 1.7, -25)); await shot("hallucination")
	game.boss_revision.nightmare.rotation.y = PI; game.player.camera.look_at(game.boss_revision.nightmare.position + Vector3.UP * 2.1); await shot("nightmare")
	game.player.position = Vector3(-3.9, 0.05, -14); game.player.camera.look_at(Vector3(-5.9, 1.5, -17)); await shot("memory_altar")
	await room("daisy"); var p: Vector3 = game.level.doll.position; game.player.position = p + Vector3(0, -0.5, 2.3); game.player.camera.look_at(p + Vector3.UP * 0.9)
	game.level.cabinet_hinge.rotation.y = -1.4; await shot("daisy_doll")
	await room("pursuit"); game.test_mode = false; State.set_flag("escapePuzzleSolved"); game.narrative.start("rescue"); game.narrative.set_process(false); game.narrative.advance(8.6); await shot("daisy_button")
	game.narrative.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.4).timeout
	get_tree().quit()

func room(id: String) -> void:
	game.boss_revision.cancel(); game.boss_revision.set_process(false)
	game.cinematic = false; game.ui.fade.color.a = 0
	await game.enter_room(id, false, false); game.player.active = false; game.level.set_process(false)
	if is_instance_valid(game.boss): game.boss.enabled = false
	await get_tree().physics_frame

func shot(label: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	print("CAPTURE06 ",label," ",get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+label+"_06.png"))
