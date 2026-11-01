extends Node3D
var game: Node3D

func _ready() -> void:
	get_window().unfocusable=true;State.save_enabled=false;State.reset()
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	game=preload("res://scenes/main/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;game.test_mode=true;game.playing=true;game.ui.close_panel()
	State.set_flag("prologueVersion");State.set_flag("lessonSeen");State.set_flag("lenteraOwned")
	await room("pursuit")
	await view("chase",Vector3(0,0.05,51),Vector3(0,2.1,24))
	await view("chase_bay",Vector3(-6.9,0.05,43),Vector3(-10.7,1.4,40.5))
	await view("lock_closed",Vector3(8.5,0.05,-55.4),Vector3(12,1.4,-57))
	for id in ["sun","moon","star"]:State.give("fragment_"+id)
	game.level.escape_puzzle.unlock()
	for i in range(110):game.level._process(1.0/60)
	await view("lock_open",Vector3(8.5,0.05,-55.4),Vector3(12,1.4,-57))
	game.test_mode=false;game.narrative.start("rescue");game.narrative.set_process(false)
	for i in range(520):game.narrative.advance(1.0/60)
	await shot("daisy_reach");game.narrative.cancel();game.test_mode=true
	await room("production")
	State.give("workshopKey");State.give("valveWheel")
	for pivot in game.level.door_pivots:pivot.set_meta("opened",true)
	for i in range(100):game.level._process(1.0/60)
	await view("workshop",Vector3(-21.3,0.05,4.3),Vector3(-28,1.4,4.5))
	await view("workbench",Vector3(-26.3,0.05,5.9),Vector3(-27.4,1.45,9.2))
	await view("wheel_pickup",Vector3(-28.8,0.05,1.8),Vector3(-31.6,1.7,1.0))
	State.install("valveWheel");game.level.refinement._process(0.01)
	await view("valves",Vector3(-11,0.05,-14.6),Vector3(-11,1.75,-18.7))
	await view("infirmary",Vector3(21.6,0.05,5),Vector3(28,1.3,5.5))
	await room("office")
	for pivot in game.level.door_pivots:pivot.set_meta("opened",true)
	for i in range(100):game.level._process(1.0/60)
	await view("office",Vector3(0,0.05,6.7),Vector3(0,1.5,-4))
	await view("archive",Vector3(-11.0,0.05,3),Vector3(-17,1.3,3))
	await view("archive_desk",Vector3(-14.7,0.05,4.7),Vector3(-15.1,1.1,6.85))
	await view("monitors",Vector3(13.2,0.05,6),Vector3(18.6,1.8,2.2))
	await view("projector",Vector3(15.3,0.05,6.4),Vector3(15.3,1.3,8.5))
	State.collect("B");State.set_flag("auditVerified")
	game._open_puzzle("breaker");game._sync_active();await get_tree().process_frame
	game.ui.terminal_console.submit("DIR");game.ui.terminal_console.submit("BACA PIN.DAT")
	await shot("terminal");game.ui.close_panel()
	game.ui.show_audit_video();game._sync_active()
	if game.ui.archive_video.video.stream!=null:
		await get_tree().create_timer(3.5).timeout
		await shot("video")
	game.ui.close_panel();game.campus.clear(game.level);game.boss_revision.cancel();game.audio.shutdown();game.queue_free()
	await get_tree().process_frame;await get_tree().physics_frame;get_tree().quit()

func room(id: String) -> void:
	game.narrative.cancel();game.cinematic=false
	await game.enter_room(id,false,false);game.player.active=false;game.player.set_physics_process(false);game.level.set_process(false)
	if is_instance_valid(game.boss):game.boss.enabled=false

func view(title: String,p: Vector3,target: Vector3) -> void:
	game.player.position=p;game.player.rotation=Vector3.ZERO;game.player.camera.rotation=Vector3.ZERO;game.player.camera.look_at(target)
	game.player.lamp_on=true;game.player.lamp.visible=true;game.player.lamp.light_energy=2.05
	game.player.viewmodel.visible=true
	await shot(title)

func shot(title: String) -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.18).timeout;await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
	var suffix="_17_compat.png" if RenderingServer.get_current_rendering_method()=="gl_compatibility" else "_17.png"
	print("CAPTURE17 ",title," ",get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+title+suffix))
