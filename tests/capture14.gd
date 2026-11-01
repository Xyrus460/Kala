extends Node3D
var game: Node3D

func _ready() -> void:
	get_window().unfocusable=true;State.save_enabled=false;State.reset()
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	game=preload("res://scenes/main/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;game.test_mode=true;game.playing=true;game.ui.close_panel()
	State.set_flag("prologueVersion");State.set_flag("lessonSeen")
	if "--burst-only" in OS.get_cmdline_user_args():
		State.data.puzzles.panel.solved=true;State.set_flag("overseerDefeated")
		await room("loading");await burst_shots();await finish();return
	await room("home");await view("pillow",Vector3(-4.6,3.3,-0.4),Vector3(-6.2,3.9,-1.2))
	await room("school")
	var npc=game.level.get_node("NPC_Sari")
	game.player.position=npc.position+Vector3(0.9,0.05,1.8);game.player.camera.look_at(npc.position+Vector3.UP*1.4)
	game._npc("Sari");game._sync_active();await get_tree().create_timer(0.8).timeout;await shot("conversation")
	await game._close();game.ui.show_journal();game.ui.journal_book.animation.pause();game.ui.journal_book._apply_open(0.45);await shot("journal_open")
	game.ui.journal_book._apply_open(1.0);await shot("journal");game.ui.close_panel()
	State.data.puzzles.panel.solved=true;State.set_flag("overseerDefeated")
	await room("loading")
	game.player.lamp_on=true;game.player._physics_process(0.001)
	await view("guard_shelf",Vector3(-22.0,0.05,9.5),Vector3(-24.35,1.20,9.6))
	await view("memo_a",Vector3(-23.2,0.05,11.3),Vector3(-24.9,1.55,11.1))
	await view("keynote",Vector3(-23.1,0.05,13.1),Vector3(-24.9,1.55,13.0))
	game.ui.show_puzzle("panel");await shot("keypad");game.ui.close_panel()
	await burst_shots()
	State.set_flag("inspectionFuseInstalled");game.level.factory_route.update()
	await view("gallery",Vector3(3.5,0.05,-29.5),Vector3(10.3,1.25,-26.7))
	await view("pumps",Vector3(-3.5,0.05,-46.0),Vector3(-14,1.7,-52))
	await view("pump_controls",Vector3(-16.0,0.05,-51.9),Vector3(-17.5,1.65,-54.7))
	await view("distribution",Vector3(3.5,0.05,-45.8),Vector3(15,1.6,-52.5))
	State.set_flag("inspectionPower");game.level.factory_route.update()
	await view("route_power",Vector3(0,0.05,-57.5),Vector3(0,1.7,-65))
	await finish()

func finish() -> void:
	game.campus.clear(game.level);game.boss_revision.cancel();game.audio.shutdown();game.queue_free()
	await get_tree().process_frame;await get_tree().physics_frame;await get_tree().create_timer(0.4).timeout;get_tree().quit()

func burst_shots() -> void:
	game.player.position=Vector3(0,0.05,5);game.player.rotation=Vector3.ZERO;game.player.camera.rotation=Vector3(-0.08,0,0)
	game.narrative.start("flash_break");game.narrative.set_process(false);game.narrative.advance(5.06)
	game.player._physics_process(0.001)
	var burst=game.narrative.expansion.burst;burst.set_process(false)
	for entry in [["burst_flash",0.045],["burst_fire",0.18],["burst_sparks",0.55],["burst_smoke",1.5]]:
		burst._render_at(entry[1]);await shot(entry[0])
	game.narrative.finish();game.player.set_physics_process(false)

func room(id: String) -> void:
	game.narrative.cancel();game.boss_revision.cancel();game.ui.close_panel();game.cinematic=false
	await game.enter_room(id,false,false);game.player.active=false;game.level.set_process(false);game.player.set_physics_process(false)
	if is_instance_valid(game.boss):game.boss.enabled=false
	await get_tree().physics_frame

func view(label: String,point: Vector3,target: Vector3) -> void:
	game.player.position=point;game.player.rotation=Vector3.ZERO;game.player.camera.look_at(target);await shot(label)

func shot(label: String) -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.15).timeout;await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
	var compatibility=RenderingServer.get_current_rendering_method()=="gl_compatibility"
	var suffix="_14_compat.png" if compatibility else "_14.png"
	print("CAPTURE14GL " if compatibility else "CAPTURE14 ",label," ",get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+label+suffix))
