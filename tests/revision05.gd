extends Node

var game: Node3D
var checks = 0
var failures = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("REV05 PASS: " + label)
	else: failures += 1; push_error("REV05 FAIL: " + label)

func _ready() -> void:
	State.save_enabled = false; State.save_path = "user://kala_revision05_test.json"
	Engine.physics_ticks_per_second = 240
	Engine.time_scale = 4.0
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame
	game.test_mode = true
	if OS.get_cmdline_user_args().has("--motion-only"):
		game.playing = true; game.ui.close_panel()
		await pursuit()
		print("KALA MOTION05: %d checks, %d failures" % [checks, failures])
		await game.quit_game(); get_tree().quit(0 if failures == 0 else 1); return
	check(game.ui.mode == "title" and game.title_set.camera.current, "title uses native 3D set and dedicated camera")
	game._ui_action("title_background", "")
	check(game.title_set.variant == 1 and game.title_set.factory.visible, "factory and school menu backdrops switch")
	game.test_mode = false
	await game.new_game()
	check(State.data.room == "home" and State.flag("prologueVersion"), "new game begins in upstairs bedroom")
	check(not game.title_set.visible and game.player.camera.current, "gameplay owns camera after leaving title")
	check(game.narrative.running and game.narrative.clip == "wake_home", "new game automatically starts waking scene")
	game.narrative.finish()
	check(State.flag("homeAwake") and game.player.active, "waking scene returns controls")
	await use("chapter", "leave_home")
	check(State.data.room == "home", "cannot leave before washing")
	await use("chapter", "door_father")
	check(not game.level.chapter_world.doors.father.open, "father door stays locked")
	check(game.level.chapter_world.doors.mother.open and game.level.has_node("Mother"), "mother visible through partly open door")
	await use("chapter", "door_bedroom")
	check(game.level.chapter_world.doors.bedroom.open, "bedroom door actually opens")
	for i in range(100): game.level.chapter_world.update(1.0 / 60)
	game.player.position = Vector3(0, 3.25, 3.0); game.player.last_safe_position = game.player.position
	check(await walk_to(Vector3(0, 0.05, 10.7), 220), "player descends real staircase to three-way landing")
	await use("chapter", "door_bathroom")
	for i in range(90): game.level.chapter_world.update(1.0 / 60)
	check(await walk_to(Vector3(-5, 0.05, 10.7), 160) and await walk_to(Vector3(-5, 0.05, 6), 140) and await walk_to(Vector3(-5, 0.05, 2), 140), "right turn after fully clearing the last stair post reaches bathroom through physical doorway")
	await use("chapter", "wash")
	check(game.narrative.running and game.narrative.clip == "wash", "bathroom plays morning preparation")
	game.narrative.finish()
	check(State.flag("homeReady"), "washing unlocks school departure")
	Input.action_press("crouch")
	game.player.active = true
	await get_tree().physics_frame; await get_tree().physics_frame
	check(game.player.crouched and game.player.get_node("Collider").shape.height < 1.0, "Ctrl changes actual player capsule")
	Input.action_release("crouch")
	await get_tree().physics_frame; await get_tree().physics_frame
	check(not game.player.crouched, "Ctrl release restores standing in open space")
	await use("chapter", "leave_home"); await settled("schoolyard")
	check(State.data.room == "schoolyard", "ready player reaches school gate and explorable courtyard")
	await use("chapter", "trash_photo")
	check(not State.data.evidence.has("op1"), "photo investigation begins after classroom incident")
	await use("chapter", "enter_school"); await settled("school")
	check(game.narrative.running and game.narrative.clip == "lesson", "entering school automatically starts class lesson")
	game.narrative.set_process(false); game.narrative.advance(23)
	check(not game.level.get_node("EnvironmentalDetail/Teacher").visible, "teacher leaves after being called")
	check(game.level.get_node("NPC_Raka").position.distance_to(game.level.get_node("NPC_Danu").position) < 1, "bullying is staged inside classroom")
	check(game.level.get_node("NPC_Sari").position.z > 6 and game.level.get_node("NPC_Sari").position.z < 14, "Sari and Adit intervene in front of classmates")
	game.narrative.finish()
	check(State.flag("lessonSeen") and State.flag("introSeen"), "lesson completes and unlocks investigation")
	game.test_mode = true
	await use("npc", "Danu"); game._close()
	check(not State.flag("invited"), "Danu does not invite without two school evidence items")
	check(not game.level.safety.contains(Vector3(16, 0, -20), 0.3), "empty black area behind classrooms is excluded")
	game.player.position = Vector3(0, 0.05, -28.8)
	await get_tree().physics_frame
	check(game.player.test_move(game.player.global_transform, Vector3(0, 0, -5)), "physical exit seal stops sprinting through map boundary")
	await use("evidence", "op2"); game._close()
	await use("exit"); await settled("schoolyard")
	check(State.data.room == "schoolyard" and game.player.position.z < -10, "school can be revisited from courtyard before dismissal")
	await use("chapter", "trash_photo")
	check(State.data.evidence.has("op1") and game.ui.mode == "photo", "trash bin contains manually inspectable Danu Raka photograph")
	game._close()
	await use("chapter", "enter_school"); await settled("school")
	await use("npc", "Danu"); game._close()
	check(State.flag("invited") and game.chapter_flow.school_evidence_count() == 2, "two evidence items unlock Danu directions")
	await use("chapter", "return_class")
	check(game.narrative.running, "player must return to class before going home")
	game.narrative.finish()
	check(State.flag("schoolDismissed"), "final lesson advances to dismissal")
	await use("exit"); await settled("schoolyard")
	await use("chapter", "school_gate")
	check(State.data.room == "schoolyard" and game.level.has_node("ConnectedStreet"), "dismissal continues through gate to connected street in same level")
	await use("chapter", "alley"); await settled("street")
	check(State.data.room == "street" and State.flag("choseRight"), "right-hand alley reconnects original factory storyline")
	await game.enter_room("corridor", false, false)
	game.player.position = Vector3(0, 0.05, -18.7); game.player.active = false
	game.level.all_doors.corridor.node.rotation.y = 1.4
	await get_tree().physics_frame
	check(game.player.test_move(game.player.global_transform, Vector3(0, 0, -5)), "factory exit remains physically sealed even with visual door forced open")
	await pursuit()
	await jumpscare()
	await game.quit_game()
	print("KALA REVISION05: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func use(action: String, parameter = "") -> void:
	game.player.active = true
	for target in get_tree().get_nodes_in_group("interactables"):
		if game.level.is_ancestor_of(target) and target.action_id == action and target.parameter == parameter:
			game._interact(target, false); return
	check(false, "interaction exists: " + action + " / " + parameter)

func settled(id: String) -> void:
	for i in range(180):
		if State.data.room == id and not game.entering: break
		await get_tree().process_frame

func walk_to(point: Vector3, frames: int) -> bool:
	game.player.active = true; game.player.set_physics_process(false)
	Input.action_press("forward"); Input.action_press("sprint")
	var reached = false
	for i in range(frames):
		var difference = point - game.player.position; difference.y = 0
		if difference.length() < 0.45: reached = true; break
		game.player.rotation.y = atan2(-difference.x, -difference.z)
		game.player._physics_process(1.0 / 60)
		await get_tree().physics_frame
	Input.action_release("forward"); Input.action_release("sprint")
	game.player.set_physics_process(true)
	if not reached: print("WALK STUCK: ", game.player.position, " target ", point)
	return reached

func pursuit() -> void:
	State.set_flag("lenteraOwned")
	await game.enter_room("pursuit", false, false)
	game.player.active = false; game.level.set_process(false)
	var enemy = game.boss; enemy.enabled = false; enemy.set_physics_process(false)
	for mesh_name in ["Source_3229", "Source_3235"]:
		var mesh = game.level.find_child(mesh_name, true, false) as MeshInstance3D
		if mesh != null: print("STAIR MESH ", mesh_name, " aabb=", mesh.get_aabb(), " transform=", mesh.global_transform)
	check(game.level.escape_puzzle.containers.size() == 7, "seven searchable desks lockers and cabinets replace glowing pickups")
	for pair in [["operator", "sun"], ["istirahat", "moon"], ["perkakas", "star"]]:
		var target: KalaInteractable
		for object in get_tree().get_nodes_in_group("interactables"):
			if game.level.is_ancestor_of(object) and object.action_id == "fragment" and object.parameter == pair[1]: target = object
		check(not target.available(), pair[1] + " hidden until furniture is opened")
		await use("search", pair[0])
		for i in range(80): game.level.escape_puzzle.update(1.0 / 60)
		check(target.available(), pair[1] + " revealed by actual furniture search")
		game.player.position = Vector3(-8.0 if target.position.x < 0 else 8.0, 0.05, target.position.z)
		game.player.last_safe_position = game.player.position; game.player.camera.look_at(target.position)
		for i in range(3): await get_tree().physics_frame
		game.player._physics_process(1.0 / 60)
		if game.player.target != target:
			print("PICKUP RAY ", pair[1], " hit=", game.player.ray.get_collider(), " at=", game.player.position, " available=", target.available())
			if game.player.ray.get_collider() is StaticBody3D: print("PICKUP BODY ", game.player.ray.get_collider().get_parent().get_path())
		check(game.player.target == target, pair[1] + " can be targeted through opened furniture")
		await use("fragment", pair[1]); game.player.active = false
	check(game.level.escape_puzzle.unlock(), "complete set unlocks physical service exit")
	State.set_flag("ventGrateOpen")
	for i in range(100): game.level._process(1.0 / 60)
	await get_tree().physics_frame
	# Real movement tests, with the player standing still beyond each obstacle.
	var cases = [
		[Vector3(0, 0.05, 57), Vector3(-8, 0.05, 38), 430, "first baffle"],
		[Vector3(-8, 0.05, 38), Vector3(8, 0.05, 19), 500, "second baffle"],
		[Vector3(20, 0.05, -58), Vector3(20, -2.35, -72), 1000, "service stairs descending"],
		[Vector3(20, -2.35, -72), Vector3(20, 0.05, -58), 1000, "service stairs ascending"],
		[Vector3(40, -2.35, -79), Vector3(40, -5.75, -103), 650, "first sloping vent"],
		[Vector3(40, -5.75, -103), Vector3(40, -2.35, -79), 650, "vent return uphill"],
		[Vector3(78, -5.75, -109), Vector3(78, -7.95, -123.5), 500, "final sloping vent"]]
	game.set_process(false); game.player.set_physics_process(false)
	for entry in cases:
		enemy.position = entry[0]; enemy.velocity = Vector3.ZERO; enemy.last_seen = entry[1]; enemy.memory = 100; enemy.nav_timer = 0; enemy.avoid_left = 0; enemy.stuck_seconds = 0
		game.player.position = entry[1]; enemy.enabled = true
		var reached = false
		for i in range(entry[2]):
			enemy._physics_process(1.0 / 60)
			await get_tree().physics_frame
			if enemy.position.distance_to(entry[1]) < 1.6: reached = true; break
		print("CHASE MOTION ", entry[3], " final=", enemy.position, " target=", entry[1])
		if not reached:
			print("CHASE DEBUG velocity=", enemy.velocity, " height=", enemy.body_collision.shape.height, " low=", enemy._low_ceiling(), " path=", enemy.path.size(), " index=", enemy.path_index, " next=", enemy.path[mini(enemy.path_index, enemy.path.size() - 1)] if not enemy.path.is_empty() else Vector2.ZERO)
			for c in range(enemy.get_slide_collision_count()):
				var hit = enemy.get_slide_collision(c)
				print("CHASE COLLISION ", hit.get_normal(), " ", hit.get_collider().get_parent().get_path(), " ", hit.get_collider().get_parent().global_position)
		check(reached, "pursuer traverses " + entry[3] + " with collision and gravity")
		enemy.enabled = false
	game.player.set_physics_process(true)
	game.set_process(true)
	enemy.position = Vector3(0, 0.05, 51); enemy.velocity = Vector3.ZERO
	game.player.position = Vector3(-3, 0.05, 32); game.player.velocity = Vector3.ZERO; game.player.crouched = true
	enemy.memory = 0; enemy.last_seen = Vector3(0, 0.05, 51); enemy.nav_timer = 0; enemy.enabled = true
	enemy._physics_process(1.0 / 60)
	check(enemy.searching and enemy.last_target.distance_to(game.player.position) > 5, "hidden silent player breaks pursuit and triggers search at last known location")
	enemy.enabled = false

func jumpscare() -> void:
	game.test_mode = false; game.playing = true; game.cinematic = false
	var preference = State.settings.scares; State.settings.scares = true
	var pose = game.player.camera.transform
	game.scare.start("caught"); game.scare.set_process(false)
	check(game.scare.running and game.cinematic and not game.player.active, "caught triggers actual native jumpscare before ending")
	game.scare._process(0.32)
	check(game.scare.monster.position.z > -1.3, "jumpscare monster lunges toward camera")
	game.scare._process(0.80)
	check(not game.scare.running and game.outcome == "caught" and game.ui.mode == "ending", "jumpscare safely hands off to retry menu")
	check(game.player.camera.transform.is_equal_approx(pose), "jumpscare restores camera transform")
	State.settings.scares = preference
