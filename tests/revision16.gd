extends Node
const C = preload("res://scripts/systems/checkpoint_catalog.gd")
var checks = 0
var failures = 0
var game: Node3D

func check(value: bool, message: String) -> void:
	checks += 1
	if value: print("PASS: ", message)
	else: failures += 1; push_error("FAIL: " + message)

func _ready() -> void:
	State.save_enabled = false; State.reset()
	State.save_path = "res://.qa_userdata/revision16/checkpoint.json"
	DirAccess.make_dir_recursive_absolute(State.save_path.get_base_dir())
	for path in [State.save_path, State.save_path + ".history.json"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; await get_tree().physics_frame
	game.test_mode = true
	check(game.ui.mode == "title" and game.title_set.camera.current, "title retains its native 3D backdrop")
	var title_buttons = game.ui.title_menu.find_children("Action_*", "Button", true, false)
	check(title_buttons.size() == 6 and not title_buttons.any(func(b): return "GRAPH" in b.text), "title has six actions including Load Game and no Graphics menu")
	game._ui_action("load_menu", ""); await get_tree().process_frame
	check(game.ui.mode == "load" and game.ui.load_menu.records.size() == 18, "empty library opens all 18 playable story sections")
	game._close(); check(game.ui.mode == "title", "Back returns Load Game to the title")
	game._ui_action("load_menu", "")
	var escape = InputEventKey.new(); escape.keycode = KEY_ESCAPE; escape.pressed = true
	game.ui.load_menu._input(escape)
	check(game.ui.mode == "title", "keyboard Escape closes Load Game without accessing a removed Control")
	game._ui_action("settings", ""); await get_tree().process_frame
	var settings = game.ui.settings_menu
	check(settings.tab_buttons.size() == 4 and not settings.TABS.has("GRAPHICS") and settings.rows.get_child_count() == 11, "visual controls live in Display without a separate Graphics tab")
	check(settings.heading.get_theme_color("font_color") == Color("e5e4df") and settings.heading.material != null, "settings heading uses distressed white ink")
	game._close()
	var old_game = State.fresh_data(); old_game.elapsed = 75.0
	check(State.archive.write_json(State.save_path, old_game) == OK, "legacy single-checkpoint fixture is writable")
	State.data = old_game.duplicate(true); State.data.flags.legacyMigrated = true; State.save_enabled = true
	check(State.save_game([], "manual") == OK, "new manual save succeeds")
	var records: Array = State.archive.entries(State)
	check(records.size() == 2 and records.any(func(r): return r.id == "legacy" and not r.data.flags.has("legacyMigrated")), "saving preserves the original legacy checkpoint as a separate row")
	State.data.flags.secondProgress = true
	State.save_game(); var automatic_id = str(State.data.save_id)
	State.data.elapsed += 46; State.save_game()
	check(State.archive.entries(State).size() == 3 and State.data.save_id == automatic_id, "unchanged autosaves update one row instead of flooding the list")
	State.save_game([], "manual"); var latest_id = str(State.data.save_id)
	check(State.archive.entries(State).size() == 4, "a manual save stays independent even at the same location")
	check(State.archive.load_slot(State, "legacy") and not State.flag("secondProgress") and State.data.elapsed == 75, "loading an older row restores its own inventory, flags and playtime")
	State.data.flags.localMutation = true
	check(not State.archive.entries(State).filter(func(r): return r.id == "legacy")[0].data.flags.has("localMutation"), "playing a loaded snapshot cannot mutate its archived copy")
	check(State.archive.delete_slot(State, latest_id) == OK and State.read_save().get("save_id", "") == automatic_id, "deleting the latest row moves Continue to the next remaining checkpoint")
	State.save_enabled = false
	for spec in C.entries():
		var before = State.data.duplicate(true)
		var value: Dictionary = C.snapshot(State, spec.id)
		check(State.valid_save(value) and State.data == before, "section template is valid and side-effect free: " + spec.id)
		await game.load_checkpoint(spec.id, true)
		await get_tree().physics_frame
		game.player.active = false
		check(State.data.room == spec.room and game.level.safety.contains(game.player.position, 0.2), "section loads its real level at a safe spawn: " + spec.id)
		if spec.id == "overseer": check(is_instance_valid(game.boss) and game.boss.kind == "overseer", "Pengawas entry starts the actual boss")
		if spec.id == "hands": check(is_instance_valid(game.boss) and game.boss.kind == "hands", "Tangan-Tangan entry starts the actual boss with Lentera-G")
		if spec.id == "memory": check(game.player.position.y < -3.5 and State.flag("relaySolved") and game.level.relay_world.memory.round_index == 0, "memory entry starts downstairs with relay prerequisites and fresh rounds")
		if spec.id == "hallucination": check(game.boss_revision.mode == "chase" and State.data.evidence.size() == 4, "hallucination entry starts Nightmare with all four usable memories")
	game._ui_action("load_menu", ""); game.ui.load_menu.show_category("sections"); game.ui.load_menu.select(9)
	await get_tree().process_frame; await get_tree().process_frame
	check(game.ui.load_menu.scroll.scroll_vertical > 0, "selected sections outside the first six rows scroll into view")
	var enter = InputEventKey.new(); enter.keycode = KEY_ENTER; enter.pressed = true
	game.ui.load_menu._input(enter)
	while game.entering: await get_tree().process_frame
	check(State.data.room == "relay" and game.player.position.y < -3.5 and game.ui.mode == "", "keyboard Enter loads the selected section through the real menu action")
	game._sync_active(); game._pause(); game._ui_action("load_menu", "")
	check(game.ui.mode == "load" and not game.player.active, "Load Game pauses gameplay when opened from Pause")
	game._close(); check(game.ui.mode == "pause" and not game.player.active, "Back restores Pause without resuming the game")
	game._ui_action("settings", ""); game._close()
	check(game.ui.mode == "pause", "settings opened from Pause return to Pause")
	game._ui_action("load_menu", ""); await get_tree().process_frame
	var menu = game.ui.load_menu
	menu.show_category("saves"); menu.select(0); var selected_id = menu.records[0].id
	menu.toggle_delete(); menu._input(escape)
	check(game.ui.mode == "load" and not menu.confirming_delete, "Escape cancels deletion while leaving the library open")
	game._close()
	check(State.archive.entries(State).any(func(r): return r.id == selected_id), "closing delete confirmation never deletes a checkpoint")
	State.save_enabled = true
	State.archive.write_json(State.save_path + ".history.json", [{"id": "broken", "data": {"version": 1}}, null])
	check(State.archive.entries(State).size() == 1 and State.valid_save(State.archive.entries(State)[0].data), "damaged history rows are skipped while Continue remains available")
	State.archive.delete_slot(State, State.archive.entries(State)[0].id)
	check(State.read_save().is_empty() and State.archive.entries(State).is_empty(), "deleting the last checkpoint leaves a clean empty library")
	check(State.archive.thumbnail_path(State, "../escape").is_empty(), "preview paths reject directory traversal")
	State.data = C.snapshot(State, "school"); State.save_game([], "manual")
	var retained_manual = State.data.save_id
	for i in range(52):
		State.data.flags.retentionStep = i; State.save_game()
	var retained: Array = State.archive.entries(State)
	check(retained.size() == 49 and retained.any(func(r): return r.id == retained_manual), "autosave retention preserves every manual save and the newest 48 progress snapshots")
	State.save_enabled = false
	var report = {"checks": checks, "failures": failures, "sections": C.entries().size()}
	State.archive.write_json("res://docs/validation_16.json", report)
	print("KALA REVISION16: %d checks, %d failures" % [checks, failures])
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.4).timeout
	get_tree().quit(0 if failures == 0 else 1)
