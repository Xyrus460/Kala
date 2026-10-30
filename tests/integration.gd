extends Node

var failures = 0
var checks = 0
var game: Node3D
var original_save = ""
var had_save = false

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)
	else: print("PASS: " + label)

func _ready() -> void:
	# The suite restores the user's save even when a check fails.
	State.save_path = "res://tests/kala_integration_tmp.json"
	had_save = FileAccess.file_exists(State.save_path)
	if had_save: original_save = FileAccess.get_file_as_string(State.save_path)
	State.save_enabled = false
	game = preload("res://scenes/main/main.tscn").instantiate()
	add_child(game)
	await get_tree().process_frame
	await get_tree().physics_frame
	game.test_mode = true
	game.playing = true
	game.ui.close_panel()
	game._sync_active()
	check(game.story.evidence.size() == 4, "four evidence records extracted")
	check(game.story.notes.size() >= 25, "source documents extracted")
	check(game.story.dialogues.Sari.before.contains("2 sama 9"), "Sari retains code clue")
	check(not State.valid_save({"version": 1}), "incomplete save rejected")
	check(not State.valid_save("bad"), "non-dictionary save rejected")
	State.reset()
	await room("school")
	await verify_input()
	await use("exit")
	check(State.data.room == "school", "school exit gated before letter")
	await use("ratna")
	check(game.ui.mode == "choice", "Ratna offers an actual choice")
	game._ui_action("ending", "bad")
	check(game.outcome == "bad", "premature accusation reaches bad ending")
	game.playing = true
	game.outcome = ""
	game.ui.close_panel()
	game._sync_active()
	await use("npc", "Sari")
	check(State.data.notes.size() > 0, "NPC dialogue archived")
	game._close()
	await use("evidence", "op1")
	check(game.ui.mode == "photo", "photo opens native inspector")
	await get_tree().process_frame
	var photo = game.ui.photo_inspector
	var press = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT; press.pressed = true; press.position = Vector2(50, 150)
	photo._gui_input(press)
	var drag = InputEventMouseMotion.new()
	drag.position = Vector2(50 + photo.size.x * 0.67, 150)
	photo._gui_input(drag)
	press.pressed = false; press.position = drag.position
	photo._gui_input(press)
	check(State.flag("photoBackSeen"), "photo back discovery persists")
	game._close()
	await use("puzzle", "locker")
	for digit in "1111": game._ui_action("puzzle_key", digit)
	game._ui_action("puzzle_key", "OK")
	check(not State.solved("locker"), "wrong locker code rejected")
	for digit in "4729": game._ui_action("puzzle_key", digit)
	game._ui_action("puzzle_key", "OK")
	check(State.solved("locker") and State.data.evidence.has("A"), "locker grants letter")
	game._close()
	await use("npc", "Danu")
	check(State.flag("invited"), "letter changes Danu and grants invitation")
	game._close()
	await room("street")
	await use("evidence", "op2")
	game._close()
	await use("puzzle", "fuse")
	game._ui_action("puzzle_order", "2")
	check(State.data.puzzles.fuse.current.is_empty(), "wrong wire resets sequence")
	for index in [0, 1, 2]: game._ui_action("puzzle_order", str(index))
	check(State.solved("fuse"), "red yellow blue restores power")
	await room("loading")
	await use("puzzle", "panel")
	check(game.ui.mode != "puzzle", "panel requires actual fuse")
	await use("door", "1")
	check(not game.level.door_pivots[1].get_meta("opened"), "maintenance door locked before key")
	await use("item", "maintenanceKey")
	await use("door", "1")
	check(game.level.door_pivots[1].get_meta("opened"), "maintenance key opens door")
	await use("item", "panelFuse")
	await use("puzzle", "panel")
	check(State.data.installed.has("panelFuse"), "fuse consumed into panel")
	for digit in "3268": game._ui_action("puzzle_key", digit)
	game._ui_action("puzzle_key", "OK")
	check(is_instance_valid(game.boss) and game.boss.kind == "overseer", "panel triggers overseer")
	check(game.boss.hp == 60, "overseer starts with reference HP")
	await verify_combat()
	game.boss.enabled = false
	game.boss.hp = 0.01
	game._boss_defeated("overseer")
	check(State.flag("oldFlashBroken") and not game.player.lamp_available(), "overseer defeat breaks old lamp")
	await room("relay")
	await use("tool")
	check(State.flag("lenteraOwned") and game.player.lamp_available(), "LENTERA-G restores lamp")
	game.player.position = Vector3(0, 0.1, 12)
	game.player.camera.look_at(Vector3(0, 3.65, -9.56))
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(is_instance_valid(game.player.target) and game.player.target.action_id == "rotor", "claw ray reaches authored rotor beyond 14 meters")
	await use("cell", "", true)
	check(not State.flag("relayCellHeld"), "cell gated by generator contact")
	await use("latch", "", true)
	check(State.flag("archiveOpen"), "claw unlocks archive")
	await use("item", "generatorContact")
	await use("generator")
	check(State.data.installed.has("generatorContact"), "generator contact installed")
	await use("cell", "", true)
	await use("socket", "", true)
	check(State.flag("relayPower") and not State.flag("relayCellHeld"), "cell inserted in socket")
	await use("lever", "", true)
	check(not State.flag("relaySolved"), "lever rejects misaligned rotors")
	await use("rotor", "0", true)
	check(State.data.rotors == [1, 1, 0], "rotor I couples to II")
	await use("rotor", "0", true)
	for i in range(3): await use("rotor", "1", true)
	check(State.data.rotors == [2, 1, 3], "coupled rotor puzzle reaches reference target")
	await use("lever", "", true)
	check(State.flag("relaySolved"), "physical lever unlocks route")
	await room("pursuit")
	check(game.boss.kind == "chase", "pursuit spawns chaser")
	await use("brake", "konveyor", true)
	check(game.boss.pause_time > 5, "brake buys escape time")
	await use("escape_lock")
	check(not State.flag("escapePuzzleSolved"), "service lock rejects incomplete symbol set")
	for pair in [["operator", "sun"], ["istirahat", "moon"], ["perkakas", "star"]]:
		await use("search", pair[0])
		await use("fragment", pair[1])
	await use("escape_lock")
	check(State.flag("escapePuzzleSolved"), "three collected fragments unlock service door")
	await game._rescue()
	check(State.data.room == "production" and State.flag("daisyShadowRescueSeen"), "Daisy rescue transfers to production")
	await use("puzzle", "valve")
	check(game.ui.mode != "puzzle", "valves require missing wheel")
	await use("item", "workshopKey")
	await use("item", "valveWheel", true)
	await use("puzzle", "valve")
	for i in range(3): game._ui_action("puzzle_order", "1")
	for i in range(2): game._ui_action("puzzle_order", "2")
	check(State.solved("valve") and game.boss.kind == "hands", "pressure solution spawns hands")
	game.player.bind_player()
	game.player.release_bind()
	check(not game.player.bound, "claw release clears restraint")
	game._boss_defeated("hands")
	await room("office")
	await use("puzzle", "breaker")
	check(game.ui.mode != "puzzle", "audit panel gated before album and recording")
	await use("evidence", "B")
	game._close()
	await use("item", "tapeReel")
	await use("audit")
	check(State.flag("auditVerified") and State.data.notes.has("audit"), "audit tape grants authorization and transcript")
	game._close()
	await use("puzzle", "breaker")
	for i in [2, 0, 3, 1]: game._ui_action("puzzle_order", str(i))
	check(State.solved("breaker"), "chronological audit opens ritual")
	await use("service")
	game._ui_action("ending", "good")
	check(game.outcome == "good", "evidence route offers good ending")
	game.playing = true
	game.outcome = ""
	game.ui.close_panel()
	await room("ritual")
	check(game.boss.hp == 260 and game.boss.shield, "final boss begins protected phase one")
	for phase in range(1, 4):
		check(game.boss.phase == phase, "ritual phase %d active" % phase)
		for i in range(3):
			for pull in range(3): await use("candle", str(i), true)
		check(not game.boss.shield, "three pulls per candle remove phase %d shield" % phase)
		if phase < 3: game.boss.begin_phase(phase + 1)
	game._boss_defeated("tumbal")
	await room("corridor")
	await use("exit")
	check(State.flag("exitLocked"), "Danu locks apparent exit")
	await room("daisy")
	check(is_instance_valid(game.level.cabinet_hinge) and is_instance_valid(game.level.doll), "Daisy cabinet exists natively")
	await game._daisy_sequence()
	check(game.outcome == "cliffhanger", "chapter-one ending exists")
	game.playing = true
	game.ui.close_panel()
	game._sync_active()
	State.data.sanity = 1
	game.hurt(2)
	check(game.outcome == "broken", "sanity zero triggers defeat")
	State.save_enabled = true
	check(State.save_game([1, 0.1, 2, 0.2, -0.1]) == OK, "checkpoint writes atomically")
	check(not State.read_save().is_empty(), "checkpoint roundtrip validates")
	State.data.sanity = 5
	check(State.load_game(true) and State.data.sanity >= 85, "retry restores checkpoint with recovery")
	# Resource decoding is checked, not only file existence.
	for index in range(32, 41):
		var path = "res://assets/audio/music_%03d.ogg" % index if index in [36, 37, 38, 39] else "res://assets/audio/embedded_%03d.mp3" % index
		var stream = load(path)
		check(stream is AudioStream and stream.get_length() > 1, "audio %d decodes" % index)
	if had_save:
		var file = FileAccess.open(State.save_path, FileAccess.WRITE)
		file.store_string(original_save)
		file.close()
	else: DirAccess.remove_absolute(State.save_path)
	game.audio.shutdown()
	await get_tree().create_timer(0.2).timeout
	game.queue_free()
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame
	KalaGeometry.materials.clear()
	print("KALA INTEGRATION: %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func room(id: String) -> void:
	game.ui.close_panel()
	game.playing = true
	await game.enter_room(id, false, false)
	await get_tree().physics_frame
	game.player.active = true
	if is_instance_valid(game.boss): game.boss.enabled = false
	check(State.data.room == id and is_instance_valid(game.level), "load level " + id)
	check(game.level.find_children("*", "MeshInstance3D", true, false).size() > 60, "source geometry " + id)
	check(game.player.position.y > -1, "spawn supported " + id)

func use(action: String, parameter = "", tool = false) -> void:
	var found: KalaInteractable
	for object in get_tree().get_nodes_in_group("interactables"):
		if game.level.is_ancestor_of(object) and object.action_id == action and object.parameter == parameter:
			found = object; break
	check(is_instance_valid(found), "interaction exists " + action + " " + parameter)
	if not is_instance_valid(found): return
	game.player.active = true
	game.claw_cooldown = 0
	game._interact(found, tool)
	await get_tree().process_frame
	if is_instance_valid(game.boss): game.boss.enabled = false

func verify_combat() -> void:
	game.player.position = Vector3(0, 0.1, 18)
	game.boss.position = Vector3(0, 0.1, 13)
	game.boss.rotation.y = 0
	game.player.camera.look_at(game.boss.global_position + game.boss.target_offset)
	await get_tree().physics_frame
	check(game.boss.beam_visible(), "beam sees exposed face with clear line")
	game.player.lamp_on = true
	game.player.lamp.visible = true
	game.player.cooldown = 0
	game.boss.gaze_bonus = 20
	game.player.active = false
	game.boss.enabled = true
	var before: float = game.boss.hp
	game.boss._physics_process(0.2)
	check(game.boss.hp < before, "aimed lamp damages boss")
	game.boss.enabled = false
	# Use an existing solid level wall: exercise the real scene, without creating
	# and destroying physics bodies inside this manually advanced combat check.
	game.player.position = Vector3(game.level.width / 2 - 2, 0.1, 0)
	game.boss.position = Vector3(game.level.width / 2 + 1, 0.1, 0)
	game.boss.rotation.y = -PI / 2
	game.player.camera.look_at(game.boss.global_position + game.boss.target_offset)
	await get_tree().physics_frame
	check(not game.boss.beam_visible(), "solid cover blocks beam")
	game.boss.position = Vector3(0, 0.1, -7)
	game.player.heat = 0.99
	game.player.add_beam_heat(0.1)
	check(game.player.cooldown > 2, "beam overheating enforces cooldown")
	game.player.active = true

func verify_input() -> void:
	var key = InputEventKey.new()
	key.physical_keycode = KEY_J
	key.keycode = KEY_J
	key.pressed = true
	get_viewport().push_input(key.duplicate())
	await get_tree().process_frame
	check(game.ui.mode == "journal", "physical J event opens journal")
	var release = key.duplicate()
	release.pressed = false
	get_viewport().push_input(release)
	game._close()
	var start: Vector3 = game.player.position
	var direction: Vector3 = -game.player.global_basis.z
	Input.action_press("forward")
	for i in range(20): await get_tree().physics_frame
	Input.action_release("forward")
	check((game.player.position - start).dot(direction) > 0.5, "W movement advances CharacterBody3D")
	var yaw: float = game.player.rotation.y
	# Headless DisplayServer cannot capture a mouse, so exercise the camera's
	# shared look handler; OS event routing is checked in the windowed playtest.
	game.player.look(Vector2(40, 0))
	await get_tree().process_frame
	check(angle_difference(yaw, game.player.rotation.y) < -0.01, "relative look handler turns native camera")
	game.player.position = Vector3(0, 0.1, 9)
	game.player.rotation = Vector3.ZERO
	game.player.camera.rotation = Vector3.ZERO
