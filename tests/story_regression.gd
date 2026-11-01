extends Node

var checks = 0
var failures = 0
var game: Node3D

func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("STORY PASS: " + label)
	else: failures += 1; push_error("STORY FAIL: " + label)

func _ready() -> void:
	State.save_enabled = false
	State.reset()
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	State.reset()
	game.playing = true; game.ui.close_panel()
	await game.enter_room("school", false, false)
	game.narrative.start("intro")
	var movie = game.narrative
	movie.set_process(false)
	check(movie.running and movie.clip == "intro", "legacy checkpoint retains authored school confrontation")
	check(not game.player.active and not game.ui.hud.visible and game.ui.cinematic_hint.visible, "cutscene locks movement and displays skip control")
	movie.advance(3.1)
	check(game.level.get_node("NPC_Raka").position.distance_to(Vector3(-0.5, 0, -8.5)) < 0.01, "Raka moves to original confrontation position")
	check(game.ui.subtitle.text.contains("RAKA:"), "original dialogue advances on timeline")
	var skip = InputEventKey.new()
	skip.keycode = KEY_E
	skip.physical_keycode = KEY_E
	skip.pressed = true
	get_viewport().push_input(skip)
	await get_tree().process_frame
	skip.pressed = false
	get_viewport().push_input(skip)
	check(not movie.running and State.flag("introSeen") and game.player.active, "E skips movie and restores playable controls")
	print("LEGACY RESTORE actual=", game.player.position, " expected=", movie.player_pose.origin)
	check(game.player.position.distance_to(movie.player_pose.origin) < 0.1, "intro returns player to pre-scene position")
	check(game.level.get_node("NPC_Raka").position.distance_to(Vector3(0.5, 0, -19)) < 0.01, "intro restores NPC exploration positions")
	var sari = game.level.get_node("NPC_Sari") as Node3D
	var ray = PhysicsRayQueryParameters3D.create(sari.position + Vector3(-2, 0.9, 0), sari.position + Vector3(0, 0.9, 0), 16)
	await get_tree().physics_frame
	var hit = game.get_world_3d().direct_space_state.intersect_ray(ray)
	check(not hit.is_empty() and hit.collider.name == "ContactBody", "Sari has a physical contact body")
	check(game.player.collision_mask & 16 != 0, "player collides with NPCs")
	game.player.heat = 1.0
	game.player.cooldown = 2.2
	for i in range(133): game.player.update_lamp_temperature(1.0 / 60)
	check(game.player.cooldown <= 0.001 and game.player.heat < 0.01, "full overheat cooldown removes accumulated heat")
	game.player.add_beam_heat(1.0 / 60)
	check(game.player.cooldown == 0, "recovered lamp does not immediately overheat again")
	game.player.active = false
	game.player.cooldown = 1
	game.player._physics_process(0.8)
	check(game.player.cooldown == 1, "paused player freezes cooldown")
	game.test_mode = true
	await game.enter_room("street", false, false)
	State.data.puzzles.fuse.solved = true
	check(movie.start("warehouse"), "warehouse invitation starts in street")
	movie.set_process(false)
	movie._gait(0.8, 0.6)
	movie.actor.animator.advance(0.35)
	check(movie.actor.skeleton!=null and movie.actor.animator.current_animation.ends_with("|Walk") and movie.actor.walking>0, "imported Danu uses the skinned walk animation during story movement")
	movie.advance(8)
	check(movie.actor.position.z > 27.3, "Danu walks through warehouse entrance")
	check(absf(game.level.all_doors.streetLeft.node.rotation.y) > 1, "authored double entrance opens")
	movie.finish()
	check(State.flag("warehouseEntrySeen") and game.player.active, "warehouse sequence ends without locking controls")
	await game.enter_room("loading", false, false)
	State.give("maintenanceKey")
	game.player.active = true
	var door: KalaInteractable
	for object in get_tree().get_nodes_in_group("interactables"):
		if game.level.is_ancestor_of(object) and object.action_id == "door" and object.parameter == "1": door = object; break
	game._interact(door, false)
	check(State.flag("door_loading_1"), "opened annex door is recorded in saved state")
	await game.enter_room("office", false, false)
	await game.enter_room("loading", false, false)
	check(game.level.door_pivots[1].get_meta("opened"), "annex door stays open after returning to room")
	await game.enter_room("office", false, false)
	State.data.puzzles.breaker.solved = true
	check(movie.start("office"), "office confrontation uses native actor")
	movie.set_process(false)
	movie.advance(10.5)
	check(movie.actor.position.z < -8.5, "Danu retreats toward ritual stairs")
	movie.finish()
	check(State.flag("officeExitSeen") and game.player.active, "office movie completes safely")
	await game.enter_room("corridor", false, false)
	check(movie.start("corridor"), "corridor chase starts once")
	movie.set_process(false)
	movie.advance(8.9)
	check(game.player.position.z < -17 and movie.slammed, "corridor run moves camera and slams exit")
	movie.advance(4.2)
	check(not movie.running and State.flag("exitLocked") and State.flag("danuChaseSeen"), "corridor sequence locks exit and records completion")
	check(game.player.active and absf(game.player.position.z + 17.55) < 0.1, "corridor returns control at safe authored position")
	check(not movie.start("corridor"), "completed chase is not replayed")
	await game.enter_room("daisy", false, false)
	check(game.player.lamp.light_energy < 0.2, "Daisy flashlight uses dim source profile")
	print("KALA STORY: %d checks, %d failures" % [checks, failures])
	game.playing = false; game.narrative.cancel(); game.boss_revision.cancel()
	game.audio.shutdown()
	await get_tree().create_timer(0.6).timeout
	game.queue_free(); await get_tree().process_frame; await get_tree().physics_frame
	get_tree().quit(0 if failures == 0 else 1)
