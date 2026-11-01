extends Node
var game: Node3D
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if ok:print("PASS: ",message)
	else:failures+=1;push_error("FAIL: "+message)
func room(id: String) -> void:
	game.narrative.cancel();game.boss_revision.cancel();game.cinematic=false;game.ui.close_panel()
	await game.enter_room(id,false,false);game.player.active=false
	if is_instance_valid(game.boss):game.boss.enabled=false
	await get_tree().physics_frame;await get_tree().physics_frame
func target_from(object: KalaInteractable,p: Vector3) -> bool:
	game.player.position=p;game.player.last_safe_position=p;game.player.camera.look_at(object.global_position)
	game.player.active=true
	for i in range(3):await get_tree().physics_frame
	game.player.active=false
	return game.player.target==object
func _ready() -> void:
	State.save_enabled=false;State.reset();Engine.physics_ticks_per_second=120
	game=preload("res://scenes/main/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;game.test_mode=true;game.playing=true;game.ui.close_panel();State.set_flag("prologueVersion");State.set_flag("lessonSeen")
	await room("school")
	check(not game.player.viewmodel.has_node("HoldingHand"),"first-person hands removed")
	var school=game.level.get_node("ExplorableSchool")
	var foundation=school.get_node("GroundedSchoolFoundation")
	check(foundation.position.y+foundation.mesh.size.y/2 < -0.21,"foundation does not share the finished floor surface")
	for title in ["Source_621","Source_639","Source_657","Source_675"]:check(not game.level.find_child(title,true,false).is_visible_in_tree(),"old door assembly retired: "+title)
	check(school.get_node("SchoolLockers").get_child_count()==14,"14 imported lockers on solid corridor walls")
	check(school.get_node("SchoolLockers").get_children().all(func(n):return n.has_node("Padlock") and n.get_node("Padlock").is_visible_in_tree()),"each locker has a visible padlock")
	var art=school.find_children("Room_STUDIO*","Node3D",true,false)[0]
	var assets=art.get_children().filter(func(n):return n.has_meta("asset_source"))
	check(assets.filter(func(n):return str(n.get_meta("asset_source")).ends_with("easel.glb")).size()==3 and assets.filter(func(n):return str(n.get_meta("asset_source")).ends_with("guitar.glb")).size()==3 and art.find_child("piano",true,false)!=null,"art studio has easels, guitars and piano")
	check(game.level.get_node("NPC_Danu").skeleton!=null,"Danu uses imported skinned character")
	for object in game.level.get_children():
		if object is KalaInteractable and object.parameter=="locker":check(await target_from(object,Vector3(0,0.05,object.position.z)),"Raka locker can be selected from the corridor")
	await room("relay");State.set_flag("lenteraOwned");State.data.installed.generatorContact=true
	var cell: KalaInteractable
	var socket: KalaInteractable
	for object in game.level.get_children():
		if object is KalaInteractable:
			if object.action_id=="cell":cell=object
			if object.action_id=="socket":socket=object
	check(await target_from(cell,Vector3(-4.4,0.05,7)),"R17 can be targeted by the real claw from outside the grille")
	game.player.active=true;game._interact(game.player.target,true);game.player.active=false
	check(State.flag("relayCellHeld"),"R17 pickup advances actual game state")
	check(await target_from(socket,Vector3(8,0.05,0.8)),"R17 socket can be targeted")
	game.player.active=true;game.claw_cooldown=0;game._interact(game.player.target,true);game.player.active=false;check(State.flag("relayPower"),"R17 installation restores relay power")
	# Detect newly occluded progression pickups. Use world collision and real
	# player targeting from physically occupiable points, not direct callbacks.
	for id in ["loading","relay","production","office"]:
		await room(id)
		for object in game.level.get_children():
			if not object is KalaInteractable or object.action_id not in ["item","note","evidence"] or not object.available():continue
			var found=false
			var last_block=""
			for ring in [1.25,1.8,2.2]:
				for i in range(12):
					var a=TAU*i/12;var p=object.position+Vector3(cos(a)*ring,0,sin(a)*ring);p.y=0.05
					var shape=CapsuleShape3D.new();shape.radius=0.28;shape.height=1.72
					var q=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform=Transform3D(Basis.IDENTITY,p+Vector3.UP*0.88);q.collision_mask=1
					if not game.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():continue
					if await target_from(object,p):found=true;break
					if game.player.ray.is_colliding():last_block=str(game.player.ray.get_collider().get_path())
				if found:break
			check(found,id+" reachable "+object.caption+("" if found else " blocked by "+last_block))
	game.ui.show_puzzle("fuse");await get_tree().process_frame
	check(not game.ui.content.get_children().any(func(c):return c is Button and "PETUNJUK" in c.text),"puzzle answer hint button removed")
	var board=game.ui.wiring_board
	check(not board.attempt_connection(0,1) and not board.attempt_connection(1,1),"wiring still rejects mismatched and out-of-order connections")
	board.attempt_connection(0,0);game.ui.wiring_board.attempt_connection(1,1);game.ui.wiring_board.attempt_connection(2,2)
	check(State.solved("fuse"),"all three wires complete the fuse puzzle")
	game.ui.show_settings("DISPLAY");await get_tree().process_frame
	var menu = game.ui.settings_menu
	var saved_settings = State.settings.duplicate()
	menu.reset_defaults()
	check(menu.rows.get_child_count()==11,"display includes screen and visual quality settings")
	menu.rows.get_child(5).find_children("*","Button",true,false)[0].pressed.emit()
	menu.rows.get_child(6).find_children("*","Button",true,false)[0].pressed.emit()
	menu.tab_buttons[1].pressed.emit()
	menu.rows.get_child(2).find_children("*","Button",true,false)[1].pressed.emit()
	menu.rows.get_child(3).find_children("*","Button",true,false)[1].pressed.emit()
	check(is_equal_approx(game.get_viewport().scaling_3d_scale,0.75) and game.get_viewport().msaa_3d==1 and Engine.max_fps==90 and game.player.camera.fov==80,"graphics and display arrows apply to viewport, frame limiter and camera")
	game.ui.show_journal();await get_tree().create_timer(0.9).timeout
	check(game.ui.journal_book.opened and game.ui.journal_book.pages.modulate.a>0.99,"journal opening animation finishes with readable pages")
	await game._close()
	check(game.ui.journal_book==null and game.ui.settings_menu==null and game.player.active,"journal close animation restores control")
	State.settings=saved_settings;State.save_settings();game._apply_graphics()
	print("KALA REVISION12: %d checks, %d failures"%[checks,failures])
	game.campus.clear(game.level);game.boss_revision.cancel();game.audio.shutdown();game.queue_free()
	await get_tree().process_frame;await get_tree().physics_frame;await get_tree().create_timer(0.4).timeout;get_tree().quit(0 if failures==0 else 1)
