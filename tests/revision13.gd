extends Node
var game: Node3D
var checks=0
var failures=0

func check(ok: bool,label: String) -> void:
	checks+=1
	if ok:print("PASS: ",label)
	else:failures+=1;push_error("FAIL: "+label)

func room(id: String) -> void:
	game.narrative.cancel();game.boss_revision.cancel();game.ui.close_panel();game.cinematic=false
	await game.enter_room(id,false,false);game.player.active=false;game.level.set_process(false)
	if is_instance_valid(game.boss):game.boss.enabled=false
	await get_tree().physics_frame;await get_tree().physics_frame

func walk(point: Vector3) -> bool:
	game.player.active=true;game.player.set_physics_process(false);game.player.camera.rotation=Vector3.ZERO
	Input.action_press("forward");Input.action_press("sprint")
	var reached=false
	var budget=ceili(game.player.position.distance_to(point)/3.4*Engine.physics_ticks_per_second)+240
	for i in range(budget):
		var difference=point-game.player.position;difference.y=0
		if difference.length()<0.16:reached=absf(game.player.position.y-point.y)<0.20;break
		game.player.rotation.y=atan2(-difference.x,-difference.z)
		game.player._physics_process(1.0/Engine.physics_ticks_per_second);await get_tree().physics_frame
	Input.action_release("forward");Input.action_release("sprint")
	game.player.set_physics_process(true);game.player.active=false
	if not reached:
		print("ROUTE13 STOP ",game.player.position," -> ",point)
		for i in range(game.player.get_slide_collision_count()):print("BLOCKER13 ",game.player.get_slide_collision(i).get_collider().get_path())
	return reached

func use_route(id: String,from: Vector3) -> bool:
	var object: KalaInteractable
	for child in game.level.get_children():
		if child is KalaInteractable and child.action_id=="factory_route" and child.parameter==id:object=child;break
	game.player.position=from;game.player.last_safe_position=from;game.player.camera.look_at(object.position)
	game.player.active=true
	for i in range(5):await get_tree().physics_frame
	var found=game.player.target==object
	if found:game._interact(game.player.target,false)
	game.player.active=false;game.level.set_process(false)
	return found

func _ready() -> void:
	State.save_enabled=false;State.reset();Engine.physics_ticks_per_second=240
	game=preload("res://scenes/main/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;game.test_mode=true;game.playing=true;game.ui.close_panel()
	State.set_flag("prologueVersion");State.set_flag("lessonSeen")
	await room("home");game.narrative.start("wash");game.narrative.set_process(false);game.narrative.advance(6)
	check(not game.player.camera.has_node("WashingHands") and game.level.get_node("FurnishedHome/BathroomShower").running,"shower renders water without first-person hands")
	game.narrative.finish();check(State.flag("homeReady") and game.player.active,"skipping shower still completes preparation and restores control")
	await room("school")
	var people=[game.level.get_node("NPC_Danu"),game.level.get_node("NPC_Raka"),game.level.get_node("NPC_Adit")]
	var heads=people.map(func(n):return n.get_meta("head_source"))
	check(heads[0]!=heads[1] and heads[1]!=heads[2] and heads[0]!=heads[2],"Danu, Raka and Adit have three different imported head meshes")
	check(people.map(func(n):return n.height).min()!=people.map(func(n):return n.height).max(),"boys have different body heights")
	var sari=game.level.get_node("NPC_Sari");var ratna=game.level.get_node("EnvironmentalDetail/Teacher")
	check(sari.female and ratna.female and sari.skeleton!=null and ratna.skeleton!=null,"Sari and Ratna use animated female skin rigs")
	check(sari.find_child("SariHead",true,false)!=null and ratna.find_child("Formad_Head",true,false)!=null,"student and teacher have distinct imported hairstyles")
	check(ratna.find_child("RatnaBody",true,false)!=null and str(ratna.get_meta("outfit_source")).ends_with("female_suit.glb"),"teacher wears the licensed formal clothing mesh")
	for person in people+[sari,ratna]:
		person.sit();check(person.seated and person.skeleton.get_bone_global_pose(person.skeleton.find_bone("LowerLeg.L")).origin.is_finite(),person.name+" can sit with its replacement skin")
		person.stand();person.animate_walk(1.0,0.6);check(not person.seated and person.animator.is_playing(),person.name+" can stand and walk after sitting")
	await room("loading")
	State.data.layout_revision=12;State.data.position=[0,-2.35,-29,0,0]
	await game.enter_room("loading",true,false);game.player.active=false;game.level.set_process(false)
	check(game.player.position.distance_to(game.level.spawn)<0.01 and State.flag("lessonSeen"),"legacy factory stair checkpoint migrates to safe ground and retains progress")
	State.data.position=[6,0.05,-29.5,0,0]
	await game.enter_room("loading",true,false);game.player.active=false;game.level.set_process(false)
	check(game.player.position.distance_to(Vector3(6,0.05,-29.5))<0.01,"current inspection checkpoint resumes at the saved gallery position")
	State.data.puzzles.panel.solved=true;State.set_flag("overseerDefeated");State.set_flag("oldFlashBroken")
	for i in range(120):game.level._process(1.0/60)
	check(not game.player.lamp_available() and not State.flag("lenteraOwned"),"inspection exploration starts without a working flashlight or Lentera-G")
	game.player.position=Vector3(0,0.05,-19);game.player.last_safe_position=game.player.position
	check(await walk(Vector3(0,0,-29.5)),"player walks horizontally from the old staircase into the inspection hub")
	check(await walk(Vector3(6,0,-29.5)),"gallery entrance is physically walkable")
	check(await use_route("power",Vector3(-11.2,0.05,-28.6)) and not State.flag("inspectionPower"),"power cabinet is reachable and rejects a missing fuse")
	check(await use_route("fuse",Vector3(7.5,0.05,-28)),"fuse can be selected and collected by the player's real E ray")
	check(State.flag("inspectionFuseHeld") and not State.flag("lenteraOwned"),"gallery exploration collects the fuse before Lentera-G")
	check(await walk(Vector3(6,0,-29.5)) and await walk(Vector3(0,0,-29.5)) and await walk(Vector3(-10.8,0,-29.5)),"gallery, hub and control room are connected and support backtracking")
	check(await use_route("log",Vector3(-8,0.05,-31.2)) and State.data.notes.has("inspection_log"),"control-room log can be read and saved in the journal")
	game._close();await get_tree().process_frame;game.player.active=false;game.level.set_process(false)
	var space=game.get_world_3d().direct_space_state
	var query=PhysicsRayQueryParameters3D.create(Vector3(0,1.3,-62),Vector3(0,1.3,-64),1)
	check(not space.intersect_ray(query).is_empty(),"inspection shutter physically blocks progress before power is restored")
	check(await use_route("power",Vector3(-11.2,0.05,-28.6)) and State.flag("inspectionFuseInstalled") and not State.flag("inspectionPower"),"fuse installation restores service lighting while the expanded puzzle keeps the shutter locked")
	# Revision14 exercises the full coupled-pressure and four-station solution.
	# This older route regression continues with a completed-inspection fixture.
	State.set_flag("inspectionPower");game.level.factory_route.update()
	check(space.intersect_ray(query).is_empty(),"powered shutter removes its collision")
	game.player.position=Vector3(-10.8,0.05,-29.5);game.player.last_safe_position=game.player.position
	check(await walk(Vector3(0,0,-29.5)) and await walk(Vector3(0,0,-64.6)),"player returns from the control room and reaches the open relay route without descending")
	game.level.factory_route.check_transition(game.player);check(State.data.room=="loading","the old stair trigger does not skip the exploration wing")
	game.player.position.z=-65.1;game.level.factory_route.check_transition(game.player)
	for i in range(6):await get_tree().process_frame
	check(State.data.room=="relay" and not State.flag("lenteraOwned"),"completed exploration leads to the relay and preserves the tool discovery")
	game.player.active=false;game.level.set_process(false)
	var pickup: KalaInteractable
	for child in game.level.get_children():
		if child is KalaInteractable and child.action_id=="tool":pickup=child;break
	game.player.position=Vector3(3,0.05,14);game.player.camera.look_at(pickup.position);game.player.active=true
	for i in range(5):await get_tree().physics_frame
	check(game.player.target==pickup,"Lentera-G remains reachable after exploring the new wing")
	game._interact(pickup,false);check(State.flag("lenteraOwned"),"Lentera-G can be acquired after the exploration route")
	await room("loading");game.player.position=Vector3(0,0.05,5);game.player.last_safe_position=game.player.position
	for angles in [Vector2(0,0),Vector2(0.6,-0.4),Vector2(-0.7,0.5)]:
		game.player.rotation.y=angles.x;game.player.camera.rotation.x=angles.y;game.player.lamp_on=true;game.player.equip_blend=0.65
		game.player.reach_point=game.player.camera.global_position-game.player.camera.global_basis.z*8;game.player.reach_time=0.5;game.player.active=true;game.player._physics_process(0.016)
		var cable=game.player.cable
		var start=cable.global_position-cable.global_basis.y*cable.mesh.height/2
		var end=cable.global_position+cable.global_basis.y*cable.mesh.height/2
		check(start.distance_to(game.player.claw_muzzle.global_position)<0.0001 and end.distance_to(game.player.reach_point)<0.0001 and game.player.claw_head.global_position.distance_to(end)<0.0001,"cable and flying jaws stay attached to the barrel at aim "+str(angles))
	game.player.reach_time=0;game.player._physics_process(0.016)
	check(game.player.claw_head.transform.is_equal_approx(game.player.claw_head_rest),"retracted jaw returns to the machine's own socket")
	game.player.active=false
	game._start_fight("overseer");game.boss.enabled=false
	check(game.boss.visual.find_child("Skeleton3D",true,false)!=null and game.boss.visual.find_child("RekaFace",true,false)!=null,"actual Pengawas enemy uses the imported mascot rig and reference face")
	game.boss.queue_free();game.boss=null
	for id in ["relay","production","office","ritual"]:
		await room(id)
		var north=-game.level.depth/2
		var floor_hit=space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,0.4,north-5),Vector3(0,-0.4,north-5),1))
		check(not floor_hit.is_empty() and absf(floor_hit.position.y)<0.01,id+" has a horizontal physical floor in its connecting passage")
	print("KALA REVISION13: %d checks, %d failures"%[checks,failures])
	game.campus.clear(game.level);game.boss_revision.cancel();game.audio.shutdown();game.queue_free()
	await get_tree().process_frame;await get_tree().physics_frame;await get_tree().create_timer(0.4).timeout;get_tree().quit(0 if failures==0 else 1)
