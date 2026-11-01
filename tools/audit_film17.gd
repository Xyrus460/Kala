extends Node3D
## Offline authored 44-second film. Render straight to OGV with Godot Movie
## Maker's native Theora/Vorbis writer; some local FFmpeg builds misencode it.
const G=preload("res://scripts/systems/geometry.gd")
const A=preload("res://scripts/systems/free_assets.gd")
const C=preload("res://scripts/systems/character_model.gd")
const KIT="res://assets/vendor/kenney_factory/"
const CUTS=[0.0,6.0,12.0,20.0,27.0,35.0,44.0]
var camera: Camera3D
var sets: Array[Node3D]=[]
var actors: Dictionary={}
var film: ShaderMaterial
var subtitle: Label
var timestamp: Label
var elapsed=0.0
var frame=0
var previous=-1
var saved: Dictionary={}
var shutter: Node3D
var alarm: OmniLight3D

func _ready() -> void:
	get_window().unfocusable=true;State.save_enabled=false
	get_viewport().msaa_3d=Viewport.MSAA_2X
	var world=WorldEnvironment.new();var env=Environment.new();world.environment=env;add_child(world)
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("070b0a")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("84988d");env.ambient_light_energy=0.10
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.tonemap_exposure=1.0
	env.fog_enabled=true;env.fog_density=0.012;env.fog_light_color=Color("263a34");env.fog_light_energy=0.4
	camera=Camera3D.new();camera.fov=49;camera.near=0.035;add_child(camera);camera.current=true
	for i in range(6):
		var stage=Node3D.new();stage.position.x=i*60;add_child(stage);sets.append(stage)
	_corridor(sets[0],false)
	_contract(sets[1])
	_chamber(sets[2],false)
	_chamber(sets[3],true)
	_invitation(sets[4])
	_corridor(sets[5],true)
	_overlay()
	var soundtrack=AudioStreamPlayer.new();soundtrack.stream=_score();add_child(soundtrack);soundtrack.play()
	_update_scene(0.0,1.0/24)

func metal(color="45574f") -> Material:
	var m=ShaderMaterial.new();m.shader=preload("res://assets/materials/factory_metal.gdshader");m.set_shader_parameter("paint",Color(color));return m

func box(parent: Node3D,p: Vector3,size: Vector3,mat: Material) -> MeshInstance3D:
	return G.box(parent,p,size,mat)

func beam(parent: Node3D,a: Vector3,b: Vector3,r=0.035,mat: Material=null) -> void:
	var m=G.cylinder(parent,(a+b)/2,r,a.distance_to(b),metal() if mat==null else mat);m.quaternion=Quaternion(Vector3.UP,(b-a).normalized())

func text(parent: Node3D,value: String,p: Vector3,pixel=0.003,color=Color("c2b99b")) -> Label3D:
	var label=G.sign_text(parent,value,p,26);label.pixel_size=pixel;label.outline_size=0;label.modulate=color;return label

func light(parent: Node3D,p: Vector3,target: Vector3,color: Color,energy: float,range_value=15.0,angle=42.0) -> SpotLight3D:
	var lamp=SpotLight3D.new();lamp.position=p;parent.add_child(lamp);lamp.look_at(parent.to_global(target));lamp.light_color=color;lamp.light_energy=energy;lamp.spot_range=range_value;lamp.spot_angle=angle;lamp.shadow_enabled=true
	return lamp

func fill(parent: Node3D,p: Vector3,color: Color,energy: float,range_value=6.0) -> OmniLight3D:
	var l=OmniLight3D.new();l.position=p;l.light_color=color;l.light_energy=energy;l.omni_range=range_value;parent.add_child(l);return l

func character(parent: Node3D,id: String,p: Vector3,yaw=0.0,scale_value=1.0) -> Node3D:
	var actor=C.create(id);parent.add_child(actor);actor.position=p;actor.rotation.y=yaw;actor.scale*=scale_value
	return actor

func room(parent: Node3D,width=12.0,depth=18.0) -> void:
	box(parent,Vector3(0,-0.12,0),Vector3(width,0.24,depth),G.material("concrete",Color("45534a")))
	var m=ShaderMaterial.new();m.shader=preload("res://assets/materials/service_wall.gdshader");m.set_shader_parameter("paint",Color("29423c"));m.set_shader_parameter("plaster",Color("5c6659"))
	for side in [-1,1]:box(parent,Vector3(side*width/2,2.1,0),Vector3(0.20,4.2,depth),m)
	box(parent,Vector3(0,2.1,-depth/2),Vector3(width,4.2,0.2),m)
	box(parent,Vector3(0,4.15,0),Vector3(width,0.2,depth),metal("253932"))
	for side in [-1,1]:
		beam(parent,Vector3(side*(width/2-0.4),3.4,-depth/2),Vector3(side*(width/2-0.4),3.4,depth/2),0.10)
		for z in range(-int(depth/2)+2,int(depth/2),3):
			box(parent,Vector3(side*(width/2-0.13),2.0,z),Vector3(0.16,4,0.18),metal())
	for i in range(18):
		var p=Vector3(sin(i*1.7)*width*0.4,0.01,cos(i*2.5)*depth*0.4)
		var paper=box(parent,p,Vector3(0.23,0.01,0.17),G.material("plain",Color("706b53")));paper.rotation.y=i*1.9

func _corridor(stage: Node3D,last: bool) -> void:
	room(stage,6.4,22)
	for z in [-8,-2,4]:
		light(stage,Vector3(0,3.9,z),Vector3(0,0,z-1),Color("b3c1a2"),2.7,10,55)
		box(stage,Vector3(0,3.98,z),Vector3(1.2,0.08,0.22),metal())
	var door=box(stage,Vector3(0,1.55,-10.83),Vector3(2.3,3.1,0.13),metal("5b6660"))
	for side in [-1,1]:box(stage,Vector3(side*1.27,1.65,-10.7),Vector3(0.16,3.3,0.23),metal("8d8b6c"))
	box(stage,Vector3(0,3.30,-10.7),Vector3(2.7,0.16,0.23),metal("8d8b6c"))
	text(stage,"K - 1 7",Vector3(0,2.60,-10.70),0.007)
	box(stage,Vector3(0,1.8,-10.73),Vector3(0.52,0.75,0.045),G.material("plain",Color("132b25")))
	for x in [-0.18,0,0.18]:box(stage,Vector3(x,1.8,-10.69),Vector3(0.015,0.71,0.04),metal())
	fill(stage,Vector3(0,0.4,-10.3),Color("b4482d"),1.7,5)
	if not last:
		actors.mother=character(stage,"Mother",Vector3(0.40,0,-7),PI)
		actors.child=character(stage,"Danu",Vector3(-0.5,0,-3.1),PI,0.60)
		light(stage,Vector3(0,3.5,-9),Vector3(0,1,-5),Color("cfbe92"),5,10,48)
	else:
		actors.last_child=character(stage,"Danu",Vector3(-0.4,0,-7.9),PI,0.60)
		light(stage,Vector3(0,3.6,-10),Vector3(-0.4,0,-7),Color("bba878"),4,9,43)
		var lantern=box(stage,Vector3(0.4,0.08,-8.4),Vector3(0.32,0.12,0.14),metal("8f8257"));lantern.rotation.y=0.4
		shutter=door
		actors.last_light=fill(stage,Vector3(0.45,0.15,-8.2),Color("bd9b5c"),0.7,5)

func desk(stage: Node3D,p: Vector3) -> void:
	box(stage,p+Vector3(0,0.9,0),Vector3(2.6,0.14,1.2),G.material("burlap",Color("584b35")))
	for x in [-1.15,1.15]:
		for z in [-0.45,0.45]:box(stage,p+Vector3(x,0.42,z),Vector3(0.07,0.84,0.07),metal())

func _contract(stage: Node3D) -> void:
	room(stage,9,12);desk(stage,Vector3(0,0,0.8))
	actors.signer=character(stage,"Mother",Vector3(0,0,0),0)
	var paper=Node3D.new();paper.position=Vector3(0,0.979,0.72);paper.rotation.x=-PI/2;stage.add_child(paper)
	box(paper,Vector3.ZERO,Vector3(0.72,0.95,0.006),G.material("plain",Color("b8aa7e")))
	text(paper,"PABRIK KARTINI\nPEMINDAHAN TANGGUNGAN",Vector3(0,0.30,0.009),0.0010,Color("30382a"))
	text(paper,"NAMA PENGGANTI",Vector3(0,0.03,0.009),0.0013,Color("623d30"))
	box(paper,Vector3(0,-0.13,0.010),Vector3(0.55,0.003,0.002),G.material("plain",Color("58513b")))
	for i in range(5):box(paper,Vector3(0,-0.25-i*0.03,0.01),Vector3(0.55,0.002,0.002),G.material("plain",Color("7a7156")))
	var pen=G.cylinder(stage,Vector3(0.38,0.992,0.6),0.012,0.22,metal("93916c"));pen.rotation.z=PI/2
	A.furniture(stage,"chairDesk",Vector3(0,0,-0.6),Vector3(0.65,0.95,0.65),0,false)
	light(stage,Vector3(-0.6,3.5,1.1),Vector3(0,0.9,0.8),Color("d5c18e"),5,8,34)
	fill(stage,Vector3(1.6,1.7,-1),Color("769f8e"),0.7,4)

func _chamber(stage: Node3D,empty: bool) -> void:
	room(stage,12,20)
	for side in [-1,1]:
		A.place(stage,KIT+"machine-fortified.glb",Vector3(side*4,0,-4),Vector3(2.4,3.2,2.3),-side*PI/2,false)
		for j in range(4):beam(stage,Vector3(side*(1.9+j*0.45),0,-5.0),Vector3(side*(1.9+j*0.45),4,-5.0),0.07)
	A.furniture(stage,"chairDesk",Vector3(0,0,-5.3),Vector3(0.9,1.2,0.9),PI,false)
	if not empty:
		actors.captive=character(stage,"Mother",Vector3(0,0,-5.3),0)
		actors.captive.sit()
	else:
		for side in [-1,1]:box(stage,Vector3(side*0.15,0.06,-5.0),Vector3(0.19,0.12,0.31),G.material("plain",Color("252c27")))
	box(stage,Vector3(0,3.9,-5.4),Vector3(0.7,0.08,0.45),metal("79775d"))
	var key=light(stage,Vector3(0,3.8,-5.2),Vector3(0,0,-5.3),Color("cab382"),5.5,8,38)
	if empty:actors.empty_lamp=key
	for i in range(7):
		var x=-2+i*0.66
		beam(stage,Vector3(x,4,-5.4),Vector3(x*0.3,1.8,-6.3),0.025,G.material("plain",Color("1b2822")))
	var monster=preload("res://scripts/systems/model_factory.gd").make("hands");stage.add_child(monster);monster.position=Vector3(0,0,-9);monster.scale=Vector3.ONE*0.48
	actors["empty_monster" if empty else "chamber_monster"]=monster
	light(stage,Vector3(0,2.3,-9.6),Vector3(0,1.2,-7),Color("9d3424"),4.5,9,62)
	if empty:alarm=fill(stage,Vector3(-3,2.7,-6),Color("bc3c28"),2.5,10)
	# Foreground jamb and wired window frame make this an observed recording.
	for side in [-1,1]:box(stage,Vector3(side*2.35,1.8,2.9),Vector3(0.13,3.6,0.25),metal("202e29"))
	box(stage,Vector3(0,3.25,2.9),Vector3(4.8,0.12,0.25),metal("202e29"))
	fill(stage,Vector3(1.2,1.1,0),Color("667f73"),0.4,7)

func _invitation(stage: Node3D) -> void:
	room(stage,10,14);desk(stage,Vector3(0,0,0))
	actors.danu=character(stage,"Danu",Vector3(0,0,-0.8),0)
	actors.danu.sit()
	A.furniture(stage,"chairDesk",Vector3(0,0,-0.8),Vector3(0.65,1.0,0.65),0,false)
	A.furniture(stage,"chairDesk",Vector3(0,0,1.7),Vector3(0.65,1.0,0.65),PI,false)
	var paper=Node3D.new();paper.position=Vector3(0,0.979,0);paper.rotation.x=-PI/2;stage.add_child(paper)
	box(paper,Vector3.ZERO,Vector3(0.60,0.79,0.006),G.material("plain",Color("b4ad8b")))
	var note=text(paper,"Raka,\n\nAku perlu bantuanmu.\nDatang sendiri.\n\n             Danu",Vector3(0,0,0.009),0.0018,Color("30392d"));note.font=preload("res://assets/fonts/Caveat.ttf")
	light(stage,Vector3(-1.6,3.4,0.8),Vector3(0,0.9,-0.1),Color("c9bc8f"),4.6,9,42)
	light(stage,Vector3(2,2,-3),Vector3(0,1,-0.7),Color("557b83"),3,8,38)
	# A school window and long bars cast the familiar shape of the factory cage.
	for x in range(6):box(stage,Vector3(-4.7,2,-2+x*0.7),Vector3(0.05,1.8,0.035),metal())

func _overlay() -> void:
	var layer=CanvasLayer.new();add_child(layer)
	var effect=ColorRect.new();effect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);effect.mouse_filter=Control.MOUSE_FILTER_IGNORE
	film=ShaderMaterial.new();film.shader=preload("res://assets/materials/archive_film.gdshader");effect.material=film;layer.add_child(effect)
	for top in [true,false]:
		var bar=ColorRect.new();bar.color=Color.BLACK;bar.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);bar.anchor_top=0 if top else 0.865;bar.anchor_bottom=0.10 if top else 1.0;layer.add_child(bar)
	subtitle=Label.new();subtitle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);subtitle.anchor_top=0.88;subtitle.offset_left=45;subtitle.offset_right=-45;subtitle.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;subtitle.vertical_alignment=VERTICAL_ALIGNMENT_CENTER;subtitle.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;subtitle.add_theme_font_size_override("font_size",20);subtitle.modulate=Color("cdc9b8");layer.add_child(subtitle)
	timestamp=Label.new();timestamp.position=Vector2(34,18);timestamp.add_theme_font_size_override("font_size",12);timestamp.modulate=Color("8b9788");layer.add_child(timestamp)

func _process(delta: float) -> void:
	frame+=1;elapsed=float(frame)/24.0
	_update_scene(elapsed,1.0/24.0)
	if elapsed>=44.0:get_tree().quit()
	if OS.get_cmdline_user_args().has("--capture"):
		for t in [3,9,16,24,31,39]:
			if elapsed>=t and not saved.has(t):
				saved[t]=true;_capture(t)

func _capture(t: int) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://docs/screenshots/film17_%02d.png"%t)

func _update_scene(t: float,delta: float) -> void:
	var shot=0
	for i in range(6):
		if t>=CUTS[i]:shot=i
	var u=clampf((t-CUTS[shot])/(CUTS[shot+1]-CUTS[shot]),0,1)
	if shot!=previous:
		previous=shot
		for i in range(sets.size()):sets[i].visible=i==shot
	var stage=sets[shot]
	var start: Vector3;var end: Vector3;var look: Vector3
	camera.fov=49
	match shot:
		0:
			start=Vector3(1.8,1.35,3.5);end=Vector3(1.2,1.35,1.2);look=Vector3(0,1.25,-7)
			actors.mother.position.z=-6.3-u*1.8;actors.mother.animate_walk(t*4.5,0.17)
			actors.child.head.rotation.y=-0.12+u*0.2
			subtitle.text="" if u<0.25 else "IBU: Tunggu di sini. Ibu akan kembali setelah mesin berhenti."
		1:
			start=Vector3(0.95,1.90,1.9);end=Vector3(0.55,1.60,1.44);look=Vector3(0,0.99,0.72);camera.fov=43
			actors.signer.reach_world(stage.to_global(Vector3(0.1,1.02,0.57)),0.9*(1-smoothstep(0.6,1,u)),delta)
			subtitle.text="IBU: Mereka meminta satu nama. Aku tidak akan menulis nama anak lain."
		2:
			start=Vector3(-0.6,1.25,5.3);end=Vector3(0,1.3,2.0);look=Vector3(0,1.25,-5.6)
			actors.chamber_monster.position.x=sin(t*0.7)*0.18
			subtitle.text="ANAK: Kalau kolom itu kosong... Ibu tidak akan keluar?" if u<0.7 else ""
		3:
			start=Vector3(0,1.3,2.0);end=Vector3(0.3,1.1,-1.4);look=Vector3(0,0.9,-5.3)
			actors.empty_lamp.light_energy=3.7+sin(t*37)*0.4
			alarm.light_energy=0.6+pow(maxf(0,sin(t*3.5)),6)*3.0
			actors.empty_monster.position.z=-8.9+u*1.5
			subtitle.text="";camera.rotation.z=sin(t*5)*0.004
		4:
			start=Vector3(1.7,1.85,2);end=Vector3(0.9,1.15,1.8);look=Vector3(0,0.95,-0.20);camera.fov=44
			actors.danu.head.rotation.x=-0.18
			actors.danu.reach_world(stage.to_global(Vector3(0.13,0.99,-0.25)),0.85,delta)
			subtitle.text="DANU: Raka percaya padaku. Ia akan datang kalau kubilang aku butuh bantuan." if u<0.64 else "DANU: Aku tahu itu salah. Aku cuma tidak mau mendengar mesin memanggil namaku lagi."
		5:
			start=Vector3(0.6,1.15,-3.4);end=Vector3(1.4,1.3,1.0);look=Vector3(-0.2,1.30,-9.5)
			actors.last_child.head.rotation.x=-u*0.12
			actors.last_light.light_energy=maxf(0.04,0.8-u*0.85+sin(t*35)*0.04)
			subtitle.text="" if u>0.6 else "IBU: Jangan biarkan mereka memilih nama berikutnya."
	camera.position=stage.position+start.lerp(end,smoothstep(0,1,u));camera.look_at(stage.to_global(look))
	camera.rotation.z=sin(t*0.6)*0.004 if shot!=3 else sin(t*5)*0.006
	film.set_shader_parameter("film_time",t)
	film.set_shader_parameter("damage",0.4 if shot in [2,3,5] else 0.05)
	var cut_fade=1-smoothstep(0.0,0.28,t-CUTS[shot])
	film.set_shader_parameter("fade",maxf(cut_fade,smoothstep(42.6,44.0,t)))
	timestamp.text="KARTINI  /  K-17     17.03     %02d:%02d:%02d"%[0 if shot<4 else 3,20+shot*7,int(t)%60]

func _score() -> AudioStreamWAV:
	var rate=22050;var count=int(44.2*rate);var bytes=PackedByteArray();bytes.resize(count*2)
	var rng=RandomNumberGenerator.new();rng.seed=17031976;var low=0.0
	for i in range(count):
		var t=float(i)/rate;var noise=rng.randf_range(-1,1);low=lerpf(low,noise,0.025)
		var swell=0.22+smoothstep(10,26,t)*0.45
		var drone=(sin(t*TAU*43)+sin(t*TAU*43.28)*0.6+sin(t*TAU*64.5)*0.35)*0.07*swell
		var machine=sin(t*TAU*97+sin(t*0.7)*2)*0.014+low*0.38
		var tick=sin(t*TAU*1800)*pow(maxf(0,sin(t*TAU*1.7)),90)*0.035
		var heartbeat=sin(t*TAU*52)*pow(maxf(0,sin(t*TAU*(0.8+smoothstep(12,26,t)*0.3))),20)*0.13
		var strike=0.0
		for onset in [6.0,12.0,20.0,23.0,26.5,35.0,40.5]:
			var age=t-onset
			if age>0 and age<2.0:strike+=(sin(age*TAU*(38-age*3))*0.21+noise*0.08)*exp(-age*4)
		var note=0.0
		for onset in [0.5,4.5,9.0,16.0,28.0,31.5,36.0]:
			var age=t-onset
			if age>0:note+=(sin(age*TAU*293.66)+sin(age*TAU*440.0)*0.3)*exp(-age*1.4)*0.035
		var end=1-smoothstep(41.6,43.8,t)
		var sound=(drone+machine+tick+heartbeat+strike+note)*end*smoothstep(0,1.4,t)
		bytes.encode_s16(i*2,int(clampf(sound,-0.85,0.85)*30000))
	var stream=AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=rate;stream.data=bytes;return stream

func _exit_tree() -> void:
	actors.clear();sets.clear();A.source_cache.clear();G.materials.clear()
