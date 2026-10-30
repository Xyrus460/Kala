extends RefCounted
const G = preload("res://scripts/systems/geometry.gd")
const A = preload("res://scripts/systems/free_assets.gd")
const HEIGHT = 3.4
const WEST = [[-30,-24,"TANGGA"],[-24,-16,"LAB IPA"],[-16,-6,"UKS"],[-6,6,"STUDIO SENI"],[6,14,"XI A"],[14,24,"RUANG GURU"],[24,30,"OSIS"]]
const EAST = [[-30,-18,"RUANG MULTIMEDIA"],[-18,-10,"LAB KOMPUTER"],[-10,0,"ARSIP / BK"],[0,9,"KANTIN"],[9,17,"PERPUSTAKAAN"],[17,30,"AULA"]]
var level: Node3D
var root: Node3D
var plaster: Material
var green: Material
var floor_mat: Material

func box(p: Vector3, size: Vector3, mat: Material, solid = true) -> MeshInstance3D:
	return G.box(root, p, size, mat, solid)

func build(owner_level: Node3D) -> void:
	level = owner_level; root = Node3D.new(); root.name = "ExplorableSchool"; level.add_child(root)
	plaster = G.material("plain", Color("d2d7cb")); green = G.material("plain", Color("51796a"))
	floor_mat = G.material("plain", Color("9aa99e"))
	# Replace architectural blockout as a unit, keeping story furniture/actors.
	for mesh in level.get_node("SourceWorld").find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mesh.global_transform * mesh.get_aabb()
		var architectural = (b.size.y > 1.8 and minf(b.size.x,b.size.z) < 0.65 and maxf(b.size.x,b.size.z) > 1.0)
		architectural = architectural or (b.size.y < 0.5 and b.size.x > 3 and b.size.z > 3)
		architectural = architectural or (b.position.y > 2.9 and maxf(b.size.x,b.size.z) > 3)
		# Retire old windows/frames at the obsolete exterior wall positions and
		# their ceiling fixtures. Blackboard and desk monitors remain in place.
		architectural = architectural or (b.position.y > 2.6 and maxf(b.size.x,b.size.z) > 0.2)
		var obsolete_window = b.size.y > 0.7 and b.position.y > 0.75 and minf(b.size.x,b.size.z) < 0.2 and absf(b.get_center().x)>11.5
		architectural = architectural or obsolete_window
		if obsolete_window:
			var assembly=mesh.get_parent()
			if assembly is Node3D and not assembly is MeshInstance3D and assembly.get_child_count() in range(2,11):
				assembly.hide()
				for body in assembly.find_children("*","StaticBody3D",true,false): body.collision_layer=0
		# Remove obsolete corridor furniture and jambs from the new openings.
		for side in [-1,1]:
			for r in (WEST if side<0 else EAST):
				var doorway = AABB(Vector3(-3.7 if side<0 else 0.7,0,(r[0]+r[1])*0.5-0.7),Vector3(3.0,2.5,1.4))
				if b.size.y>0.04 and b.end.y<2.9 and b.size.x<3 and b.size.z<4 and doorway.intersects(b): architectural=true
		if architectural:
			mesh.hide()
			for body in mesh.find_children("*", "StaticBody3D", true, false): body.collision_layer = 0
	for child in level.get_node("MapBoundary").get_children():
		if child is MeshInstance3D: child.hide()
		if child is CollisionShape3D: child.disabled = true
	box(Vector3(0,-0.17,-0.6), Vector3(28.4,0.34,61.2), G.material("concrete",Color("7b847a"))).name = "GroundedSchoolFoundation"
	for storey in range(3):
		var y = HEIGHT * storey
		_floor(storey)
		for side in [-1,1]:
			# Repeating solid piers and recessed glass, with no overlapping facade.
			for z in range(-28,30,4): _window_wall(Vector3(side*14.0,y,z), PI/2)
			for x in [4,8,12]: _window_wall(Vector3(side*x,y,-30.6),0)
			box(Vector3(side*14,y+1.58,-30.3),Vector3(0.18,3.16,0.6),plaster)
			# Exterior colour band occurs only once on each storey.
			box(Vector3(side*14,y+3.18,-0.3),Vector3(0.23,0.18,60.6),green)
			# Room partitions, doors and signs share one coordinate definition.
			var rooms = WEST if side < 0 else EAST
			for idx in range(rooms.size()):
				var r: Array = rooms[idx]; var z0 = float(r[0]); var z1 = float(r[1]); var middle = (z0+z1)*0.5
				var title = str(r[2]) if storey == 0 else ("TANGGA" if side < 0 and idx == 0 else ["KELAS XII", "RUANG BACA", "KLUB SAINS", "RUANG MUSIK", "RUANG DISKUSI", "KELAS X", "RUANG STUDI"][idx] + " · " + str(storey+1))
				_partition(side,y,z0,z1,middle,title)
				if z0 > -30: box(Vector3(side*8,y+1.58,z0),Vector3(12,3.16,0.16),plaster)
				if title == "TANGGA": continue
				var preserve = storey == 0 and ((side < 0 and idx in [1,4]) or (side > 0 and idx in [1,4]))
				if not preserve: _furnish(side,y,middle,title,idx)
				_lamp(Vector3(side*8,y+3.08,middle))
		# End wall and entrance opening, then corridor practicals.
		box(Vector3(0,y+1.58,30),Vector3(28.2,3.16,0.18),plaster)
		if storey > 0: box(Vector3(0,y+1.58,-30.6),Vector3(4,3.16,0.18),plaster)
		else:
			for side in [-1,1]: box(Vector3(side*1.76,1.58,-30.6),Vector3(0.48,3.16,0.18),plaster)
			box(Vector3(0,2.94,-30.6),Vector3(3.1,0.44,0.18),plaster)
		for z in range(-27,30,9): _lamp(Vector3(0,y+3.08,z))
		if storey < 2: _stairs(storey)
		var caption = G.sign_text(root,"LANTAI %d   /   TANGGA ←" % (storey+1),Vector3(0,y+2.4,-24.1),20)
		caption.modulate = Color("344f43")
	box(Vector3(0,10.16,-0.3),Vector3(28.4,0.24,60.6),plaster).name = "SchoolRoof"
	preload("res://scripts/systems/school_puzzles.gd").new().build(level)

func _floor(storey: int) -> void:
	var y = HEIGHT*storey - 0.11
	if storey == 0:
		box(Vector3(0,y,-0.3),Vector3(28,0.22,60.6),floor_mat); return
	# One stairwell opening per floor. The top landing has 1.8 m clearance.
	box(Vector3(0,y,1.9),Vector3(28,0.22,56.2),floor_mat)
	box(Vector3(0,y,-29.5),Vector3(28,0.22,2.2),floor_mat)
	box(Vector3(-12.4,y,-27.3),Vector3(3.2,0.22,2.2),floor_mat)
	box(Vector3(5.5,y,-27.3),Vector3(17,0.22,2.2),floor_mat)

func _stairs(storey: int) -> void:
	var y = HEIGHT*storey
	for i in range(24):
		var h = (i+1)*HEIGHT/24
		# A thin structural tread preserves headroom under the next flight.
		box(Vector3(-3.0-(i+0.5)*0.325,y+h-0.09,-27.3),Vector3(0.325,0.18,2.08),floor_mat).name = "CampusStep_%d_%d" % [storey,i]
		for side in [-1,1]:
			if i % 2 == 0: box(Vector3(-3.0-(i+0.5)*0.325,y+h+0.49,-27.3+side*0.98),Vector3(0.045,0.98,0.045),green,false)
	for side in [-1,1]:
		var rail = box(Vector3(-6.9,y+2.76,-27.3+side*0.98),Vector3(Vector2(7.8,3.4).length(),0.08,0.08),green,true)
		rail.rotation.z = -atan2(3.4,7.8)
		# Guard on upper floor edge: long sides except the stair's exit/entry.
		box(Vector3(-6.9,y+HEIGHT+0.55,-27.3+side*1.13),Vector3(7.8,1.1,0.07),green,true).visible = false
		box(Vector3(-6.9,y+HEIGHT+1.06,-27.3+side*1.13),Vector3(7.8,0.08,0.08),green,false)
		for x in [-10.7,-9.4,-8.1,-6.8,-5.5,-4.2,-3.1]: box(Vector3(x,y+HEIGHT+0.52,-27.3+side*1.13),Vector3(0.05,1.04,0.05),green,false)
	box(Vector3(-11.7,y+HEIGHT-0.11,-27.3),Vector3(1.8,0.22,2.2),floor_mat)

func _partition(side: int, y: float, z0: float, z1: float, door_z: float, title: String) -> void:
	for end in [Vector2(z0,door_z-0.9),Vector2(door_z+0.9,z1)]:
		box(Vector3(side*2,y+1.58,(end.x+end.y)/2),Vector3(0.16,3.16,end.y-end.x),plaster)
	box(Vector3(side*2,y+2.78,door_z),Vector3(0.16,0.76,1.8),plaster)
	for z in [door_z-0.92,door_z+0.92]: box(Vector3(side*2,y+1.2,z),Vector3(0.23,2.4,0.07),green)
	var label = G.sign_text(root,title,Vector3(side*1.89,y+2.60,door_z),18,-side*PI/2)
	label.modulate = Color("30483d"); label.outline_size = 0; label.pixel_size = 0.0045

func _window_wall(p: Vector3, yaw: float) -> void:
	var wall = Node3D.new(); root.add_child(wall); wall.position=p; wall.rotation.y=yaw
	G.box(wall,Vector3(0,0.48,0),Vector3(4,0.96,0.18),plaster,true)
	G.box(wall,Vector3(0,2.96,0),Vector3(4,0.4,0.18),plaster,true)
	for x in [-1.83,1.83]: G.box(wall,Vector3(x,1.84,0),Vector3(0.34,1.8,0.18),plaster,true)
	var glass = G.material("plain",Color("6d9396")).duplicate(); glass.roughness=0.22; glass.metallic=0.25
	G.box(wall,Vector3(0,1.84,0),Vector3(3.32,1.8,0.055),glass,true)
	for x in [-1.67,0,1.67]: G.box(wall,Vector3(x,1.84,0.02),Vector3(0.045,1.84,0.10),green)
	G.box(wall,Vector3(0,2.2,0.02),Vector3(3.4,0.045,0.1),green)

func _furnish(side: int, y: float, z: float, title: String, index: int) -> void:
	if "UKS" in title:
		for dx in [5,10]: A.furniture(root,"bedSingle",Vector3(side*dx,y,z),Vector3(1.3,0.75,2.1),0)
	elif "ARSIP" in title or "BACA" in title:
		for dz in [-2,0,2]: A.furniture(root,"bookcaseOpen",Vector3(side*12.7,y,z+dz),Vector3(1.7,2.15,0.5),side*PI/2)
	elif "AULA" in title:
		box(Vector3(side*9,y+0.13,z-3),Vector3(8,0.26,3),green)
		for dz in [0,2,4]: A.furniture(root,"bench",Vector3(side*8,y,z+dz),Vector3(6,0.82,0.6),0)
	else:
		for dx in [5,9]:
			A.furniture(root,"desk",Vector3(side*dx,y,z),Vector3(1.7,0.8,0.7),0)
			A.furniture(root,"chair",Vector3(side*dx,y,z+0.85),Vector3(0.48,0.9,0.48),PI,false)
			if "KOMPUTER" in title: A.furniture(root,"computerScreen",Vector3(side*dx,y+0.8,z),Vector3(0.6,0.4,0.2),0,false)
		A.furniture(root,"bookcaseOpen",Vector3(side*12.8,y,z-2),Vector3(1.7,2.0,0.4),side*PI/2)
	if index % 2 == 0: A.furniture(root,"pottedPlant",Vector3(side*3.3,y,z-2),Vector3(-1,1.1,-1),0,false)

func _lamp(p: Vector3) -> void:
	var mat = G.material("plain",Color("e5ead6")).duplicate(); mat.emission_enabled=true; mat.emission=Color("c8ddc9"); mat.emission_energy_multiplier=1.1
	box(p,Vector3(0.65,0.06,0.4),mat,false)
	var light = OmniLight3D.new(); light.position=p-Vector3.UP*0.2; light.light_color=Color("dce8d6"); light.light_energy=0.7; light.omni_range=8; root.add_child(light)
