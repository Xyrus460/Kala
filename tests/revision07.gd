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
	await game.enter_room(id, false, false)
	game.player.active = false
	if is_instance_valid(game.boss): game.boss.enabled = false
	await get_tree().physics_frame

func walk(point: Vector3) -> bool:
	game.player.active = true; game.player.set_physics_process(false)
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
	State.save_enabled = false; Engine.physics_ticks_per_second = 240
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode = true; game.playing = true; game.ui.close_panel()
	State.set_flag("prologueVersion")
	await room("home")
	game.level.chapter_world.doors.bedroom.open = true
	for i in range(100): game.level.chapter_world.update(1.0 / 60)
	game.player.position = Vector3(-4.4, 3.25, 1.2); game.player.last_safe_position = game.player.position
	check(await walk(Vector3(-4.4, 3.2, 3.9)), "walk out of bedroom through its actual door")
	check(await walk(Vector3(0, 3.2, 3.9)), "landing connects bedroom to stairs without holes or obstruction")
	check(await walk(Vector3(0, 0.0, 10.5)), "descend whole stair flight from landing")
	check(await walk(Vector3(-2, 0, 10.5)) and await walk(Vector3(0, 0, 10.5)), "turn past the last stair post without invisible railing overhang")
	check(await walk(Vector3(0, 3.2, 3.9)), "climb whole stair flight and reconnect to landing")
	check(await walk(Vector3(4.4, 3.2, 3.9)), "landing connects second bedroom too")
	await room("school"); State.set_flag("lenteraOwned")
	game.player.reach_time = 2; game.player.anchored = true; game.player.active = true
	game.player._physics_process(1.0 / 60)
	check(not game.player.cable.visible and not game.player.can_use_claw(), "stale cable cannot appear or fire at school")
	game.player.active = false
	var poses = {}
	for identity in ["Danu", "Raka", "Sari", "Adit"]: poses[identity] = game.level.get_node("NPC_" + identity).transform
	check(game.narrative.start("lesson"), "lesson starts from live school state")
	game.narrative.set_process(false); game.narrative.advance(2)
	check(game.level.get_node("NPC_Danu").seated and game.level.get_node("NPC_Raka").seated, "main cast starts seated at desks")
	game.narrative.advance(24)
	var danu = game.level.get_node("NPC_Danu"); var raka = game.level.get_node("NPC_Raka")
	check(not danu.seated and not raka.seated and danu.position.distance_to(raka.position) < 1.0, "bullying stands in clear aisle within reach")
	var q = PhysicsRayQueryParameters3D.create(danu.position + Vector3.UP, raka.position + Vector3.UP, 1)
	check(game.get_world_3d().direct_space_state.intersect_ray(q).is_empty(), "no desk or wall intersects confrontation")
	game.narrative.finish()
	for identity in poses:
		var npc = game.level.get_node("NPC_" + identity)
		check(npc.transform.is_equal_approx(poses[identity]) and not npc.seated and npc.get_node("ContactBody").collision_layer == 16, "restore pose and collision: " + identity)
	await room("relay"); State.data.flags.erase("lenteraOwned"); State.data.flags.erase("lenteraPickupSeen")
	check(game.narrative.start("pickup"), "pickup cinematic starts")
	game.narrative.finish()
	check(State.flag("lenteraOwned") and game.ui.mode == "tutorial" and not game.player.active, "pickup automatically opens tutorial and pauses gameplay")
	check(game.ui.tutorial.video.stream != null and game.ui.tutorial.video.is_playing(), "bundled tutorial video plays")
	game._close()
	check(State.flag("lenteraGuideSeen") and game.player.active, "continue closes tutorial and restores controls")
	game.ui.show_journal(); game._ui_action("tutorial", "")
	check(game.ui.mode == "tutorial", "tutorial can be replayed from journal")
	game._close()
	await room("production"); game._start_fight("hands"); game.boss.enabled = false
	var rig = game.boss.hands_rig
	var grounded = true
	for i in range(120):
		rig.animate(1.0 / 60, 2.5 / 60, false, 0.65)
		var floor_y = minf(rig.skeleton.get_bone_global_pose(rig.bone_feet[0]).origin.y, rig.skeleton.get_bone_global_pose(rig.bone_feet[1]).origin.y) + rig.sculpt.position.y
		if absf(floor_y - rig.foot_floor) > 0.025: grounded = false
	check(grounded and absf(game.boss.visual.rotation.x) < 0.01, "six-arm rig stays upright with planted soles throughout gait")
	await room("ritual"); game.boss_revision.set_process(false)
	check(game.boss.visual.get_meta("final_reference", false) and not game.boss.visual.find_child("FinalCore", true, false).visible, "reference mask and halo are unobstructed by oversized core")
	State.collect("op1"); game._process(0)
	check(game.ui.evidence_list.visible and game.ui.evidence_list.text.contains("■ sobekan foto"), "evidence remains top-left during boss combat")
	game.boss.position = Vector3(10, 0.05, 8); game.boss.begin_phase(3)
	check(game.cinematic and not game.player.active, "phase three freezes combat immediately")
	game.boss_revision.update_scene(1.2)
	check(game.boss_revision.mode == "fog" and game.boss.position.distance_to(Vector3(0, 0.05, 0)) < 0.01, "center transition completes in 1.2 seconds even from far corner")
	check(game.boss_revision.visions.size() == 6 and game.boss_revision.visions.all(func(v): return v.get_meta("final_reference", false)), "six copies of reference final boss surround player")
	game.boss_revision.update_scene(4.01)
	for i in range(180):
		await get_tree().process_frame
		if State.data.room == "hallucination" and not game.entering: break
	game.player.active = false
	check(State.data.room == "hallucination" and game.boss_revision.visions.is_empty(), "short transition cleans visions and starts playable chase")
	check(game.boss_revision.rig.parts.has("FinalHead"), "hallucination uses matching final boss rig")
	await room("daisy")
	check(game.level.get_node("DaisyRoomVolume") is FogVolume and game.level.get_node("DaisyFloorVolume") is FogVolume, "Daisy fog occupies real room and floor volumes")
	check(game.level.get_node("DaisyRoomVolume").material.shader.code.contains("WORLD_POSITION"), "fog samples world-space 3D noise with realtime drift")
	print("KALA REVISION07: %d checks, %d failures" % [checks, failures])
	game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if failures == 0 else 1)
