extends Node3D

@onready var player: KalaPlayer = $Player
@onready var ui: KalaHUD = $HUD
@onready var audio: KalaAudio = $Audio
@onready var narrative: Node = $Narrative
var level: KalaLevel
var boss: KalaEnemy
var playing = false
var entering = false
var story: Dictionary = {}
var projectiles: Array[Dictionary] = []
var minions: Array[Node3D] = []
var burn_left = 0.0
var autosave_time = 0.0
var claw_cooldown = 0.0
var previous_menu = "title"
var cinematic = false
var outcome = ""
var test_mode = false
var story_origin = Vector3.ZERO
var quitting = false
var chapter_flow = preload("res://scripts/systems/chapter_flow.gd").new()
var campus = preload("res://scripts/systems/continuous_campus.gd").new()
var title_set: Node3D
var scare: Node3D
var boss_revision: Node
const DEFEAT_FLAGS = {"overseer": "overseerDefeated", "hands": "handsDefeated", "tumbal": "tumbalDefeated"}
const HINTS = {"locker": "Foto kelas 1A: balik kertasnya. Sari mengingat dua angka terakhir.", "fuse": "Pita gerbang: merah → kuning → biru.", "panel": "Memo A: 3. Memo B: 2 lalu 6. Memo C: 8.", "valve": "Semua panah ke atas. Katup II tiga putaran, III dua putaran dari posisi awal.", "breaker": "Urutkan jam audit: 00.20 → 01.40 → 02.10 → 03.15."}

func _ready() -> void:
	get_tree().auto_accept_quit = false
	chapter_flow.host = self
	campus.host = self
	boss_revision = preload("res://scripts/systems/boss_revision.gd").new()
	boss_revision.host = self; add_child(boss_revision)
	title_set = preload("res://scripts/ui/title_set.gd").new()
	add_child(title_set)
	scare = preload("res://scripts/systems/jumpscare.gd").new()
	scare.host = self; add_child(scare)
	_configure_input()
	var text = FileAccess.get_file_as_string("res://assets/story.json").trim_prefix("\ufeff")
	story = JSON.parse_string(text)
	player.interaction_requested.connect(_interact)
	player.journal_requested.connect(_journal)
	player.pause_requested.connect(_pause)
	player.footstep.connect(func(): audio.effect("step"))
	ui.action_requested.connect(_ui_action)
	audio.apply_volume()
	await enter_room("school", false, false)
	playing = false
	ui.title_screen()
	title_set.show_set()
	_apply_graphics()
	_sync_active()
	if OS.get_cmdline_user_args().has("--smoke"): _smoke()

func _configure_input() -> void:
	var bindings = {"forward": [KEY_W, KEY_UP], "back": [KEY_S, KEY_DOWN], "left": [KEY_A], "right": [KEY_D], "look_left": [KEY_LEFT], "look_right": [KEY_RIGHT], "sprint": [KEY_SHIFT], "crouch": [KEY_CTRL], "interact": [KEY_E], "flashlight": [KEY_F], "claw": [KEY_R], "pulse": [KEY_Q], "journal": [KEY_J], "pause": [KEY_ESCAPE], "flip": [KEY_SPACE]}
	for action in bindings:
		if not InputMap.has_action(action): InputMap.add_action(action)
		for key in bindings[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
			var logical = InputEventKey.new()
			logical.keycode = key
			InputMap.action_add_event(action, logical)

func new_game() -> void:
	narrative.cancel()
	scare.cancel()
	State.reset()
	State.set_flag("prologueVersion")
	playing = true
	outcome = ""
	ui.close_panel()
	await enter_room("home")
	if not test_mode: narrative.start("wake_home")

func enter_room(id: String, restore = false, save = true) -> void:
	if entering: return
	if not restore and campus.cross(id, save): return
	var previous_room = str(State.data.room)
	entering = true
	boss_revision.clear_hazards()
	if id not in ["ritual", "hallucination"]: boss_revision.cancel()
	narrative.cancel()
	ui.notify("", 0)
	ui.prompt.text = ""
	player.active = false
	_clear_actors()
	campus.clear(level)
	if is_instance_valid(level):
		level.queue_free()
		await get_tree().process_frame
	level = load("res://scenes/levels/%s.tscn" % id).instantiate() as KalaLevel
	$Level.add_child(level)
	level.passage_entered.connect(_travel)
	campus.prepare(level)
	State.data.room = id
	if playing:
		title_set.hide_set()
		player.camera.make_current()
	player.position = level.spawn
	player.rotation = Vector3(0, level.spawn_yaw, 0)
	player.camera.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	player.target = null
	player.speed_multiplier = 1
	player.release_bind()
	player.heat = 0
	player.cooldown = 0
	player.pulse_cooldown = 0; player.pulse_flash = 0
	player.reach_time = 0
	player.anchored = false
	player.cable.hide()
	if restore and State.data.get("layout_revision", 0) >= (11 if id in ["home", "school", "schoolyard", "neighborhood"] else 2) and State.data.position.size() == 5:
		var p: Array = State.data.position
		player.position = Vector3(p[0], p[1], p[2])
		player.rotation.y = p[3]
		player.camera.rotation.x = clampf(p[4], -1.25, 1.25)
	else:
		State.data.sanity = minf(100, State.data.sanity + 18)
	if not level.safety.contains(player.position, 0.2) or player.position.y < level.safety.floor_limit(player.position) - 2:
		player.position = level.spawn
	if restore and id == "pursuit" and not State.flag("escapePuzzleSolved") and player.position.x > 11.5 and player.position.z < -54:
		player.position = level.spawn
	player.last_safe_position = player.position
	player.tool_raising = false
	State.data.layout_revision = 11
	player.lamp_on = id not in ["school", "home", "schoolyard", "neighborhood"] and player.lamp_available()
	player.viewmodel.visible = id not in ["school", "home", "schoolyard", "neighborhood"]
	player.lamp.light_energy = 0.099 if id == "daisy" else 2.05
	preload("res://scripts/systems/atmosphere.gd").apply(self, id)
	if State.flag("prologueVersion") and not restore: chapter_flow.arrived(id, previous_room)
	audio.play_music("daisy" if id == "daisy" else "")
	if id == "loading" and State.solved("panel") and not State.flag("overseerDefeated"): _start_fight("overseer")
	if id == "production" and State.solved("valve") and not State.flag("handsDefeated"): _start_fight("hands")
	if id == "ritual" and not State.flag("tumbalDefeated"): _start_fight("tumbal")
	if id == "pursuit": _start_fight("chase")
	entering = false
	if save and playing: _save()
	_sync_active()
	if id == "hallucination": boss_revision.setup_chase()
	if playing and not test_mode:
		if id == "school" and State.flag("prologueVersion") and not State.flag("lessonSeen"): narrative.start("lesson")
		elif id == "relay" and not State.flag("lenteraOwned") and not State.flag("lenteraDiscoverySeen"): narrative.start("discovery")
		elif id == "corridor" and not State.flag("exitLocked"): narrative.start("corridor")
		elif id == "street" and State.solved("fuse") and not State.flag("warehouseEntrySeen"): narrative.start("warehouse")
		elif id == "office" and State.solved("breaker") and not State.flag("officeExitSeen"): narrative.start("office")

func _clear_actors() -> void:
	for actor in $Actors.get_children(): actor.queue_free()
	boss = null
	projectiles.clear()
	minions.clear()
	burn_left = 0

func _save() -> Error:
	if State.data.room == "hallucination" or boss_revision.mode in ["center", "fog", "portal", "human_escape", "banish"]: return ERR_UNAVAILABLE
	var error = State.save_game([player.position.x, player.position.y, player.position.z, player.rotation.y, player.camera.rotation.x])
	if error != OK: ui.notify("Checkpoint gagal ditulis. Kode: " + str(error))
	return error

func _sync_active() -> void:
	var active = playing and ui.mode == "" and not cinematic and not entering
	player.active = active
	ui.hud.visible = playing and ui.mode == "" and not cinematic
	ui.subtitle.visible = ui.mode == ""
	if not active:
		player.target = null
		player.cable.visible = false
	for actor in $Actors.get_children():
		if actor is KalaEnemy: actor.enabled = active
	level.set_process(active)
	if not active: audio.voice.stream_paused = ui.mode in ["pause", "settings"]
	else: audio.voice.stream_paused = false
	audio.music.stream_paused = ui.mode in ["pause", "settings"]
	if active: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _interact(target: KalaInteractable, tool: bool) -> void:
	if not player.active or not is_instance_valid(target) or not target.available(): return
	if tool:
		if not State.flag("lenteraOwned") or claw_cooldown > 0: return
		claw_cooldown = 0.32
	if target.tool_only and not tool: return
	var id = target.parameter
	match target.action_id:
		"campus_door":
			if target.get_parent().toggle(): audio.effect("click"); _save()
			else: ui.notify("Mundur sedikit dari ambang agar pintu bisa ditutup.")
		"memory": boss_revision.remember(int(id))
		"chapter": chapter_flow.interact(id)
		"search":
			var message = level.escape_puzzle.search(id)
			ui.notify(message, 5); audio.effect("click"); _save()
		"fragment":
			State.give("fragment_" + id)
			ui.notify("Potongan %s ditemukan. %d/3 pengunci terkumpul." % [id.capitalize(), 3 - level.escape_puzzle.missing().size()])
			audio.effect("click")
			_save()
		"escape_lock":
			if level.escape_puzzle.unlock():
				if is_instance_valid(boss): boss.pause_time = maxf(boss.pause_time, 3.5)
				ui.notify("Sun · Moon · Star terpasang. Pintu servis terbuka—turuni tangganya!", 5)
				audio.effect("impact")
				_save()
			else: ui.notify("Pengunci belum lengkap. Cari potongan: " + ", ".join(level.escape_puzzle.missing()), 5)
		"npc": _npc(id)
		"ratna":
			ui.clear_panel("BU RATNA", "choice")
			ui.paragraph("Kesaksianmu akan berdampak pada orang lain. Periksa waktu, tempat, dan saksi.")
			ui.button("Laporkan Raka berdasarkan yang kulihat", "ending", "bad")
			ui.button("Kumpulkan bukti lebih dahulu", "close")
		"evidence": _evidence(id)
		"note": _note(id)
		"puzzle": _open_puzzle(id)
		"item":
			State.give(id)
			ui.notify("Disimpan: " + target.caption.trim_prefix("Ambil "))
			_save()
		"door":
			var pivot = level.door_pivots[int(id)]
			var lock = str(pivot.get_meta("lock"))
			if lock != "" and not State.owns(lock) and not State.flag(lock): ui.notify("Terkunci: " + target.caption)
			else:
				pivot.set_meta("opened", not pivot.get_meta("opened"))
				State.set_flag("door_%s_%s" % [State.data.room, id], pivot.get_meta("opened"))
				_save()
				audio.effect("click")
		"tool":
			if not test_mode: narrative.start("pickup")
			else:
				State.set_flag("lenteraOwned")
				player.lamp_on = true
				_save()
		"latch": State.set_flag("archiveOpen"); _save(); audio.effect("impact")
		"generator":
			ui.notify("Kontak generator terpasang." if State.install("generatorContact") else "Kontak generator belum ditemukan.")
			_save()
		"cell":
			if State.data.installed.has("generatorContact"):
				State.set_flag("relayCellHeld"); _save()
			else: ui.notify("Catu generator belum aktif.")
		"socket":
			if State.flag("relayCellHeld"):
				State.set_flag("relayPower"); State.set_flag("relayCellHeld", false); _save()
			else: ui.notify("Soket R-17 kosong.")
		"rotor":
			if State.flag("relayPower"): State.turn_relay(int(id)); _save(); audio.effect("click")
		"lever":
			if State.flag("relayPower") and State.data.rotors == [2, 1, 3]:
				State.set_flag("relaySolved"); _save(); ui.notify("Pengunci arsip terlepas. Ada langkah di balik pintu.")
			else: audio.effect("impact")
		"brake":
			if is_instance_valid(boss) and level.time >= float(level.brake_cooldowns.get(id, 0)):
				State.set_flag("brake_" + id)
				level.brake_cooldowns[id] = level.time + 22
				boss.pause_time = 5.3
				ui.notify("Rem menahan pengejar. Cari tempat berlindung; rem pulih dalam 22 detik.", 5)
				audio.effect("impact")
		"grate":
			State.set_flag("ventGrateOpen")
			if is_instance_valid(boss): boss.pause_time = maxf(boss.pause_time, 3.4)
			audio.effect("impact"); _save()
		"fan":
			level.fan_stop_time = 6.5
			if is_instance_valid(boss): boss.pause_time = maxf(boss.pause_time, 2.5)
			audio.effect("impact")
		"mural": ui.notify("kita seharusnya tidak bertemu secepat ini, ayo bermain!", 7)
		"audit":
			if not State.install("tapeReel"): ui.notify("Pemutar pita masih kosong.")
			else:
				State.set_flag("auditVerified")
				State.add_note("audit", "ARSIP SUARA / 17 MARET", "PEREMPUAN: Mereka meminta satu nama supaya mesin berhenti. Aku tidak akan menulis nama anak lain.\n\nANAK: Kalau kolom itu kosong, Ibu tidak akan keluar?\n\nDANU: Raka percaya padaku. Ia akan datang kalau kubilang aku membutuhkan bantuan. Aku tahu itu salah. Aku cuma tidak mau mendengar mesin memanggil namaku lagi.")
				ui.show_note("ARSIP SUARA / 17 MARET", State.data.notes.audit.body)
				_save()
		"candle":
			if is_instance_valid(boss): boss.pull_seal(int(id)); audio.effect("click")
		"service":
			ui.clear_panel("JALUR SERVIS", "choice")
			ui.paragraph("Bu Ratna memerlukan album dan sedikitnya dua bukti lain. Bukti saat ini: %d/4." % State.data.evidence.size())
			ui.button("Bawa bukti ke BK — akhir alternatif", "ending", "good", not State.data.evidence.has("B") or State.data.evidence.size() < 3)
			ui.button("Tetap mencari Danu", "close")
		"exit": _exit_room()
		"hidden":
			if State.flag("exitLocked"): _travel("daisy")
			else: ui.notify("D–08 terkunci. Periksa pintu keluar.")
		"rescue": _rescue()
		"daisy": _daisy_sequence()
	_sync_active()

func _npc(name_value: String) -> void:
	var after = chapter_flow.school_evidence_count() >= 2 and State.data.evidence.has("op1") if State.flag("prologueVersion") else State.data.evidence.has("A")
	var text: String = story.dialogues[name_value]["after" if after else "before"]
	State.add_note("talk_" + name_value + str(after), name_value.to_upper(), text)
	if name_value == "Danu" and after: State.set_flag("invited")
	ui.show_dialogue(name_value, text)
	_save()

func _evidence(id: String) -> void:
	State.collect(id)
	var record: Dictionary = story.evidence[id]
	State.add_note("ev_" + id, record.title, record.body)
	if id == "op1": ui.show_photo()
	else: ui.show_note(record.title, record.body)
	_save()

func _note(id: String) -> void:
	if not story.notes.has(id):
		ui.notify("Catatan belum tersedia: " + id)
		return
	var record: Dictionary = story.notes[id]
	State.add_note(id, record.title, record.body)
	ui.show_note(record.title, record.body)
	_save()

func _open_puzzle(id: String) -> void:
	if State.solved(id):
		if id == "locker": _evidence("A")
		else: ui.notify("Panel sudah aktif.")
		return
	if id == "panel" and not State.install("panelFuse"):
		ui.notify("Sekering operator belum dipasang. Periksa ruang jaga dan suku cadang."); return
	if id == "valve" and (not State.flag("lenteraOwned") or not State.install("valveWheel")):
		ui.notify("Roda katup II belum dipasang. Periksa perawatan dan bengkel."); return
	if id == "breaker" and (not State.flag("auditVerified") or not State.data.evidence.has("B")):
		ui.notify("Periksa album dan dengarkan pita audit lebih dahulu."); return
	ui.show_puzzle(id)

func _puzzle_complete(id: String) -> void:
	ui.close_panel()
	audio.effect("click")
	_save()
	match id:
		"locker": _evidence("A")
		"fuse":
			ui.notify("Lampu gang dan pengunci gudang mendapat daya.")
			if not test_mode: narrative.start("warehouse")
		"panel": _start_fight("overseer"); ui.notify("SI PENGAWAS · sorot wajahnya. Tatapannya menahan langkahmu.", 7)
		"valve": _start_fight("hands"); ui.notify("TANGAN-TANGAN · sorot tubuhnya. R / E berulang untuk lepas dari cengkeraman.", 7)
		"breaker":
			ui.notify("DANU: Kau membaca terlalu jauh. Setiap cerita perlu seseorang yang disalahkan.", 7)
			if not test_mode: narrative.start("office")
	_sync_active()

func _exit_room() -> void:
	var id: String = State.data.room
	if id == "school" and State.flag("prologueVersion"):
		_travel("schoolyard")
		return
	var allowed = false
	match id:
		"school": allowed = State.data.evidence.has("A") and State.flag("invited")
		"street": allowed = State.solved("fuse")
		"loading": allowed = State.flag("overseerDefeated")
		"relay": allowed = State.flag("relaySolved")
		"production": allowed = State.flag("handsDefeated")
		"office": allowed = State.solved("breaker")
		"ritual": allowed = State.flag("tumbalDefeated")
		"corridor":
			if not test_mode and not State.flag("exitLocked"):
				narrative.start("corridor")
				return
			State.set_flag("exitLocked")
			_save()
			ui.notify("Danu memutar kunci dari luar. Cari pintu D–08 di dinding timur.", 7)
			return
	if not allowed:
		ui.notify(_objective())
		return
	var index = State.ROOMS.find(id)
	if id in ["school", "street"]: _travel(State.ROOMS[index + 1])
	else:
		level.passage_authorized = true
		ui.notify("Pintu terbuka. Lanjutkan menuruni tangga akses.", 4)

func _travel(id: String) -> void:
	if entering: return
	if id == "pursuit" and State.data.room == "relay" and not test_mode and not State.flag("handsAmbushRunSeen"):
		narrative.start("ambush")
		return
	ui.close_panel()
	enter_room.call_deferred(id)
	player.active = false

func _start_fight(kind: String) -> void:
	if is_instance_valid(boss): return
	boss = preload("res://scenes/enemies/enemy.tscn").instantiate() as KalaEnemy
	boss.kind = kind
	boss.player = player
	boss.level = level
	boss.position = Vector3(0, 0.1, 63 if kind == "chase" else -5 if kind == "tumbal" else -8)
	$Actors.add_child(boss)
	boss.defeated.connect(_boss_defeated)
	boss.damage_player.connect(hurt)
	boss.bind_player.connect(func(): player.bind_player(); ui.notify("Tangan mengunci kakimu. R atau tekan E tujuh kali.", 4))
	boss.spawn_projectile.connect(_projectile)
	boss.ritual_summon.connect(_summon)
	boss.phase_changed.connect(boss_revision.phase_changed)
	audio.play_music(kind)
	player.lamp_on = true
	_sync_active()

func _boss_defeated(kind: String) -> void:
	boss_revision.clear_hazards()
	if kind == "tumbal":
		boss_revision.cancel()
		cinematic = false
	for p in projectiles:
		if is_instance_valid(p.node): p.node.queue_free()
	projectiles.clear(); burn_left = 0
	State.set_flag(DEFEAT_FLAGS[kind])
	State.data.sanity = minf(100, State.data.sanity + 25)
	if is_instance_valid(boss):
		var fallen = boss
		story_origin = fallen.position
		if kind == "tumbal" and not test_mode:
			fallen.queue_free()
		else:
			var tween = create_tween()
			tween.tween_property(fallen, "rotation:x", -PI / 2, 1.2)
			tween.tween_callback(fallen.queue_free)
	boss = null
	for minion in minions:
		if is_instance_valid(minion): minion.queue_free()
	minions.clear()
	player.release_bind()
	player.speed_multiplier = 1
	audio.play_music("")
	audio.effect("impact")
	if kind == "overseer":
		if not test_mode: narrative.start("flash_break")
		else: State.set_flag("oldFlashBroken"); player.lamp_on = false
	elif kind == "tumbal":
		if not test_mode: narrative.start("reversion")
		else: State.set_flag("danuHumanReturned")
	else: ui.notify("Tangan terakhir berhenti. Dari kantor terdengar suara rekamanmu sendiri.", 6)
	_save()

func hurt(amount: float) -> void:
	if not playing or cinematic: return
	State.data.sanity = maxf(0, State.data.sanity - amount)
	if amount >= 5: audio.effect("impact")
	if State.data.sanity <= 0:
		scare.start("caught" if State.data.room == "pursuit" else "broken")

func _projectile(origin: Vector3, direction: Vector3, kind: String) -> void:
	if kind == "hand" and is_instance_valid(boss) and boss.kind == "hands" and origin.distance_to(boss.position + Vector3.UP * 1.2) < 0.5:
		boss_revision.hand_wave(); return
	var node: Node3D
	if kind == "hand":
		node = preload("res://scripts/enemies/spectral_hand.gd").create(); $Actors.add_child(node); node.position = origin
	else:
		node = KalaGeometry.sphere($Actors, origin, Vector3(0.35, 0.25, 0.35), KalaGeometry.material("sinew", Color("739b64")))
	projectiles.append({"node": node, "velocity": direction * (3.5 if kind == "hand" else 6.5), "life": 9.0 if kind == "hand" else 5.0, "kind": kind})

func _summon() -> void:
	if minions.size() >= 5: return
	var actor = preload("res://scenes/enemies/enemy.tscn").instantiate() as KalaEnemy
	actor.kind = "ash"
	actor.player = player
	actor.level = level
	actor.position = Vector3(-4 + minions.size() * 2, 0.1, -3)
	$Actors.add_child(actor)
	actor.damage_player.connect(hurt)
	actor.defeated.connect(func(_kind): minions.erase(actor); actor.queue_free())
	actor.enabled = player.active
	minions.append(actor)

func claw_combat_target(origin: Vector3, direction: Vector3) -> Dictionary:
	var result: Dictionary = {}
	var best = 32.0
	var query = PhysicsRayQueryParameters3D.create(origin, origin + direction * best, 1)
	var surface = get_world_3d().direct_space_state.intersect_ray(query)
	var cover = origin.distance_to(surface.position) if not surface.is_empty() else best
	var candidates: Array[Dictionary] = []
	for projectile in projectiles:
		if is_instance_valid(projectile.node): candidates.append({"node": projectile.node, "point": projectile.node.global_position, "kind": "projectile", "radius": 0.48})
	for minion in minions:
		if is_instance_valid(minion) and minion.hp > 0: candidates.append({"node": minion, "point": minion.global_position + Vector3.UP * 1.05, "kind": "ash", "radius": 0.52})
	for candidate in candidates:
		var offset: Vector3 = candidate.point - origin
		var along = offset.dot(direction)
		var side = offset.length_squared() - along * along
		if along < 0 or side > candidate.radius * candidate.radius: continue
		var distance = maxf(0, along - sqrt(maxf(0, candidate.radius * candidate.radius - side)))
		if distance < best and cover >= distance - 0.75:
			best = distance
			result = candidate
			result.distance = distance
	return result

func resolve_claw_combat(target: Dictionary) -> bool:
	if not player.active or not State.flag("lenteraOwned") or claw_cooldown > 0 or not is_instance_valid(target.node): return false
	claw_cooldown = 0.32
	if target.kind == "projectile":
		for i in range(projectiles.size() - 1, -1, -1):
			if projectiles[i].node == target.node:
				projectiles.remove_at(i)
				target.node.queue_free()
				break
	elif target.kind == "ash":
		target.node.hp -= 6
		if target.node.hp <= 0:
			target.node.enabled = false
			target.node.defeated.emit("ash")
	audio.effect("impact")
	return true

func _rescue() -> void:
	if cinematic or State.data.room != "pursuit": return
	if not State.flag("escapePuzzleSolved"):
		ui.notify("Pintu servis memerlukan potongan Sun, Moon, dan Star.")
		return
	if not test_mode:
		narrative.start("rescue")
		return
	cinematic = true
	_sync_active()
	ui.notify("Kakimu menyerah. Bayangan kecil bergerak menuju panel pengaman.", 5)
	var shadow = preload("res://scripts/systems/model_factory.gd").make("actor_daisy") as Node3D
	shadow.name = "DaisyRescueShadow"
	shadow.position = player.position + Vector3(0, 0.035, -1.6)
	shadow.rotation.x = -PI / 2
	shadow.scale = Vector3(0.8, 0.8, 0.04)
	level.add_child(shadow)
	var shadow_material = StandardMaterial3D.new()
	shadow_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_material.albedo_color = Color("080d09")
	for child in shadow.find_children("*", "MeshInstance3D", true, false): child.material_override = shadow_material
	await get_tree().create_timer(4 if not test_mode else 0.02).timeout
	audio.effect("impact")
	State.set_flag("handsPursuitComplete")
	State.set_flag("daisyShadowRescueSeen")
	cinematic = false
	await enter_room("production")
	ui.notify("Sebuah pintu besi menghantam lantai di antara kalian. Kau terbangun di ruang produksi.", 6)

func _daisy_sequence() -> void:
	if cinematic: return
	cinematic = true
	_sync_active()
	player.camera.look_at(level.doll.global_position + Vector3.UP * 1.04)
	var tween = create_tween()
	tween.tween_property(level.cabinet_hinge, "rotation:y", -1.4, 2.0)
	tween.tween_property(level.doll, "rotation:y", 0.14, 2.0)
	await tween.finished
	ui.notify("DAISY: Kamu datang lebih cepat dari yang kuingat.", 4)
	await get_tree().create_timer(3).timeout
	for i in range(3):
		audio.effect("click")
		await get_tree().create_timer(0.35).timeout
	ui.notify("DAISY: ...kamu datang sendiri, kan?", 3)
	var dark = create_tween()
	dark.tween_property(ui.fade, "color:a", 1.0, 2.0)
	await dark.finished
	cinematic = false
	ui.fade.color.a = 0
	_ending("cliffhanger")

func _pause() -> void:
	if cinematic or entering: return
	if ui.mode == "title": return
	if ui.mode != "":
		if ui.mode == "ending": return
		_close()
		return
	if not playing: return
	ui.show_pause(_objective())
	_sync_active()

func _journal() -> void:
	if not playing or cinematic or entering: return
	if ui.mode == "journal": _close()
	elif ui.mode == "": ui.show_journal(); _sync_active()

func _close() -> void:
	audio.voice.stop()
	if ui.mode == "tutorial": State.set_flag("lenteraGuideSeen"); _save()
	if ui.mode in ["settings", "controls", "graphics", "credits"] and not playing: ui.title_screen()
	else: ui.close_panel()
	_sync_active()

func _ui_action(action: String, value: String) -> void:
	match action:
		"new": new_game()
		"continue", "retry":
			if State.load_game(action == "retry"):
				playing = true; outcome = ""; ui.close_panel(); enter_room(State.data.room, true)
		"close": _close()
		"title":
			if playing and outcome == "": _save()
			playing = false
			audio.play_music("")
			ui.title_screen()
			title_set.show_set()
		"title_background": title_set.show_set(title_set.variant == 0)
		"graphics": _graphics()
		"quality": State.settings.quality = int(value); State.save_settings(); _apply_graphics(); _graphics()
		"credits":
			ui.clear_panel("KALA / JALAN KARTINI", "credits")
			ui.paragraph("CHAPTER 01 — TIGA FASE\n\nSetiap cerita menyimpan seseorang yang disalahkan.\n\nCerita dasar, model, tekstur, foto dan musik: HTML referensi KALA milik pengguna.\nSculpt monster: hands_repaired.glb dari pengguna.\nModel NPC/Daisy native, rumah, jalan tersambung, halusinasi dan sistem gameplay: dikembangkan untuk edisi ini.\n\nKontrol: WASD + mouse, Shift lari, tahan Ctrl jongkok, E periksa, F lampu, R penjepit, J jurnal.\n\nKALA Native 0.10 / 27 Oktober 2026")
			ui.paragraph("Furnitur kamar: Bedroom and Living Room Furniture — 3DAssets.dev, CC0 1.0; geometri sumber dibuat dengan Muse Spark via T3 Code, disesuaikan untuk Godot.\nNakas: Classic Nightstand 01 — Kirill Sannikov / Poly Haven (CC0).\nSekering: Cartridge fuse 10 x 38 mm — Innerscene (CC0).\nKeypad, material tambahan, jeruji dan animasi kaki dibuat untuk KALA.")
			ui.paragraph("ASET GRATIS\nKenney — Furniture Kit, Building Kit, City Kit (Suburban), Nature Kit, Factory Kit (CC0 1.0).\nQuaternius — Radio dan Animated Woman (CC0 1.0).\nInnerscene — Crib dan Adventure motorcycle (CC0).\nMixazzz / M. Khludeev — School from Moscow (CC0).\nDREAM_SEARCH_REPEAT — Banco Escuela (CC0).\n\nDaisy dan Flower Pot oleh Zsky (CC BY 3.0). Model disesuaikan ukuran dan orientasinya untuk KALA.\nDaisy: https://poly.pizza/m/4r0WBz3RZz\nFlower Pot: https://poly.pizza/m/u0CrZnpykb\nLisensi: https://creativecommons.org/licenses/by/3.0/\n\nCaveat — Pablo Impallari / Impallari Type, SIL Open Font License 1.1.\nSumber dan lisensi lengkap: assets/vendor/licenses.json.")
			ui.button("KEMBALI", "close")
		"quit": quit_game()
		"save":
			var error = _save()
			var message = "Checkpoint tersimpan." if error == OK else "Checkpoint belum bisa disimpan di sini." if error == ERR_UNAVAILABLE else "Checkpoint gagal ditulis. Kode: " + str(error)
			if is_instance_valid(ui.pause_menu): ui.pause_menu.show_status(message)
			else: ui.notify(message)
		"ending": _ending(value)
		"photo": ui.show_photo()
		"tutorial": show_lentera_guide()
		"photo_back":
			if not State.flag("photoBackSeen"):
				State.set_flag("photoBackSeen")
				State.add_note("photo_back", "BELAKANG FOTO", "47 — dua angka pertama. Sari ingat dua angka berikutnya.")
				_save()
		"journal_note": ui.show_note(State.data.notes[value].title, State.data.notes[value].body)
		"puzzle_key":
			var id = ui.puzzle_id
			if State.keypad(id, value): _puzzle_complete(id)
			elif is_instance_valid(ui.keypad_board): ui.keypad_board.refresh(str(State.data.puzzles[id].entered), "Kode belum cocok." if value == "OK" else "")
			else: ui.show_puzzle(id, "Kode belum cocok." if value == "OK" else "")
		"puzzle_order":
			var id = ui.puzzle_id
			var success = State.rotate_valve(int(value)) if id == "valve" else State.order_press(id, int(value))
			if success: _puzzle_complete(id)
			else: ui.show_puzzle(id)
		"hint": ui.show_puzzle(value, HINTS[value])
		"settings": _settings()
		"controls":
			ui.clear_panel("KONTROL", "controls")
			ui.paragraph("WASD / ↑ ↓: bergerak\nMouse / ← →: melihat\nShift: lari\nTahan Ctrl: jongkok / langkah lebih senyap\nE: interaksi / buka furnitur / ambil isi\nF: lampu\nR: lepas / tarik penjepit LENTERA-G\nShift dengan kabel di dinding: tarik tubuh\nJ: jurnal\nEsc: jeda / tutup panel\n\nJongkok bertahan otomatis jika langit-langit terlalu rendah.\nSorot wajah Pengawas dari depan. Beri waktu lampu mendingin.\nTangan menahan kaki: R atau E tujuh kali.\nLilin ritual fase 1–2: tarik masing-masing tiga kali.\nFase 3: lari dari Nightmare dan gunakan empat evidence di altar (E).\n\nProgres disimpan saat berganti ruang, memperoleh bukti, barang, dan menyelesaikan puzzle.")
			ui.button("KEMBALI", "close")
	_sync_active()

func _settings() -> void:
	ui.clear_panel("PENGATURAN", "settings")
	for spec in [["sensitivity", "Sensitivitas mouse", 0.5, 1.8], ["volume", "Volume utama", 0.0, 1.0], ["music", "Volume musik", 0.0, 1.0]]:
		ui.paragraph(spec[1])
		var slider = HSlider.new()
		slider.min_value = spec[2]
		slider.max_value = spec[3]
		slider.step = 0.05
		slider.value = State.settings[spec[0]]
		slider.value_changed.connect(func(v): State.settings[spec[0]] = v; State.save_settings(); audio.apply_volume())
		ui.content.add_child(slider)
	var check = CheckButton.new()
	check.text = "Bayangan lampu pemain"
	check.button_pressed = State.settings.shadows
	check.toggled.connect(func(v): State.settings.shadows = v; State.save_settings())
	ui.content.add_child(check)
	var scares = CheckButton.new(); scares.text = "Jumpscare saat tertangkap"; scares.button_pressed = State.settings.scares
	scares.toggled.connect(func(v): State.settings.scares = v; State.save_settings()); ui.content.add_child(scares)
	ui.button("KONTROL", "controls")
	ui.button("KEMBALI", "close")

func show_lentera_guide() -> void:
	if not State.flag("lenteraOwned"): return
	ui.show_tutorial()
	_sync_active()

func _apply_graphics() -> void:
	var quality = clampi(int(State.settings.quality), 0, 2)
	get_viewport().msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][quality]
	get_viewport().positional_shadow_atlas_size = 4096 if quality == 2 else 2048
	if RenderingServer.get_current_rendering_method() == "forward_plus":
		var env: Environment = $WorldEnvironment.environment
		env.ssao_enabled = quality > 0; env.ssao_intensity = 1.25; env.ssao_radius = 1.0
		env.ssil_enabled = quality == 2; env.ssil_intensity = 0.55
		env.glow_enabled = quality > 0; env.glow_intensity = 0.35; env.glow_hdr_threshold = 1.8

func _graphics() -> void:
	ui.clear_panel("GRAPHICS", "graphics")
	ui.paragraph("Pencahayaan terarah, material PBR, detail ruangan dan bayangan dinamis.\nPreset aktif: " + ["RINGAN", "TINGGI", "SINEMATIK"][int(State.settings.quality)])
	for i in range(3): ui.button(["RINGAN · tanpa MSAA", "TINGGI · MSAA 2×", "SINEMATIK · MSAA 4× / shadow 4096"][i], "quality", str(i))
	ui.button("KEMBALI", "close")

func _ending(type: String) -> void:
	outcome = type
	playing = false
	audio.voice.stop()
	audio.play_music("daisy" if type == "cliffhanger" else "")
	var titles = {"bad": "KAMBING HITAM", "good": "TERUNGKAP", "broken": "AKALMU RUNTUH", "caught": "TERTANGKAP", "cliffhanger": "DAISY", "consumed": "AKHIR BURUK / PENANGGUNG BARU"}
	var texts = {
		"consumed": "Bukti yang hilang membuat halusinasi terasa nyata. Portal di belakang tubuh Pemegang menelanmu. Danu kembali menjadi manusia dan berlari; kau mengejarnya, tetapi setiap langkah membawamu lebih jauh ke dalam perjanjian.\n\nEmpat ingatan harus dibawa dan digunakan: foto, agenda Sari, surat Raka, serta album dan perjanjian.\n\nAKHIR BURUK — namamu kini ada di kolom penanggung.",
		"bad": "Bu Ratna menerima laporan tentang Raka. Keesokan harinya, kursi Raka kosong. Danu mengucapkan terima kasih. Di Jalan Kartini, seseorang menulis nama baru di kolom penanggung.\n\nAKHIR ALTERNATIF · cari bukti sebelum memutuskan.",
		"good": "Kau menyerahkan album, surat, serta bukti pendukung kepada Bu Ratna. Sari mengonfirmasi tanggal. Adit menjelaskan foto itu. Raka akhirnya dapat bercerita. Namanya dipulihkan.\n\nGudang ditutup. Danu menghilang. Satu kotak dalam daftar tidak ditemukan.\n\nAKHIR ALTERNATIF · cerita di dalam pabrik masih menyimpan pintu lain.",
		"broken": "Bisikan menggunakan suaramu sendiri. Ingatan terakhir terasa seperti mimpi orang lain.\n\nCheckpoint tersedia. Bergerak menyamping ketika makhluk membungkuk. Arahkan lampu dengan tepat dan beri waktu agar panasnya turun.",
		"caught": "Tangan-Tangan mencapai saluran sebelum kau menemukan akses servis.\n\nGunakan Shift, tarik rem dengan R, lalu terus menuju tanda servis kuning.",
		"cliffhanger": "Tiga ketukan. Daisy menatap sesuatu di belakangmu. Sebelum kau sempat menoleh, lampunya padam.\n\nCHAPTER 1 — END\nTo be continued…\n\nKALA / Port native Godot\nCerita, tekstur, foto, rekaman dan musik: berasal dari HTML referensi pengguna.\nGeometri dan sistem native: implementasi ulang untuk proyek ini."}
	if story.get("endings", {}).has(type) and story.endings[type] is Array:
		titles[type] = story.endings[type][0]
		texts[type] = story.endings[type][1]
	ui.clear_panel(titles[type], "ending")
	ui.paragraph(texts[type])
	ui.paragraph("Waktu %02d:%02d · Bukti %d/4 · Catatan %d" % [int(State.data.elapsed) / 60, int(State.data.elapsed) % 60, State.data.evidence.size(), State.data.notes.size()])
	if type in ["broken", "caught"]: ui.button("ULANG CHECKPOINT", "retry")
	ui.button("MAIN DARI AWAL", "new")
	ui.button("MENU UTAMA", "title")
	_sync_active()

func _objective() -> String:
	if State.data.room == "hallucination": return boss_revision.objective()
	if State.flag("prologueVersion") and State.data.room in ["home", "schoolyard", "school", "neighborhood"]: return chapter_flow.objective()
	match State.data.room:
		"school": return "Bicara dengan Sari dan Adit. Periksa foto kelas 1A dan loker Raka." if not State.data.evidence.has("A") else "Bicarakan surat itu dengan Danu, lalu menuju gerbang." if not State.flag("invited") else "Ikuti undangan Danu melalui gerbang. Periksa bukti sebelum memutuskan."
		"street": return "Periksa warung dan catatan servis. Sambungkan kabel penerangan." if not State.solved("fuse") else "Lampu gang menyala. Masuk Gudang Kartini."
		"loading": return "Periksa ruang jaga dan suku cadang. Pulihkan panel bangsal." if not State.solved("panel") else "SI PENGAWAS · putuskan tugas jaganya." if not State.flag("overseerDefeated") else "Ada ruang lain di balik pintu utara."
		"relay": return "Telusuri Rumah Relai." if not State.flag("lenteraOwned") else "Pintu arsip masih tertutup." if not State.flag("relaySolved") else "Pengunci arsip terlepas. Masuk jalur pemeliharaan."
		"pursuit": return "Cari Sun · Moon · Star di laci meja, loker malam dan lemari perkakas (%d/3). Ctrl: sembunyi; R: rem." % [3 - level.escape_puzzle.missing().size()] if not State.flag("escapePuzzleSolved") else "Pintu SERVIS terbuka. Turuni ventilasi, tarik kisi dan rem kipas dengan R."
		"production": return "Periksa perlengkapan tekanan di bengkel dan perawatan." if not State.solved("valve") else "TANGAN-TANGAN · putuskan cengkeramannya." if not State.flag("handsDefeated") else "Saluran aman. Masuk kantor."
		"office": return "Baca album, cari gulungan pita dan putar rekaman audit." if not State.flag("auditVerified") else "Urutkan saklar audit. Jalur servis di selatan tetap tersedia."
		"ritual": return "PEMEGANG · tarik setiap lilin tiga kali, lalu sorot tubuh / inti." if not State.flag("tumbalDefeated") else "Perjanjian runtuh. Masuk lorong belakang."
		"corridor": return "Kejar Danu menuju pintu keluar." if not State.flag("exitLocked") else "Cari pintu logam D–08 di dinding timur."
		"daisy": return "Periksa lemari kaca bertuliskan DAISY."
	return ""

func _process(delta: float) -> void:
	if entering or not is_instance_valid(level) or not level.is_inside_tree(): return
	claw_cooldown = maxf(0, claw_cooldown - delta)
	var active = player.active
	if active:
		if State.flag("prologueVersion"): chapter_flow.update(delta)
		if State.data.room == "pursuit" and not test_mode and not State.flag("handsPursuitComplete") and State.flag("escapePuzzleSolved") and player.position.x > 86 and player.position.z < -122 and player.position.y < -7.4:
			_rescue(); return
		if State.data.room == "relay" and not test_mode and State.flag("relaySolved") and not State.flag("handsAmbushRunSeen") and player.position.z < -10:
			narrative.start("ambush")
			return
		State.data.elapsed += delta
		autosave_time += delta
		if autosave_time > 45 and not is_instance_valid(boss): _save(); autosave_time = 0
		if burn_left > 0:
			burn_left -= delta
			hurt(delta * 2)
		_update_projectiles(delta)
	ui.chapter.text = "%02d / %s" % [State.ROOMS.find(State.data.room) + 1, State.TITLES[State.ROOMS.find(State.data.room)]]
	ui.objective.text = _objective()
	ui.health.value = State.data.sanity
	ui.heat.value = player.heat * 100
	ui.vitals.text = "A K A L  S E H A T\n%d" % ceili(State.data.sanity)
	ui.heat.visible = player.heat > 0.035 or player.cooldown > 0 or player.pulse_cooldown > 0
	ui.heat_label.visible = ui.heat.visible
	ui.heat_label.text = "Mendinginkan" if player.cooldown > 0 else "Pulse %.1f d" % player.pulse_cooldown if player.pulse_cooldown > 0 else "Panas"
	ui.evidence_list.text = ""
	ui.evidence_list.visible = State.data.room != "home" and State.flag("lessonSeen") or not State.flag("prologueVersion")
	ui.chapter.visible = not is_instance_valid(boss)
	ui.objective.visible = not is_instance_valid(boss)
	ui.health.visible = State.data.room not in ["home", "school", "schoolyard", "neighborhood"]
	ui.vitals.visible = ui.health.visible
	for key in ["A", "op1", "op2", "B"]:
		ui.evidence_list.text += ("■ " if State.data.evidence.has(key) else "□ ") + {"A": "surat loker", "op1": "sobekan foto", "op2": "agenda Sari", "B": "album & perjanjian"}[key] + "\n"
	ui.prompt.text = ""
	if player.bound: ui.prompt.text = "R · LEPASKAN / E · BERJUANG %d/7" % player.struggle
	elif is_instance_valid(player.target): ui.prompt.text = ("R" if player.target.tool_only or player.camera.global_position.distance_to(player.target.global_position) > 2.7 else "E") + " · " + player.target.caption
	ui.boss.visible = is_instance_valid(boss)
	ui.boss_bar.visible = is_instance_valid(boss) and boss.kind != "chase"
	ui.boss_detail.visible = ui.boss_bar.visible
	if is_instance_valid(boss):
		ui.boss.text = boss.stats.label
		ui.boss_detail.text = "%d HP" % ceili(boss.hp)
		if boss.kind == "tumbal":
			ui.boss.text += "  /  FASE %d" % boss.phase
			ui.boss_detail.text = "LILIN  %d · %d · %d" % boss.seals if boss.shield else "%d HP  /  INTI TERBUKA" % ceili(boss.hp)
		ui.boss_bar.value = boss.hp / (80 if boss.kind == "overseer" else boss.max_hp) * 100
	$FilmLayer/Film.material.set_shader_parameter("damage", 1.0 - State.data.sanity / 100)
	for i in range(level.marks.size()):
		var mark = level.marks[i]
		if not is_instance_valid(mark) or not mark.is_inside_tree(): continue
		var difference: Vector3 = mark.global_position - player.camera.global_position
		var direction = difference.normalized()
		var lit = State.flag("relayPower") and player.lamp.visible and difference.length() < 12 and (-player.camera.global_basis.z).dot(direction) > 0.94
		if lit:
			lit = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(player.camera.global_position, mark.global_position - direction * 0.08, 1)).is_empty()
		mark.visible = lit

func _update_projectiles(delta: float) -> void:
	for i in range(projectiles.size() - 1, -1, -1):
		var p: Dictionary = projectiles[i]
		var before: Vector3 = p.node.global_position
		if p.kind == "hand":
			var toward: Vector3 = (player.position + Vector3.UP - before).normalized()
			p.velocity = (p.velocity as Vector3).lerp(toward * 3.5, minf(1, delta * 2.2))
			p.node.rotation.z += delta * 0.5
		p.node.position += p.velocity * delta
		p.life -= delta
		var query = PhysicsRayQueryParameters3D.create(before, p.node.global_position, 1)
		var hit = not get_world_3d().direct_space_state.intersect_ray(query).is_empty()
		if player.global_position.distance_to(p.node.global_position - Vector3.UP) < 0.8:
			if p.kind == "hand": player.bind_player()
			else: burn_left = 6; hurt(4)
			hit = true
		if hit or p.life <= 0:
			if p.kind == "slime": boss_revision.add_slime(Vector3(p.node.position.x, 0.025, p.node.position.z), 1.6)
			p.node.queue_free()
			projectiles.remove_at(i)

func _smoke() -> void:
	print("SMOKE BUILD: ", ProjectSettings.get_setting("application/config/version"))
	State.set_flag("prologueVersion")
	test_mode = true
	State.save_enabled = false
	playing = true
	ui.close_panel()
	for id in State.ROOMS:
		await enter_room(id, false, false)
		await get_tree().physics_frame
		print("SMOKE ROOM OK: ", id, " nodes=", level.get_child_count())
	await quit_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: quit_game()

func quit_game() -> void:
	if quitting: return
	quitting = true
	playing = false
	narrative.cancel()
	player.active = false
	set_process(false)
	for actor in $Actors.get_children():
		if actor is KalaEnemy: actor.enabled = false
	audio.shutdown()
	# Let the audio server release active playback before tearing down resources.
	await get_tree().create_timer(0.6, true, false, true).timeout
	var shutdown = preload("res://scripts/systems/shutdown.gd").new()
	get_tree().root.add_child(shutdown)
	shutdown.finish(self)

func _exit_tree() -> void:
	KalaGeometry.materials.clear()

