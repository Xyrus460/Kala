extends Node3D

var host: Node3D
var running = false
var elapsed = 0.0
var result = "caught"
var camera: Camera3D
var monster: Node3D
var rig: RefCounted
var original_pose: Transform3D
var lamp_was_on = false

func _ready() -> void:
	set_process(false)

func start(ending: String) -> void:
	if running: return
	if not State.settings.scares or host.test_mode: host._ending(ending); return
	result = ending; running = true; elapsed = 0
	host.cinematic = true; host._sync_active()
	camera = host.player.camera; original_pose = camera.transform
	lamp_was_on = host.player.lamp_on; host.player.lamp_on = false; host.player.lamp.hide()
	monster = preload("res://scripts/systems/model_factory.gd").make("hands" if State.data.room in ["pursuit", "production"] else "tumbal" if State.data.room in ["ritual", "hallucination"] else "overseer") as Node3D
	camera.add_child(monster)
	monster.position = Vector3(0, -2.0, -3.2)
	monster.rotation.y = 0
	if State.data.room in ["pursuit", "production"]:
		rig = preload("res://scripts/enemies/hands_rig.gd").new(); rig.bind(monster)
	var light = OmniLight3D.new(); light.position = Vector3(-0.7, 2.0, 0.8); light.light_color = Color("b9c9c3"); light.light_energy = 0.95; light.omni_range = 5; monster.add_child(light)
	host.player.viewmodel.hide()
	host.audio.effect("scare")
	set_process(true)

func _process(delta: float) -> void:
	if not running: return
	elapsed += delta
	var lunge = smoothstep(0.05, 0.32, elapsed)
	monster.position.z = lerpf(-3.2, -1.15, lunge)
	monster.position.y = -2.0 + sin(elapsed * 16) * 0.035
	monster.rotation.z = sin(elapsed * 31) * 0.09
	camera.rotation.z = sin(elapsed * 67) * 0.035 * lunge
	if rig != null: rig.animate(delta, delta * 4.5, false, 1.0)
	host.ui.fade.color = Color(0.035, 0.002, 0.002, clampf((elapsed - 0.68) / 0.27, 0, 1))
	if elapsed >= 1.02:
		cancel()
		host._ending(result)

func cancel() -> void:
	if not running: return
	running = false; set_process(false)
	if is_instance_valid(monster): monster.queue_free()
	monster = null; rig = null
	camera.transform = original_pose
	host.player.lamp_on = lamp_was_on
	host.player.viewmodel.show()
	host.cinematic = false; host.ui.fade.color = Color(0, 0, 0, 0)
