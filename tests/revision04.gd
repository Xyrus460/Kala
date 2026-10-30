extends Node

var game: Node3D
var checks = 0
var failures = 0
var capture = false

func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("REV04 PASS: " + label)
	else: failures += 1; push_error("REV04 FAIL: " + label)

func _ready() -> void:
	get_window().unfocusable = true
	capture = OS.get_cmdline_user_args().has("--capture")
	State.save_enabled = false
	State.reset()
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.test_mode = true
	game.playing = true
	game.ui.close_panel()
	await photo_test()
	await room("school")
	var volumes = game.level.find_children("*", "MeshInstance3D", true, false).filter(func(n): return n.has_meta("light_volume"))
	check(volumes.size() == 14 and volumes.all(func(n): return not n.visible), "all fourteen erroneous school cones are invisible")
	await boundary(Vector3(11.4, 0.1, -14), Vector3(3, 0, 0), "school east classroom wall")
	await boundary(Vector3(0, 0.1, -29.3), Vector3(0, 0, -3), "school north wall")
	await room("daisy")
	await boundary(Vector3(1.9, -3.5, -20), Vector3(3, 0, 0), "chapter transition lower stair side")
	check(game.level.safety.contains(Vector3(0, -3.6, -21), 0.35), "chapter transition staircase remains inside playable footprint")
	await room("relay")
	await boundary(Vector3(25.3, 0.1, 8), Vector3(3, 0, 0), "factory generator annex perimeter")
	game.player.position = Vector3(3, 0.05, 13.7)
	game.player.last_safe_position = game.player.position
	game.player.camera.look_at(Vector3(3, 1.28, 12))
	game.player.active = true
	for i in range(3): await get_tree().physics_frame
	check(is_instance_valid(game.player.target) and game.player.target.action_id == "tool", "real camera ray reaches LENTERA-G through roof light volume")
	game.player.active = false
	await movies()
	await watcher_test()
	await pursuit_test()
	await combat_test("loading", "overseer", Vector3(0, 0.1, 18), Vector3(0, 0.1, 13))
	await combat_test("production", "hands", Vector3(0, 0.1, 18), Vector3(0, 0.1, 13))
	await combat_test("ritual", "tumbal", Vector3(0, 0.1, 8), Vector3(0, 0.1, 3))
	for index in [32, 33, 34, 35]:
		game.audio.say(index)
		check(not game.audio.voice.playing and game.audio.voice.stream == null, "Danu recording %d cannot play" % index)
	game.audio.shutdown()
	await get_tree().create_timer(0.2).timeout
	game.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	print("KALA REVISION04: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func room(id: String) -> void:
	game.ui.close_panel()
	await game.enter_room(id, false, false)
	game.player.active = false
	game.level.set_process(false)
	if is_instance_valid(game.boss): game.boss.enabled = false
	await get_tree().physics_frame

func snapshot(label: String) -> void:
	if not capture: return
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var path = "res://docs/screenshots/" + label + "_04.png"
	print("REV04 CAPTURE ", path, " result=", get_viewport().get_texture().get_image().save_png(path))

func photo_test() -> void:
	game.ui.show_photo()
	game._sync_active()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().process_frame
	await get_tree().process_frame
	var photo = game.ui.photo_inspector
	await snapshot("photo_front")
	var start = photo.get_global_rect().position + Vector2(60, 180)
	var press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = start; press.global_position = start
	get_viewport().push_input(press, true)
	await get_tree().process_frame
	var motion = InputEventMouseMotion.new()
	motion.position = start + Vector2(photo.size.x * 0.35, 0)
	motion.global_position = motion.position
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	get_viewport().push_input(motion, true)
	await get_tree().process_frame
	check(photo.dragging and absf(photo.card.rotation.y) > 1.3 and absf(photo.card.rotation.y) < 2.1, "viewport mouse drag rotates photo continuously")
	await snapshot("photo_drag")
	motion.position = start + Vector2(photo.size.x * 0.67, 0); motion.global_position = motion.position
	get_viewport().push_input(motion, true)
	press.pressed = false; press.position = motion.position; press.global_position = motion.position
	get_viewport().push_input(press, true)
	await get_tree().create_timer(0.24).timeout
	check(photo.back_visible and State.flag("photoBackSeen"), "manual mouse drag reveals rear clue and records discovery")
	await snapshot("photo_back")
	var keys = InputEventKey.new()
	keys.keycode = KEY_SPACE; keys.physical_keycode = KEY_SPACE; keys.pressed = true
	get_viewport().push_input(keys)
	await get_tree().process_frame
	check(photo.back_visible and not photo.dragging, "Space does not flip the photograph")
	keys.pressed = false; get_viewport().push_input(keys)
	press.pressed = true; press.position = start; press.global_position = start
	get_viewport().push_input(press, true)
	motion.position = start - Vector2(photo.size.x * 0.67, 0); motion.global_position = motion.position
	get_viewport().push_input(motion, true)
	press.pressed = false; press.position = motion.position; press.global_position = motion.position
	get_viewport().push_input(press, true)
	await get_tree().create_timer(0.24).timeout
	check(not photo.back_visible, "reverse mouse drag returns photograph to front")
	var buttons = game.ui.panel.find_children("*", "Button", true, false)
	check(buttons.all(func(b): return not b.text.to_lower().contains("balik")), "photo inspector has no flip button")
	game._close()
	await get_tree().process_frame
	check(not is_instance_valid(photo), "closing photo releases its native viewports")

func boundary(location: Vector3, motion: Vector3, label: String) -> void:
	game.player.position = location
	await get_tree().physics_frame
	check(game.player.test_move(game.player.global_transform, motion), label + " physically blocks escaping")

func movies() -> void:
	var movie = game.narrative
	check(movie.start("discovery"), "roof and workbench discovery scene starts")
	movie.set_process(false)
	movie.advance(2.6)
	await snapshot("discovery")
	movie.finish()
	check(State.flag("lenteraDiscoverySeen") and game.player.active, "discovery returns control")
	check(movie.start("pickup"), "LENTERA-G pickup scene starts")
	movie.set_process(false)
	movie.advance(0.6)
	check(game.player.tool_raising and movie.expansion.prop.visible and movie.expansion.prop.position.distance_to(Vector3(3, 1.28, 12)) > 0.2, "pickup animates actual world tool toward camera")
	await snapshot("pickup")
	movie.finish()
	check(State.flag("lenteraOwned") and State.flag("lenteraPickupSeen") and game.player.lamp_on and not game.player.tool_raising, "pickup restores held tool and flashlight")
	game.player.active = false
	await room("loading")
	check(movie.start("flash_break"), "old flashlight breaking scene starts")
	movie.set_process(false)
	movie.advance(4.5)
	check(State.flag("oldFlashBroken") and movie.expansion.actor.visible, "old flashlight is visibly thrown before breaking")
	await snapshot("flash_break")
	movie.finish()
	check(State.flag("flashBreakComplete") and game.player.active, "flashlight scene completion unlocks movement")
	await room("ritual")
	game.story_origin = Vector3(0, 0, 0)
	check(movie.start("reversion"), "Danu transformation scene starts")
	movie.set_process(false)
	movie.advance(3.4)
	check(movie.actor.visible and not movie.expansion.monster.visible and movie.actor.scale.x > 0.99, "monster transforms into original human Danu model")
	await snapshot("reversion")
	movie.finish()
	check(State.flag("danuHumanReturned") and State.flag("danuDescended") and game.player.active, "Danu transformation restores controls and completion flags")
	await room("relay")
	game.player.position = Vector3(0, 0.05, -11)
	check(movie.start("ambush"), "relay ambush scene starts")
	movie.set_process(false)
	for i in range(22): movie.advance(0.1)
	check(game.player.position.distance_to(Vector3(0, 0.05, -11)) > 1 and movie.expansion.hands.arms.size() == 6, "ambush moves player with complete six-arm pursuer")
	await snapshot("ambush")
	movie.finish()
	await settled("pursuit")
	check(State.data.room == "pursuit" and not movie.running and game.player.active, "ambush hands off to playable pursuit")
	game.player.active = false
	game.level.set_process(false)
	game.boss.enabled = false
	State.set_flag("escapePuzzleSolved")
	check(movie.start("rescue"), "Daisy shadow rescue scene starts")
	movie.set_process(false)
	movie.advance(6.5)
	check(movie.expansion.shadow.visible and movie.expansion.monster.visible, "rescue stages Daisy shadow and approaching hands")
	await snapshot("rescue")
	movie.advance(3)
	check(movie.expansion.prop != null and movie.expansion.prop.position.y < -6, "rescue visibly drops the shutter")
	movie.finish()
	await settled("production")
	check(State.flag("daisyShadowRescueSeen") and State.flag("handsPursuitComplete") and State.data.room == "production" and game.player.active, "rescue completes and transfers safely to production")
	State.data.flags.erase("escapePuzzleSolved")
	State.data.flags.erase("handsPursuitComplete")

func settled(id: String) -> void:
	for i in range(120):
		await get_tree().process_frame
		if not game.entering and State.data.room == id: return

func watcher_test() -> void:
	await room("relay")
	var watcher = game.level.get_node("RelayWatcher")
	watcher.set_process(false)
	game.player.position = Vector3(0, 0.05, 10)
	game.player.camera.look_at(Vector3(0, 1.6, 20))
	game.player.active = true
	watcher._process(3.1)
	check(watcher.actor.visible and watcher.rig.arms.size() == 6, "six-arm watcher appears after acquiring LENTERA-G")
	game.player.camera.look_at(watcher.actor.global_position + Vector3.UP * 1.9)
	var eye_point: Vector3 = watcher.actor.global_position + Vector3.UP * 1.9
	var query = PhysicsRayQueryParameters3D.create(game.player.camera.global_position, eye_point, 1)
	var occlusion = game.get_world_3d().direct_space_state.intersect_ray(query)
	print("WATCHER VIEW: camera=", game.player.camera.global_position, " actor=", watcher.actor.global_position, " occlusion=", occlusion.get("position", "clear"))
	check(occlusion.is_empty(), "watcher face is not hidden behind level geometry")
	watcher._process(0.9)
	check(watcher.retreat, "watcher notices player looking at it")
	await snapshot("relay_watcher")
	for i in range(180): watcher._process(1.0 / 30)
	check(not watcher.actor.visible and int(State.data.flags.get("handsWatchStage", -1)) == 0, "watcher opens alcove door retreats and records stage")
	game.player.active = false

func pursuit_test() -> void:
	await room("pursuit")
	var enemy = game.boss
	enemy.set_physics_process(false)
	enemy.enabled = true
	game.player.position = Vector3(5, 0.05, 56)
	enemy.position = Vector3(0, 0.05, 58)
	var start = enemy.position
	for i in range(50):
		enemy._physics_process(1.0 / 60)
		await get_tree().physics_frame
	check(enemy.position.x > start.x + 0.7, "pursuer moves toward live player position off original route")
	game.player.position = Vector3(-7, 0.05, 57)
	start = enemy.position
	for i in range(55):
		enemy._physics_process(1.0 / 60)
		await get_tree().physics_frame
	check(enemy.position.x < start.x - 0.7 and enemy.last_target.x < 0, "pursuer turns and replans when player reverses direction")
	enemy.enabled = false
	check(enemy.hands_rig.arms.size() == 6 and enemy.visual.scale.is_equal_approx(Vector3.ONE), "pursuer uses full source model with six articulated arms")
	game.player.camera.look_at(enemy.global_position + Vector3.UP * 1.4)
	await snapshot("hands_model")
	enemy.position = Vector3(40, -4.1, -91)
	game.player.position = Vector3(40, -4.4, -94)
	enemy.enabled = true
	enemy._physics_process(1.0 / 60)
	check(enemy.body_collision.shape.height < 1.1 and enemy.visual.scale.x > 0.99, "vent pursuit folds rig and collider without shrinking entire model")
	enemy.enabled = false
	var path = game.level.actor_path(Vector3(0, 0, 58), Vector3(88, -8, -124))
	check(path.size() > 300 and Vector2(path[-1].x - 88, path[-1].y + 124).length() < 2, "navigation reaches entire chase including annex stairs and vents")
	check(not game.level.escape_puzzle.unlock(), "service exit rejects incomplete three-piece puzzle")
	await boundary(Vector3(11.2, 0.1, -57), Vector3(2, 0, 0), "locked pursuit exit")
	for piece in ["sun", "moon", "star"]:
		game.level.escape_puzzle.search({"sun": "operator", "moon": "istirahat", "star": "perkakas"}[piece])
		for i in range(90): game.level.escape_puzzle.update(1.0 / 60)
		var target = find_interaction("fragment", piece)
		game.player.position = Vector3(target.position.x + (1.6 if target.position.x < 0 else -1.6), 0.05, target.position.z)
		game.player.last_safe_position = game.player.position
		game.player.camera.look_at(target.global_position)
		game.player.active = true
		for i in range(3): await get_tree().physics_frame
		check(game.player.target == target, piece + " fragment is reachable using actual camera ray")
		game._interact(target, false)
		game.player.active = false
		check(State.owns("fragment_" + piece), piece + " fragment collection is stored")
	var moon = game.level.get_node("EscapePuzzle/moon").get_child(0) as MeshInstance3D
	check(moon.mesh.get_surface_count() == 1 and moon.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() > 50, "crescent moon has visible triangulated geometry")
	var lock = find_interaction("escape_lock", "")
	game.player.position = Vector3(9.3, 0.05, -57)
	game.player.last_safe_position = game.player.position
	game.player.camera.look_at(lock.position)
	game.player.active = true
	for i in range(3): await get_tree().physics_frame
	check(game.player.target == lock, "service lock can be targeted from corridor")
	game._interact(lock, false)
	game.player.active = false
	for i in range(90): game.level.escape_puzzle.update(1.0 / 60)
	await get_tree().physics_frame
	check(State.flag("escapePuzzleSolved") and game.level.escape_puzzle.gate.collision_layer == 0 and absf(game.level.all_doors.pursuitEscape.node.rotation.y) > 1.2, "three pieces open actual animated door and remove lock barrier")
	game.player.position = Vector3(11, 0.05, -57)
	await get_tree().physics_frame
	check(not game.player.test_move(game.player.global_transform, Vector3(3, 0, 0)), "unlocked door is physically passable")
	await snapshot("escape_unlocked")
	await room("pursuit")
	check(game.level.escape_puzzle.gate.collision_layer == 0 and not game.level.get_node("EscapePuzzle/sun").visible, "solved service lock and collected pieces survive room reload")

func find_interaction(action: String, parameter: String) -> KalaInteractable:
	for object in get_tree().get_nodes_in_group("interactables"):
		if game.level.is_ancestor_of(object) and object.action_id == action and object.parameter == parameter: return object
	return null

func combat_test(id: String, kind: String, player_position: Vector3, enemy_position: Vector3) -> void:
	await room(id)
	if not is_instance_valid(game.boss): game._start_fight(kind)
	var enemy = game.boss
	enemy.set_physics_process(false)
	enemy.position = enemy_position
	enemy.rotation.y = 0
	game.player.position = player_position
	game.player.active = false
	game.player.lamp_on = true
	game.player.lamp.visible = true
	game.player.cooldown = 0
	game.player.heat = 0
	enemy.recovery = 0; enemy.dash_timer = 20; enemy.gaze_bonus = 20; enemy.shield = false
	enemy.enabled = true
	var before_hp: float = enemy.hp
	var before_position: Vector3 = enemy.position
	var lit = 0
	for i in range(45):
		game.player.camera.look_at(enemy.global_position + enemy.target_offset)
		await get_tree().physics_frame
		if enemy.beam_visible(): lit += 1
		enemy._physics_process(1.0 / 60)
	enemy.enabled = false
	check(lit > 30 and enemy.hp < before_hp, kind + " takes continuous flashlight damage")
	check(Vector2(enemy.position.x - before_position.x, enemy.position.z - before_position.z).length() > 0.4, kind + " keeps moving while illuminated")
