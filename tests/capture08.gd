extends Node
var game: Node3D
func _ready() -> void:
	get_window().unfocusable = true; State.save_enabled = false
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen")
	await room("home")
	await view("bedroom", Vector3(-4.2, 3.25, 1.6), Vector3(-5, 4.3, -1.2))
	await view("nursery", Vector3(4.5, 3.25, 1.8), Vector3(4.6, 4.3, -1.7))
	await view("landing", Vector3(-5.5, 3.25, 3.7), Vector3(1.7, 4.5, 3.9))
	await view("stairs", Vector3(1.8, 0.05, 11.8), Vector3(0, 2.8, 5.5))
	await view("living", Vector3(-1.7, 0.05, 12), Vector3(-5.6, 0.9, 10))
	await view("kitchen", Vector3(1.5, 0.05, 12.7), Vector3(6.3, 1.1, 10.3))
	await view("bathroom", Vector3(-4.8, 0.05, 3.7), Vector3(-5.3, 1.2, -0.2))
	await view("frontdoor", Vector3(-1.8, 0.05, 10.9), Vector3(0, 1.25, 13.6))
	game._pause(); await shot("pause"); game._close()
	await room("schoolyard")
	await view("school", Vector3(0, 0.05, 12), Vector3(0, 3.3, -17))
	await view("street", Vector3(-21, 0.05, 28), Vector3(-50, 3, 32))
	await view("motorcycles", Vector3(-11, 0.05, 28.5), Vector3(-12.5, 0.8, 25.7))
	await room("school")
	await view("classdoor", Vector3(1.1, 0.05, 11.8), Vector3(-2.5, 1.5, 9.7))
	await view("classroom", Vector3(-3.7, 0.05, 12.7), Vector3(-8, 1.2, 9))
	game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.3).timeout; get_tree().quit()

func room(id: String) -> void:
	game.cinematic = false; game.ui.fade.color.a = 0
	await game.enter_room(id, false, false); game.player.active = false; game.level.set_process(false)
	if is_instance_valid(game.boss): game.boss.enabled = false
	await get_tree().physics_frame

func view(label: String, p: Vector3, target: Vector3) -> void:
	game.player.position = p; game.player.camera.look_at(target)
	await shot(label)

func shot(label: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.4).timeout
	await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	print("CAPTURE08 ", label, " ", get_viewport().get_texture().get_image().save_png("res://docs/screenshots/" + label + "_08.png"))
