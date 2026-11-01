extends Node
var game: Node3D
func _ready() -> void:
	get_window().unfocusable=true;State.save_enabled=false;State.reset()
	game=preload("res://scenes/main/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;game.test_mode=true;game.playing=true;game.ui.close_panel()
	State.set_flag("prologueVersion");State.set_flag("lessonSeen")
	await room("school")
	await view("lockers",Vector3(0.3,0.05,-8),Vector3(-1.7,1.15,-6.9))
	await view("art",Vector3(-3.3,0.05,3.8),Vector3(-8,1.4,0))
	await view("class_door",Vector3(0.1,0.05,9.1),Vector3(-2.4,1.2,10.6))
	await view("seated",Vector3(-6.8,0.05,10.6),Vector3(-8,1.0,9))
	await view("student",Vector3(0.9,0.05,-9.5),Vector3(-1.28,1,-11.5))
	await view("upper_music",Vector3(-3.4,3.45,3.8),Vector3(-9,4.7,0))
	await view("uks",Vector3(-3.4,0.05,-8),Vector3(-9,1.0,-12))
	await view("floor",Vector3(0,0.05,-24),Vector3(0,0.6,4))
	await room("loading")
	await view("keypad",Vector3(12.3,0.05,-14.3),Vector3(14.8,1.5,-15))
	await room("relay")
	State.set_flag("lenteraOwned");game.player.lamp_on=true
	await view("r17",Vector3(-4.4,0.05,8),Vector3(-7.2,1.25,7))
	game.ui.show_puzzle("fuse");await shot("wiring")
	game.ui.show_settings("DISPLAY");await shot("settings")
	game.ui.settings_menu.show_category("GRAPHICS");await shot("graphics")
	game.ui.show_journal();await get_tree().create_timer(0.9).timeout;await shot("journal")
	game.campus.clear(game.level);game.boss_revision.cancel();game.audio.shutdown();game.queue_free()
	await get_tree().process_frame;await get_tree().physics_frame;await get_tree().create_timer(0.4).timeout;get_tree().quit()

func room(id: String) -> void:
	game.cinematic=false;game.ui.fade.color.a=0;game.boss_revision.cancel();game.boss_revision.set_process(false)
	await game.enter_room(id,false,false);game.player.active=false;game.level.set_process(false)
	if is_instance_valid(game.boss):game.boss.enabled=false
	game.player.lamp_on=id not in ["school"]
	await get_tree().physics_frame

func view(label: String,point: Vector3,target: Vector3) -> void:
	game.player.position=point;game.player.camera.look_at(target);await shot(label)

func shot(label: String) -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.5).timeout;await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
	print("CAPTURE12 ",label," ",get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+label+"_12.png"))
