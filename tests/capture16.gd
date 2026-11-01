extends Node
const C = preload("res://scripts/systems/checkpoint_catalog.gd")
var game: Node3D

func _ready() -> void:
	get_window().unfocusable = true
	State.save_enabled = false; State.reset()
	State.save_path = "res://.qa_userdata/capture16/checkpoint.json"
	DirAccess.make_dir_recursive_absolute(State.save_path.get_base_dir())
	for path in [State.save_path, State.save_path + ".history.json"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(path)
	DirAccess.make_dir_recursive_absolute("res://docs/screenshots")
	game = preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; await get_tree().physics_frame
	game.test_mode = true; game.player.set_physics_process(false)
	game.set_process(false)
	# Render actual level photographs for every always-available section.
	var sections = C.entries()
	if OS.get_cmdline_user_args().has("--menus-only"): sections = []
	if OS.get_cmdline_user_args().has("--refresh-memory"): sections = sections.filter(func(spec): return spec.id == "memory")
	for spec in sections:
		await game.load_checkpoint(spec.id, true)
		game.player.active = false; game.ui.hud.hide(); game.ui.subtitle.hide()
		game.narrative.cancel(); game.cinematic = false
		game.player.lamp_on = game.player.lamp_available(); game.player._physics_process(0.001)
		await get_tree().create_timer(0.20).timeout
		await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
		var image = get_viewport().get_texture().get_image()
		image.resize(640, 360, Image.INTERPOLATE_LANCZOS)
		image.save_jpg("res://assets/ui/checkpoints/" + spec.id + ".jpg", 0.86)
		# The same room photograph is also a fallback for legacy saves.
		if not FileAccess.file_exists("res://assets/ui/checkpoints/" + spec.room + ".jpg"):
			image.save_jpg("res://assets/ui/checkpoints/" + spec.room + ".jpg", 0.86)
		print("PREVIEW16 ", spec.id)
	# Seed this isolated QA profile with actual, distinct checkpoint states.
	State.save_enabled = true
	for spec in ["school", "street", "loading", "inspection", "relay_tools", "memory"]:
		State.data = C.snapshot(State, spec); State.data.elapsed = 780 + C.entries().filter(func(v): return v.id == spec)[0].number * 95
		State.save_game([], "manual" if spec == "memory" else "auto")
		State.archive.save_preview(State, State.data.save_id, Image.load_from_file(ProjectSettings.globalize_path("res://assets/ui/checkpoints/" + spec + ".jpg")))
	State.save_enabled = false
	game.playing = false; game.ui.title_screen(); game.title_set.show_set(true); game._sync_active()
	await shot("title_16")
	game._ui_action("settings", "")
	await shot("settings_16")
	game._close(); game._ui_action("load_menu", "")
	await shot("load_saves_16")
	game.ui.load_menu.show_category("sections"); game.ui.load_menu.select(9)
	await shot("load_sections_16")
	# Check how the 1280x720 composition scales down and into a 4:3 window.
	get_window().size = Vector2i(960, 540)
	await shot("load_small_16")
	get_window().size = Vector2i(1024, 768)
	await shot("load_4x3_16")
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.4).timeout
	get_tree().quit()

func shot(title: String) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.25).timeout
	await RenderingServer.frame_post_draw; await RenderingServer.frame_post_draw
	var result = get_viewport().get_texture().get_image().save_png("res://docs/screenshots/" + title + ".png")
	print("CAPTURE16 ", title, " ", result)
