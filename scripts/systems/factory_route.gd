extends RefCounted
## Horizontal factory circulation and the inspection wing before Lentera-G.
const G=preload("res://scripts/systems/geometry.gd")
const A=preload("res://scripts/systems/free_assets.gd")
var level: Node3D
var root: Node3D
var end_z=0.0
var shutter: MeshInstance3D
var fuse: Node3D
var lights: Array[Light3D]=[]
var leaving=false
var north=0.0
const PRESSURE_TARGET = [1,3,0]
const CIRCUIT_ORDER = [2,0,3,1]
const CIRCUIT_NAMES = ["I / PENERIMAAN", "II / PERAKITAN", "III / UJI BEBAN", "IV / INSPEKSI"]
var valve_wheels: Array[Node3D] = []
var valve_readouts: Array[Label3D] = []
var circuit_readouts: Array[Label3D] = []
var power_readout: Label3D
var last_status = ""

func apply(owner_level: Node3D) -> void:
	level=owner_level;north=-level.depth/2
	root=Node3D.new();root.name="FactoryExploration";level.add_child(root)
	for mesh in level.get_node("SourceWorld").find_children("*","MeshInstance3D",true,false):
		var bounds: AABB=mesh.global_transform*mesh.get_aabb()
		if bounds.get_center().z<north-0.15:
			mesh.hide()
			for body in mesh.find_children("*","StaticBody3D",true,false):body.collision_layer=0
	var regions: Array=[]
	for region in level.safety.regions:
		if float(region.z)+float(region.d)<north+1:continue
		regions.append(region.duplicate())
	var extension_start=regions.size()
	if level.room_id=="loading":
		regions.append({"x":-2.1,"z":-66.0,"w":4.2,"d":44.7,"y":0.0,"h":3.8})
		regions.append({"x":-13.5,"z":-35.0,"w":11.4,"d":11.0,"y":0.0,"h":3.8})
		regions.append({"x":2.1,"z":-35.0,"w":11.9,"d":11.0,"y":0.0,"h":3.8})
		regions.append({"x":-21.5,"z":-55.0,"w":19.4,"d":16.0,"y":0.0,"h":3.8})
		regions.append({"x":2.1,"z":-56.0,"w":21.4,"d":17.0,"y":0.0,"h":3.8})
		end_z=-65.0
	else:
		regions.append({"x":-1.65,"z":north-10.4,"w":3.3,"d":11.0,"y":0.0,"h":3.8})
		end_z=north-8.8
	level.safety.regions=regions
	level.safety.extent=Rect2()
	for region in regions:
		var rect=Rect2(region.x,region.z,region.w,region.d)
		level.safety.extent=rect if level.safety.extent.size==Vector2.ZERO else level.safety.extent.merge(rect)
	var old=level.get_node("MapBoundary");level.remove_child(old);old.free()
	level.safety._build_perimeter(level)
	for mesh in level.get_node("MapBoundary").find_children("*","MeshInstance3D",false,false):mesh.hide()
	var floor_mat=ShaderMaterial.new();floor_mat.shader=preload("res://assets/materials/toy_factory_floor.gdshader");floor_mat.set_shader_parameter("colorful",0.45)
	var wall=ShaderMaterial.new();wall.shader=preload("res://assets/materials/toy_factory_wall.gdshader");wall.set_shader_parameter("paint",Color("325563"));wall.set_shader_parameter("plaster",Color("a6aa99"))
	for i in range(extension_start,regions.size()):
		var region: Dictionary=regions[i]
		var length=minf(region.z+region.d,north)-region.z
		var center=Vector3(region.x+region.w/2,0,region.z+length/2)
		G.box(root,center-Vector3.UP*0.10,Vector3(region.w,0.2,length),floor_mat,true).name="LevelFactoryFloor"
		G.box(root,center+Vector3.UP*3.82,Vector3(region.w,0.16,length),G.material("concrete",Color("72786d")),true)
	for collision in level.get_node("MapBoundary").get_children():
		if not collision is CollisionShape3D or collision.position.z>=north:continue
		var size=collision.shape.size
		G.box(root,Vector3(collision.position.x,1.9,collision.position.z),Vector3(size.x,3.8,size.z),wall)
	if level.room_id=="loading":_inspection_wing(wall)
	else:
		_sign("JALUR DISTRIBUSI / "+{"relay":"PEMELIHARAAN","production":"ADMINISTRASI","office":"LABORATORIUM","ritual":"KARANTINA"}[level.room_id],Vector3(0,2.65,north-4.5),2.8)
		_light(Vector3(0,3.4,north-4),Color("91b8b6"),1.8)
		for side in [-1,1]:G.box(root,Vector3(side*1.43,0.9,north-5.0),Vector3(0.05,0.07,9),G.material("plain",Color("b39b54")))

func _sign(message: String,point: Vector3,width=3.0,yaw=0.0) -> void:
	var sign_root=Node3D.new();sign_root.position=point;sign_root.rotation.y=yaw;root.add_child(sign_root)
	G.box(sign_root,Vector3.ZERO,Vector3(width,0.52,0.05),G.material("plain",Color("1c333a")))
	var text=G.sign_text(sign_root,message,Vector3(0,0,0.034),23)
	text.pixel_size=minf(0.008,width/maxf(1,message.length()*15));text.outline_size=0
	if absf(point.x)<0.1 and point.y+0.26<3.74:
		var stem=3.74-point.y-0.26
		for x in [-width*0.32,width*0.32]:G.cylinder(sign_root,Vector3(x,0.26+stem/2,0),0.015,stem,G.material("steel",Color("5b6862")))

func _light(point: Vector3,color: Color,energy: float,powered=false) -> void:
	A.furniture(root,"lampSquareCeiling",point,Vector3(0.7,0.08,0.3),0,false)
	if point.y+0.08<3.74:
		var stem=3.74-point.y-0.08
		G.cylinder(root,point+Vector3.UP*(0.08+stem/2),0.018,stem,G.material("steel",Color("5b6862")))
	var lamp=OmniLight3D.new();lamp.position=point-Vector3.UP*0.3;lamp.light_color=color;lamp.light_energy=energy;lamp.omni_range=7
	root.add_child(lamp)
	if powered:lights.append(lamp)

func _inspection_wing(wall: Material) -> void:
	for side in [-1,1]:
		var x=side*2.0
		for z in [-25.3,-33.7]:G.box(root,Vector3(x,1.9,z),Vector3(0.16,3.8,2.6),wall,true)
		G.box(root,Vector3(x,3.35,-29.5),Vector3(0.16,0.9,5.7),wall,true)
		for z in [-28.1,-30.9]:G.box(root,Vector3(x,1.42,z),Vector3(0.3,2.84,0.13),G.material("steel",Color("475b60")))
		_sign("POS PENGAWAS" if side<0 else "GALERI PAMERAN",Vector3(x-side*0.12,3.0,-29.5),3.2,-side*PI/2)
	_sign("INSPEKSI / RELAI UTARA",Vector3(0,2.95,-23.5),3.8)
	_sign("GALERI REKA →    ← POS PENGAWAS",Vector3(0,2.9,-32.6),3.7)
	_sign("POMPA ←    DISTRIBUSI →",Vector3(0,2.95,-38.0),3.8)
	_sign("LENTERA-G / RUANG INSPEKSI",Vector3(0,3.05,-64.5),3.8)
	for z in [-25,-32,-38]:_light(Vector3(0,3.55,z),Color("739d9c"),0.6)
	for p in [Vector3(-8,3.5,-29),Vector3(9,3.5,-29)]:
		_light(p,Color("e2c28c"),1.7,true)
		_light(p+Vector3(0,-1.2,3),Color("81958c"),0.35)
	for i in range(3):
		var x=4.2+i*3.7
		G.box(root,Vector3(x,0.32,-33.4),Vector3(1.45,0.64,1.05),G.material("plain",Color("974a3b")),true)
		A.place(root,"res://assets/vendor/kenney_factory/box-large.glb",Vector3(x,0.65,-33.4),Vector3(0.7,0.66,0.7),i*0.3,false)
		var toy=level.get_node("FactoryArtDirection")._toy(Vector3(x,1.32,-33.4),["a34338","36788e","bca057"][i],0.72,root)
		toy.rotation.y=0.15*(i-1)
		_sign(["01 / PENERIMAAN","02 / PERAKITAN","03 / INSPEKSI"][i],Vector3(x,1.75,-34.8),2.8)
	A.place(root,"res://assets/vendor/kenney_factory/conveyor-bars-sides.glb",Vector3(11,0,-25.5),Vector3(2.1,0.95,1.4),-PI/2,true,"GalleryAssemblyExhibit")
	for side in [-1,1]:
		var shelf_x=12.5 if side>0 else -12.4
		A.furniture(root,"bookcaseOpen",Vector3(shelf_x,0,-31.0),Vector3(1.45,2.2,0.48),-side*PI/2,true)
		for i in range(3):
			level.get_node("FactoryArtDirection")._toy(Vector3(shelf_x-side*0.12,0.25+i*0.59,-31),["a34338","36788e","bca057"][i],0.46,root)
	A.furniture(root,"desk",Vector3(7.5,0,-26),Vector3(2.5,0.86,0.85),0,true)
	fuse=A.place(root,"res://assets/vendor/revision10/cartridge_fuse.glb",Vector3(7.5,0.87,-26),Vector3(-1,0.28,-1),0,false,"InspectionFuse")
	level.interact(Vector3(7.5,1.01,-26),"factory_route","Ambil sekering penerangan darurat","fuse",false,Vector3(0.4,0.4,0.4))
	_sign("CADANGAN CAHAYA\nPASANG DI POS PENGAWAS",Vector3(7.5,1.9,-24.12),3.4,PI)
	A.furniture(root,"desk",Vector3(-9,0,-33.4),Vector3(3,0.86,1),0,true)
	for i in range(3):A.furniture(root,"computerScreen",Vector3(-10.1+i*1.15,0.87,-33.4),Vector3(0.85,0.65,0.22),0,false)
	A.furniture(root,"chairDesk",Vector3(-9,0,-31.8),Vector3(0.7,1.0,0.7),PI,false)
	G.box(root,Vector3(-13.25,1.40,-28.6),Vector3(0.3,1.35,1.05),G.material("steel",Color("3c5356")),true).name="InspectionPowerCabinet"
	A.place(root,"res://assets/vendor/kenney_factory/lever-single.glb",Vector3(-13.01,1.18,-28.6),Vector3(0.38,0.48,0.32),PI/2,false)
	level.interact(Vector3(-12.94,1.5,-28.6),"factory_route","Pasang sekering / pulihkan listrik darurat","power",false,Vector3(0.4,0.8,0.8))
	_sign("PENERANGAN DARURAT\nGALERI / RELAI",Vector3(-12.99,2.55,-28.6),2.4,PI/2)
	G.box(root,Vector3(-8,0.88,-33.3),Vector3(0.35,0.018,0.42),G.material("cotton",Color("c1b591")))
	level.interact(Vector3(-8,0.94,-33.3),"factory_route","Baca log pengawasan terakhir","log",false,Vector3(0.4,0.25,0.45))
	shutter=G.box(root,Vector3(0,1.45,-63.2),Vector3(3.9,2.9,0.16),G.material("steel",Color("48605d")),true);shutter.name="InspectionShutter"
	for y in range(13):G.box(shutter,Vector3(0,-1.3+y*0.21,0.1),Vector3(3.78,0.035,0.06),G.material("plain",Color("6f7e72")))
	level.interact(Vector3(0,1.4,-62.95),"factory_route","Periksa shutter ruang inspeksi","shutter")
	_utility_wing(wall)
	update()

func _document(id: String,point: Vector3,yaw: float,heading: String) -> void:
	var board=Node3D.new();board.name="InspectionDocument_"+id;board.position=point;board.rotation.y=yaw;root.add_child(board)
	G.box(board,Vector3.ZERO,Vector3(1.18,0.82,0.05),G.material("plain",Color("515d56")))
	G.box(board,Vector3(0,0,0.03),Vector3(1.05,0.69,0.006),G.material("plain",Color("cabd96")))
	var text=G.sign_text(board,heading+"\n\nE · BACA PROSEDUR",Vector3(0,0,0.037),21);text.pixel_size=0.0031;text.modulate=Color("353d35");text.outline_size=0
	level.interact(point+board.basis.z*0.18,"factory_route","Baca "+heading,id,false,Vector3(0.7,0.7,0.7))

func _utility_wing(wall: Material) -> void:
	var valves=State.data.get("inspectionValves",[])
	if not valves is Array or valves.size()!=3 or not valves.all(func(v):return (v is float or v is int) and v>=0 and v<4 and floorf(v)==v):
		State.data.inspectionValves=[2,1,3]
	if not State.data.get("inspectionSequence",null) is Array:State.data.inspectionSequence=[]
	var sequence: Array=State.data.inspectionSequence
	if sequence.size()>4 or sequence!=CIRCUIT_ORDER.slice(0,sequence.size()):sequence.clear()
	if State.flag("inspectionPower"):
		State.set_flag("inspectionFuseInstalled");State.set_flag("inspectionPressure")
		State.data.inspectionValves=PRESSURE_TARGET.duplicate();State.data.inspectionSequence=CIRCUIT_ORDER.duplicate()
	for z in [-38,-45.5,-54,-60]:_light(Vector3(0,3.55,z),Color("859f9b"),0.5,true)
	for side in [-1,1]:
		var x=side*2.12
		for segment in [[-41.5,5.0],[-52.0,8.0]]:
			var partition=G.box(root,Vector3(x,1.9,segment[0]),Vector3(0.16,3.8,segment[1]),wall,true)
			level.nav_extra.append(Rect2(partition.position.x-0.10,segment[0]-segment[1]/2,0.2,segment[1]))
		G.box(root,Vector3(x,3.35,-46),Vector3(0.16,0.9,4.0),wall,true)
		_sign("RUANG POMPA / 03" if side<0 else "DISTRIBUSI DAYA / 04",Vector3(x-side*0.12,2.95,-46),3.5,-side*PI/2)
		for z in [-41,-52]:_light(Vector3(side*12,3.55,z),Color("8daaa0") if side<0 else Color("d6bb88"),0.65,true)
		for z in [-42,-50]:
			var support_x=side*(20.9 if side<0 else 22.9)
			G.box(root,Vector3(support_x,1.9,z),Vector3(0.18,3.8,0.22),G.material("steel",Color("586969")))
	_document("pressure_note",Vector3(-20.8,1.8,-54.975),0,"PENGATURAN TEKANAN")
	_document("sequence_note",Vector3(-6.0,1.8,-34.975),0,"PROSEDUR PEMULIHAN")
	_document("gallery_note",Vector3(10.8,1.8,-34.975),0,"LEMBAR SERAH TERIMA")
	for i in range(3):
		var x=-17.5+i*5.2
		A.place(root,"res://assets/vendor/kenney_factory/machine-connection-pipe.glb",Vector3(x,0,-41.0),Vector3(1.8,2.5,2.0),PI,true,"InspectionPump%d"%i)
		level.nav_extra.append(Rect2(x-0.9,-42,1.8,2))
		var panel=Node3D.new();panel.name="PressureValve%d"%i;panel.position=Vector3(x,1.45,-54.78);root.add_child(panel)
		G.box(panel,Vector3.ZERO,Vector3(1.25,1.05,0.20),G.material("steel",Color("465d5d")),true)
		G.box(panel,Vector3(0,0,-0.16),Vector3(0.9,0.8,0.12),G.material("steel",Color("465d5d")))
		var wheel=Node3D.new();wheel.name="Wheel";wheel.position.z=0.20;panel.add_child(wheel);valve_wheels.append(wheel)
		var ring=MeshInstance3D.new();var torus=TorusMesh.new();torus.inner_radius=0.22;torus.outer_radius=0.27;torus.rings=24;torus.ring_segments=8;ring.mesh=torus;ring.rotation.x=PI/2;ring.material_override=G.material("steel",Color("a98049"));wheel.add_child(ring)
		for angle in [0.0,PI/2]:
			var spoke=G.box(wheel,Vector3.ZERO,Vector3(0.47,0.035,0.035),G.material("steel",Color("a98049")));spoke.rotation.z=angle
		var arrow=G.sign_text(wheel,"↑",Vector3(0,0.08,0.04),42);arrow.pixel_size=0.004;arrow.outline_size=0
		var readout=G.sign_text(panel,"",Vector3(0,0.77,0.15),24);readout.pixel_size=0.004;readout.outline_size=0;valve_readouts.append(readout)
		level.interact(Vector3(x,1.45,-54.42),"factory_route","Putar katup "+["I","II","III"][i],"valve_"+str(i),false,Vector3(0.8,0.8,0.5))
	# Four separate wall stations require moving around the distribution hall.
	for i in range(4):
		var point=[Vector3(7,1.45,-55.78),Vector3(18,1.45,-55.78),Vector3(23.28,1.45,-48),Vector3(10,1.45,-39.22)][i]
		var yaw=[0.0,0.0,-PI/2,PI][i]
		var station=Node3D.new();station.name="InspectionCircuit%d"%i;station.position=point;station.rotation.y=yaw;root.add_child(station)
		G.box(station,Vector3.ZERO,Vector3(1.35,1.3,0.20),G.material("steel",Color("435557")),true)
		G.box(station,Vector3(0,0,-0.16),Vector3(1.0,1.0,0.12),G.material("steel",Color("435557")))
		A.place(station,"res://assets/vendor/kenney_factory/lever-single.glb",Vector3(0,-0.35,0.15),Vector3(0.45,0.62,0.34),0,false)
		var readout=G.sign_text(station,"",Vector3(0,0.90,0.13),22);readout.pixel_size=0.004;readout.outline_size=0;circuit_readouts.append(readout)
		level.interact(point+station.basis.z*0.48,"factory_route","Aktifkan terminal "+CIRCUIT_NAMES[i],"circuit_"+str(i),false,Vector3(0.8,0.9,0.5))
	for x in [8,16]:
		A.place(root,"res://assets/vendor/kenney_factory/machine-window.glb",Vector3(x,0,-47.0),Vector3(2.2,2.55,2.2),PI/2,true)
		level.nav_extra.append(Rect2(x-1.1,-48.1,2.2,2.2))
	_utility_details()
	G.box(root,Vector3(0,2.5,-62.98),Vector3(3.5,0.75,0.12),G.material("plain",Color("263e40")))
	power_readout=G.sign_text(root,"",Vector3(0,2.5,-62.90),20);power_readout.pixel_size=0.0047;power_readout.outline_size=0

func _utility_details() -> void:
	var steel=G.material("steel",Color("58675f"))
	var warning=G.material("plain",Color("ae944c"))
	# The pumps feed actual overhead runs, with downpipes into the machines.
	for x in [-17.5,-12.3,-7.1]:
		G.cylinder(root,Vector3(x,2.80,-41),0.11,0.6,steel)
		var pipe=G.cylinder(root,Vector3(x,3.12,-47.65),0.11,13.3,steel);pipe.rotation.x=PI/2
		for z in [-43.5,-50.5]:
			G.box(root,Vector3(x,3.57,z),Vector3(0.035,0.5,0.05),steel)
			G.box(root,Vector3(x,3.33,z),Vector3(0.44,0.04,0.18),steel)
		for z in [-43,-51.0]:
			G.box(root,Vector3(x,0.012,z),Vector3(2.8,0.018,0.06),warning)
	for point in [Vector3(13.8,0,-42.0),Vector3(13.8,0,-52.0)]:
		A.place(root,"res://assets/vendor/kenney_factory/machine-fortified.glb",point,Vector3(2.5,2.4,1.2),0,true)
		level.nav_extra.append(Rect2(point.x-1.25,point.z-0.6,2.5,1.2))
	for side in [-1,1]:
		var min_x=-21.4 if side<0 else 2.2;var max_x=-2.2 if side<0 else 23.4
		for z in [-39.18,-54.80 if side<0 else -55.80]:
			G.box(root,Vector3((min_x+max_x)/2,0.14,z),Vector3(max_x-min_x,0.12,0.06),steel)
			G.box(root,Vector3((min_x+max_x)/2,0.21,z),Vector3(max_x-min_x,0.025,0.065),warning)
		for z in [-42.5,-50]:_light(Vector3(side*18,3.55,z),Color("8aab9d") if side<0 else Color("d2b384"),0.65,true)
		_sign("RUANG POMPA" if side<0 else "PANEL DISTRIBUSI",Vector3(-13 if side<0 else 14,2.95,-54.975 if side<0 else -55.975),3.8)
	# Match the weathered metal finish used in the rest of the factory.
	var finish=ShaderMaterial.new();finish.shader=preload("res://assets/materials/factory_metal.gdshader");finish.set_shader_parameter("paint",Color("56746c"))
	for prop in root.get_children():
		if not prop is Node3D or not str(prop.get_meta("asset_source","")).contains("/machine-"):continue
		for mesh in prop.find_children("*","MeshInstance3D",true,false):mesh.material_override=finish

func interact(id: String,host: Node3D) -> void:
	match id:
		"fuse":
			State.set_flag("inspectionFuseHeld");host.audio.effect("click")
			host.ui.notify("Sekering darurat ditemukan. Cari kabinet listrik di Pos Pengawas.",6)
		"power":
			if State.flag("inspectionFuseInstalled") or State.flag("inspectionPower"):
				host.ui.notify(objective(),6);return
			if not State.flag("inspectionFuseHeld"):
				host.ui.notify("Dudukan sekering kosong. Periksa meja inventaris di Galeri Pameran.",6);return
			State.set_flag("inspectionFuseInstalled");host.audio.effect("click")
			host.ui.notify("Penerangan servis menyala. Shutter masih dikunci tekanan dan empat terminal. Baca prosedur di pos, lalu periksa Ruang Pompa.",8)
		"log":
			State.add_note("inspection_log","LOG POS PENGAWAS / SHIFT TERAKHIR","REKA sudah berhenti menjaga. Jalur utara masih dikunci sistem keselamatan, bukan petugas lain. Sekering di meja galeri hanya menyalakan penerangan servis. Pulihkan tekanan di Ruang Pompa, lalu rangkai empat terminal di Distribusi Daya. Lembar serah terima di galeri dan prosedur di papan pos menjelaskan urutannya. Peralatan LENTERA-G tetap disimpan di ruang relai utara, di bawah atap kaca.")
			host.ui.show_note("LOG POS PENGAWAS / SHIFT TERAKHIR",State.data.notes.inspection_log.body)
		"pressure_note":_read_procedure(host,id,"PENGATURAN TEKANAN","Tiga manometer harus menunjuk: I → KANAN, II → KIRI, III → ATAS.\n\nSetiap putaran adalah seperempat lingkaran. Katup I ikut memutar II. Katup II ikut memutar III. Katup III hanya mengubah dirinya sendiri. Mulailah dari hulu; perbaikan di hilir tidak mengubah hulu. Lampu hijau akan mengunci rangkaian yang sudah benar.")
		"sequence_note":_read_procedure(host,id,"PROSEDUR PEMULIHAN","Sekering → tekanan → empat terminal. Terminal tidak menerima beban sebelum tekanan stabil.\n\nPengujian beban dilakukan sebelum penerimaan. Penerimaan harus diikuti inspeksi. Perakitan adalah langkah terakhir. Cocokkan nama ini dengan label I–IV di Ruang Distribusi. Salah urutan mengosongkan empat sambungan, tetapi tekanan dan sekering tetap aman.")
		"gallery_note":_read_procedure(host,id,"LEMBAR SERAH TERIMA","Peta jalur utara: Galeri Pameran dan Pos Pengawas, lanjut ke Ruang Pompa di barat serta Distribusi Daya di timur. Shutter inspeksi berada di ujung koridor utara.\n\nPenamaan terminal: I = Penerimaan, II = Perakitan, III = Uji Beban, IV = Inspeksi. Setelah listrik servis menyala, ikuti prosedur di papan pos. LENTERA-G tidak diperlukan untuk memulihkan sistem ini.")
		"shutter":host.ui.notify(objective(),7)
		_:
			if id.begins_with("valve_"): _turn_valve(int(id.trim_prefix("valve_")),host)
			elif id.begins_with("circuit_" ): _connect_circuit(int(id.trim_prefix("circuit_")),host)
	host._save();host._sync_active();update()

func _read_procedure(host: Node3D,id: String,title: String,body: String) -> void:
	State.add_note(id,title,body);host.ui.show_note(title,body)

func _turn_valve(index: int,host: Node3D) -> void:
	if index<0 or index>2:return
	if not State.flag("inspectionFuseInstalled"):
		host.ui.notify("Aktuator belum mendapat daya. Pasang sekering di Pos Pengawas.",5);return
	if State.flag("inspectionPressure") or State.flag("inspectionPower"):
		host.ui.notify("Tekanan sudah stabil; pengaman mengunci ketiga katup.",4);return
	var values: Array=State.data.inspectionValves
	values[index]=(int(values[index])+1)%4
	if index<2:values[index+1]=(int(values[index+1])+1)%4
	host.audio.effect("click")
	if values==PRESSURE_TARGET:
		State.set_flag("inspectionPressure");host.audio.effect("reveal")
		host.ui.notify("Tekanan stabil. Sekarang pulihkan empat terminal di Distribusi Daya sesuai prosedur pos.",7)

func _connect_circuit(index: int,host: Node3D) -> void:
	if index<0 or index>3 or State.flag("inspectionPower"):return
	if not State.flag("inspectionPressure"):
		host.ui.notify("Interlock tekanan masih merah. Stabilkan tiga manometer di Ruang Pompa.",6);return
	var sequence: Array=State.data.inspectionSequence
	if index==CIRCUIT_ORDER[sequence.size()]:
		sequence.append(index);host.audio.effect("click")
		if sequence.size()==4:
			State.set_flag("inspectionPower");host.audio.effect("impact")
			host.ui.notify("Empat jalur tersambung. Shutter inspeksi utara terbuka. Ikuti koridor menuju atap kaca.",8)
		else:host.ui.notify("Jalur tersambung %d / 4. Lanjutkan sesuai prosedur."%sequence.size(),4)
	else:
		sequence.clear();host.audio.effect("disrupt")
		host.ui.notify("Urutan beban salah; empat jalur direset. Sekering dan tekanan tetap stabil. Baca kembali prosedur di jurnal.",7)

func objective() -> String:
	if State.flag("inspectionPower"):return "Listrik dan tekanan stabil. Lewati shutter di ujung koridor utara menuju Lentera-G."
	if not State.flag("inspectionFuseInstalled"):return "Jelajahi galeri dan pos: temukan sekering, lalu pasang di kabinet Pos Pengawas."
	if not State.flag("inspectionPressure"):return "Pulihkan tiga manometer di Ruang Pompa barat. Catatan servis menjelaskan pengaruh antar katup."
	return "Sambungkan empat terminal di Distribusi Daya timur (%d/4). Cocokkan prosedur pos dengan label terminal."%State.data.get("inspectionSequence",[]).size()

func update() -> void:
	if level.room_id!="loading":return
	fuse.visible=not State.flag("inspectionFuseHeld")
	var powered=State.flag("inspectionPower")
	shutter.visible=not powered
	for body in shutter.find_children("*","StaticBody3D",true,false):body.collision_layer=0 if powered else 1
	for lamp in lights:lamp.light_energy=1.7 if powered else 1.1 if State.flag("inspectionFuseInstalled") else 0.32
	var values: Array=State.data.inspectionValves
	for i in range(valve_wheels.size()):
		valve_wheels[i].rotation.z=-int(values[i])*PI/2
		valve_readouts[i].text=["I","II","III"][i]+"  "+["↑","→","↓","←"][int(values[i])]
		valve_readouts[i].modulate=Color("98c5a2") if State.flag("inspectionPressure") else Color("e6cb83")
	var sequence: Array=State.data.inspectionSequence
	for i in range(circuit_readouts.size()):
		circuit_readouts[i].text=CIRCUIT_NAMES[i]+("\n● TERHUBUNG" if sequence.has(i) or powered else "\n○ MENUNGGU")
		circuit_readouts[i].modulate=Color("98c5a2") if sequence.has(i) or powered else Color("d8c89b")
	var status="DAYA %s    TEKANAN %s\nTERMINAL %d / 4"%["OK" if State.flag("inspectionFuseInstalled") or powered else "—","OK" if State.flag("inspectionPressure") or powered else "—",4 if powered else sequence.size()]
	if status!=last_status:power_readout.text=status;last_status=status

func check_transition(player: Node3D) -> void:
	update()
	if leaving or player.position.z>=end_z:return
	if level.room_id=="loading" and not State.flag("inspectionPower"):return
	leaving=true
	level.passage_entered.emit(State.ROOMS[State.ROOMS.find(level.room_id)+1])
	level.set_process(false)
