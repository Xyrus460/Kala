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
		if difference.length()<0.17:reached=absf(game.player.position.y-point.y)<0.20;break
		game.player.rotation.y=atan2(-difference.x,-difference.z)
		game.player._physics_process(1.0/Engine.physics_ticks_per_second);await get_tree().physics_frame
	Input.action_release("forward");Input.action_release("sprint")
	game.player.set_physics_process(true);game.player.active=false
	if not reached:
		print("ROUTE14 STOP ",game.player.position," -> ",point)
		for i in range(game.player.get_slide_collision_count()):print("BLOCKER14 ",game.player.get_slide_collision(i).get_collider().get_path())
	return reached

func use_object(action: String,id: String,from: Vector3) -> bool:
	var object: KalaInteractable
	for child in game.level.get_children():
		if child is KalaInteractable and child.action_id==action and child.parameter==id:object=child;break
	if object==null:return false
	game.player.position=from;game.player.last_safe_position=from;game.player.camera.look_at(object.global_position);game.player.active=true
	for i in range(5):await get_tree().physics_frame
	var found=game.player.target==object
	if found:game._interact(game.player.target,false)
	else:print("MISSED14 ",action," / ",id," target ",game.player.target)
	game.player.active=false;game.level.set_process(false)
	return found

func route(id: String,from: Vector3) -> bool:
	return await use_object("factory_route",id,from)

func surface_bounds(mesh: MeshInstance3D) -> AABB:
	var vertices: PackedVector3Array=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var bounds=AABB(mesh.global_transform*vertices[0],Vector3.ZERO)
	for vertex in vertices:bounds=bounds.expand(mesh.global_transform*vertex)
	return bounds

func _ready() -> void:
	State.save_enabled=false;State.reset();Engine.physics_ticks_per_second=240
	game=preload("res://scenes/main/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;game.test_mode=true;game.playing=true;game.ui.close_panel()
	State.set_flag("prologueVersion");State.set_flag("lessonSeen")
	await room("home")
	var pillow=game.level.find_child("single-bed-timber_3",true,false)
	var mattress=game.level.find_child("single-bed-timber_2",true,false)
	var p=surface_bounds(pillow);var m=surface_bounds(mattress)
	check(p.position.y<=m.end.y and p.position.y>=m.end.y-0.035 and p.position.z>=m.position.z,"pillow rests into the duvet and its footprint stays on the bed")
	check(p.size.y<0.18,"baked pillow incline is flattened instead of balancing on a corner")
	await room("school")
	for who in ["Danu","Raka","Sari","Adit"]:
		var npc=game.level.get_node("NPC_"+who)
		game.player.position=npc.global_position+Vector3(1.2,0,1.2);npc.rotation.y=-3*PI/4
		game._npc(who);game._sync_active()
		for i in range(70):npc._process(1.0/60)
		var toward=(game.player.global_position-npc.global_position).normalized()
		check(npc.global_basis.z.dot(toward)>0.995,who+" smoothly faces the actual player during dialogue")
		await game._close();check(npc.conversation_target==null,who+" releases dialogue tracking when the conversation closes")
	game.ui.show_journal();game._sync_active();await get_tree().create_timer(0.2).timeout
	check(game.ui.journal_book.opening>0 and game.ui.journal_book.opening<1,"journal has a continuous intermediate opening pose")
	await game._close();game._journal();await get_tree().create_timer(0.9).timeout
	check(game.ui.journal_book.opened and game.ui.journal_book.pages.modulate.a>0.99,"closing mid-open and reopening leaves readable journal pages")
	await game._close()
	game.ui.show_puzzle("panel");game._sync_active()
	check(game.ui.corner_close.text=="Tutup (Esc)" and game.ui.corner_close.anchor_left==1.0 and game.ui.content.find_children("*","Button",true,false).is_empty(),"keypad uses a small top-right close button without a footer bar")
	game.ui.corner_close.pressed.emit();await get_tree().process_frame
	check(game.ui.mode=="" and game.player.active,"corner close returns control to the player")
	State.data.puzzles.panel.solved=true;State.set_flag("overseerDefeated")
	await room("loading")
	check(game.level.find_child("GuardStorageRack",true,false)!=null and game.level.find_child("GuardLocker",true,false)!=null and not game.level.find_child("Source_1964",true,false).visible,"guard shelf and locker use grounded replacements instead of blank blockout cartons")
	for entry in [["memo_a",Vector3(-23.3,0.05,11.1)],["guard_keynote",Vector3(-23.3,0.05,13.0)],["memo_b",Vector3(25.2,0.05,-8.6)],["memo_c",Vector3(-9.2,0.05,-20.2)]]:
		check(await use_object("note",entry[0],entry[1]),entry[0]+" mounted paper is readable with the player's real E ray")
		await game._close();game.player.active=false;game.level.set_process(false)
	for mesh_name in ["Source_1950","Source_2031","Source_1952","Source_1954"]:
		check(not game.level.find_child(mesh_name,true,false).visible,mesh_name+" obsolete floating paper is retired")
	check(await use_object("item","maintenanceKey",Vector3(-22.5,0.05,15.4)) and State.owns("maintenanceKey"),"replacement key hanging on its real hook can still be collected with E")
	for yaw in [0.0,1.2,-2.8]:
		State.data.flags.erase("flashBreakComplete");State.data.flags.erase("oldFlashBroken")
		game.player.position=Vector3(0,0.05,1);game.player.rotation.y=yaw;game.player.camera.rotation=Vector3(-0.1,0,0)
		check(game.narrative.start("flash_break"),"flashlight cinematic starts at yaw "+str(yaw));game.narrative.set_process(false)
		var landing: Vector3=game.narrative.expansion.throw_end
		var previous=game.player.camera.global_basis.get_rotation_quaternion();var rotation_total=0.0
		for i in range(660):
			game.narrative.advance(1.0/60)
			var current=game.player.camera.global_basis.get_rotation_quaternion();rotation_total+=previous.angle_to(current);previous=current
		check(game.narrative.expansion.throw_end.is_equal_approx(landing) and rotation_total<1.8,"throw endpoint stays fixed and camera never enters a spin at yaw "+str(yaw))
		check(game.narrative.expansion.burst.fragments.size()==58 and game.narrative.expansion.burst.clouds.size()==19,"battery burst contains physical shards, sparks, fire and rolling smoke")
		check(absf(game.player.camera.h_offset)<0.001 and absf(game.player.camera.v_offset)<0.001,"blast camera shake decays completely")
		game.narrative.finish();await get_tree().process_frame
		check(game.player.active and game.level.find_child("CinematicProps",true,false)==null and game.player.camera.rotation.is_equal_approx(Vector3(-0.1,0,0)),"cutscene restores camera pose and releases its effects")
	await room("loading")
	check(game.level.find_child("GalleryMascot",true,false)==null and not is_instance_valid(game.boss),"post-Pengawas exploration contains no second mascot or boss")
	var area=0.0
	for region in game.level.safety.regions:
		if region.z<-22:area+=region.w*region.d
	check(area>1000 and game.level.factory_route.end_z<-60,"post-boss route expands to over 1000 square metres and four exploration rooms")
	check(await route("power",Vector3(-11.2,0.05,-28.6)) and not State.flag("inspectionPower"),"missing fuse cannot bypass the expanded puzzle")
	check(await route("valve_0",Vector3(-17.5,0.05,-53.0)) and State.data.inspectionValves==[2,1,3],"unpowered pressure actuator does not turn")
	check(await route("fuse",Vector3(7.5,0.05,-28)),"emergency fuse remains reachable without Lentera-G")
	check(await route("power",Vector3(-11.2,0.05,-28.6)) and State.flag("inspectionFuseInstalled") and not State.flag("inspectionPower"),"fuse powers work lights but cannot open the final shutter")
	check(await route("circuit_2",Vector3(21.2,0.05,-48)) and State.data.inspectionSequence.is_empty(),"distribution interlock rejects input until pressure stabilizes")
	game.player.position=Vector3(0,0.05,-29.5);game.player.last_safe_position=game.player.position
	check(await walk(Vector3(0,0,-46)) and await walk(Vector3(-12,0,-46)) and await walk(Vector3(-17.5,0,-52.8)),"player physically walks from gallery hub into the enlarged pump room")
	for index in [0,0,0,1,1,1,2,2]:
		check(await route("valve_"+str(index),Vector3(-17.5+index*5.2,0.05,-53.0)),"real E ray operates coupled valve "+str(index+1))
	check(State.flag("inspectionPressure") and not State.flag("inspectionPower"),"solving coupled pressure gauges enables distribution without opening the shutter")
	check(await route("circuit_0",Vector3(7,0.05,-53.6)) and State.data.inspectionSequence.is_empty(),"wrong first circuit resets the sequence")
	check(await route("circuit_2",Vector3(21.2,0.05,-48)) and await route("circuit_1",Vector3(18,0.05,-53.6)) and State.data.inspectionSequence.is_empty(),"wrong later circuit also resets earlier connections")
	await route("circuit_2",Vector3(21.2,0.05,-48))
	var partial=State.data.duplicate(true);await room("office");State.data=partial;await room("loading")
	check(State.flag("inspectionPressure") and State.data.inspectionSequence==[2],"leaving and revisiting preserves pressure and partial circuit progress")
	var space=game.get_world_3d().direct_space_state
	var query=PhysicsRayQueryParameters3D.create(Vector3(0,1.3,-62),Vector3(0,1.3,-64),1)
	check(not space.intersect_ray(query).is_empty(),"final shutter physically blocks partial puzzle completion")
	check(await route("circuit_0",Vector3(7,0.05,-53.6)) and await route("circuit_3",Vector3(10,0.05,-41.3)) and await route("circuit_1",Vector3(18,0.05,-53.6)),"all four physically separate circuit stations accept the deduced order")
	check(State.flag("inspectionPower") and space.intersect_ray(query).is_empty(),"only the complete fuse-pressure-circuit solution opens shutter collision")
	game.player.position=Vector3(21,0.05,-52);game.player.last_safe_position=game.player.position
	check(await walk(Vector3(21,0,-50.4)) and await walk(Vector3(5,0,-50.4)) and await walk(Vector3(5,0,-46)) and await walk(Vector3(0,0,-46)) and await walk(Vector3(0,0,-64.6)),"player can navigate around distribution cabinets and walk the full route through the open shutter")
	game.player.position.z=-65.1;game.level.factory_route.check_transition(game.player)
	for i in range(8):await get_tree().process_frame
	check(State.data.room=="relay" and not State.flag("lenteraOwned"),"expanded puzzle leads to the original Lentera-G discovery")
	State.data.erase("inspectionValves");State.data.erase("inspectionSequence");await room("loading")
	check(State.flag("inspectionPower") and not game.level.factory_route.shutter.visible and not is_instance_valid(game.boss),"older completed inspection saves retain their open route without replaying the boss")
	print("KALA REVISION14: %d checks, %d failures"%[checks,failures])
	game.campus.clear(game.level);game.boss_revision.cancel();game.audio.shutdown();game.queue_free()
	await get_tree().process_frame;await get_tree().physics_frame;await get_tree().create_timer(0.4).timeout;get_tree().quit(0 if failures==0 else 1)
