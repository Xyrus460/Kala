extends Node

var checks = 0
var failures = 0
var game: Node3D

func check(value: bool, label: String) -> void:
	checks += 1
	if value: print("CLAW PASS: " + label)
	else: failures += 1; push_error("CLAW FAIL: " + label)

func _ready() -> void:
	State.save_enabled = false
	State.reset()
	State.set_flag("lenteraOwned")
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	game.test_mode = true
	game.playing = true
	game.ui.close_panel()
	await game.enter_room("loading", false, false)
	game.player.position = Vector3(0, 0.1, 18)
	game._projectile(Vector3(0, 1.5, 14), Vector3.ZERO, "hand")
	game.player.camera.look_at(Vector3(0, 1.5, 14))
	var key = InputEventKey.new()
	key.keycode = KEY_R
	key.physical_keycode = KEY_R
	key.pressed = true
	get_viewport().push_input(key)
	check(game.projectiles.is_empty(), "R intercepts aimed hand projectile through player input")
	check(game.player.reach_time > 0 and game.player.reach_point.distance_to(Vector3(0, 1.5, 14)) < 0.1, "claw cable reaches intercepted projectile")
	key.pressed = false
	get_viewport().push_input(key)
	game._summon()
	var ash: KalaEnemy = game.minions[0]
	ash.enabled = false
	game.player.position = Vector3(-4, 0.1, 2)
	game.player.camera.look_at(ash.global_position + Vector3.UP * 1.05)
	game.player.reach_time = 0
	game.claw_cooldown = 0
	key.pressed = true
	get_viewport().push_input(key)
	check(ash.hp == 6, "claw removes reference six HP from ash minion")
	check(not game.resolve_claw_combat({"node": ash, "kind": "ash"}), "claw cooldown prevents repeated instant damage")
	key.pressed = false
	get_viewport().push_input(key)
	game.player.reach_time = 0
	game.claw_cooldown = 0
	key.pressed = true
	get_viewport().push_input(key)
	check(game.minions.is_empty(), "second claw hit removes defeated ash safely")
	key.pressed = false
	get_viewport().push_input(key)
	game._projectile(Vector3(18, 1.5, 0), Vector3.ZERO, "slime")
	game.player.position = Vector3(13, 0.1, 0)
	game.player.camera.look_at(Vector3(18, 1.5, 0))
	await get_tree().physics_frame
	var target: Dictionary = game.claw_combat_target(game.player.camera.global_position, -game.player.camera.global_basis.z)
	check(target.is_empty(), "solid room wall blocks remote projectile interception")
	game.audio.shutdown()
	await get_tree().create_timer(0.2).timeout
	game.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	print("KALA CLAW: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
