extends Node
var game: Node3D
var checks = 0
var failures = 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if ok: print("PASS: ", message)
	else: failures += 1; push_error("FAIL: " + message)

func target(action: String, parameter = "") -> KalaInteractable:
	for object in game.level.get_children():
		if object is KalaInteractable and object.action_id == action and (parameter == "" or object.parameter == parameter): return object
	return null

func pose(point: Vector3, look: Vector3) -> void:
	game.player.position = point; game.player.last_safe_position = point; game.player.velocity = Vector3.ZERO
	game.player.rotation = Vector3.ZERO; game.player.camera.look_at(look)
	game.player.active = true
	for i in range(4): await get_tree().physics_frame
	game.player.active = false

func act(object: KalaInteractable, point: Vector3, tool = false) -> void:
	await pose(point, object.global_position)
	check(game.player.target == object, "actual interaction ray reaches " + object.caption)
	if game.player.target != object:
		if game.player.ray.is_colliding(): print("BLOCKED ", game.player.ray.get_collider().get_path())
		return
	game.player.active = true; game.claw_cooldown = 0; game._interact(object, tool); game.player.active = false

func walk(point: Vector3, max_frames = 900) -> bool:
	game.player.active = true; game.player.set_physics_process(false); game.player.camera.rotation = Vector3.ZERO
	Input.action_press("forward"); Input.action_press("sprint")
	var reached = false
	for i in range(max_frames):
		var d = point - game.player.position; d.y = 0
		if d.length() < 0.18: reached = absf(point.y - game.player.position.y) < 0.27; break
		game.player.rotation.y = atan2(-d.x, -d.z)
		game.player._physics_process(1.0 / 60); await get_tree().physics_frame
	Input.action_release("forward"); Input.action_release("sprint")
	game.player.active = false; game.player.set_physics_process(true)
	if not reached:
		print("WALK STOP ", game.player.position, " -> ", point)
		for i in range(game.player.get_slide_collision_count()): print("BLOCKER ", game.player.get_slide_collision(i).get_collider().get_path())
	return reached

func _ready() -> void:
	State.save_enabled = false; State.reset(); Engine.physics_ticks_per_second = 240
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen"); State.set_flag("lenteraOwned"); State.set_flag("archiveOpen")
	await game.enter_room("relay", false, false); game.player.active = false
	for pivot in game.level.door_pivots: pivot.set_meta("opened", true)
	for i in range(100): game.level._process(1.0 / 60)
	await get_tree().physics_frame
	var world = game.level.relay_world
	var memory = world.memory
	check(world.get_node("R17SocketCabinet").is_visible_in_tree(), "R17 has a complete visible cabinet")
	check(game.level.find_child("RelayCell", true, false).global_position.distance_to(game.level.to_global(Vector3(-7.15, 1.28, 7))) < 0.01, "R17 cartridge is visibly mounted at its actual interaction point")
	check(world.get_node("ArchiveLeverConsole/FreeAssetArchiveLever").is_visible_in_tree(), "free CC0 lever has a grounded console")
	check(game.level.props.generatorContact.name == "SingleGeneratorContact", "one physical copper contact replaces floating source placeholders")
	check(not game.level.find_child("Source_1634", true, false).is_visible_in_tree(), "floating archive paper is retired")
	check(is_equal_approx(world.get_node("DieselGeneratorG02/GroundedSkid").position.y, 0.10), "diesel generator rests on its skid")
	check(game.level.find_child("OverheadToyTrain", true, false) == null, "railway display no longer obscures relay signs")
	var mark = world.get_node("DieselGeneratorG02").find_child("BlueInspectionMark", true, false)
	await pose(Vector3(18.9, 0.05, mark.global_position.z), mark.global_position)
	game.player.lamp_on = true; game.player._update_reveal(0.8)
	check(float(mark.get_meta("exposure")) > 0.95 and mark.modulate.b > 0.95, "generator's blue ink reveals before relay power exists")
	game.player.lamp_on = false; game.player._update_reveal(1.2)
	check(float(mark.get_meta("exposure")) < 0.05, "blue ink fades when the lamp is off")
	await pose(Vector3(0, 0.05, -5), Vector3(0, 2.55, -9.55))
	game.player.lamp_on = true; game._process(0.001)
	check(game.level.marks[1].global_position.distance_to(Vector3(0, 2.55, -9.55)) < 0.01 and game.level.marks[1].is_visible_in_tree(), "rotor's blue clue is mounted in world space and reveals without relay power")
	await act(target("item", "generatorContact"), Vector3(-20.8, 0.05, -3.8))
	check(State.owns("generatorContact"), "generator contact is collectible")
	await act(target("generator"), Vector3(18.7, 0.05, 8.1))
	check(State.data.installed.has("generatorContact"), "G02 accepts the contact")
	await act(target("cell"), Vector3(-4.9, 0.05, 7), true)
	check(State.flag("relayCellHeld"), "R17 leaves its service dock")
	await act(target("socket"), Vector3(8, 0.05, 0.8), true)
	check(State.flag("relayPower"), "new socket installs R17 and powers the relay")
	for i in range(3):
		for turns in range(([2, 1, 3][i] - int(State.data.rotors[i]) + 4) % 4):
			game.player.active = true; game.claw_cooldown = 0; game._interact(target("rotor", str(i)), true); game.player.active = false
	await act(target("lever"), Vector3(3.2, 0.05, -11.2), true)
	check(State.flag("relaySolved"), "rebuilt lever unlocks the solved relay")
	await pose(Vector3(-8, 0.05, 15.0), Vector3(-8, 0, 19))
	check(await walk(Vector3(-8, -4, 29.1)), "memory staircase is physically descendable")
	check(await walk(Vector3(-8, -4, 35.0)), "landing connects to the memory chamber")
	await act(target("recall", "start"), Vector3(-8, -3.95, 34.5))
	check(memory.phase == "playback", "the console starts an audible spatial sequence")
	var paused_beat = memory.beat; memory._process(3.0)
	check(is_equal_approx(memory.beat, paused_beat), "memory timing pauses with player controls")
	game.player.active = true; memory._process(4.0); game.player.active = false
	# Drive the complete timed playback, including pauses between symbols.
	for i in range(40): game.player.active = true; memory._process(0.25); game.player.active = false
	check(memory.phase == "response", "playback opens the response window")
	memory.interact("3")
	check(memory.phase == "failed" and memory.pressure > 0, "wrong answers advance the duct threat and allow a retry")
	for retry in range(3):
		memory.interact("start")
		for i in range(60):
			if memory.phase == "response": break
			game.player.active = true; memory._process(0.20); game.player.active = false
		memory.interact("3")
	check(memory.phase == "attack" and State.data.sanity <= 88, "repeated mistakes trigger a damaging mascot lunge")
	game.player.active = true; memory._process(1.0); game.player.active = false
	memory.interact("start")
	for round_number in range(3):
		for i in range(60):
			if memory.phase == "response": break
			game.player.active = true; memory._process(0.20); game.player.active = false
		check(memory.phase == "response", "round %d playback completes" % (round_number + 1))
		var answers = memory.expected.duplicate()
		if round_number == 1: check(answers == [2, 0, 3, 1], "second round reverses the playback order")
		if round_number == 0:
			await act(target("recall", str(answers[0])), Vector3(-8, -3.80, 41.8), true)
			answers.pop_front()
		for answer in answers: memory.interact(str(answer))
		if round_number == 0:
			await game.enter_room("relay", false, false); game.player.active = false
			world = game.level.relay_world; memory = world.memory
			check(memory.round_index == 1 and memory.phase == "idle", "completed rounds persist when leaving and re-entering relay")
			await pose(Vector3(-8, -3.8, 41.8), Vector3(-8, -1.5, 36))
			memory.interact("start")
		elif round_number < 2: game.player.active = true; memory._process(2.1); game.player.active = false
	check(State.flag("memorySolved") and not world.get_node("MemoryServiceShutter").visible, "three rounds open the real service shutter")
	await pose(Vector3(-8, -3.95, 35.0), Vector3(-8, -2.5, 29))
	check(await walk(Vector3(-8, -4, 29.1)), "return from memory to landing")
	check(await walk(Vector3(8, -4, 29.1)), "landing joins both lower wings")
	check(await walk(Vector3(8, 0, 15.0)), "service staircase can be climbed with the actual player capsule")
	await pose(Vector3(8, 0.05, 15), Vector3(8, -2, 29))
	check(await walk(Vector3(8, -4, 29.1)) and await walk(Vector3(12, -4, 29.1)) and await walk(Vector3(12, -4, 48.8)), "stairs and service room provide a complete walkable exit route")
	game.test_mode = false
	await act(target("recall", "service"), Vector3(12, -3.95, 48.8))
	check(game.narrative.running and game.narrative.clip == "ambush" and game.narrative.expansion.path.all(func(p): return p.y < -3.8), "service exit starts the real ambush entirely on B1")
	game.narrative.set_process(false)
	for i in range(80):
		if not game.narrative.running: break
		game.narrative.advance(0.1); await get_tree().process_frame
	await get_tree().process_frame; await get_tree().process_frame
	check(State.data.room == "pursuit", "service exit enters the existing chase chapter")
	print("KALA REVISION15: %d checks, %d failures" % [checks, failures])
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.4).timeout
	get_tree().quit(0 if failures == 0 else 1)
