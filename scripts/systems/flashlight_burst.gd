extends Node3D
## A small pressurized battery burst: hot core, flying casing/glass, sparks,
## floor dust and rolling smoke. Camera movement is owned by the cutscene.
const G = preload("res://scripts/systems/geometry.gd")
const SHADER = preload("res://assets/materials/flashlight_burst.gdshader")
static var smoke_texture: ImageTexture
var camera: Camera3D
var age = -1.0
var clouds: Array[Dictionary] = []
var fragments: Array[Dictionary] = []
var flash: OmniLight3D
var ring: MeshInstance3D
var scorch: MeshInstance3D
var rng = RandomNumberGenerator.new()

func trigger(view_camera: Camera3D) -> void:
	if age >= 0: return
	name = "FlashlightBatteryBurst"
	camera = view_camera; age = 0.0; rng.seed = 14071
	flash = OmniLight3D.new(); flash.name = "BlastLight"; flash.light_color = Color("ffd9a0"); flash.omni_range = 9; flash.shadow_enabled = bool(State.settings.shadows); add_child(flash)
	for i in range(8):
		_cloud(true, Vector3(rng.randf_range(-0.25,0.25),rng.randf_range(0.0,0.25),rng.randf_range(-0.25,0.25)), Vector3(rng.randf_range(-1,1),rng.randf_range(0.7,1.8),rng.randf_range(-1,1)), rng.randf_range(0.30,0.65), i*0.014)
	for i in range(11):
		_cloud(false, Vector3(rng.randf_range(-0.3,0.3),0.08,rng.randf_range(-0.3,0.3)), Vector3(rng.randf_range(-0.35,0.35),rng.randf_range(0.25,0.6),rng.randf_range(-0.35,0.35)), rng.randf_range(3.0,5.4), i*0.025)
	ring = _quad(1); ring.name = "PressureDustRing"; ring.rotation.x = -PI/2; ring.position.y = -0.065
	scorch = _quad(2); scorch.name = "ScorchMark"; scorch.rotation.x = -PI/2; scorch.position.y = -0.075; scorch.scale = Vector3.ONE*1.65
	var glass=G.material("plain",Color("a4c3c1")); glass.metallic=0.7; glass.roughness=0.22
	var casing=G.material("steel",Color("655e43"))
	var ember=StandardMaterial3D.new();ember.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ember.albedo_color=Color("ff9d2f");ember.emission_enabled=true;ember.emission=Color("ff590b");ember.emission_energy_multiplier=3.0
	for i in range(58):
		var spark=i>=22
		var size=Vector3(0.006,0.006,rng.randf_range(0.05,0.16)) if spark else Vector3(rng.randf_range(0.025,0.070),0.014,rng.randf_range(0.04,0.09))
		var mesh=G.box(self,Vector3.ZERO,size,ember if spark else glass if i%3==0 else casing)
		if not spark:
			var shard=PrismMesh.new();shard.size=size;mesh.mesh=shard
		mesh.name=("Spark" if spark else "CasingShard")+str(i)
		var angle=rng.randf()*TAU; var speed=rng.randf_range(1.2,5.2)
		var velocity=Vector3(cos(angle)*speed,rng.randf_range(1.4,4.8),sin(angle)*speed)
		fragments.append({"node":mesh,"velocity":velocity,"spin":Vector3(rng.randf_range(-7,7),rng.randf_range(-7,7),rng.randf_range(-7,7)),"life":rng.randf_range(0.45,1.25) if spark else 5.4,"spark":spark})
	_render_at(0.0)
	set_process(true)

func _quad(mode: int) -> MeshInstance3D:
	var node=MeshInstance3D.new();node.mesh=QuadMesh.new();node.mesh.size=Vector2.ONE
	var material=ShaderMaterial.new();material.shader=SHADER;material.set_shader_parameter("effect_mode",mode);material.set_shader_parameter("seed",rng.randf()*20)
	node.material_override=material;node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(node)
	return node

func _cloud(fire: bool,offset: Vector3,velocity: Vector3,life: float,delay: float) -> void:
	var node=_quad(0);node.name="FirePlume" if fire else "RollingSmoke"
	if not fire:
		var material=StandardMaterial3D.new();material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;material.cull_mode=BaseMaterial3D.CULL_DISABLED
		material.albedo_texture=_smoke_texture();material.albedo_color=Color(0.26,0.28,0.27,0)
		node.material_override=material
	clouds.append({"node":node,"origin":offset,"velocity":velocity,"life":life,"delay":delay,"fire":fire,"size":rng.randf_range(0.8,1.35),"rotation":rng.randf()*TAU})

func _smoke_texture() -> ImageTexture:
	if smoke_texture!=null:return smoke_texture
	var noise=FastNoiseLite.new();noise.seed=1407;noise.frequency=0.052;noise.fractal_octaves=4
	var pixels=Image.create(128,128,false,Image.FORMAT_RGBA8)
	for y in range(128):
		for x in range(128):
			var uv=(Vector2(x,y)+Vector2.ONE*0.5)/64.0-Vector2.ONE
			var n=noise.get_noise_2d(x,y)*0.5+0.5
			var radius=uv.length()
			var mask=pow(maxf(0,1.0-radius*radius),2.0)*(1.0-smoothstep(0.68,0.98,radius))
			var detail=smoothstep(0.18,0.78,n)
			pixels.set_pixel(x,y,Color(0.55+n*0.45,0.55+n*0.45,0.55+n*0.45,mask*(0.25+detail*0.75)))
	smoke_texture=ImageTexture.create_from_image(pixels)
	return smoke_texture

func _process(delta: float) -> void:
	if age<0:return
	age+=delta;_render_at(age)
	if age>7.5:
		set_process(false);hide()

func _render_at(time: float) -> void:
	if not is_instance_valid(flash):return
	flash.light_energy=12.0*exp(-time*19.0)+2.2*exp(-time*5.0)*(0.7+0.3*sin(time*67.0))
	for cloud in clouds:
		var t=time-cloud.delay;var u=clampf(t/cloud.life,0,1);var node: MeshInstance3D=cloud.node
		node.visible=t>=0 and u<1
		if not node.visible:continue
		var movement=t if not cloud.fire else (1.0-exp(-t*4))*0.5
		node.position=cloud.origin+cloud.velocity*movement
		node.scale=Vector3.ONE*cloud.size*((0.35+u*2.5) if cloud.fire else (0.45+sqrt(u)*2.2))
		if is_instance_valid(camera):node.look_at(camera.global_position)
		node.rotate_object_local(Vector3.FORWARD,cloud.rotation+u*0.4)
		if cloud.fire:
			node.material_override.set_shader_parameter("age",t)
			node.material_override.set_shader_parameter("heat",1.0-u*0.45)
			node.material_override.set_shader_parameter("opacity",1.0-smoothstep(0.15,1.0,u))
		else:
			node.material_override.albedo_color.a=smoothstep(0.0,0.06,u)*(1.0-smoothstep(0.35,1.0,u))*0.86
	ring.visible=time<0.55;ring.scale=Vector3.ONE*(0.3+time*6.5);ring.material_override.set_shader_parameter("opacity",maxf(0,1-time/0.55))
	scorch.material_override.set_shader_parameter("opacity",smoothstep(0.0,0.25,time)*(1.0-smoothstep(6.0,7.5,time))*0.65)
	for fragment in fragments:
		var node: MeshInstance3D=fragment.node;var v: Vector3=fragment.velocity
		node.visible=time<fragment.life
		if not node.visible:continue
		var hit=(v.y+sqrt(v.y*v.y+2.0*9.8*0.08))/9.8
		var point=v*time-Vector3.UP*4.9*time*time
		if time>hit:
			var after=time-hit;var bounce=(9.8*hit-v.y)*0.25
			point=v*hit+Vector3(v.x,0,v.z)*(1.0-exp(-after*2.4))/2.4
			point.y=maxf(-0.08,-0.08+bounce*after-4.9*after*after)
		node.position=point
		node.rotation=fragment.spin*minf(time,hit+0.5)
		if fragment.spark and v.length()>0.01:
			node.look_at(node.global_position+v-Vector3.UP*9.8*time)
		node.scale=Vector3.ONE*(1.0-smoothstep(fragment.life*0.7,fragment.life,time))
