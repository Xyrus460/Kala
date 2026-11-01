extends Node
var game: Node3D
var checks=0
var failures=0

func check(value: bool,message: String) -> void:
	checks+=1
	if value:print("PASS17: ",message)
	else:failures+=1;push_error("FAIL17: "+message)

func room(id: String) -> void:
	game.narrative.cancel();game.ui.close_panel();game.cinematic=false
	await game.enter_room(id,false,false);game.player.active=false;game.level.set_process(false)
	if is_instance_valid(game.boss):game.boss.enabled=false
	await get_tree().physics_frame;await get_tree().physics_frame

func target(action: String,id="") -> KalaInteractable:
	for object in get_tree().get_nodes_in_group("interactables"):
		if game.level.is_ancestor_of(object) and object.action_id==action and object.parameter==id:return object
	return null

func aim(action: String,id: String,from: Vector3,tool=false) -> bool:
	var object=target(action,id)
	if object==null:return false
	game.ui.close_panel();game.player.position=from;game.player.last_safe_position=from;game.player.camera.rotation=Vector3.ZERO;game.player.camera.look_at(object.global_position);game.player.active=true;game.player.cooldown=0;game.claw_cooldown=0
	for i in range(4):await get_tree().physics_frame
	game.player.camera.look_at(object.global_position)
	game.player._physics_process(1.0/60)
	var found=game.player.target==object
	if found:game._interact(object,tool)
	else:
		print("MISS17 ",action," / ",id," pos=",object.global_position," found=",game.player.target," eye=",game.player.camera.global_position)
		print("AREA17 layer=",object.collision_layer," transform=",object.global_transform," available=",object.available()," children=",object.get_children())
		var query=PhysicsRayQueryParameters3D.create(game.player.camera.global_position,object.global_position,2);query.collide_with_areas=true
		print("DIRECT17 ",game.get_world_3d().direct_space_state.intersect_ray(query))
		if game.player.ray.is_colliding():print("BLOCK17 ",game.player.ray.get_collider().get_path()," point ",game.player.ray.get_collision_point())
	game.player.active=false;game.level.set_process(false)
	if is_instance_valid(game.boss):game.boss.enabled=false
	return found

func _ready() -> void:
	State.save_enabled=false;State.reset()
	game=preload("res://scenes/main/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;game.test_mode=true;game.playing=true;game.ui.close_panel()
	State.set_flag("prologueVersion");State.set_flag("lessonSeen");State.set_flag("lenteraOwned")
	await room("pursuit")
	var hinge=game.level.all_doors.pursuitEscape.node
	var sockets=hinge.get_node("Sockets")
	var lock_target=target("escape_lock")
	check(sockets.get_parent()==hinge and lock_target.get_parent()==hinge,"lock geometry and E hitbox inherit the physical door hinge")
	var local_pose: Transform3D=sockets.transform
	var before: Vector3=sockets.global_position
	for pair in [["operator","sun"],["istirahat","moon"],["perkakas","star"]]:
		var piece=target("fragment",pair[1]);check(not piece.available(),pair[1]+" starts inside closed furniture")
		game.level.escape_puzzle.search(pair[0])
		for i in range(90):game.level.escape_puzzle.update(1.0/60)
		check(piece.available() and piece.get_parent().get_parent()!=game.level.escape_puzzle.root,pair[1]+" is physically attached to its drawer or shelf")
		var point=piece.global_position;var side=1 if point.x<0 else -1
		game.player.crouched=pair[1]!="moon"
		check(await aim("fragment",pair[1],Vector3(point.x+side*1.4,0.05,point.z)),pair[1]+" can be taken with the real player ray")
	check(game.level.escape_puzzle.unlock(),"complete symbol set releases the service door")
	for i in range(90):game.level._process(1.0/60)
	check(sockets.transform.is_equal_approx(local_pose) and sockets.global_position.distance_to(before)>0.5,"panel follows the opened door with a stable local transform")
	check(game.level.escape_puzzle.gate.collision_layer==0,"opened lock releases its physical barrier")
	game.test_mode=false;game.narrative.start("rescue");game.narrative.set_process(false)
	var previous=Quaternion.IDENTITY;var max_step=0.0
	for i in range(520):
		game.narrative.advance(1.0/60)
		var q: Quaternion=game.narrative.expansion.shadow.arms[1].quaternion
		if i>470:max_step=maxf(max_step,previous.angle_to(q))
		previous=q
	var movie=game.narrative.expansion
	var hand=movie.shadow.elbows[1].get_node("Wrist/Palm")
	var button=movie.rescue_button.get_node("ButtonCap")
	print("DAISY17 HAND ",hand.global_position," button ",button.global_position," delta ",hand.global_position.distance_to(button.global_position))
	check(hand.global_position.distance_to(button.global_position)<0.075,"Daisy's complete hand reaches the depressed button")
	check(max_step<0.10,"Daisy's reach remains continuous across individual animation frames")
	check(movie.shadow.scale.x==movie.shadow.scale.z,"shadow uses a coherent 3D skeleton without a flattened arm axis")
	game.narrative.cancel();game.test_mode=true
	await room("production")
	check(target("puzzle","valve")==null and target("valve","0")!=null and target("valve","2")!=null,"three physical valves replace the combined menu")
	check(not game.level.find_child("Source_2182",true,false).visible,"the sign giving away the valve answer is removed")
	check(not game.story.notes.valve_note.body.contains("90") and not game.story.notes.valve_note.body.contains("atas"),"service note gives no positions or turn counts")
	check(game.level.refinement.wheels.size()==3 and game.level.refinement.needles.size()==3,"each pipe has its own wheel and animated pressure gauge")
	check(await aim("note","hands_note",Vector3(18.1,0.05,-3)),"technician note is attached to the wall and can be read")
	check(await aim("valve","1",Vector3(-11,0.05,-16.5)) and not State.solved("valve") and State.data.puzzles.valve.pos==[0,1,2],"empty centre spindle prevents pressure input")
	State.give("workshopKey")
	for pivot in game.level.door_pivots:pivot.set_meta("opened",true)
	for i in range(90):game.level._process(1.0/60)
	for entry in [["valve_note",Vector3(-26.9,0.05,7.4)],["tool_origin",Vector3(-25.6,0.05,7.4)],["wheel_log",Vector3(-29.6,0.05,5.1)]]:
		check(await aim("note",entry[0],entry[1]),entry[0]+" lies on a workbench and remains readable")
	check(await aim("item","valveWheel",Vector3(-29.7,0.05,1.0),true) and State.owns("valveWheel"),"hooked wheel can be retrieved with the real Lentera-G claw ray")
	game.ui.close_panel()
	var wheel=game.level.refinement.wheels[1];var angle=wheel.rotation.z
	check(await aim("valve","1",Vector3(-11,0.05,-16.5)),"E turns the installed physical valve")
	game.level.refinement._process(0.025)
	check(wheel.rotation.z!=angle and absf(wheel.rotation.z-game.level.refinement.valve_angles[1])>0.01,"valve moves through intermediate poses instead of snapping")
	game.level.refinement._process(1.0)
	for index in [1,1,2,2]:
		await aim("valve",str(index),Vector3(-14.5+index*3.5,0.05,-16.5));game.level.refinement._process(0.6)
	game.player.active=true;game._pause();game._process(1.0)
	check(game.valve_encounter_delay>0 and not is_instance_valid(game.boss),"pausing during the last valve turn cannot start the encounter or dismiss pause")
	await game._close()
	await get_tree().create_timer(0.72).timeout
	check(State.solved("valve") and is_instance_valid(game.boss) and game.boss.kind=="hands","physical valve solution triggers the original encounter")
	State.set_flag("handsDefeated")
	await room("office")
	check(await aim("evidence","B",Vector3(0,0.05,-3.8)),"family album rests on the new desk and can be examined")
	check(await aim("note","contract_zero",Vector3(5.4,0.05,4.8)),"contract note rests on the office writing table")
	check(game.level.refinement.get_node("PersonnelArchive").find_children("GroundedArchiveRack*","Node3D",true,false).size()==5,"archive contains five grounded, stocked racks")
	check(not game.level.find_child("Source_2513",true,false).visible,"merged legacy monitor geometry is fully retired")
	check(game.level.refinement.get_node("SurveillanceRoom/BoltedCRTBank").find_children("MountedCRT*","Node3D",true,false).size()==6,"six CRT cabinets share a supported steel bank")
	for entry in [["breaker_note",Vector3(-16.4,0.05,5.4)],["liability_form",Vector3(-13.4,0.05,5.4)],["monitor_log",Vector3(20.3,0.05,4.0)]]:
		check(await aim("note",entry[0],entry[1]),entry[0]+" remains reachable after room reconstruction")
	check(await aim("item","tapeReel",Vector3(-14.8,0.05,5.4)) and State.owns("tapeReel"),"audit tape rests on the archive desk and can be collected")
	State.collect("B")
	check(await aim("audit","",Vector3(15.3,0.05,6.8)),"audit deck opens the native video player through real E interaction")
	var video_panel=game.ui.archive_video
	check(video_panel.video.stream is VideoStreamTheora and game.ui.mode=="archive_video","recording uses the actual bundled Theora video decoder")
	check(not State.flag("auditVerified"),"opening a recording cannot grant authorization before it finishes")
	game._sync_active();check(not game.player.active and game.audio.ambience.stream_paused,"film owns playback controls and suppresses competing ambience")
	video_panel.video.stream_position=5.0;await get_tree().process_frame
	video_panel.toggle();check(video_panel.video.paused,"video has working pause transport")
	video_panel.toggle();check(not video_panel.video.paused,"video resumes from pause")
	await game._close();check(not State.flag("auditVerified") and not is_instance_valid(game.ui.archive_video),"closing an unfinished film releases its decoder without authorizing audit")
	game.ui.show_audit_video();game._sync_active();await get_tree().process_frame
	game.ui.archive_video._finished()
	check(State.flag("auditVerified") and State.data.notes.has("audit"),"end-of-stream grants audit and keeps a journal record")
	await game._close();game._open_puzzle("breaker");game._sync_active();await get_tree().process_frame
	var terminal=game.ui.terminal_console
	check(is_instance_valid(terminal) and terminal.command is LineEdit and not game.ui.panel_center.visible,"ritual panel is an interactive command terminal")
	terminal.submit("DIR");terminal.submit("BACA AUDIT.LOG");terminal.submit("BACA PIN.DAT")
	check(terminal.output.get_parsed_text().contains("CRC gagal") and terminal.output.get_parsed_text().contains("KONTAKTOR 03"),"terminal filesystem and damaged audit logs can be inspected")
	terminal.submit("SAMBUNG 1");check(State.data.puzzles.breaker.current.is_empty(),"incorrect contact sequence trips the interlock")
	terminal.submit("SAMBUNG 3");terminal.submit("SAMBUNG 1")
	check(State.data.puzzles.breaker.current==[2,0] and game.ui.terminal_console==terminal,"commands change persisted circuit state without replacing the terminal")
	terminal.submit("SAMBUNG 9");check(State.data.puzzles.breaker.current==[2,0],"invalid commands cannot change relay state")
	await game._close();game._open_puzzle("breaker");await get_tree().process_frame
	check(game.ui.terminal_console.connected_lines==[2,0],"partial terminal work survives closing and reopening")
	game.ui.terminal_console.submit("SAMBUNG 4");game.ui.terminal_console.submit("SAMBUNG 2")
	check(State.solved("breaker") and game.ui.mode=="","chronological terminal commands release ritual passage and restore play")
	print("KALA REVISION17: %d checks, %d failures"%[checks,failures])
	game.campus.clear(game.level);game.narrative.cancel();game.boss_revision.cancel();game.audio.shutdown();game.queue_free()
	await get_tree().process_frame;await get_tree().physics_frame;await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if failures==0 else 1)
