extends Node3D
const G = preload("res://scripts/systems/geometry.gd")
const A = preload("res://scripts/systems/free_assets.gd")
const COLORS = ["a52e25","d5a934","285f8f","46806a"]
const THEMES = {"loading":"Bangsal Muat / Galeri Reka", "relay":"Rumah Relai / Simpul Daya", "production":"Ruang Produksi / Rangkai Rasa", "office":"Kantor Danu / Arsip Pengawasan", "ritual":"Ruang Ritual / Laboratorium Ambang", "corridor":"Lorong Belakang / Sektor Karantina", "daisy":"Ruang Daisy / Rumah Kenangan", "pursuit":"Jalur Pemeliharaan / Saluran Bawah", "street":"Gudang Kartini"}
var level: Node3D
var toys: Array[Node3D] = []
var clock = 0.0
var lamps: Array[Light3D] = []

func apply(owner_level: Node3D) -> void:
	level=owner_level; name="FactoryArtDirection"; level.add_child(self)
	set_meta("theme",THEMES[level.room_id])
	if level.room_id=="street":
		_sign("PABRIK MAINAN KARTINI",Vector3(0,4.4,27.8),6.5,0,Color("d6a83e")); return
	_surfaces()
	match level.room_id:
		"loading": _reception()
		"relay": _station()
		"production": _assembly()
		"office": _surveillance()
		"ritual": _laboratory()
		"corridor": _containment()
		"daisy": _nursery()
		"pursuit": _depths()

func mat(hex_value: String) -> Material:
	return G.material("plain",Color(hex_value))

func box(p: Vector3, size: Vector3, material: Material, solid=false, parent: Node3D=null) -> MeshInstance3D:
	var item=G.box(self if parent==null else parent,p,size,material,solid)
	if solid: level.nav_extra.append(Rect2(p.x-size.x/2,p.z-size.z/2,size.x,size.z).grow(0.08))
	return item

func _surfaces() -> void:
	var id=level.room_id
	var wall=ShaderMaterial.new(); wall.shader=preload("res://assets/materials/toy_factory_wall.gdshader")
	wall.set_shader_parameter("paint",Color({"loading":"416880","relay":"426c59","production":"a07935","office":"515955","ritual":"506b68","corridor":"354d55","daisy":"7c5364","pursuit":"5a5c51"}[id]))
	wall.set_shader_parameter("plaster",Color("b7b6a1" if id in ["ritual","corridor"] else "b2a686"))
	wall.set_shader_parameter("clinical",1.0 if id in ["ritual","corridor"] else 0.0)
	var presentation=JSON.parse_string(FileAccess.get_file_as_string("res://assets/source_presentation.json"))[id]
	for record in presentation.walls:
		var mesh=level.find_child(record.name,true,false)
		if mesh!=null: mesh.set_surface_override_material(int(record.surface),wall)
	var floor_finish=ShaderMaterial.new(); floor_finish.shader=preload("res://assets/materials/toy_factory_floor.gdshader")
	floor_finish.set_shader_parameter("colorful",1.0 if id in ["loading","production","relay","daisy"] else 0.12)
	for mesh in level.get_node("SourceWorld").find_children("*","MeshInstance3D",true,false):
		var b: AABB=mesh.global_transform*mesh.get_aabb()
		if b.size.y<0.31 and b.size.x>3 and b.size.z>3 and b.end.y<0.10 and b.end.y>-0.08: mesh.material_override=floor_finish
	# Accents recolor existing machine geometry without moving its colliders.
	var old=level.get_node("FactoryRevision09")
	var index=0
	for prop in old.get_children():
		if not str(prop.name).begins_with("machine"): continue
		var paint=ShaderMaterial.new(); paint.shader=preload("res://assets/materials/factory_metal.gdshader")
		paint.set_shader_parameter("paint",Color(COLORS[index%COLORS.size()])); index+=1
		for mesh in prop.find_children("*","MeshInstance3D",true,false): mesh.material_override=paint

func _sign(text_value: String,p: Vector3,w: float,yaw=0.0,color=Color("d0b74e")) -> void:
	var sign_root=Node3D.new(); sign_root.position=p; sign_root.rotation.y=yaw; add_child(sign_root)
	G.box(sign_root,Vector3.ZERO,Vector3(w,0.8,0.16),mat("1e343b"))
	G.box(sign_root,Vector3(0,0.43,0),Vector3(w+0.16,0.07,0.20),mat("b58f2c"))
	var label=G.sign_text(sign_root,text_value,Vector3(0,0,0.095),36)
	label.modulate=color; label.outline_size=0; label.pixel_size=minf(0.022,w/maxf(text_value.length()*22,1))
	label.no_depth_test=false

func _arch(z: float, text_value: String, width_value=7.0, y=4.5) -> void:
	for side in [-1,1]:
		box(Vector3(side*width_value/2,y/2,z),Vector3(0.55,y,0.6),mat("a3382c" if side<0 else "345f91"),true)
		for h in [0.18,y-0.22]: box(Vector3(side*width_value/2,h,z),Vector3(0.72,0.22,0.76),mat("bd962d"))
	box(Vector3(0,y,z),Vector3(width_value+0.6,0.46,0.7),mat("c59d32"))
	_sign(text_value,Vector3(0,y-0.03,z+0.42),width_value+0.8)

func _spot(p: Vector3,color: Color,energy=3.0) -> void:
	var light=SpotLight3D.new(); light.position=p; light.rotation.x=-PI/2
	light.light_color=color; light.light_energy=energy; light.spot_range=12; light.spot_angle=55; light.shadow_enabled=true
	add_child(light)
	var bulb=mat("e5d7ad").duplicate(); bulb.emission_enabled=true; bulb.emission=color; bulb.emission_energy_multiplier=2
	box(p+Vector3.UP*0.10,Vector3(0.8,0.12,0.36),bulb)

func _face(parent: Node3D,p: Vector3,size=1.0) -> void:
	for side in [-1,1]:
		G.sphere(parent,p+Vector3(side*0.26,0.18,0)*size,Vector3(0.38,0.46,0.16)*size,mat("eee5c6"))
		G.sphere(parent,p+Vector3(side*0.26,0.15,0.085)*size,Vector3(0.17,0.24,0.06)*size,mat("1a2425"))
	G.sphere(parent,p+Vector3(0,-0.28,0)*size,Vector3(0.72,0.17,0.12)*size,mat("482527"))

func _toy(p: Vector3,color: String,size=1.0,parent: Node3D=null) -> Node3D:
	var toy=Node3D.new(); toy.position=p; (self if parent==null else parent).add_child(toy)
	toy.scale=Vector3.ONE*size
	G.sphere(toy,Vector3(0,0.38,0),Vector3(0.44,0.58,0.32),mat(color))
	G.sphere(toy,Vector3(0,0.84,0),Vector3(0.63,0.52,0.40),mat(color))
	for side in [-1,1]:
		G.sphere(toy,Vector3(side*0.29,1.0,0),Vector3(0.22,0.27,0.18),mat(color))
		G.sphere(toy,Vector3(side*0.25,0.46,0),Vector3(0.18,0.48,0.20),mat(color))
		G.sphere(toy,Vector3(side*0.16,0.12,0.06),Vector3(0.24,0.24,0.30),mat("c6aa51"))
	_face(toy,Vector3(0,0.84,0.19),0.45)
	return toy

func _reception() -> void:
	_arch(-12.4,"GALERI REKA",8.8,4.4)
	_sign("PABRIK MAINAN KARTINI",Vector3(0,4.5,17.5),9,PI)
	for side in [-1,1]:
		for i in range(4):
			var toy=_toy(Vector3(side*6.8,0.86,-3.8+i*1.35),COLORS[(i+1)%4],0.65)
			toy.set_meta("origin",toy.position); toys.append(toy)
		_sign("LOLOS INSPEKSI\nSIAP DIKIRIM",Vector3(side*12,2.5,7),2.7,-side*PI/2)
		_spot(Vector3(side*6.8,5.2,1),Color("e9c889"),4)
	# Oversized blue mascot mounted in a side display, clear of the main route.
	_mascot(Vector3(-10.8,0.12,-9.5))
	box(Vector3(-10.8,0.06,-9.5),Vector3(2.1,0.12,2.1),mat("8d342e"),true)
	_sign("REKA / TEMAN MENYIMPAN CERITA",Vector3(-10.8,3.6,-9.5),4)

func _mascot(p: Vector3) -> void:
	var imported=preload("res://scripts/systems/mascot_model.gd").create()
	imported.name="RekaMascot";imported.position=p;add_child(imported)

func _station() -> void:
	_sign("RUMAH RELAI / KARTINI",Vector3(0,5.6,-16.7),9.0)
	for p in [Vector3(-7,4.7,3),Vector3(7,4.7,3)]: _spot(p,Color("a6c5b5"),3)

func _assembly() -> void:
	_arch(-5.5,"RANGKAI RASA",8.6,4.7)
	for side in [-1,1]:
		_face(self,Vector3(side*6.5,2.0,-5.55),1.15)
		for i in range(5):
			var toy=_toy(Vector3(side*6.5,0.93,-2.8+i*1.5),COLORS[(i+2)%4],0.58)
			toy.set_meta("origin",toy.position); toys.append(toy)
		_spot(Vector3(side*6.5,5.8,2),Color("e1cfa3"),4)
		_sign("RAKIT  →  WARNAI  →  PERIKSA",Vector3(side*15.6,3.2,1.5),7,-side*PI/2)
		for i in range(3):
			var tube=G.cylinder(self,Vector3(side*(5.5+i*0.8),4.4,-7),0.14,2.6,mat(COLORS[i]))
			tube.rotation.z=0.14*side

func _surveillance() -> void:
	_sign("RUANG PENGAWASAN / PETUGAS SAJA",Vector3(0,2.9,-7),7.8)
	for i in range(6):
		var p=Vector3(7.6,1.2+(i/3)*0.72,-3.7+(i%3)*1.15)
		box(p,Vector3(0.22,0.64,1.0),mat("202a29"))
		var screen=mat("426c60").duplicate(); screen.emission_enabled=true; screen.emission=Color("31584a"); screen.emission_energy_multiplier=0.65
		box(p+Vector3(-0.13,0,0),Vector3(0.015,0.50,0.85),screen)
		_sign("CAM %02d · NO SIGNAL"%(i+1),p+Vector3(-0.15,0,0),0.8,-PI/2,Color("9dbda6"))
	for z in [-4,0,4]:
		for i in range(7): box(Vector3(-8.2,1.0,z-0.45+i*0.15),Vector3(0.22,0.28,0.09),mat(COLORS[i%4]))
	_spot(Vector3(0,3.4,0),Color("adbeab"),2)

func _laboratory() -> void:
	_sign("LABORATORIUM AMBANG",Vector3(0,4.6,-11.5),8)
	for side in [-1,1]:
		for z in [-8,7]:
			var p=Vector3(side*11.3,0,z)
			var chamber=Node3D.new(); chamber.position=p; chamber.name="SpecimenChamber"; add_child(chamber)
			G.cylinder(chamber,Vector3(0,0.18,0),0.87,0.36,mat("435a58"))
			G.cylinder(chamber,Vector3(0,3.25,0),0.87,0.25,mat("435a58"))
			var body=StaticBody3D.new(); var collider=CollisionShape3D.new(); var shape=CylinderShape3D.new()
			shape.radius=0.87; shape.height=3.4; collider.shape=shape; collider.position.y=1.7; body.add_child(collider); chamber.add_child(body)
			level.nav_extra.append(Rect2(p.x-0.95,p.z-0.95,1.9,1.9))
			for dx in [-0.7,0.7]: G.box(chamber,Vector3(dx,1.7,0),Vector3(0.10,3.1,0.10),mat("9aa8a0"))
			var glass=mat("719887").duplicate(); glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA; glass.albedo_color.a=0.19; glass.roughness=0.15
			G.cylinder(chamber,Vector3(0,1.7,0),0.78,2.9,glass)
			_toy(Vector3(0,0.45,0),"a18b7e",1.9,chamber)
			var glow=OmniLight3D.new(); glow.position=p+Vector3(0,2,0.5); glow.light_color=Color("7ba99a"); glow.omni_range=4; glow.light_energy=0.8; add_child(glow)
			_sign("SUBJEK ARSIP / DILARANG MEMBUKA",p+Vector3(0,3.8,0),3)
		_spot(Vector3(side*8,5.7,0),Color("a0ccc9"),3.5)
	# Cables converge above the ritual floor; arena and candle refuges stay clear.
	for x in [-6,-3,3,6]:
		var cable=G.cylinder(self,Vector3(x,4.7,0),0.04,3.2,mat("292f2e")); cable.rotation.z=x*0.09
		box(Vector3(x,3.05,0),Vector3(0.38,0.15,0.38),mat("647872"))

func _containment() -> void:
	_sign("SEKTOR KARANTINA / HARAP TENANG",Vector3(0,2.48,-16.8),3.7)
	for side in [-1,1]:
		for z in [-12,-4,4,12]:
			var x=side*(level.width/2-0.22)
			for dz in [-0.9,-0.6,-0.3,0,0.3,0.6,0.9]: box(Vector3(x,1.25,z+dz),Vector3(0.055,2.5,0.045),mat("263333"))
			for y in [0.1,2.5]: box(Vector3(x,y,z),Vector3(0.1,0.08,2),mat("263333"))
			_sign("CELL %02d"%int(z+15+(20 if side>0 else 0)),Vector3(x-side*0.08,2.65,z),1,-side*PI/2,Color("b5b4a1"))
	for z in [-12,0,12]:
		var light=OmniLight3D.new(); light.position=Vector3(0,2.7,z); light.light_color=Color("c14938"); light.omni_range=4; light.light_energy=0.42; add_child(light); lamps.append(light)

func _nursery() -> void:
	_sign("RUMAH KENANGAN",Vector3(-3.4,3.1,-5.6),4.2,0,Color("d7b279"))
	for side in [-1,1]:
		for i in range(4):
			var block=box(Vector3(side*3.8,0.22,1.5-i*0.65),Vector3(0.43,0.44,0.43),mat(COLORS[i])); block.rotation.y=i*0.24
			var letter=G.sign_text(self,["A","B","C","D"][i],block.position+Vector3(0,0,0.23),28); letter.modulate=Color("e3d8aa")
		A.furniture(self,"bedSingle",Vector3(side*4.4,0,-1.9),Vector3(1.15,0.7,2.05),0,true,"NurseryBed")
		level.nav_extra.append(Rect2(side*4.4-0.58,-2.93,1.16,2.06))
		_spot(Vector3(side*3.6,3.65,0),Color("c5b39a"),0.9)
	for i in range(9):
		var moon=G.sphere(self,Vector3(-3+i*0.75,3.1+sin(i)*0.2,-3.5),Vector3.ONE*0.16,mat("c9aa5f")); moon.name="NurseryStar"

func _depths() -> void:
	for z in [40,20,0,-20,-40]:
		_sign("SALURAN BAWAH / TERUS BERGERAK",Vector3(0,3.2,z),5.6)
		for side in [-1,1]:
			var lamp=OmniLight3D.new(); lamp.position=Vector3(side*9.5,2.2,z); lamp.light_color=Color("a94032"); lamp.omni_range=5; lamp.light_energy=0.65; add_child(lamp); lamps.append(lamp)
	# Ceiling duct ribs follow the actual main chase; no baffles are moved.
	for z in range(-42,48,6):
		box(Vector3(0,3.8,z),Vector3(20,0.12,0.16),mat("7b783e"))
		for side in [-1,1]: box(Vector3(side*9.8,3.55,z),Vector3(0.12,0.5,0.18),mat("7b783e"))

func _process(delta: float) -> void:
	clock+=delta
	if level.room_id=="loading":
		var display=get_node_or_null("RekaMascot")
		if display!=null:display.visible=not State.solved("panel")
	for i in range(toys.size()):
		var toy=toys[i]; var origin: Vector3=toy.get_meta("origin")
		toy.position=origin+Vector3(0,sin(clock*2+i)*0.006,sin(clock*0.4+i)*0.22)
	for i in range(lamps.size()): lamps[i].light_energy=0.46+sin(clock*1.7+i)*0.08
