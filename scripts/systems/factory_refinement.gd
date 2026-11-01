extends Node3D
## Replace unsupported legacy set dressing with complete, grounded service rooms.
const G = preload("res://scripts/systems/geometry.gd")
const A = preload("res://scripts/systems/free_assets.gd")
const KIT = "res://assets/vendor/kenney_factory/"
var level: Node3D
var wheels: Array[Node3D] = []
var needles: Array[Node3D] = []
var valve_angles: Array[float] = []
var last_values: Array = []
var valve_busy_until = 0.0
var time = 0.0
var tape_reels: Array[Node3D] = []

func apply(owner_level: Node3D) -> void:
	level = owner_level; name = "FactoryRefinement17"; level.add_child(self)
	match level.room_id:
		"pursuit": _pursuit()
		"production": _production()
		"office": _office()

func metal(tint = "485d58") -> Material:
	var m = ShaderMaterial.new(); m.shader = preload("res://assets/materials/factory_metal.gdshader")
	m.set_shader_parameter("paint", Color(tint)); m.set_shader_parameter("decay", 0.08);m.set_shader_parameter("grain_strength",0.08)
	return m

func retire(node: Node3D) -> void:
	if node == null: return
	node.hide()
	for body in node.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0

func retire_ids(ids: Array) -> void:
	for id in ids: retire(level.find_child("Source_" + str(id), true, false))

func box(parent: Node3D, p: Vector3, size: Vector3, material: Material, solid = false) -> MeshInstance3D:
	var mesh = G.box(parent, p, size, material, solid)
	if solid:
		var b = parent.transform * AABB(p - size / 2, size)
		level.nav_extra.append(Rect2(b.position.x,b.position.z,b.size.x,b.size.z))
	return mesh

func label(parent: Node3D, text: String, p: Vector3, pixel = 0.003, color = Color("c1bea4")) -> Label3D:
	var text_mesh = G.sign_text(parent, text, p, 24)
	text_mesh.pixel_size = pixel; text_mesh.outline_size = 0; text_mesh.modulate = color
	return text_mesh

func beam(parent: Node3D, start: Vector3, end: Vector3, radius = 0.035, material: Material = null) -> MeshInstance3D:
	var segment = G.cylinder(parent, (start + end) / 2, radius, start.distance_to(end), metal() if material == null else material)
	segment.quaternion = Quaternion(Vector3.UP, (end-start).normalized())
	return segment

func ring(parent: Node3D, p: Vector3, radius: float, thickness: float, material: Material) -> MeshInstance3D:
	var mesh = MeshInstance3D.new(); var torus = TorusMesh.new()
	torus.inner_radius = radius - thickness; torus.outer_radius = radius + thickness
	torus.rings = 40; torus.ring_segments = 10; mesh.mesh = torus
	mesh.rotation.x = PI / 2; mesh.position = p; mesh.material_override = material; parent.add_child(mesh)
	return mesh

func lamp(parent: Node3D, p: Vector3, color: Color, energy = 1.7) -> void:
	G.box(parent,p,Vector3(1.25,0.09,0.22),metal("293a39"))
	var glow = G.material("plain",color).duplicate(); glow.emission_enabled = true; glow.emission = color; glow.emission_energy_multiplier = 1.8
	G.box(parent,p-Vector3.UP*0.055,Vector3(1.06,0.025,0.14),glow)
	var light = OmniLight3D.new(); light.position = p - Vector3.UP * 0.35; light.light_color = color
	light.light_energy = energy; light.omni_range = 8; light.shadow_enabled = true; parent.add_child(light)
	for x in [-0.48,0.48]: beam(parent,p+Vector3(x,0.04,0),Vector3(p.x+x,maxf(3.50,p.y+0.16),p.z),0.012)

func bench(parent: Node3D, p: Vector3, width = 3.5, yaw = 0.0) -> Node3D:
	var desk = Node3D.new(); desk.position = p; desk.rotation.y = yaw; desk.name = "GroundedWorkbench"; parent.add_child(desk)
	var wood = ShaderMaterial.new(); wood.shader = preload("res://assets/materials/wood.gdshader"); wood.set_shader_parameter("wood_color",Color("67543b"))
	box(desk,Vector3(0,0.91,0),Vector3(width,0.12,0.88),wood,true)
	for x in [-width/2+0.12,width/2-0.12]:
		for z in [-0.31,0.31]:
			G.box(desk,Vector3(x,0.435,z),Vector3(0.07,0.87,0.07),metal())
		G.box(desk,Vector3(x,0.19,0),Vector3(0.08,0.07,0.68),metal())
	G.box(desk,Vector3(0,0.34,-0.30),Vector3(width-0.2,0.08,0.06),metal())
	return desk

func rack(parent: Node3D, p: Vector3, width = 2.3, yaw = 0.0, archives = false) -> Node3D:
	var r = Node3D.new(); r.name = "GroundedArchiveRack" if archives else "GroundedPartsRack"; r.position = p; r.rotation.y = yaw; parent.add_child(r,true)
	var steel = metal("46534e"); var card = G.material("burlap",Color("9c8765"))
	for x in [-width/2,width/2]:
		for z in [-0.29,0.29]:
			G.box(r,Vector3(x,1.32,z),Vector3(0.055,2.64,0.055),steel)
			G.box(r,Vector3(x,0.035,z),Vector3(0.16,0.07,0.14),steel)
	for row in range(4):
		var y = 0.16 + row * 0.59
		G.box(r,Vector3(0,y,0),Vector3(width+0.05,0.065,0.66),steel)
		for col in range(4):
			var x = -width*0.38+col*width*0.25
			if archives:
				G.box(r,Vector3(x,y+0.235,0),Vector3(width*0.215,0.40,0.48),card)
				G.box(r,Vector3(x,y+0.28,0.244),Vector3(0.21,0.10,0.007),G.material("plain",Color("bcb095")))
				label(r,"%02d / %02d"%[row+1,col+17],Vector3(x,y+0.28,0.25),0.0012,Color("383e33"))
			else:
				var carton=A.place(r,KIT+"box-small.glb",Vector3(x,y+0.033,0),Vector3(width*0.21,0.34,0.46),0,false)
				for mesh in carton.find_children("*","MeshInstance3D",true,false):mesh.material_override=card
	beam(r,Vector3(-width/2,0.2,-0.30),Vector3(width/2,2.45,-0.30),0.018,steel)
	beam(r,Vector3(width/2,0.2,-0.30),Vector3(-width/2,2.45,-0.30),0.018,steel)
	box(r,Vector3(0,1.32,0),Vector3(width,2.64,0.62),_invisible_material(),true).hide()
	return r

func _invisible_material() -> Material:
	return G.material("plain",Color("273632"))

func paper(id: String, parent: Node3D, p: Vector3, yaw = 0.0) -> void:
	var note = Node3D.new(); note.name = "SupportedNote_"+id; note.position = p; note.rotation.y = yaw; parent.add_child(note)
	G.box(note,Vector3.ZERO,Vector3(0.39,0.012,0.29),G.material("plain",Color("c4b88f")))
	for i in range(6):G.box(note,Vector3(-0.015,0.0065,-0.10+i*0.032),Vector3(0.27-(i%3)*0.025,0.001,0.003),G.material("plain",Color("766d55")))
	for object in level.get_children():
		if object is KalaInteractable and object.action_id == "note" and object.parameter == id: object.position = to_local(note.global_position) + Vector3.UP * 0.08

func wall_note(id: String,p: Vector3,yaw: float,title: String) -> void:
	var board=Node3D.new();board.name="WallNote_"+id;board.position=p;board.rotation.y=yaw;add_child(board)
	G.box(board,Vector3.ZERO,Vector3(0.66,0.83,0.05),metal())
	G.box(board,Vector3(0,0,0.029),Vector3(0.53,0.70,0.008),G.material("plain",Color("b6ab86")))
	var writing=label(board,title,Vector3(0,0.23,0.035),0.0017,Color("3a4235"));writing.font=preload("res://assets/fonts/Caveat.ttf")
	for i in range(8):G.box(board,Vector3(0,0.10-i*0.043,0.035),Vector3(0.39-(i%3)*0.035,0.003,0.001),G.material("plain",Color("77735b")))
	for x in [-0.23,0.23]:G.box(board,Vector3(x,0.30,0.044),Vector3(0.032,0.04,0.012),metal("9b967b"))
	for object in level.get_children():
		if object is KalaInteractable and object.action_id=="note" and object.parameter==id:object.position=p+board.basis.z*0.14

func _annex_finish(id: String, color: String) -> void:
	var shell = level.find_child(id,true,false)
	if shell == null: return
	var wall = ShaderMaterial.new(); wall.shader = preload("res://assets/materials/service_wall.gdshader"); wall.set_shader_parameter("paint",Color(color))
	for mesh in shell.find_children("*","MeshInstance3D",true,false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		if b.size.y > 3.5 and b.size.x > 5: mesh.material_override = wall
		elif b.size.y < 0.35 and b.size.x > 5 and b.size.z > 5 and b.end.y < 0.1:mesh.material_override = _floor()
	# Legacy batching left paint strips a few millimetres above the floor.
	# Cover each annex with one finished floor at a separate, stable height.
	var floor_size=Vector2(12,12) if id in ["workshop","infirmary"] else Vector2(10,10) if id=="records" else Vector2(12,8)
	var floor_center={"workshop":Vector3(-26,-0.009,4),"infirmary":Vector3(26,-0.009,5),"records":Vector3(-15,-0.009,3),"monitor":Vector3(16,-0.009,5.5)}[id]
	G.box(self,floor_center,Vector3(floor_size.x-0.30,0.045,floor_size.y-0.30),_floor())

func _floor() -> Material:
	var m = ShaderMaterial.new(); m.shader = preload("res://assets/materials/relay_service_floor.gdshader"); return m

func _production() -> void:
	retire_ids([2164,2166,2167,2168,2169,2170,2172,2181,2182,2244,2246,2248,2252,2253,2254,2255,2256,2257,2258,2323,2325,2327,2329,2331,2285,2286,2287,2288,2289,2290,2291])
	wall_note("hands_note",Vector3(19.79,1.55,-3),-PI/2,"CATATAN TEKNISI")
	for child in level.get_node("FactoryRevision09").get_children():
		if str(child.name).begins_with("screen-panel-flat") or str(child.name).begins_with("bathroomCabinet"):retire(child)
	_annex_finish("workshop","304b48"); _annex_finish("infirmary","56655b")
	var workshop = Node3D.new(); workshop.name = "PressureWorkshop"; add_child(workshop)
	bench(workshop,Vector3(-27,0,8.8),6.5)
	for x in [-30.5,-27.5,-24.5]:rack(workshop,Vector3(x,0,-1.40),2.3)
	bench(workshop,Vector3(-31.0,0,3.6),4.0,PI/2)
	var peg = Node3D.new(); peg.position = Vector3(-27.0,1.94,9.72); peg.rotation.y=PI; workshop.add_child(peg)
	G.box(peg,Vector3.ZERO,Vector3(6.5,1.25,0.10),metal("3e5049"))
	for x in range(24):
		for y in range(5):G.sphere(peg,Vector3(-3+x*0.26,-0.45+y*0.22,0.054),Vector3.ONE*0.018,G.material("plain",Color("162522")))
	for i in range(7):
		var x=-2.6+i*0.66
		beam(peg,Vector3(x,0.36,0.08),Vector3(x,0.36,0.15),0.015)
		G.box(peg,Vector3(x,0.04,0.13),Vector3(0.055,0.56,0.06),metal("8b8e7a"))
		ring(peg,Vector3(x,-0.23,0.13),0.09,0.025,metal("8b8e7a"))
	var spare_gear=A.place(workshop,KIT+"cog-a.glb",Vector3(-28,0.972,8.8),Vector3(0.46,0.12,0.46),0,false)
	for mesh in spare_gear.find_children("*","MeshInstance3D",true,false):mesh.material_override=metal("8a8873")
	var tool_case=A.place(workshop,KIT+"box-long.glb",Vector3(-24.8,0.972,8.8),Vector3(0.75,0.24,0.4),0,false)
	for mesh in tool_case.find_children("*","MeshInstance3D",true,false):mesh.material_override=metal("3e5352")
	# A vise is bolted to the bench; loose tools rest on its actual surface.
	G.box(workshop,Vector3(-29.8,1.06,8.6),Vector3(0.42,0.18,0.36),metal())
	for x in [-29.94,-29.66]:G.box(workshop,Vector3(x,1.22,8.6),Vector3(0.10,0.21,0.30),metal("797f70"))
	beam(workshop,Vector3(-30.1,1.10,8.6),Vector3(-29.4,1.10,8.6),0.025)
	paper("valve_note",workshop,Vector3(-26.9,0.981,8.8));paper("tool_origin",workshop,Vector3(-25.6,0.981,8.8))
	paper("wheel_log",workshop,Vector3(-31,0.981,5.1),PI/2)
	lamp(workshop,Vector3(-27,3.40,7.2),Color("c7c3a0"),2.3)
	lamp(workshop,Vector3(-27,3.40,0.6),Color("7caa9e"),1.3)
	# Heavy repair station and a low parts cart give the workshop a used floor
	# plan while leaving the doorway, papers and wheel approach open.
	var lathe=A.place(workshop,KIT+"machine-bed.glb",Vector3(-26.5,0,1.8),Vector3(2.8,1.40,1.15),PI/2,true,"RepairLathe")
	for mesh in lathe.find_children("*","MeshInstance3D",true,false):mesh.material_override=metal("52645c")
	level.nav_extra.append(Rect2(-27.1,0.3,1.2,3.0))
	var cart=Node3D.new();cart.name="PartsTrolley";cart.position=Vector3(-23.2,0,7.4);workshop.add_child(cart)
	for y in [0.23,0.73]:G.box(cart,Vector3(0,y,0),Vector3(0.88,0.07,0.62),metal())
	for x in [-0.38,0.38]:
		for z in [-0.25,0.25]:
			G.box(cart,Vector3(x,0.50,z),Vector3(0.035,0.64,0.035),metal())
			var caster=G.cylinder(cart,Vector3(x,0.09,z),0.09,0.055,G.material("plain",Color("232a24")));caster.rotation.z=PI/2
	A.place(cart,KIT+"cog-b.glb",Vector3(0,0.77,0),Vector3(0.36,0.09,0.36),0,false)
	# Wheel rests on a real pair of hooks, facing the open work area.
	var item = level.props.get("valveWheel") as Node3D
	if item != null:
		item.global_position = level.to_global(Vector3(-31.65,1.72,1.0)); item.rotation.y=PI/2
		for x in [-0.20,0.20]:beam(workshop,Vector3(-31.80,1.92,1+x),Vector3(-31.55,1.92,1+x),0.025)
		G.box(workshop,Vector3(-31.86,1.72,1),Vector3(0.09,1.0,1.2),metal())
		for object in level.get_children():
			if object is KalaInteractable and object.action_id=="item" and object.parameter=="valveWheel":object.position=Vector3(-31.2,1.72,1)
	# Refurbished treatment room; preserve its key board, rebuild supporting desks.
	var clinic=Node3D.new();clinic.name="WorkersTreatment";add_child(clinic)
	A.furniture(clinic,"bedSingle",Vector3(29.7,0,4),Vector3(1.4,0.82,3.3),PI/2,true)
	bench(clinic,Vector3(27.8,0,8.8),4.5)
	rack(clinic,Vector3(30.8,0,0.05),1.5,0,true)
	paper("infirmary_record",clinic,Vector3(27.4,0.981,8.8));paper("raka_message",clinic,Vector3(28.8,0.981,8.8))
	lamp(clinic,Vector3(27.2,3.4,5),Color("aabca8"),1.6)
	# Each valve is its own physical interaction, with no answer overlay.
	for object in level.get_children():
		if object is KalaInteractable and object.action_id=="puzzle" and object.parameter=="valve":object.free()
	var manifold = Node3D.new(); manifold.name="PressureManifold";manifold.position=Vector3(-11,0,-19.75);add_child(manifold)
	G.box(manifold,Vector3(0,1.47,0),Vector3(10.5,2.54,0.18),metal("2c403e"))
	# The service bank occupies real space, so the player and pursuer cannot
	# enter the protruding wheels or walk through the pipe assembly.
	box(manifold,Vector3(0,1.45,0.50),Vector3(10.5,2.9,1.0),_invisible_material(),true).hide()
	for x in [-4.7,4.7]:
		for y in [0.42,2.52]:
			var bolt=G.cylinder(manifold,Vector3(x,y,0.13),0.04,0.05,metal("8c8a71"));bolt.rotation.x=PI/2
	for i in range(3):
		var x=-3.5+i*3.5
		beam(manifold,Vector3(x,0.0,0.38),Vector3(x,5.65,0.38),0.12,metal("6f6e55"))
		for y in [0.22,2.9,5.45]:
			var flange=ring(manifold,Vector3(x,y,0.38),0.18,0.035,metal());flange.rotation.x=0
		var housing=G.cylinder(manifold,Vector3(x,1.45,0.60),0.18,0.45,metal());housing.rotation.x=PI/2
		var wheel=Node3D.new();wheel.name="PhysicalValve%d"%i;wheel.position=Vector3(x,1.45,0.91);manifold.add_child(wheel);wheels.append(wheel)
		ring(wheel,Vector3.ZERO,0.34,0.045,metal("974f37"))
		for spoke in range(5):
			var direction=Vector3(sin(spoke*TAU/5),cos(spoke*TAU/5),0)
			beam(wheel,Vector3.ZERO,direction*0.31,0.023,metal("974f37"))
		G.sphere(wheel,Vector3.ZERO,Vector3(0.13,0.13,0.10),metal("ad9b6b"))
		var gauge=Node3D.new();gauge.name="Manometer%d"%i;gauge.position=Vector3(x,2.39,0.62);manifold.add_child(gauge)
		ring(gauge,Vector3.ZERO,0.27,0.035,metal("8b8e7b"))
		var face=G.cylinder(gauge,Vector3(0,0,-0.02),0.253,0.045,G.material("plain",Color("b8b49b")));face.rotation.x=PI/2
		for tick in range(13):
			var a=-2.35+tick*4.7/12
			var mark=G.box(gauge,Vector3(sin(a)*0.205,cos(a)*0.205,0.015),Vector3(0.012,0.035,0.008),G.material("plain",Color("354039")));mark.rotation.z=-a
		var needle=Node3D.new();needle.name="Needle";needle.position.z=0.029;gauge.add_child(needle);needles.append(needle)
		G.box(needle,Vector3(0,0.095,0),Vector3(0.014,0.20,0.01),G.material("plain",Color("5b2822")))
		G.sphere(needle,Vector3.ZERO,Vector3.ONE*0.04,metal())
		label(manifold,["I","II","III"][i],Vector3(x,0.85,0.55),0.004)
		var mark=label(gauge,"·",Vector3(0,0.233,0.04),0.003,Color(0.55,0.72,0.66,0));mark.name="CalibrationTrace%d"%i;mark.add_to_group("light_reveal");mark.set_meta("exposure",0.0)
		level.interact(manifold.position+Vector3(x,1.45,1.02),"valve","Putar katup "+["I","II","III"][i],str(i),false,Vector3(0.76,0.76,0.35))
		var value=int(State.data.puzzles.valve.pos[i]);valve_angles.append(-value*PI/2);wheel.rotation.z=valve_angles[i];needle.rotation.z=valve_angles[i]
	last_values=State.data.puzzles.valve.pos.duplicate()
	label(manifold,"K-03  /  DISTRIBUSI UAP",Vector3(0,3.27,0.14),0.004)
	G.box(manifold,Vector3(0,3.27,0),Vector3(4.7,0.38,0.16),metal("273b38"))

func _office() -> void:
	retire_ids([2380,2381,2382,2393,2409,2410,2472,2474,2476,2478,2482,2483,2484,2485,2486,2487,2557,2559,2561,2563,2513,2515,2516,2517,2518,2519,2520,2521,2522,2523,2524,2525,2526])
	retire(level.find_child("Item_installedTape",true,false))
	for child in level.get_node("FactoryRevision09").get_children():
		if str(child.name).begins_with("bookcase") or str(child.name).begins_with("screen-panel-wide"):retire(child)
		elif str(child.get_meta("asset_source","")).ends_with("/desk.glb"):
			var timber=ShaderMaterial.new();timber.shader=preload("res://assets/materials/wood.gdshader");timber.set_shader_parameter("wood_color",Color("67543c"))
			for mesh in child.find_children("*","MeshInstance3D",true,false):mesh.material_override=timber
	var art=level.get_node("FactoryArtDirection")
	for mesh in art.find_children("*","MeshInstance3D",true,false):
		var b: AABB=mesh.global_transform*mesh.get_aabb()
		if absf(b.get_center().x)>7:retire(mesh)
	for sign_node in art.find_children("*","Label3D",true,false):
		if str(sign_node.text).begins_with("CAM"):sign_node.hide()
		elif str(sign_node.text).begins_with("RUANG PENGAWASAN"):
			for x in [-2.5,2.5]:beam(sign_node.get_parent(),Vector3(x,0.43,0),Vector3(x,0.70,0),0.014)
	_annex_finish("records","3e514d");_annex_finish("monitor","293d3e")
	bench(self,Vector3(0,0,-5.8),4.3)
	var album=Node3D.new();album.name="SupportedFamilyAlbum";album.position=Vector3(0,0.976,-5.6);add_child(album)
	G.box(album,Vector3(0,0.025,0),Vector3(0.94,0.05,0.65),G.material("burlap",Color("4e5540")))
	G.box(album,Vector3(0.015,0.025,0),Vector3(0.87,0.028,0.60),G.material("plain",Color("b9b393")))
	G.box(album,Vector3(0,0.055,0),Vector3(0.94,0.016,0.65),G.material("burlap",Color("4e5540")))
	var title=label(album,"ARSIP KELUARGA\nD.",Vector3(0,0.065,0),0.0022);title.rotation.x=-PI/2
	for object in level.get_children():
		if object is KalaInteractable and object.action_id=="evidence" and object.parameter=="B":object.position=album.position+Vector3.UP*0.10
	bench(self,Vector3(5.4,0,6.3),2.7);paper("contract_zero",self,Vector3(5.4,0.981,6.3))
	var records=Node3D.new();records.name="PersonnelArchive";add_child(records)
	for x in [-18.5,-15.7,-12.9]:rack(records,Vector3(x,0,-1.4),2.3,0,true)
	for z in [2.2,5.5]:rack(records,Vector3(-19.4,0,z),2.4,PI/2,true)
	bench(records,Vector3(-15.1,0,6.85),5.1)
	paper("breaker_note",records,Vector3(-16.4,0.981,6.85));paper("liability_form",records,Vector3(-13.4,0.981,6.85))
	var tape=level.props.get("tapeReel") as Node3D
	if tape!=null:
		tape.global_position=level.to_global(Vector3(-14.8,1.04,6.85));tape.rotation.x=-PI/2
	for object in level.get_children():
		if object is KalaInteractable and object.action_id=="item" and object.parameter=="tapeReel":object.position=Vector3(-14.8,1.13,6.85)
	lamp(records,Vector3(-15,3.42,4.7),Color("d3c19c"),1.8)
	lamp(records,Vector3(-16,3.42,0),Color("7d9b92"),0.8)
	# The six CRTs sit on a steel rack bolted to the surveillance wall.
	var monitor=Node3D.new();monitor.name="SurveillanceRoom";add_child(monitor)
	G.box(monitor,Vector3(16,3.65,5.5),Vector3(12,0.25,8),G.material("plain",Color("293c36")))
	bench(monitor,Vector3(18.7,0,2.75),5.6)
	bench(monitor,Vector3(15.3,0,8.35),3.8)
	var bank=Node3D.new();bank.name="BoltedCRTBank";bank.position=Vector3(18.6,0,1.83);monitor.add_child(bank)
	for x in [-2.25,2.25]:
		G.box(bank,Vector3(x,1.45,0),Vector3(0.08,2.9,0.38),metal())
		for y in [0.15,2.75]:G.box(bank,Vector3(x,y,-0.14),Vector3(0.22,0.14,0.48),metal())
	for y in [1.0,1.92]:G.box(bank,Vector3(0,y,0),Vector3(4.7,0.08,0.65),metal())
	for row in range(2):
		for col in range(3):
			var crt=Node3D.new();crt.name="MountedCRT%d"%(row*3+col);crt.position=Vector3(-1.5+col*1.5,1.04+row*0.92,0);bank.add_child(crt)
			G.box(crt,Vector3(0,0.36,0),Vector3(1.26,0.72,0.55),metal("33413c"))
			var screen=ShaderMaterial.new();screen.shader=preload("res://assets/materials/memory_crt.gdshader");screen.set_shader_parameter("intensity",0.7)
			G.box(crt,Vector3(0,0.38,0.285),Vector3(1.02,0.51,0.035),screen)
			label(crt,"CAM %02d"%(row*3+col+1),Vector3(-0.33,0.13,0.308),0.0013,Color("8eb0a0"))
			beam(crt,Vector3(0,0,-0.29),Vector3(0,-crt.position.y+0.08,-0.29),0.012,G.material("plain",Color("192623")))
	var chair=A.furniture(monitor,"chairDesk",Vector3(18.6,0,4.45),Vector3(0.68,1.05,0.68),0,false)
	for mesh in chair.find_children("*","MeshInstance3D",true,false):mesh.material_override=metal("4a5348")
	paper("monitor_log",monitor,Vector3(20.3,0.981,2.75))
	lamp(monitor,Vector3(17.5,3.42,5.7),Color("779e97"),1.0)
	# A grounded console supports the audit player, screen, reels and cables.
	var deck=Node3D.new();deck.name="AuditProjector";deck.position=Vector3(15.3,0.972,8.35);deck.rotation.y=PI;monitor.add_child(deck)
	G.box(deck,Vector3(0,0.15,0),Vector3(1.18,0.30,0.60),metal())
	for side in [-1,1]:
		var reel=Node3D.new();reel.position=Vector3(side*0.33,0.32,0);deck.add_child(reel);tape_reels.append(reel)
		var disc=G.cylinder(reel,Vector3.ZERO,0.25,0.035,metal("a7a28a"))
		for i in range(3):G.sphere(reel,Vector3(sin(i*TAU/3)*0.13,0.023,cos(i*TAU/3)*0.13),Vector3(0.10,0.008,0.10),G.material("plain",Color("22332e")))
		G.cylinder(reel,Vector3(0,0.028,0),0.045,0.02,metal())
	var playback=A.furniture(monitor,"computerScreen",Vector3(15.3,0.972,9.02),Vector3(1.1,0.85,0.30),PI,false,"AuditVideoScreen")
	for object in level.get_children():
		if object is KalaInteractable and object.action_id=="audit":object.position=Vector3(15.3,1.24,8.20);object.caption="Putar rekaman audit"
	# Cabinet is flush with the east wall, with conduit running into it.
	var terminal=Node3D.new();terminal.name="RitualTerminalCabinet";terminal.position=Vector3(9.69,1.5,2);terminal.rotation.y=-PI/2;add_child(terminal)
	G.box(terminal,Vector3.ZERO,Vector3(1.65,1.70,0.26),metal("3d504b"))
	G.box(terminal,Vector3(0,0.14,0.15),Vector3(1.30,0.78,0.04),G.material("plain",Color("0b211b")))
	label(terminal,"KARTINI / K-17\nARSIP LOKAL",Vector3(0,0.14,0.18),0.003,Color("6ca78a"))
	for i in range(8):G.box(terminal,Vector3(-0.48+i*0.14,-0.51,0.15),Vector3(0.07,0.016,0.018),metal("9b9a7b"))
	beam(terminal,Vector3(0,0.85,-0.04),Vector3(0,2.0,-0.04),0.045)
	for object in level.get_children():
		if object is KalaInteractable and object.action_id=="puzzle" and object.parameter=="breaker":object.position=Vector3(9.20,1.54,2);object.caption="Gunakan terminal K-17"
	# Replace unsupported decorative books in the office with shelved files.
	for z in [-5.0,0.0,5.0]:rack(self,Vector3(-8.9,0,z),2.4,PI/2,true)

func _pursuit() -> void:
	# Smooth, damp concrete replaces the old pixelated brick everywhere along
	# the route, while original floors, stairs, vents and collision stay aligned.
	var wall=ShaderMaterial.new();wall.shader=preload("res://assets/materials/service_wall.gdshader");wall.set_shader_parameter("paint",Color("283f40"));wall.set_shader_parameter("plaster",Color("5e655e"))
	var defs=JSON.parse_string(FileAccess.get_file_as_string("res://assets/source_presentation.json"))
	for record in defs.pursuit.walls:
		var mesh=level.find_child(record.name,true,false)
		if mesh!=null:mesh.material_override=wall
	# The safety perimeter also supplies visible wall faces in narrow service
	# passages; its old brick shader used to cover the retouched source walls.
	for mesh in level.get_node("MapBoundary").find_children("*","MeshInstance3D",true,false):mesh.material_override=wall
	for id in [3247,3248]:
		var mesh=level.find_child("Source_"+str(id),true,false)
		if mesh!=null:mesh.material_override=wall
	# Restore structural steel on baffles and all exposed brackets.
	for mesh in level.get_node("SourceWorld").find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var material=mesh.get_active_material(i)
			if material is BaseMaterial3D and material.albedo_texture!=null and material.albedo_texture.resource_path.ends_with("embedded_026.jpg"):
				mesh.set_surface_override_material(i,metal("52605a"))
	for z in range(-60,61,6):
		var bay=Node3D.new();bay.name="ServiceBay";bay.position.z=z;add_child(bay)
		for side in [-1,1]:
			G.box(bay,Vector3(side*11.76,2.6,0),Vector3(0.17,5.2,0.22),metal("3a504d"))
			G.box(bay,Vector3(side*11.72,0.14,0),Vector3(0.28,0.28,0.48),metal())
			for y in [0.25,4.7]:G.box(bay,Vector3(side*11.76,y,0.13),Vector3(0.24,0.12,0.04),metal("7d8270"))
			beam(bay,Vector3(side*11.65,4.3,0),Vector3(side*10.75,4.96,0),0.04)
		G.box(bay,Vector3(0,5.02,0),Vector3(23.6,0.18,0.22),metal("3a504d"))
		if z%12==0:
			lamp(bay,Vector3(0,4.94,0),Color("8ca89c"),1.1)
	for side in [-1,1]:
		for y in [3.65,4.12]:
			beam(self,Vector3(side*11.2,y,-64),Vector3(side*11.2,y,64),0.09)
			for z in range(-60,64,4):
				beam(self,Vector3(side*11.86,y+0.11,z),Vector3(side*11.1,y+0.11,z),0.018)
		for z in [-51,-25,1,27,53]:
			G.box(self,Vector3(side*11.69,1.48,z),Vector3(0.16,0.70,0.36),metal("785141"))
			var light=OmniLight3D.new();light.position=Vector3(side*11.35,1.52,z);light.light_color=Color("c57e47");light.light_energy=0.55;light.omni_range=4;add_child(light)
	# Bolt chase monitors to the wall instead of leaving screens suspended.
	for screen in level.get_node("FactoryRevision09").get_children():
		if not str(screen.name).begins_with("screen-hanging"):continue
		beam(self,screen.position+Vector3(-0.1,0.28,0),Vector3(-11.9,screen.position.y+0.28,screen.position.z),0.035)
		G.box(self,Vector3(-11.84,screen.position.y+0.28,screen.position.z),Vector3(0.08,0.32,0.38),metal())
	for sign_node in level.get_node("EnvironmentalDetail").find_children("*","Label3D",true,false):
		if not str(sign_node.text).begins_with("SEKTOR"):continue
		var side=signf(sign_node.position.x);sign_node.position.x=side*11.69
		G.box(self,Vector3(side*11.76,sign_node.position.y,sign_node.position.z),Vector3(0.08,0.68,2.6),metal("283e39"))
	# Existing ceiling ribs had two short floating ends; rebuild their supports.
	var art=level.get_node("FactoryArtDirection")
	for mesh in art.find_children("*","MeshInstance3D",true,false):
		var b: AABB=mesh.global_transform*mesh.get_aabb()
		if b.size.x>19 or (b.size.y>0.4 and b.size.y<0.6 and absf(b.get_center().x)>9):retire(mesh)
	for sign_root in art.get_children():
		if sign_root is Node3D and sign_root.find_children("*","Label3D",true,false).size()>0:
			var sign_bounds=A._bounds(sign_root)
			if sign_bounds.size.x>4:
				for x in [-2.1,2.1]:beam(sign_root,Vector3(x,0.42,0),Vector3(x,5.1-sign_root.position.y,0),0.013)
	# Entrance memo now rests on a small maintenance desk.
	bench(self,Vector3(1.2,0,55),1.4)
	# Every lower frame uses the authored floor, width and ceiling height,
	# including the two slopes. No hanging crossbar is positioned by guesswork.
	for passage in level.reference_data().chase_passages:
		var start=Vector3(passage.a[0],passage.a[1],passage.a[2]);var end=Vector3(passage.b[0],passage.b[1],passage.b[2])
		var length=Vector2(end.x-start.x,end.z-start.z).length()
		for i in range(maxi(1,int(length/4))):
			var t=(float(i)+0.5)/maxf(1,int(length/4))
			var bracket=Node3D.new();bracket.name="FittedVentFrame";bracket.position=start.lerp(end,t)
			bracket.rotation.y=atan2(end.x-start.x,end.z-start.z);add_child(bracket)
			var half=float(passage.width)/2-0.065;var height=float(passage.height)
			G.box(bracket,Vector3(0,height-0.055,0),Vector3(half*2+0.06,0.08,0.12),metal())
			for side in [-1,1]:
				G.box(bracket,Vector3(side*half,height/2,0),Vector3(0.07,height,0.12),metal())
				for y in [0.10,height-0.14]:G.box(bracket,Vector3(side*(half+0.02),y,0),Vector3(0.10,0.15,0.20),metal())
			if i%2==0:
				var p=Vector3(-half+0.06,height-0.24,0)
				G.box(bracket,p,Vector3(0.09,0.20,0.25),metal("8d8b6b"))
				var lamp_value=OmniLight3D.new();lamp_value.position=p+Vector3(0.15,0,0);lamp_value.light_color=Color("85a697");lamp_value.light_energy=0.75;lamp_value.omni_range=4;bracket.add_child(lamp_value)

func turn_valve(index: int) -> bool:
	if index<0 or index>=wheels.size() or time<valve_busy_until:return false
	valve_busy_until=time+0.48
	return true

func _process(delta: float) -> void:
	time+=delta
	if not wheels.is_empty():
		var values: Array=State.data.puzzles.valve.pos
		for i in range(wheels.size()):
			wheels[i].visible=i!=1 or State.data.installed.has("valveWheel")
			if int(values[i])!=int(last_values[i]):
				valve_angles[i]-=posmod(int(values[i])-int(last_values[i]),4)*PI/2
				last_values[i]=values[i]
			wheels[i].rotation.z=lerpf(wheels[i].rotation.z,valve_angles[i],1-exp(-delta*9.0))
			needles[i].rotation.z=lerp_angle(needles[i].rotation.z,-int(values[i])*PI/2,1-exp(-delta*4.5))
	for reel in tape_reels:
		var player=get_tree().get_first_node_in_group("kala_player")
		if State.data.installed.has("tapeReel") and player!=null and player.get_parent().ui.mode=="archive_video":reel.rotation.y+=delta*1.6
