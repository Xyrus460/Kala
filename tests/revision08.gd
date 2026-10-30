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

func pose(p: Vector3, target: Vector3) -> void:
	game.player.position = p; game.player.last_safe_position = p
	game.player.camera.look_at(target); game.player.active = true
	await get_tree().physics_frame; await get_tree().physics_frame; await get_tree().physics_frame
	game.player.active = false

func walk(point: Vector3) -> bool:
	game.player.active = true; game.player.set_physics_process(false)
	game.player.camera.rotation = Vector3.ZERO
	Input.action_press("forward"); Input.action_press("sprint")
	var reached = false
	for i in range(450):
		var difference = point - game.player.position; difference.y = 0
		if difference.length() < 0.18: reached = absf(point.y - game.player.position.y) < 0.35; break
		game.player.rotation.y = atan2(-difference.x, -difference.z)
		game.player._physics_process(1.0 / 60)
		await get_tree().physics_frame
	Input.action_release("forward"); Input.action_release("sprint")
	game.player.set_physics_process(true); game.player.active = false
	if not reached: print("WALK FAILED ", game.player.position, " -> ", point)
	return reached

func _ready() -> void:
	State.save_enabled = false; State.reset(); Engine.physics_ticks_per_second = 240
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion")
	await room("home")
	game.player.position = Vector3(-4.4, 3.25, 1.2)
	check(game.player.test_move(game.player.global_transform, Vector3(0, 0, 2)), "closed imported bedroom door has actual collision")
	await pose(Vector3(-4.4, 3.25, 1), Vector3(-4.4, 4.3, 2.5))
	check(is_instance_valid(game.player.target) and game.player.target.parameter == "door_bedroom", "bedroom door accepts the real interaction ray")
	game.chapter_flow.interact("door_bedroom")
	for i in range(120): game.level.chapter_world.update(1.0 / 60)
	check(await walk(Vector3(-4.4, 3.2, 3.9)), "open replacement door can actually be walked through")
	check(await walk(Vector3(0, 3.2, 3.9)), "finished landing is continuous")
	check(await walk(Vector3(4.4, 3.2, 3.9)), "second floor leads to nursery")
	game.chapter_flow.interact("door_nursery")
	for i in range(120): game.level.chapter_world.update(1.0 / 60)
	check(await walk(Vector3(4.4, 3.2, 1.2)), "nursery door opens into furnished room without obstruction")
	check(game.level.get_node("FurnishedHome/BabyCrib").get_meta("asset_source").contains("innerscene"), "nursery uses downloaded real cot model")
	check(game.level.has_node("FurnishedHome/ChangingStation"), "nursery changing station is installed")
	check(await walk(Vector3(4.4, 3.2, 3.9)) and await walk(Vector3(0, 3.2, 3.9)), "return from nursery reaches stairwell")
	check(await walk(Vector3(0, 0, 10.6)), "enclosed stairwell preserves full headroom on descent")
	game.chapter_flow.interact("door_bathroom")
	for i in range(120): game.level.chapter_world.update(1.0 / 60)
	check(await walk(Vector3(-5, 0, 10.6)) and await walk(Vector3(-5, 0, 6)) and await walk(Vector3(-5, 0, 2.8)), "living furniture leaves a real route to bathroom")
	await pose(Vector3(-3.1, 0.05, 2), Vector3(-3.1, 1.05, 0.8))
	check(is_instance_valid(game.player.target) and game.player.target.parameter == "wash", "washing is reachable using actual interaction ray")
	check(game.level.get_node("FurnishedHome/Toilet").get_meta("asset_source").contains("toilet.glb"), "toilet is the imported sanitary model")
	var view_query = PhysicsRayQueryParameters3D.create(Vector3(5, 1.2, 7.2), Vector3(5, 1.2, 5.95), 1)
	check(game.get_world_3d().direct_space_state.intersect_ray(view_query).is_empty(), "furniture leaves mother doorway approach and view unobstructed")
	var mirrors = game.level.find_children("WorkingMirror*", "Node3D", true, false)
	check(mirrors.size() == 2, "bathroom and mother vanity both have working mirrors")
	var mirror = mirrors[1]
	var eye: Vector3 = game.player.camera.global_position
	var normal: Vector3 = mirror.global_basis.z.normalized()
	check(mirror.reflection.global_position.distance_to(eye - normal * normal.dot(eye - mirror.global_position) * 2) < 0.01, "mirror camera reflects current player position across real glass plane")
	check(mirror.surface.material_override.albedo_texture is ViewportTexture and mirror.reflection.cull_mask & (1 << 19) == 0, "mirror uses live rendered scene and excludes recursive glass")
	await pose(Vector3(0, 0.05, 11.7), Vector3(0, 1.25, 13.6))
	check(is_instance_valid(game.player.target) and game.player.target.parameter == "leave_home", "front door caption can be targeted without overlapping wall")
	game._pause(); await get_tree().process_frame
	check(game.ui.mode == "pause" and not game.player.active and game.ui.pause_menu.has_node("PauseObjectives"), "reference pause layout freezes player and displays live objective")
	var panel = game.ui.pause_menu
	var actions = panel.get_node("PauseActions").get_children()
	check(actions.size() == 6 and actions[1].text == "ULANG CHECKPOINT" and actions[2].text == "MUAT GAME", "pause menu exposes resume, retry, load, save, settings and title")
	actions[3].pressed.emit()
	check(panel.get_node("SaveStatus").text == "Checkpoint tersimpan.", "save button gives visible feedback while game remains paused")
	actions[0].pressed.emit()
	check(game.ui.mode == "" and game.player.active, "resume button restores live gameplay")
	game._ui_action("credits", "")
	var credited = false
	for child in game.ui.content.get_children():
		if child is Label and child.text.contains("Innerscene") and child.text.contains("DREAM_SEARCH_REPEAT"): credited = true
	check(credited, "credits screen names the free asset authors")
	game._close()
	await room("schoolyard")
	check(game.campus.rooms.school.has_node("ExplorableSchool/GroundedSchoolFoundation"), "campus facade belongs to the same grounded, explorable school")
	check(game.level.get_node("RepeatingNeighborhood").get_child_count() > 100, "repeated houses fill the surrounding campus skyline")
	var invisible = true
	for mesh in game.level.get_node("MapBoundary").find_children("*", "MeshInstance3D", false, false):
		if mesh.visible: invisible = false
	check(invisible, "entire outdoor perimeter stays invisible")
	for p in [Vector3(-28.3, 0.05, 30.5), Vector3(28.3, 0.05, 30.5), Vector3(0, 0.05, 37.3)]:
		game.player.position = p
		var direction = Vector3(signf(p.x) * 3, 0, 0) if absf(p.x) > 20 else Vector3(0, 0, 3)
		check(game.player.test_move(game.player.global_transform, direction), "invisible perimeter physically stops player at " + str(p))
	check(game.level.get_node("ConnectedStreet/ParkedMotorcycle0").get_meta("asset_source").contains("motorcycle.glb"), "parked motorcycles use imported geometry")
	game.player.position = Vector3(0, 0.05, -10)
	check(await walk(Vector3(0, 0, -13.0)), "school porch and open doors do not obstruct approach to entrance")
	await room("school")
	var clean = true
	for mesh in game.level.get_node("SchoolFurnishings").find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		if absf(b.get_center().x + 1.84) < 0.1 and b.position.y > 0.8 and b.end.y < 1.3 and b.position.z < 10 and b.end.z > 9: clean = false
	check(clean, "no new corridor rail crosses class doorway")
	check(game.level.has_node("EnvironmentalDetail/AlignedDesk00/SchoolDesk"), "classroom uses free imported school desk")
	game.player.position = Vector3(0.3, 0.05, 9.7); game.player.last_safe_position = game.player.position
	check(await walk(Vector3(-3.3, 0, 9.7)), "player can walk through actual classroom opening")
	print("KALA REVISION08: %d checks, %d failures" % [checks, failures])
	game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if failures == 0 else 1)
