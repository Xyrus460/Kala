extends Node
var game: Node3D
var checks = 0
var failures = 0

func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("PASS: ", label)
	else: failures += 1; push_error("FAIL: " + label)

func room(id: String) -> void:
	game.boss_revision.cancel()
	game.cinematic = false; game.ui.close_panel(); game.playing = true
	await game.enter_room(id, false, false)
	game.player.active = false; game.level.set_process(false)
	if is_instance_valid(game.boss): game.boss.enabled = false
	await get_tree().physics_frame

func _ready() -> void:
	State.save_enabled = false
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; await get_tree().physics_frame
	game.test_mode = true; game.playing = true; game.ui.close_panel()
	await game.new_game()
	check(game.level.has_node("FurnishedHome/LivingSofa"), "prologue contains finished living room furniture")
	var mother = game.level.get_node("Mother")
	var animated_mother = false
	for animation in mother.find_children("*", "AnimationPlayer", true, false):
		if animation.is_playing(): animated_mother = true
	check(mother.get_meta("asset_source").ends_with("mother.glb") and animated_mother, "mother uses an imported character with a live idle animation at vanity")
	await room("school")
	var friend = game.level.get_node("EnvironmentalDetail/Classmate_0")
	check(friend.seated and absf(friend.hips[0].rotation.x + PI / 2) < 0.01 and absf(friend.knees[0].rotation.x - PI / 2) < 0.01, "classmate sits with articulated thigh and shin")
	check(friend.position.y == 0 and game.level.get_node("NPC_Sari").has_method("sit"), "baked NPCs are replaced without sinking into floor")
	await room("schoolyard")
	check(game.level.has_node("ConnectedStreet") and game.level.safety.contains(Vector3(0, 0, 30), 0.4) and game.level.safety.contains(Vector3(26, 0, 54), 0.4), "school gate, road and alley share one continuous playable level")
	check(game.get_node("WorldEnvironment").environment.sky.sky_material.panorama != null, "cloud sky is active")
	State.set_flag("schoolDismissed"); game.chapter_flow.interact("school_gate")
	check(State.data.room == "schoolyard", "school gate no longer changes to a disconnected street scene")
	State.set_flag("lenteraOwned")
	game.player.bind_grace = 0; game.player.bind_player(); game.player.struggle = 3; game.player.bind_player()
	check(game.player.struggle == 3, "multiple homing hands cannot reset the escape button progress")
	game.player.release_bind()
	await room("production"); game._start_fight("hands")
	var b = game.boss
	check(b.visual.has_node("RepairedSculpt") and b.hands_rig.skeleton.get_bone_count() >= 80, "supplied sculpt with full skeleton replaces six-arm boss")
	check(b.hands_rig.bone_arms.all(func(index): return index >= 0), "all six imported arm bones are bound for native animation")
	b.phase = 2; game.boss_revision.phase_changed(2)
	check(game.boss_revision.pending_hands.size() >= 4, "phase two warns about a multidirectional hand wave")
	game.boss_revision.update_hazards(3)
	check(game.projectiles.size() >= 4 and game.projectiles[0].node.name.begins_with("SeekingHand"), "hand wave creates actual fingered homing hands")
	var projectile = game.projectiles[0]; var before: Vector3 = projectile.velocity
	game.player.position = Vector3(0, 0.05, 0); game._update_projectiles(0.1)
	check(not (projectile.velocity as Vector3).is_equal_approx(before), "hand adjusts flight toward live player")
	await room("ritual")
	check(game.boss.visual.has_node("BackPortal") and game.boss.visual.get_node("BackPortal").position.z < 0, "final boss has visible body and portal behind it")
	game.boss.begin_phase(2); game.boss_revision.slime_wave()
	check(game.boss_revision.hazards.size() >= 8, "phase two coats the arena with visible slime pools")
	var h = game.boss_revision.hazards[0]; game.player.position = h.node.position; State.data.sanity = 100
	game.boss_revision.update_hazards(2)
	check(State.data.sanity < 90, "standing in active slime takes damage per second")
	game.player.position = Vector3(0, 0.3, 0); var hp: float = State.data.sanity; game.boss_revision.update_hazards(1)
	check(is_equal_approx(State.data.sanity, hp), "safe elevated ground avoids slime damage")
	game.boss.begin_phase(3)
	check(game.boss_revision.mode == "center" and game.boss.scripted_motion, "phase three stops normal combat and sends boss to center")
	game.boss_revision.update_scene(8)
	check(game.boss_revision.mode == "fog" and game.cinematic, "fog scene locks player movement")
	check(game.boss.visual.get_node("BackPortal").has_node("PortalFogEmitter"), "phase three smoke visibly emits from the back portal")
	game.boss_revision.update_scene(3)
	check(game.get_node("WorldEnvironment").environment.fog_density > 0.05, "hallucination fog fills arena")
	game.boss_revision.update_scene(4.1)
	for i in range(180):
		await get_tree().process_frame
		if not game.entering and State.data.room == "hallucination": break
	check(State.data.room == "hallucination" and game.boss_revision.mode == "chase" and game.player.active, "fog transitions into controllable hallucination chase")
	game.player.active = false; game.boss_revision.set_process(false)
	check(game.level.nav_extra.size() >= 9 and game.level.has_node("FracturedMemories/MemoryAltar3"), "chase contains obstacles, scenery and four evidence altars")
	var p = game.level.actor_path(Vector3(0, 0, 3), Vector3(0, 0, -98))
	check(p.size() > 150, "continuous navigation reaches chase finale")
	game.player.set_physics_process(false); game.set_process(false)
	var blocked = false
	for point in p:
		var next = Vector3(point.x, 0.05, point.y)
		var movement: Vector3 = next - game.player.position
		movement.y = 0
		if movement.length() > 0.1:
			if game.player.test_move(game.player.global_transform, movement): blocked = true; break
			game.player.position = next
	check(not blocked and game.player.position.z < -97, "player capsule can traverse every chase path segment without crossing solid scenery")
	game.set_process(true); game.player.set_physics_process(true)
	for i in range(4):
		var altar = game.level.get_node("FracturedMemories/MemoryAltar%d" % i)
		game.player.position = altar.position + Vector3(0, 0.05, 1.8)
		game.player.camera.look_at(altar.position + Vector3(0, 1.2, 0.5))
		game.player.active = true
		for frame in range(3): await get_tree().physics_frame
		check(is_instance_valid(game.player.target) and game.player.target.action_id == "memory" and game.player.target.parameter == str(i), "memory altar %d accepts the real interaction ray" % i)
	game.player.active = false
	State.data.evidence.clear()
	game.boss_revision.remember(0)
	check(game.boss_revision.anchors.is_empty(), "missing evidence cannot be invented at an altar")
	for id in ["A", "op1", "op2", "B"]: State.collect(id)
	for i in range(4): game.boss_revision.remember(i)
	check(game.boss_revision.anchors.size() == 4, "all four collected evidence pieces can be used")
	game.boss_revision.remember(0)
	check(game.boss_revision.anchors.size() == 4, "same evidence cannot count twice")
	game.boss_revision.resolve_chase()
	check(game.boss_revision.mode == "banish" and State.flag("hallucinationDefeated"), "four evidence pieces defeat nightmare")
	game.boss_revision.update_scene(4.1)
	for i in range(180):
		await get_tree().process_frame
		if not game.entering and State.data.room == "ritual": break
	check(State.flag("tumbalDefeated") and State.flag("danuHumanReturned") and State.data.room == "ritual", "successful hallucination restores Danu and original story exit")
	await room("hallucination"); game.boss_revision.set_process(false); game.player.active = false
	State.data.evidence.erase("op2")
	for i in range(4): game.boss_revision.remember(i)
	game.boss_revision.resolve_chase()
	check(game.boss_revision.mode == "portal", "three evidence pieces lead to portal jumpscare")
	game.boss_revision.update_scene(3.5)
	check(game.boss_revision.mode == "human_escape" and is_instance_valid(game.boss_revision.human), "bad branch returns Danu to human and stages player pursuit")
	game.boss_revision.update_scene(5.1)
	check(game.outcome == "consumed" and not game.playing, "portal bad ending is terminal")
	await room("pursuit")
	game.test_mode = false; State.set_flag("escapePuzzleSolved"); game.narrative.start("rescue"); game.narrative.set_process(false)
	game.narrative.advance(8.6)
	var movie = game.narrative.expansion
	check(is_instance_valid(movie.rescue_button) and movie.rescue_button.position.x < game.player.position.x, "Daisy rescue button is behind escape direction")
	check(movie.shadow.arms[1].rotation.z > 1 and movie.rescue_button.get_node("ButtonCap").position.z < 0.04, "animated shadow visibly reaches and depresses safety button")
	check(movie.shadow.elbows[1].get_node("Palm").global_position.distance_to(movie.rescue_button.get_node("ButtonCap").global_position) < 0.24, "shadow palm actually reaches the depressed button")
	var view = PhysicsRayQueryParameters3D.create(game.player.camera.global_position, movie.rescue_button.position + Vector3(0.13, 0, 0), 1)
	check(game.get_world_3d().direct_space_state.intersect_ray(view).is_empty(), "Daisy safety button is visible from cinematic camera")
	game.narrative.finish()
	await room("daisy")
	var daisy = game.level.doll
	check(daisy.doll and daisy.find_children("CurledPigtail*", "Node3D", true, false).size() == 2, "Daisy has golden curly pigtails and sculpted doll face")
	print("KALA REVISION06: %d checks, %d failures" % [checks, failures])
	game.boss_revision.cancel()
	game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame
	await get_tree().create_timer(0.3).timeout
	get_tree().quit(0 if failures == 0 else 1)
