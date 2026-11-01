extends Node3D
const A=preload("res://scripts/systems/free_assets.gd")
const G=preload("res://scripts/systems/geometry.gd")
const ASSETS="res://assets/vendor/revision13/"
static var uniform_materials: Dictionary = {}
var torso: Node3D
var skeleton: Skeleton3D
var animator: AnimationPlayer
var seated=false
var walking=0.0
var reach_amount=0.0
var identity=""
var height=1.76
var female=false
var model_root: Node3D
var conversation_target: Node3D

static func create(who: String) -> Node3D:
	var rig=load("res://scripts/systems/student_model.gd").new();rig.name=who;rig.identity=who
	rig.build();return rig

func build() -> void:
	set_meta("identity",identity)
	female=identity in ["Sari","Ratna","Nadia","Intan"]
	height={"Danu":1.79,"Raka":1.73,"Adit":1.68,"Sari":1.64,"Ratna":1.70,"Bima":1.81,"Fajar":1.70,"Nadia":1.61,"Intan":1.67}.get(identity,1.74)
	torso=Node3D.new();torso.name="TorsoRig";add_child(torso)
	var source=ASSETS+"woman_skirt.glb" if female else "res://assets/vendor/revision12/casual.glb"
	var model=A.place(torso,source,Vector3.ZERO,Vector3(-1,height,-1),0,false,"TeacherOutfit" if identity=="Ratna" else "Student")
	model_root=model
	model.scale.x={"Danu":1.06,"Raka":0.95,"Adit":0.91,"Bima":1.08,"Fajar":0.97}.get(identity,1.0)
	skeleton=model.find_child("Skeleton3D",true,false)
	animator=model.find_child("AnimationPlayer",true,false)
	if female:
		_replace_part("Body",ASSETS+("female_suit.glb" if identity=="Ratna" else "woman_blouse.glb"))
		if identity in ["Sari","Nadia","Intan"]:_replace_part("Head",ASSETS+"woman_blouse.glb")
	else:
		var head_source=ASSETS+("male_business.glb" if identity in ["Danu","Bima"] else "male_hoodie.glb")
		if identity!="Raka":_replace_part("Head",head_source)
	set_meta("head_source",ASSETS+("woman_skirt.glb" if identity=="Ratna" else "woman_blouse.glb") if female else source if identity=="Raka" else ASSETS+("male_business.glb" if identity in ["Danu","Bima"] else "male_hoodie.glb"))
	set_meta("outfit_source",ASSETS+"female_suit.glb" if identity=="Ratna" else source)
	var skin=Color({"Danu":"b3896d","Raka":"c49b7d","Adit":"9b7256","Sari":"bf9677","Ratna":"b18b70","Bima":"a07859","Fajar":"c09c80","Nadia":"ad815f","Intan":"c7a58a"}.get(identity,"ba9373"))
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var original=mesh.get_active_material(i)
			if not original is StandardMaterial3D: continue
			var key=identity+"/"+str(mesh.name)+"/"+str(i)
			if uniform_materials.has(key):
				mesh.set_surface_override_material(i,uniform_materials[key])
				continue
			var mat=original.duplicate();mat.roughness=0.88;mat.metallic=0
			var material_name=str(original.resource_name)
			if material_name=="Skin":mat.albedo_color=skin
			elif "Hair" in material_name or material_name in ["Red","Eyebrows"] and "Head" in str(mesh.name):mat.albedo_color=Color("28201b" if identity in ["Ratna","Danu"] else "191b20")
			elif "Body" in str(mesh.name) and material_name not in ["Brown","Gold"]:mat.albedo_color=Color("ab9572" if identity=="Ratna" else "e1e0d8")
			elif "Legs" in str(mesh.name):mat.albedo_color=skin if material_name=="Skin" else Color("655944" if identity=="Ratna" else "586779")
			elif "Feet" in str(mesh.name) and material_name!="Skin":mat.albedo_color=Color("27282b")
			elif material_name=="Brown":mat.albedo_color=Color("43352b")
			uniform_materials[key]=mat
			mesh.set_surface_override_material(i,mat)
	if animator!=null:
		for key in animator.get_animation_list():
			if "Idle" in key or "Walk" in key: animator.get_animation(key).loop_mode=Animation.LOOP_LINEAR
		_play("Idle")
	# Uniform collars and name badges follow the chest bone, including seated poses.
	var badge=BoneAttachment3D.new();badge.name="UniformDetails";badge.bone_name="Chest" if skeleton.find_bone("Chest")>=0 else "Spine";skeleton.add_child(badge)
	var rig=_rig_transform()
	var bone=rig*skeleton.get_bone_global_pose(skeleton.find_bone(badge.bone_name))
	var details=Node3D.new();badge.add_child(details);details.transform=bone.affine_inverse()
	var y=height*0.71
	G.box(details,Vector3(0.075,y,0.125),Vector3(0.08,0.026,0.009),G.material("plain",Color("242b31"))).name="TeacherNameBadge" if identity=="Ratna" else "SchoolBadge"
	if identity!="Ratna":
		for side in [-1,1]:
			var collar=G.box(details,Vector3(side*0.05,height*0.78,0.13),Vector3(0.085,0.10,0.018),G.material("plain",Color("eeeee7")));collar.rotation.z=side*0.32

func _replace_part(part: String,path: String) -> void:
	# Modular CC assets share the named humanoid rest rig. Rebind the imported
	# garment/head to the live skeleton; a second independently animated rig drifts.
	var donor=load(path).instantiate() as Node3D
	var donor_skeleton=donor.find_child("Skeleton3D",true,false) as Skeleton3D
	for old in model_root.find_children("*","MeshInstance3D",true,false):
		if part in str(old.name) or (part=="Head" and "Formad" in str(old.name)):old.hide()
	for original in donor.find_children("*","MeshInstance3D",true,false):
		if part not in str(original.name):continue
		var mesh=original.duplicate() as MeshInstance3D
		skeleton.add_child(mesh);mesh.skeleton=NodePath("..");mesh.name=identity+part
		var skin=original.skin.duplicate() as Skin
		for i in range(skin.get_bind_count()):
			var bone_name=skin.get_bind_name(i)
			if bone_name=="":bone_name=donor_skeleton.get_bone_name(skin.get_bind_bone(i))
			skin.set_bind_name(i,bone_name)
		mesh.skin=skin
	donor.free()

func _play(suffix: String) -> void:
	if animator==null:return
	for key in animator.get_animation_list():
		if (str(key).ends_with("|"+suffix) or str(key).ends_with("_"+suffix)) and animator.current_animation!=key: animator.play(key,0.24);return

func sit() -> void:
	if seated:return
	seated=true
	if animator!=null:
		_play("Idle");animator.advance(0);animator.pause()
	torso.position.y=-0.38*height/1.76
	for s in ["L","R"]:
		# Imported bones use their own local axes (and independent foot bones).
		# Solve in character coordinates instead of copying primitive rig Euler angles.
		align_bone("UpperLeg."+s,Vector3.BACK)
		align_bone("LowerLeg."+s,Vector3.DOWN)
		var knee=_rig_transform()*skeleton.get_bone_global_pose(skeleton.find_bone("LowerLeg."+s))
		move_bone("Foot."+s,Vector3(knee.origin.x,0.025,knee.origin.z))
		align_bone("Foot."+s,Vector3.BACK)
		align_bone("UpperArm."+s,Vector3(0,-1,0.1))
		align_bone("LowerArm."+s,Vector3(0,0.12,1))

func _rig_transform() -> Transform3D:
	var result=Transform3D.IDENTITY
	var n: Node3D=skeleton
	while n!=self:
		result=n.transform*result;n=n.get_parent()
	return result

func align_bone(bone: String,direction: Vector3) -> void:
	var i=skeleton.find_bone(bone)
	if i<0:return
	var rig=_rig_transform()
	var current=rig*skeleton.get_bone_global_pose(i)
	var turn=Quaternion(current.basis.y.normalized(),direction.normalized())
	var desired=rig.basis.orthonormalized().inverse()*Basis(turn)*current.basis.orthonormalized()
	var parent=skeleton.get_bone_parent(i)
	if parent>=0:desired=skeleton.get_bone_global_pose(parent).basis.orthonormalized().inverse()*desired
	skeleton.set_bone_pose_rotation(i,desired.orthonormalized().get_rotation_quaternion())

func move_bone(bone: String,point: Vector3) -> void:
	var i=skeleton.find_bone(bone)
	if i<0:return
	var target=_rig_transform().affine_inverse()*point
	var parent=skeleton.get_bone_parent(i)
	if parent>=0:target=skeleton.get_bone_global_pose(parent).affine_inverse()*target
	skeleton.set_bone_pose_position(i,target)

func stand() -> void:
	if not seated:return
	seated=false;torso.position.y=0
	if skeleton!=null:skeleton.reset_bone_poses()
	_play("Idle")

func animate_walk(_time: float,strength=0.55) -> void:
	if seated:return
	walking=0.15 if strength>0.01 else 0.0
	_play("Walk" if walking>0 else "Idle")

func reach(amount: float) -> void: reach_amount=amount

func _process(delta: float) -> void:
	if seated:return
	if is_instance_valid(conversation_target):
		var toward = conversation_target.global_position - global_position
		if Vector2(toward.x, toward.z).length_squared() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(toward.x, toward.z), 1.0 - exp(-delta * 7.0))
	walking=maxf(0,walking-delta)
	if walking<=0:_play("Idle")
	if reach_amount>0.001:
		align_bone("UpperArm.R",Vector3(0,-1,0).lerp(Vector3(0,-0.25,1),reach_amount))
		align_bone("LowerArm.R",Vector3(0,-1,0).lerp(Vector3(0,0.15,1),reach_amount))
