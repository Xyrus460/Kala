extends Node
var game: Node3D
var checks = 0
var failures = 0
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else: failures += 1; push_error("FAIL: " + label)

func room(id: String) -> void:
	game.boss_revision.cancel(); game.cinematic = false; game.ui.close_panel()
	await game.enter_room(id, false, false); game.player.active = false
	if is_instance_valid(game.boss): game.boss.enabled = false
	await get_tree().physics_frame

func _ready() -> void:
	State.save_enabled = false; State.reset(); Engine.physics_ticks_per_second = 240
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen")
	await room("home")
	check(game.level.get_node("FurnishedHome/bedSingle").get_meta("asset_source").contains("revision10"), "bedroom uses the new detailed furniture")
	check(game.level.get_node("FurnishedHome/ChangingStation").get_meta("asset_source").contains("revision10"), "nursery uses the new chest")
	await room("schoolyard")
	var school = game.campus.rooms.school
	check(not school.find_child("Source_70", true, false).visible, "oversized floating ceiling is retired")
	var no_slab = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(6, 1.8, -14), Vector3(6, 6, -14), 1))
	check(no_slab.is_empty(), "outdoor approach has open sky outside the entrance canopy")
	var doors = game.level.get_node("SchoolCampus/OperableEntranceDoors")
	game.player.position = Vector3(0, 0.14, -13.2)
	doors.toggle()
	for i in range(90): doors._physics_process(1.0 / 60)
	await get_tree().physics_frame
	check(not doors.opened and game.player.test_move(game.player.global_transform, Vector3(0,0,-3)), "closing entrance creates a physical blocker")
	doors.toggle()
	for i in range(90): doors._physics_process(1.0 / 60)
	await get_tree().physics_frame
	check(doors.opened and not game.player.test_move(game.player.global_transform, Vector3(0,0,-2.7)), "opening entrance clears the actual player capsule")
	game.player.position = Vector3(0, 0.05, -15.4); doors.toggle()
	check(doors.opened, "door cannot close through player standing in threshold")
	game.player.position = Vector3(0, 0.05, -13.2)
	game.campus.cross("school", false)
	check(is_instance_valid(doors) and doors.opened, "resident door state survives crossing to school interior")
	await room("loading")
	var source = game.level.find_child("Source_2001", true, false)
	check(not source.is_visible_in_tree() and game.level.props.panelFuse.name == "OperatorFusePickup", "overlapping fuse meshes are replaced by one pickup")
	check(game.level.props.panelFuse.get_node("CartridgeFuse").get_meta("asset_source").ends_with("cartridge_fuse.glb"), "pickup uses downloaded free cartridge fuse")
	State.give("panelFuse"); game.level._process(0)
	check(not game.level.props.panelFuse.visible, "collected fuse disappears with persistent inventory state")
	var door_box = AABB(Vector3(14.1,0,-11.5),Vector3(1.6,2.9,3))
	var clear = true
	for item in game.level.get_node("FactoryRevision09").get_children():
		if item.name != "structure-high" and not str(item.name).begins_with("structure-high"): continue
		if door_box.has_point(item.position): clear = false
	check(clear, "support structures leave maintenance doorway clear")
	game.ui.show_puzzle("panel"); await get_tree().process_frame; await get_tree().physics_frame
	var board = game.ui.keypad_board
	var key = board.model.get_node("Key_3")
	var pixel = board.camera.unproject_position(key.global_position) / Vector2(board.view.size) * board.size
	var click = InputEventMouseButton.new(); click.button_index = MOUSE_BUTTON_LEFT; click.pressed = true; click.position = pixel
	board._gui_input(click)
	check(State.data.puzzles.panel.entered == "3", "clicking the physical 3D key enters its digit")
	var press = InputEventKey.new(); press.keycode = KEY_2; press.pressed = true; board.handle_key(press)
	check(State.data.puzzles.panel.entered == "32", "keyboard shares the same real puzzle state")
	press.keycode = KEY_BACKSPACE; board.handle_key(press)
	check(State.data.puzzles.panel.entered == "3", "backspace corrects a single digit")
	board.press("2"); board.press("6"); board.press("8"); press.keycode = KEY_ENTER; board.handle_key(press)
	check(State.solved("panel") and game.ui.mode == "", "physical keypad completes the existing 3268 puzzle")
	var closed = weakref(board); await get_tree().process_frame
	check(not is_instance_valid(closed.get_ref()), "closing keypad releases its viewport and input handlers")
	await room("relay")
	check(game.level.has_node("FactoryRevision09/ArchiveGrille"), "relay cage has a complete framed enclosure")
	State.set_flag("lenteraOwned"); game.player.position = Vector3(-4.4, 0.05, 7)
	var cell: KalaInteractable
	for object in game.level.get_children():
		if object is KalaInteractable and object.action_id == "cell": cell = object
	game.player.camera.look_at(cell.global_position)
	await get_tree().physics_frame
	check(game.player._tool_focus() == cell, "Lentera claw reaches the relay cell at its accessible service dock")
	await room("ritual")
	var rig = game.boss.hands_rig
	var grounded = true; var contiguous = true
	for i in range(360):
		rig.animate(1.0 / 60, 2.7 / 60, false, 0.65 if i > 180 else 0)
		var y0 = rig.root.to_local(rig.parts.FinalFoot0.global_position).y
		var y1 = rig.root.to_local(rig.parts.FinalFoot1.global_position).y
		if minf(y0,y1) < 0.115 or minf(y0,y1) > 0.125: grounded = false
		for side in range(2):
			var knee = rig.parts["FinalKnee%d" % side]
			var foot = rig.parts["FinalFoot%d" % side]
			if not knee.transform.origin.is_equal_approx(rig.rest["FinalKnee%d" % side].origin) or not foot.transform.origin.is_equal_approx(rig.rest["FinalFoot%d" % side].origin): contiguous = false
	check(grounded, "boss always has a planted foot and no floor penetration throughout gait")
	check(contiguous, "boss knee and ankle joints remain connected during movement and attack")
	for i in range(120): rig.animate(1.0 / 60, 0, false, 0)
	check(rig.locomotion < 0.001 and rig.attack < 0.001, "boss returns smoothly to idle after movement stops")
	print("KALA REVISION10: %d checks, %d failures" % [checks, failures])
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if failures == 0 else 1)
