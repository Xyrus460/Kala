extends Node
var game: Node3D
func _ready() -> void:
	get_window().unfocusable = true; State.save_enabled=false; State.reset()
	game=preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode=true; game.playing=true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen")
	if not OS.get_cmdline_user_args().has("--factory"):
		await room("home")
		await view("door",Vector3(-4.4,3.25,0.8),Vector3(-4.4,4.3,2.5))
		await view("walls",Vector3(-0.5,3.25,3.6),Vector3(0,4.5,-0.5))
		await view("stairs",Vector3(-3.1,0.05,10.0),Vector3(0,2.0,7.1))
		await view("closed_gap",Vector3(-1.8,0.05,6.1),Vector3(-1.8,1.5,2.0))
		game.narrative.start("wash"); game.narrative.set_process(false); game.narrative.advance(5)
		await shot("shower"); game.narrative.finish()
		await room("schoolyard")
		await view("school",Vector3(0,0.05,7),Vector3(0,4.5,-22))
		await view("school_ground",Vector3(10,0.05,-12),Vector3(9,1,-17))
		await room("school")
		await view("lab",Vector3(-3.4,0.05,-17.5),Vector3(-10,1.5,-22))
		await view("ratna",Vector3(-6,0.05,9),Vector3(-8,1.2,6.9))
		await view("campus_stairs",Vector3(-2.8,0.05,-27.3),Vector3(-10,3.2,-27.3))
		await view("upper_floor",Vector3(0,6.85,-24),Vector3(0,8.2,12))
		await view("library_puzzle",Vector3(12.25,0.05,15),Vector3(12.25,1.2,13))
	else:
		for id in ["loading","relay","production","office","ritual","corridor","daisy","pursuit"]:
			await room(id)
			var z = game.level.depth*0.32
			var pos = Vector3(0,0.05,z)
			if id=="pursuit": pos=Vector3(0,0.05,48)
			await view("factory_"+id,pos,Vector3(0,2.0,-3 if id!="pursuit" else 35))
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.4).timeout; get_tree().quit()

func room(id: String) -> void:
	game.cinematic=false; game.ui.fade.color.a=0; game.boss_revision.cancel(); game.boss_revision.set_process(false)
	await game.enter_room(id,false,false); game.player.active=false; game.level.set_process(false)
	if is_instance_valid(game.boss): game.boss.enabled=false
	game.player.lamp_on=id not in ["home","schoolyard","school"]
	await get_tree().physics_frame

func view(label: String, point: Vector3, target: Vector3) -> void:
	game.player.position=point; game.player.camera.look_at(target); await shot(label)

func shot(label: String) -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.3).timeout; await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	print("CAPTURE11 ",label," ",get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+label+"_11.png"))
