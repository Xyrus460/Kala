extends Node
var game: Node3D
var ended=false
var failures=0
var checks=0

func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("VIDEO17 PASS: ",message)
	else:failures+=1;push_error("VIDEO17 FAIL: "+message)

func _ready() -> void:
	get_window().unfocusable=true;State.save_enabled=false;State.reset()
	game=preload("res://scenes/main/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;game.test_mode=true;game.playing=true;game.ui.close_panel()
	await game.enter_room("office",false,false)
	game.ui.show_audit_video();game._sync_active()
	game.ui.archive_video.completed.connect(func():ended=true)
	var player=game.ui.archive_video.video
	for seconds in [3.0,14.0,14.0]:
		await get_tree().create_timer(seconds).timeout
		var time=player.stream_position
		check(player.is_playing() and time>1,"real video stream advances to %.1f seconds"%time)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://docs/screenshots/video17_live_%02d.png"%int(time))
		check(not State.flag("auditVerified"),"unfinished normal playback keeps audit locked")
	await get_tree().create_timer(14).timeout
	check(ended and State.flag("auditVerified"),"actual decoder end-of-stream authorizes the audit")
	check(not player.is_playing(),"video stops cleanly at its real ending")
	game.ui.archive_video.play();await get_tree().create_timer(0.8).timeout
	check(player.is_playing() and player.stream_position<2,"replay restarts the film without an invalid seek")
	await game._close();check(game.player.active and not game.audio.ambience.stream_paused,"closing film restores player and room audio")
	print("KALA VIDEO17: %d checks, %d failures"%[checks,failures])
	game.campus.clear(game.level);game.boss_revision.cancel();game.audio.shutdown();game.queue_free()
	await get_tree().process_frame;await get_tree().physics_frame;get_tree().quit(0 if failures==0 else 1)
