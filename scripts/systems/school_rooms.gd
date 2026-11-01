extends RefCounted
const A = preload("res://scripts/systems/free_assets.gd")
const G = preload("res://scripts/systems/geometry.gd")
const V = "res://assets/vendor/revision12/"
var room: Node3D
var side: int
var floor_y: float
var middle: float
var span: float

func furniture(id: String,x: float,z: float,dimensions: Vector3,yaw=0.0,top=0.0,solid=true) -> Node3D:
	return A.furniture(room,id,Vector3(side*x,floor_y+top,middle+z),dimensions,yaw,solid)

func asset(id: String,x: float,z: float,height: float,yaw=0.0) -> Node3D:
	return A.place(room,V+id+".glb",Vector3(side*x,floor_y,middle+z),Vector3(-1,height,-1),yaw,true,"",0,PI/2 if id=="guitar" else 0)

func books(x: float,z: float,top=0.82) -> void:
	furniture("books",x,z,Vector3(0.38,0.24,0.25),0,top,false)

func shelf(x: float,z: float) -> void:
	furniture("bookcaseOpen",x,z,Vector3(1.6,2.05,0.42),side*PI/2)
	for h in [0.3,0.75,1.2,1.65]:
		for dz in [-0.5,0.0,0.5]: furniture("books",x-0.05,z+dz,Vector3(0.35,0.27,0.27),side*PI/2,h,false)

func table(x: float,z: float,w=1.6) -> void:
	furniture("table",x,z,Vector3(w,0.80,0.85))
	for dz in [-0.8,0.8]: furniture("chair",x,z+dz,Vector3(0.45,0.88,0.45),PI if dz>0 else 0,0,false)

func furnish(parent: Node3D,s: int,y: float,z0: float,z1: float,title: String,preserve: bool) -> void:
	room=Node3D.new();room.name="Room_"+title.validate_node_name();parent.add_child(room)
	room.set_meta("purpose",title);side=s;floor_y=y;middle=(z0+z1)*0.5;span=z1-z0
	# Reserve x=2..4 and the centre aisle for doors and evidence access.
	if preserve:
		if "LAB IPA" in title:
			furniture("bathroomSink",12.8,2.5,Vector3(1.4,0.90,0.55),side*PI/2)
			shelf(12.7,-2.0)
		elif "PERPUSTAKAAN" in title: shelf(3.2,-2.5)
		return
	if "SENI" in title or "MUSIK" in title:
		for p in [Vector2(6,-2.3),Vector2(9,-2.3),Vector2(12,-2.3)]: asset("easel",p.x,p.y,1.65,PI+0.22)
		painting("monet_wheat",Vector3(side*7,y+1.9,z0+0.13),1.8,1.07)
		for i in range(3):
			asset("guitar",12.9,0.2+i*0.85,1.02,-side*PI/2)
			var stand=Vector3(side*12.9,y,middle+0.2+i*0.85)
			G.box(room,stand+Vector3(0,0.025,0),Vector3(0.42,0.05,0.34),G.material("plain",Color("343b3d")))
			G.cylinder(room,stand+Vector3(side*0.10,0.28,0),0.015,0.56,G.material("plain",Color("343b3d")))
		asset("piano",7.5,minf(3.8,span*0.5-1.2),1.25,PI)
		furniture("benchCushion",7.5,minf(2.5,span*0.5-2.3),Vector3(1.1,0.52,0.45))
		table(5.3,0,2.2); books(5,0)
		for dx in [5.5,5.8,6.1]:
			var cup=G.cylinder(room,Vector3(side*dx,y+0.88,middle),0.065,0.16,G.material("plain",Color("a99273")))
			cup.name="BrushPot"
			for i in range(4):
				var brush=G.cylinder(cup,Vector3((i-1.5)*0.025,0.15,0),0.007,0.25,G.material("plain",Color("635544")));brush.rotation.z=(i-1.5)*0.12
		furniture("speaker",11.5,span*0.5-0.7,Vector3(0.55,1.1,0.45))
	elif "UKS" in title:
		for z in [-2.1,1.8]:
			furniture("bedSingle",10,z,Vector3(1.1,0.72,2.1),PI/2)
			furniture("cabinetBed",12.3,z,Vector3(0.55,0.70,0.50))
		furniture("bathroomCabinet",5,-3.5,Vector3(1.8,1.3,0.5))
		furniture("bathroomSink",12.7,-3.5,Vector3(1,0.90,0.5),side*PI/2)
		furniture("bench",5,2.8,Vector3(2.5,0.85,0.55))
		var sign=G.sign_text(room,"+   UKS\nPERTOLONGAN PERTAMA",Vector3(side*5,y+2.1,middle-span/2+0.12),24);sign.modulate=Color("617c69")
	elif "BACA" in title or "ARSIP" in title or "STUDI" in title:
		for z in [-span*0.3,0,span*0.3]: shelf(12.7,z)
		for z in [-span*0.22,span*0.22]: table(7,z,2.4);books(7,z)
		furniture("lampSquareTable",7.7,-span*0.22,Vector3(-1,0.42,-1),0,0.8,false)
	elif "KANTIN" in title:
		for x in [5.0,7.0,9.0]:
			furniture("kitchenBar",x,-span*0.5+0.7,Vector3(2,0.95,0.70))
		furniture("kitchenFridge",12.5,-span*0.5+0.7,Vector3(0.85,1.9,0.7))
		furniture("kitchenCoffeeMachine",5,-span*0.5+0.7,Vector3(0.32,0.42,0.35),0,0.95,false)
		for x in [6,10]: table(x,1,2.2)
	elif "AULA" in title:
		G.box(room,Vector3(side*9,y+0.15,middle-span*0.5+1.5),Vector3(8,0.30,2.8),G.material("plain",Color("645746")),true)
		for z in [-1,1,3,5]:
			for x in [6,10]: furniture("bench",x,z,Vector3(3,0.83,0.5))
		for x in [5.5,12.5]: furniture("speaker",x,-span*0.5+1.2,Vector3(0.6,1.1,0.5),0,0.3)
	elif "SAINS" in title:
		for x in [6,10]:
			table(x,-1,2.3);table(x,1.6,2.3)
			for z in [-1.0,1.6]:
				for dx in [-0.5,0,0.5]:
					G.cylinder(room,Vector3(side*(x+dx),y+0.93,middle+z),0.07,0.26,G.material("plain",Color("95afb0")))
		shelf(12.7,-span*0.3)
	elif "MULTIMEDIA" in title:
		furniture("televisionModern",8,-span/2+0.4,Vector3(3.8,2.2,0.20),0,0.7,false)
		for z in [-1.5,0.8,3]:
			for x in [5.5,8,10.5]: furniture("chair",x,z,Vector3(0.5,0.95,0.5),PI,0,false)
		for x in [4.5,11.5]: furniture("speaker",x,-span/2+0.7,Vector3(0.5,1.1,0.45))
	elif "KELAS" in title:
		for z in [-span*0.23,span*0.23]:
			for x in [5.3,8,10.7]:
				furniture("desk",x,z,Vector3(1.4,0.8,0.65));furniture("chair",x,z+0.75,Vector3(0.45,0.9,0.45),PI,0,false);books(x,z)
		G.box(room,Vector3(side*8,y+1.85,middle-span/2+0.12),Vector3(4.5,1.2,0.08),G.material("plain",Color("2b4840")))
	else:
		# Staff, student council and discussion rooms: shared work surfaces,
		# filing storage and a board, rather than empty ornamental shelving.
		for z in [-span*0.22,span*0.22]: table(7,z,3);books(7,z)
		shelf(12.7,0)
		furniture("laptop",6.2,-span*0.22,Vector3(0.38,0.25,0.3),0,0.8,false)
		G.box(room,Vector3(side*8,y+1.85,middle-span/2+0.12),Vector3(3.5,1.1,0.06),G.material("plain",Color("a99d80")))

func lockers(level: Node3D,parent: Node3D) -> void:
	var bank=Node3D.new();bank.name="SchoolLockers";parent.add_child(bank)
	for s in [-1,1]:
		for i in range(7):
			# Only solid corridor wall sections, away from the UKS/art/kantin doors.
			var z=(-8.5 if s<0 else 6.0)+i*0.52
			var locker=A.place(bank,V+"locker.glb",Vector3(s*1.66,0.02,z),Vector3(0.48,1.85,0.48),-s*PI/2,true,"Locker_%d_%d"%[s,i],-PI/2)
			# The imported handle is on the left, 16 cm from the door centre.
			# The staple passes through the shackle, directly below that handle.
			var hardware = G.material("plain", Color("626968"))
			G.box(locker, Vector3(-0.158,0.933,0.212), Vector3(0.068,0.082,0.024), hardware)
			G.box(locker, Vector3(-0.158,0.937,0.243), Vector3(0.021,0.018,0.061), hardware)
			A.place(locker,V+"padlock.glb",Vector3(-0.158,0.817,0.253),Vector3(-1,0.14,-1),0,false,"Padlock")
			var label=G.sign_text(locker,"RAKA" if s<0 and i==2 else "%02d"%(i+1),Vector3(0,1.55,0.247),18);label.pixel_size=0.0018;label.outline_size=0
			if s<0 and i==2:
				for object in level.get_children():
					if object is KalaInteractable and object.action_id=="puzzle" and object.parameter=="locker": object.position=Vector3(-1.32,1.15,z)

func painting(id: String,p: Vector3,w: float,h: float) -> void:
	var path=V+id+".jpg"
	if not ResourceLoader.exists(path):return
	var frame=G.box(room,p,Vector3(w+0.08,h+0.08,0.055),G.material("plain",Color("756247")))
	frame.name="FramedPainting"
	var canvas=MeshInstance3D.new();var quad=QuadMesh.new();quad.size=Vector2(w,h);canvas.mesh=quad;canvas.position.z=0.031;frame.add_child(canvas)
	var mat=StandardMaterial3D.new();mat.albedo_texture=load(path);mat.roughness=1;mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC;canvas.material_override=mat
