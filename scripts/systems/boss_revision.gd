extends Node
const G = preload("res://scripts/systems/geometry.gd")
const Models = preload("res://scripts/systems/model_factory.gd")
const MEMORY_IDS = ["op1", "op2", "A", "B"]
var host: Node3D
var mode = ""
var clock = 0.0
var wave_timer = 2.0
var hazards: Array[Dictionary] = []
var pending_hands: Array[Dictionary] = []
var nightmare: Node3D
var rig: RefCounted
var anchors: Array[int] = []
var path = PackedVector2Array()
var path_index = 0
var replan = 0.0
var stun = 0.0
var human: Node3D
var finish_origin = Vector3.ZERO
var pulse = 0.0
var slam_stage = -1
var visions: Array[Node3D] = []
var vision_rigs: Array[RefCounted] = []
var center_origin = Vector3.ZERO
const CENTER_SECONDS = 1.2
const FOG_SECONDS = 4.0

func all_evidence() -> bool:
	for id in MEMORY_IDS:
		if not State.data.evidence.has(id): return false
	return true

func phase_changed(next: int) -> void:
	if not is_instance_valid(host.boss): return
	if host.boss.kind == "hands" and next == 2:
		host.ui.notify("Dindingnya bergerak! Tangan datang dari lantai, dinding, dan atas. R mematahkan tangan yang mendekat.", 7)
		hand_wave()
	if host.boss.kind == "tumbal" and next == 2:
		wave_timer = 0.5
		host.ui.notify("Lendir merembes ke lantai. Jauhi genangannya—lendir mengikis sanity setiap detik.", 7)
	if host.boss.kind == "tumbal" and next == 3:
		clear_hazards()
		mode = "center"; clock = 0
		center_origin = host.boss.position
		host.cinematic = true; host._sync_active()
		host.boss.scripted_motion = true
		host.ui.notify("Danu mundur ke tengah. Ada sesuatu keluar dari portalnya…", 5)

func hand_wave() -> void:
	if not is_instance_valid(host.boss): return
	if not pending_hands.is_empty() or host.projectiles.size() >= 18: return
	for i in range(6):
		var a = TAU * i / 6 + host.boss.elapsed * 0.23
		var p = host.player.position + Vector3(sin(a) * 7.5, 0, cos(a) * 7.5)
		p.x = clampf(p.x, -host.level.width * 0.4, host.level.width * 0.4)
		p.z = clampf(p.z, -host.level.depth * 0.4, host.level.depth * 0.4)
		p.y = [0.25, 2.7, 4.2][i % 3]
		if not host.level.safety.contains(p, 0.4): continue
		var warning = G.sphere(host.get_node("Actors"), p, Vector3.ONE * 0.45, glow_material("b87965"))
		pending_hands.append({"node": warning, "point": p, "time": 1.0 + i * 0.12})

func glow_material(color: String) -> StandardMaterial3D:
	var mat = StandardMaterial3D.new(); mat.albedo_color = Color(color); mat.emission_enabled = true; mat.emission = Color(color); mat.emission_energy_multiplier = 1.8; return mat

func slime_wave() -> void:
	if hazards.size() > 18: return
	for x in range(-2, 3):
		for z in range(-2, 3):
			add_slime(Vector3(x * 5.1, 0.025, z * 5.1), 3.3, 14.0, 1.5)
	pulse += 1

func add_slime(p: Vector3, radius = 1.4, life = 10.0, warning = 0.65) -> void:
	if hazards.size() >= 28 or not host.level.safety.contains(p, radius * 0.5): return
	var node = MeshInstance3D.new(); node.name = "DamagingSlime"
	var quad = QuadMesh.new(); quad.size = Vector2.ONE * radius * 2; node.mesh = quad
	var mat = ShaderMaterial.new(); mat.shader = preload("res://assets/materials/slime.gdshader"); node.material_override = mat
	node.rotation.x = -PI / 2; node.position = Vector3(p.x, 0.025, p.z); host.get_node("Actors").add_child(node)
	hazards.append({"node": node, "radius": radius, "life": life, "warning": warning})

func _process(delta: float) -> void:
	if not is_instance_valid(host.level) or host.entering or not host.playing: return
	if host.ui.mode != "": return
	if mode in ["center", "fog", "banish", "portal", "human_escape"]:
		update_scene(delta); return
	if not host.player.active: return
	update_hazards(delta)
	if mode == "chase": update_chase(delta); return
	if is_instance_valid(host.boss):
		if host.boss.phase >= 2 and host.boss.kind == "tumbal":
			wave_timer -= delta
			if wave_timer <= 0: slime_wave(); wave_timer = 8

func update_hazards(delta: float) -> void:
	for i in range(pending_hands.size() - 1, -1, -1):
		var h: Dictionary = pending_hands[i]; h.time -= delta
		if h.time <= 0:
			host._projectile(h.point, (host.player.position + Vector3.UP - h.point).normalized(), "hand")
			h.node.queue_free(); pending_hands.remove_at(i)
	var touching = false
	for i in range(hazards.size() - 1, -1, -1):
		var h: Dictionary = hazards[i]; h.life -= delta; h.warning -= delta
		h.node.scale = Vector3.ONE * minf(1, maxf(0.1, (1.25 - h.warning) / 1.25)) * minf(1, h.life)
		if h.warning <= 0 and host.player.position.y < 0.28 and Vector2(host.player.position.x - h.node.position.x, host.player.position.z - h.node.position.z).length() < h.radius * 0.85: touching = true
		if h.life <= 0: h.node.queue_free(); hazards.remove_at(i)
	if touching: host.hurt(delta * 6)

func update_scene(delta: float) -> void:
	clock += delta
	if mode == "fog" and is_instance_valid(host.boss) and host.boss.hands_rig != null:
		host.boss.hands_rig.animate(delta, 0.0, false, 0.2)
	elif mode in ["banish", "portal"] and is_instance_valid(nightmare) and rig != null:
		rig.animate(delta, delta * 6 if mode == "portal" and clock < 1.3 else 0.0, false, 1.0 if mode == "portal" else 0.0)
	var env: Environment = host.get_node("WorldEnvironment").environment
	match mode:
		"center":
			if not is_instance_valid(host.boss): cancel(); return
			var previous: Vector3 = host.boss.position
			host.boss.position = center_origin.lerp(Vector3(0, 0.05, 0), smoothstep(0, CENTER_SECONDS, clock))
			host.boss.hands_rig.animate(delta, previous.distance_to(host.boss.position))
			if clock >= CENTER_SECONDS:
				mode = "fog"; clock = 0; host.cinematic = true; host._sync_active()
				portal_smoke()
				if Vector2(host.player.position.x, host.player.position.z).length() < 1.5: host.player.position = Vector3(0, 0.05, 3.5)
				host.player.camera.look_at(Vector3(0, 2, 0))
				spawn_visions()
				host.ui.notify("AKU: Mana Danu yang asli? Aku… nggak kuat lagi!", FOG_SECONDS)
				host.audio.effect("scare")
		"fog":
			animate_visions(delta)
			env.fog_density = lerpf(0.0045, 0.22, smoothstep(0.6, FOG_SECONDS, clock))
			env.fog_light_color = Color("86818f")
			host.player.camera.rotation.z = sin(clock * 2.4) * 0.035
			host.ui.fade.color = Color(0.39, 0.36, 0.42, smoothstep(3.4, FOG_SECONDS, clock))
			if clock >= FOG_SECONDS: _begin_chase()
		"banish":
			nightmare.scale = Vector3.ONE * maxf(0.03, 1 - clock / 4)
			nightmare.rotation.y += delta * 2
			host.player.camera.look_at(nightmare.position + Vector3.UP * 1.8)
			if clock >= 4: _return_to_danu()
		"portal":
			host.player.camera.look_at(nightmare.position + Vector3.UP * 2)
			var to_player = host.player.position - nightmare.position; to_player.y = 0
			nightmare.rotation.y = atan2(to_player.x, to_player.z)
			if clock < 1.3 and State.settings.scares:
				nightmare.position = nightmare.position.move_toward(host.player.position - to_player.normalized() * 0.55, delta * 16)
				host.player.camera.rotation.z = sin(clock * 61) * 0.055
			elif clock > 1.3:
				# Pass through the aperture behind the body, then see Danu escape.
				var destination = nightmare.to_global(Vector3(0, 0, -1.0))
				host.player.position = host.player.position.lerp(destination, minf(1, delta * 1.9))
				host.ui.fade.color = Color(0.08, 0.0, 0.13, smoothstep(1.4, 3.0, clock))
			if clock > 3.4:
				nightmare.hide(); human = Models.make("npc_Danu"); host.get_node("Actors").add_child(human)
				host.player.position = Vector3(0, 0.05, -89); human.position = Vector3(0, 0, -94)
				mode = "human_escape"; clock = 0; host.ui.fade.color.a = 0
				host.ui.notify("Danu kembali menjadi manusia. Aku mengejarnya… tetapi jalan ini terus menjauh.", 6)
		"human_escape":
			human.position.z = -94 - clock * 1.5; human.rotation.y = PI; human.animate_walk(clock * 11)
			host.player.position.z = -89 - clock * 1.2
			host.player.camera.look_at(human.position + Vector3.UP * 1.5)
			host.ui.fade.color.a = smoothstep(3.1, 4.8, clock)
			if clock >= 5:
				mode = ""; host.cinematic = false; host.ui.fade.color.a = 0; State.set_flag("portalBadEnding"); host._ending("consumed")

func _begin_chase() -> void:
	clear_visions()
	mode = "loading"; host.cinematic = false; host.ui.fade.color.a = 0
	host.player.camera.rotation.z = 0
	await host.enter_room("hallucination", false, false)

func portal_smoke() -> void:
	if not is_instance_valid(host.boss): return
	var smoke = CPUParticles3D.new(); smoke.name = "PortalFogEmitter"
	smoke.amount = 72; smoke.lifetime = 6; smoke.emitting = true; smoke.local_coords = false
	smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE; smoke.emission_sphere_radius = 0.8
	smoke.direction = Vector3(0, 0.15, 1); smoke.spread = 150; smoke.gravity = Vector3.ZERO
	smoke.initial_velocity_min = 0.8; smoke.initial_velocity_max = 2.4
	smoke.scale_amount_min = 1.2; smoke.scale_amount_max = 3.4
	var quad = QuadMesh.new(); quad.size = Vector2(2, 2); smoke.mesh = quad
	var gradient = Gradient.new(); gradient.set_color(0, Color(0.55, 0.52, 0.60, 0.28)); gradient.set_color(1, Color(0.55, 0.52, 0.60, 0))
	var texture = GradientTexture2D.new(); texture.gradient = gradient; texture.fill = GradientTexture2D.FILL_RADIAL; texture.fill_from = Vector2(0.5, 0.5); texture.fill_to = Vector2(1.0, 0.5); texture.width = 128; texture.height = 128
	var mat = StandardMaterial3D.new(); mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED; mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_texture = texture; mat.vertex_color_use_as_albedo = true
	smoke.material_override = mat
	host.boss.visual.get_node("BackPortal").add_child(smoke)

func setup_chase() -> void:
	if is_instance_valid(nightmare): nightmare.queue_free()
	nightmare = Models.make("nightmare"); nightmare.name = "HallucinationDanu"; host.get_node("Actors").add_child(nightmare)
	nightmare.position = Vector3(0, 0, 11)
	rig = preload("res://scripts/enemies/final_rig.gd").new(); rig.bind(nightmare)
	anchors.clear(); path.clear(); clock = 0; replan = 0; stun = 3; mode = "chase"
	slam_stage = -1
	host.player.release_bind(); host.player.lamp_on = true; host.cinematic = false; host._sync_active()
	host.audio.play_music("chase")
	host.ui.notify("HALUSINASI / LARI! Aktifkan empat ingatan di altar bercahaya (E). Sorot wajahnya untuk menahan pengejar. R mematahkan tangan.", 10)
	State.save_game([host.player.position.x, host.player.position.y, host.player.position.z, 0, 0])

func update_chase(delta: float) -> void:
	clock += delta; stun = maxf(0, stun - delta); replan -= delta
	var to_monster: Vector3 = nightmare.position + Vector3.UP * 2 - host.player.camera.global_position
	if host.player.lamp.visible and host.player.cooldown <= 0 and to_monster.length() < 14 and (-host.player.camera.global_basis.z).dot(to_monster.normalized()) > 0.94:
		var ray = PhysicsRayQueryParameters3D.create(host.player.camera.global_position, nightmare.position + Vector3.UP * 2, 1)
		if host.get_world_3d().direct_space_state.intersect_ray(ray).is_empty():
			host.player.add_beam_heat(delta); stun = maxf(stun, 0.15)
	if replan <= 0:
		path = host.level.actor_path(nightmare.position, host.player.position); path_index = 1 if path.size() > 1 else 0; replan = 0.3
	var before = nightmare.position
	if stun <= 0 and path_index < path.size():
		var p = path[path_index]; var goal = Vector3(p.x, 0, p.y)
		nightmare.position = nightmare.position.move_toward(goal, delta * (4.5 if nightmare.position.distance_to(host.player.position) > 20 else 3.8))
		if nightmare.position.distance_to(goal) < 0.08: path_index += 1
	var direction: Vector3 = host.player.position - nightmare.position; direction.y = 0
	nightmare.rotation.y = lerp_angle(nightmare.rotation.y, atan2(direction.x, direction.z), minf(1, delta * 4))
	rig.animate(delta, before.distance_to(nightmare.position), false, 0.8)
	if direction.length() < 1.3 and stun <= 0:
		host.scare.start("broken"); return
	# Doors slam behind the runner; phantoms flicker in the peripheral lanes.
	for phantom in host.level.get_node("FracturedMemories").get_children():
		if str(phantom.name).begins_with("FalseDanu"):
			phantom.visible = absf(phantom.position.z - host.player.position.z) < 17 and sin(clock * 3.1 + phantom.position.z) > -0.65
		elif str(phantom.name).begins_with("MemoryShutter"):
			var closed = host.player.position.z < float(phantom.get_meta("threshold")) - 5
			phantom.position.y = move_toward(phantom.position.y, 2.5 if closed else 7.2, delta * 9)
	var stage = clampi(int(-host.player.position.z / 23), 0, 3)
	if stage > slam_stage:
		slam_stage = stage; host.audio.effect("impact")
		if stage > 0: host.ui.notify(["", "Suara Ibu datang dari loker. Jangan berhenti.", "Semua Danu menoleh bersamaan. Percayai tanggal dalam foto.", "Lorong pabrik kembali. Bawa seluruh ingatan ke ujungnya."][stage], 5)
	if fmod(clock, 9) < delta and host.player.position.z > -87:
		var p = host.player.position + Vector3(5.5 if int(clock) % 2 else -5.5, 1.4, -4)
		host._projectile(p, (host.player.position + Vector3.UP - p).normalized(), "hand")
	if host.player.position.z < -96: resolve_chase()

func remember(index: int) -> void:
	if mode != "chase" or index < 0 or index > 3 or anchors.has(index): return
	if not State.data.evidence.has(MEMORY_IDS[index]):
		host.ui.notify("Ingatan ini kosong. Bukti itu tidak pernah kuambil… Terus lari!", 5); stun = maxf(stun, 1.5); return
	anchors.append(index); stun = 5.0
	State.data.sanity = minf(100, State.data.sanity + 12)
	var altar = host.level.get_node("FracturedMemories/MemoryAltar%d" % index)
	altar.get_node("MemoryGlow").light_color = Color("ffe2a0")
	host.audio.effect("click")
	host.ui.notify("%d/4 ingatan dipulihkan. Itu bukan Danu yang asli. Terus menuju ujung lorong!" % anchors.size(), 6)

func resolve_chase() -> void:
	if mode != "chase": return
	clock = 0; host.cinematic = true; host._sync_active(); host.player.release_bind(); clear_hazards()
	if all_evidence() and anchors.size() == 4:
		mode = "banish"; State.set_flag("hallucinationDefeated")
		host.ui.notify("AKU: Foto. Agenda. Surat. Perjanjian. Aku ingat semuanya. Kamu bukan Danu!", 6)
		for i in range(4):
			var page = G.box(nightmare, Vector3(sin(i * PI / 2) * 1.7, 1.7, cos(i * PI / 2) * 1.7), Vector3(0.45, 0.6, 0.025), glow_material("cde9d0")); page.rotation.y = i * PI / 2
	else:
		mode = "portal"; host.audio.effect("scare")
		host.ui.notify("Ada bagian yang hilang. Portal itu… ada di belakang tubuhnya!", 4)

func _return_to_danu() -> void:
	mode = "loading"; host.cinematic = false; State.set_flag("tumbalDefeated")
	await host.enter_room("ritual", false, false)
	mode = ""; host.story_origin = Vector3.ZERO; host._boss_defeated("tumbal")

func objective() -> String:
	return "LARI / gunakan bukti di empat altar dengan E (%d/4). Sorot pengejar untuk menahannya. Ujung lorong di depan." % anchors.size()

func clear_hazards() -> void:
	for h in hazards:
		if is_instance_valid(h.node): h.node.queue_free()
	for h in pending_hands:
		if is_instance_valid(h.node): h.node.queue_free()
	hazards.clear(); pending_hands.clear()

func cancel() -> void:
	clear_visions()
	clear_hazards(); mode = ""; nightmare = null; human = null; rig = null; anchors.clear(); wave_timer = 2

func spawn_visions() -> void:
	clear_visions()
	for i in range(6):
		var vision = Models.make("nightmare"); vision.name = "EncirclingBoss%d" % i
		host.get_node("Actors").add_child(vision); visions.append(vision)
		var motion = preload("res://scripts/enemies/final_rig.gd").new(); motion.bind(vision); vision_rigs.append(motion)
	animate_visions(0)

func animate_visions(delta: float) -> void:
	for i in range(visions.size()):
		var angle = TAU * i / visions.size() + clock * 0.24
		var p = host.player.position + Vector3(sin(angle) * 3.7, 0, cos(angle) * 3.7)
		p.x = clampf(p.x, -host.level.width * 0.45, host.level.width * 0.45)
		p.z = clampf(p.z, -host.level.depth * 0.45, host.level.depth * 0.45)
		visions[i].position = p
		var facing = host.player.position - p
		visions[i].rotation.y = atan2(facing.x, facing.z)
		vision_rigs[i].animate(delta, delta * 0.7, false, 0.35)

func clear_visions() -> void:
	for vision in visions:
		if is_instance_valid(vision): vision.queue_free()
	visions.clear(); vision_rigs.clear()
