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

func walk_to(point: Vector3) -> bool:
	game.player.active = true; game.player.set_physics_process(false)
	Input.action_press("forward"); Input.action_press("sprint")
	var reached = false
	for i in range(1250):
		var d = point - game.player.position; d.y = 0
		if d.length() < 0.16: reached = true; break
		game.player.rotation.y = atan2(-d.x, -d.z)
		game.player._physics_process(1.0 / 60)
		await get_tree().physics_frame
	Input.action_release("forward"); Input.action_release("sprint")
	game.player.set_physics_process(true); game.player.active = false
	if not reached:
		print("WALK BLOCKED ", game.player.position, " -> ", point)
		for i in range(game.player.get_slide_collision_count()): print("CONTACT ", game.player.get_slide_collision(i).get_collider().get_path())
		var hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(game.player.position + Vector3.UP, point + Vector3.UP, 1))
		if not hit.is_empty(): print("PATH HIT ",hit.collider.get_path(), " ",hit.position)
	return reached

func _ready() -> void:
	State.save_enabled = false; State.reset(); Engine.physics_ticks_per_second = 240
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen")
	await room("home")
	State.data.layout_revision = 5; State.data.position = [-7.95, 0.05, 7.0, 0.0, 0.0]
	await game.enter_room("home", true, false); game.player.active = false
	check(game.player.position.distance_to(game.level.spawn) < 0.01 and State.data.layout_revision == State.LAYOUT_REVISION and State.flag("lessonSeen"), "old checkpoint relocates out of sealed geometry while preserving story progress")
	await get_tree().physics_frame
	var roof = PhysicsRayQueryParameters3D.create(Vector3(0, 3.8, 11.8), Vector3(0, 8, 11.8), 1)
	check(not game.get_world_3d().direct_space_state.intersect_ray(roof).is_empty(), "stairwell has a solid roof above the former sky gap")
	check(game.level.has_node("StairTread16") and not game.level.has_node("StairTread17"), "bottom tread no longer coincides with tiled floor")
	var flowers = game.level.find_children("DaisyArrangement*", "Node3D", true, false)
	check(flowers.size() == 2 and absf(flowers[1].position.y - 4.01) < 0.001, "daisy pots sit on the actual desk and dining tabletop")
	check(game.level.get_node("Mother").get_meta("asset_source").ends_with("mother.glb"), "mother uses the downloaded animated character")
	var nursery_opening = AABB(Vector3(3.83, 3.20, 2.25), Vector3(1.14, 2.18, 0.40))
	var clear_doorway = true
	for mesh in game.level.get_node("FurnishedHome").find_children("*", "MeshInstance3D", true, false):
		if nursery_opening.intersects(mesh.global_transform * mesh.get_aabb()): clear_doorway = false
	check(clear_doorway, "nursery pictures do not project into the open doorway")
	await room("schoolyard")
	var yard = game.level; var interior = game.campus.rooms.school
	game.player.position = Vector3(0, 0.05, -12.8); game.player.last_safe_position = game.player.position
	check(await walk_to(Vector3(0, 0.05, -16.1)), "player physically crosses the outdoor entrance floor")
	var before_eye: Vector3 = game.player.camera.global_position
	var to_wall = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0, 1.5, -13), Vector3(0, 1.5, -18), 1))
	if not to_wall.is_empty(): print("ENTRANCE HIT ",to_wall.collider.get_path(), " ", to_wall.position)
	check(to_wall.is_empty(), "entrance has no solid fake backdrop or hidden doorway collision")
	game.campus.cross("school", false)
	check(game.level == interior and game.campus.rooms.schoolyard == yard, "crossing preserves both scene instances without reload")
	check(game.level.safety.contains(game.player.position, 0.14), "rebased entrance position is inside school safety bounds")
	check(await walk_to(Vector3(0, 0.05, -27.2)), "player can continue walking into the school corridor")
	game.campus.cross("schoolyard", false)
	check(game.level == yard and game.campus.rooms.school == interior, "returning outdoors preserves evidence and NPC scene state")
	game.player.position = Vector3(26, 0.05, 37.5); game.player.last_safe_position = game.player.position
	await get_tree().physics_frame
	for z in [42, 44, 46, 48, 52, 56]:
		var hit = game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(26, 1.2, z), Vector3(26, -2, z), 1))
		if not hit.is_empty(): print("ALLEY FLOOR ", z, " ",hit.position," ",hit.collider.get_path())
	check(await walk_to(Vector3(26, 0.05, 58)), "complete alley is walkable with no house blocking it")
	await room("street")
	check(game.level.has_node("FactoryRevision09/WarungKartini"), "street contains a stocked open-front warung")
	check(game.level.has_node("FactoryRevision09/FuseCabinet/FlushElectricalSign"), "electrical sign is remounted outside its housing")
	game.ui.show_puzzle("fuse"); await get_tree().process_frame
	var board = game.ui.wiring_board
	check(not board.attempt_connection(0, 1) and State.data.puzzles.fuse.current.is_empty(), "wrong cable endpoint cannot power the circuit")
	check(not board.attempt_connection(2, 2), "cable order obeys the existing circuit clue")
	var source_pixel = board.camera.unproject_position(board.socket_point(0, -1)) / Vector2(board.view.size) * board.size
	var end_pixel = board.camera.unproject_position(board.socket_point(0, 1)) / Vector2(board.view.size) * board.size
	var press = InputEventMouseButton.new(); press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = source_pixel
	board._gui_input(press)
	var drag = InputEventMouseMotion.new(); drag.position = end_pixel; board._gui_input(drag)
	var release = InputEventMouseButton.new(); release.button_index = MOUSE_BUTTON_LEFT; release.pressed = false; release.position = end_pixel
	board._gui_input(release); await get_tree().process_frame
	check(State.data.puzzles.fuse.current == [0], "drag board commits a valid cable into persistent puzzle state")
	var closed_board = weakref(game.ui.wiring_board)
	game.ui.close_panel(); await get_tree().process_frame
	check(not is_instance_valid(closed_board.get_ref()), "closing cable puzzle releases its off-screen 3D viewport")
	game.ui.show_puzzle("fuse"); await get_tree().process_frame
	check(game.ui.wiring_board.completed == [0], "closing and reopening preserves connected cables")
	game.ui.wiring_board.attempt_connection(1, 1); await get_tree().process_frame
	game.ui.wiring_board.attempt_connection(2, 2); await get_tree().process_frame
	check(State.solved("fuse") and game.ui.mode == "", "three physical connections complete the real puzzle and close the board")
	game.ui.show_note("CATATAN / 017", "Tulisan yang ditemukan di meja inspeksi.")
	await get_tree().process_frame
	check(game.ui.content.get_child(0).find_child("HandwrittenText", true, false) != null, "evidence opens as readable handwritten paper")
	game.ui.show_dialogue("Sari", "Satu kalimat.\n\nKesaksian berikutnya.")
	check(game.ui.mode == "dialogue" and game.ui.dialogue_card.pages.size() == 2, "conversation uses separate progressive testimony pages")
	game.ui.close_panel()
	await room("loading")
	game.player.lamp_on = false; game.player.equip_blend = 1
	game.player._update_equip(0.3)
	check(game.player.viewmodel.position.y < -0.35, "switching flashlight off lowers the held tool out of view")
	game.player.lamp_on = true
	for i in range(30):game.player._update_equip(1.0/60)
	check(game.player.equip_blend > 0.99 and absf(game.player.viewmodel.position.y) < 0.02, "switching flashlight on smoothly settles the draw animation")
	State.set_flag("lenteraOwned"); game.player.lamp_on = true; game.player.active = true
	game.player.position = Vector3(0, 0.1, 5); game.player.last_safe_position = game.player.position
	game._start_fight("overseer"); var enemy = game.boss
	enemy.position = Vector3(0, 0.1, 0); enemy.rotation.y = 0; enemy.enabled = true; enemy.set_physics_process(false)
	game.player.camera.look_at(enemy.global_position + enemy.target_offset)
	await get_tree().physics_frame
	check(game.player.trigger_pulse() and enemy.pause_time > 0, "pulse reaches a visible enemy in range")
	check(not game.player.trigger_pulse(), "pulse cannot be spammed during cooldown")
	game.player.pulse_cooldown = 0; game.player.heat = 0
	var blocker = KalaGeometry.box(game.level, Vector3(0, 1.2, 2.5), Vector3(4, 3, 0.4), KalaGeometry.material("plain"), true)
	await get_tree().physics_frame; enemy.pause_time = 0; enemy.pulse_immunity = 0
	game.player.trigger_pulse()
	check(enemy.pause_time == 0, "opaque wall blocks pulse")
	check(not enemy._update_light_response(0.8), "opaque wall also blocks continuous reveal/disrupt")
	blocker.free(); await get_tree().physics_frame
	game.player.lamp.visible = true; game.player.cooldown = 0
	enemy._update_light_response(0.8)
	check(enemy.light_exposure > 0.5 and enemy.disruption_left > 0, "sustained visible light reveals and interrupts Overseer gaze")
	game.player.lamp_on = false
	for i in range(100): enemy.disruption_left = maxf(0, enemy.disruption_left - 0.05); enemy._update_light_response(0.05)
	check(enemy.light_exposure == 0 and enemy.disruption_left == 0 and not enemy.reveal_marker.visible, "light effects end cleanly after the lamp is switched off")
	enemy.pause_time = 0; enemy.recovery = 0; enemy.windup = 0; enemy.dash_left = 0
	enemy._physics_process(0.1)
	check(Vector2(enemy.velocity.x, enemy.velocity.z).length() > 0.5, "enemy resumes pursuing after disruption expires")
	game.player.lamp_on = true; game.player.pulse_cooldown = 0; game.player.heat = 0; enemy.pause_time = 0; enemy.pulse_immunity = 0; enemy.position.z = -10
	game.player.trigger_pulse(); check(enemy.pause_time == 0, "enemy outside pulse range remains unaffected")
	game.player.pulse_cooldown = 0; game.player.heat = 0; enemy.position = Vector3(8, 0.1, 4)
	game.player.trigger_pulse(); check(enemy.pause_time == 0, "pulse does not reach an enemy outside the forward cone")
	game.player.active = false
	print("KALA REVISION09: %d checks, %d failures" % [checks, failures])
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if failures == 0 else 1)
