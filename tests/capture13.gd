extends Node3D
var game: Node3D
var stage: Node3D
var camera: Camera3D
const G=preload("res://scripts/systems/geometry.gd")

func _ready() -> void:
	get_window().unfocusable=true;State.save_enabled=false;State.reset()
	stage=Node3D.new();add_child(stage)
	var env=WorldEnvironment.new();var environment=Environment.new();env.environment=environment
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("89948d")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("c9d3d8");environment.ambient_light_energy=0.55
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;stage.add_child(env)
	var sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-40,-30,0);sun.light_energy=1.5;sun.shadow_enabled=true;stage.add_child(sun)
	G.box(stage,Vector3(0,-0.1,0),Vector3(18,0.2,12),G.material("plain",Color("78837a")))
	camera=Camera3D.new();camera.fov=45;stage.add_child(camera);camera.make_current()
	for i in range(5):
		var who=["Danu","Raka","Adit","Sari","Ratna"][i]
		var model=preload("res://scripts/systems/model_factory.gd").make("npc_"+who);model.position.x=(i-2)*1.25;stage.add_child(model)
		var label=G.sign_text(stage,who,Vector3(model.position.x,2.1,0),24);label.outline_size=2
	camera.position=Vector3(0,1.4,9);camera.look_at(Vector3(0,1.0,0));await shot("characters")
	camera.position=Vector3(2.5,1.25,2.9);camera.look_at(Vector3(2.5,1.15,0));await shot("ratna")
	stage.queue_free();await get_tree().process_frame
	stage=Node3D.new();add_child(stage)
	var mascot=preload("res://scripts/systems/mascot_model.gd").create();stage.add_child(mascot)
	var light=OmniLight3D.new();light.position=Vector3(0,3,3);light.omni_range=9;light.light_energy=3;stage.add_child(light)
	camera=Camera3D.new();camera.fov=45;stage.add_child(camera);camera.position=Vector3(0,1.9,6.5);camera.look_at(Vector3(0,1.65,0));camera.make_current();await shot("mascot")
	stage.queue_free();await get_tree().process_frame
	if "--assets-only" in OS.get_cmdline_user_args():get_tree().quit();return
	game=preload("res://scenes/main/main.tscn").instantiate();add_child(game)
	await get_tree().process_frame;game.test_mode=true;game.playing=true;game.ui.close_panel();State.set_flag("prologueVersion");State.set_flag("lessonSeen")
	await room("home");game.narrative.start("wash");game.narrative.set_process(false);game.narrative.advance(5);await shot("shower");game.narrative.cancel()
	await room("school");State.data.flags.erase("lessonSeen");game.narrative.start("lesson");game.narrative.set_process(false);game.narrative.advance(4);await shot("classroom");game.narrative.cancel()
	await room("loading");State.set_flag("overseerDefeated");State.set_flag("oldFlashBroken")
	for i in range(80):game.level._process(1.0/60)
	game.player.lamp_on=false;await view("route_entrance",Vector3(0,0.05,-19),Vector3(0,1.7,-29))
	await view("gallery",Vector3(3.5,0.05,-29.5),Vector3(9,1.35,-27))
	await view("control",Vector3(-3.5,0.05,-29),Vector3(-10,1.4,-31))
	State.set_flag("inspectionPower");game.level.factory_route.update();await view("route_power",Vector3(0,0.05,-32),Vector3(0,1.6,-41))
	State.set_flag("lenteraOwned");game.player.lamp_on=true
	game.player.position=Vector3(0,0.05,5);game.player.last_safe_position=game.player.position;game.player.camera.look_at(Vector3(1.5,1.25,-2));game.player.equip_blend=1;game.player.reach_time=1.0;game.player.reach_point=Vector3(1.5,1.25,-2)
	game.player.active=true;game.player._physics_process(0.001);game.player.active=false;game.player.set_physics_process(false);await shot("claw")
	game.player.reach_time=0;game.player.claw_head.transform=game.player.claw_head_rest
	game.campus.clear(game.level);game.boss_revision.cancel();game.audio.shutdown();game.queue_free()
	await get_tree().process_frame;await get_tree().physics_frame;await get_tree().create_timer(0.4).timeout;get_tree().quit()

func room(id: String) -> void:
	game.cinematic=false;game.ui.fade.color.a=0;game.boss_revision.cancel();game.boss_revision.set_process(false)
	await game.enter_room(id,false,false);game.player.active=false;game.level.set_process(false)
	if is_instance_valid(game.boss):game.boss.enabled=false
	await get_tree().physics_frame

func view(label: String,point: Vector3,target: Vector3) -> void:
	game.player.position=point;game.player.camera.look_at(target);await shot(label)

func shot(label: String) -> void:
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	await get_tree().create_timer(0.4).timeout;await RenderingServer.frame_post_draw;await RenderingServer.frame_post_draw
	print("CAPTURE13 ",label," ",get_viewport().get_texture().get_image().save_png("res://docs/screenshots/"+label+"_13.png"))
