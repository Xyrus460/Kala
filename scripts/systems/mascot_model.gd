extends Node3D
## CC0 Quaternius Bunny, adapted as the factory's Reka / Pengawas mascot.
const A=preload("res://scripts/systems/free_assets.gd")
const G=preload("res://scripts/systems/geometry.gd")
var skeleton: Skeleton3D
var animator: AnimationPlayer
var walking=false
var moving_left=0.0

static func create() -> Node3D:
	var model=load("res://scripts/systems/mascot_model.gd").new()
	model.name="RekaPengawas";model.build();return model

func build() -> void:
	set_meta("asset_source","res://assets/vendor/revision13/pengawas.glb")
	var model=A.place(self,"res://assets/vendor/revision13/pengawas.glb",Vector3.ZERO,Vector3(-1,3.25,-1),0,false,"RiggedMascot")
	model.scale=Vector3(0.78,1,0.79)
	skeleton=model.find_child("Skeleton3D",true,false)
	animator=model.find_child("AnimationPlayer",true,false)
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		if "Carrot" in str(mesh.name):mesh.hide();continue
		var adapted=ArrayMesh.new()
		for i in range(mesh.mesh.get_surface_count()):
			var arrays=mesh.mesh.surface_get_arrays(i)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var colors=PackedColorArray();colors.resize(vertices.size());colors.fill(Color.WHITE)
			var source=mesh.get_active_material(i)
			var title=str(source.resource_name)
			if title in ["Eye_White","Eye_Black"]:continue
			var mat=source.duplicate() as StandardMaterial3D
			mat.roughness=0.93;mat.metallic=0
			if title=="Bunny_Main":
				mat.albedo_color=Color.WHITE;mat.vertex_color_use_as_albedo=true
				for v in range(vertices.size()):
					var p=vertices[v]
					colors[v]=Color("c49d50") if absf(p.x)>0.0173 or p.z<0.0042 else Color("347f8d")
			elif title=="Bunny_Secondary":
				mat.albedo_color=Color("c5b18a")
				# Remove the source rabbit's small pink nose and downturned mouth;
				# the mascot's broad muzzle and black nose follow the head instead.
				var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
				var kept=PackedInt32Array()
				for triangle in range(0,indices.size(),3):
					var p=(vertices[indices[triangle]]+vertices[indices[triangle+1]]+vertices[indices[triangle+2]])/3
					if p.y< -0.0055 and p.z>0.022 and p.z<0.030 and absf(p.x)<0.004:continue
					for corner in range(3):kept.append(indices[triangle+corner])
				arrays[Mesh.ARRAY_INDEX]=kept
			elif title=="Eye_White":mat.albedo_color=Color("e3e3cc")
			elif title=="Eye_Black":mat.albedo_color=Color("101b22")
			arrays[Mesh.ARRAY_COLOR]=colors
			adapted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			adapted.surface_set_material(adapted.get_surface_count()-1,mat)
		mesh.mesh=adapted
	for key in animator.get_animation_list():
		if str(key).ends_with("|Idle") or str(key).ends_with("|Walk"):animator.get_animation(key).loop_mode=Animation.LOOP_LINEAR
	_play("Idle")
	# A cloth scarf is attached to the animated chest in character coordinates.
	var scarf=BoneAttachment3D.new();scarf.name="RekaScarf";scarf.bone_name="Neck";skeleton.add_child(scarf)
	var local=Node3D.new();scarf.add_child(local)
	var bone=skeleton.find_bone("Neck")
	var transform_value=Transform3D.IDENTITY
	var parent: Node3D=skeleton
	while parent!=self:transform_value=parent.transform*transform_value;parent=parent.get_parent()
	local.transform=(transform_value*skeleton.get_bone_global_pose(bone)).affine_inverse()
	var neck=(transform_value*skeleton.get_bone_global_pose(bone)).origin
	var cloth=G.material("plain",Color("a94430"))
	G.box(local,Vector3(0,neck.y,neck.z+0.03),Vector3(0.68,0.15,0.55),cloth)
	var tail=G.box(local,Vector3(0.16,neck.y-0.26,neck.z+0.20),Vector3(0.16,0.49,0.045),cloth);tail.rotation.z=-0.12
	var face=BoneAttachment3D.new();face.name="RekaFace";face.bone_name="Head";skeleton.add_child(face)
	var detail=Node3D.new();face.add_child(detail)
	var head_transform=transform_value*skeleton.get_bone_global_pose(skeleton.find_bone("Head"))
	detail.transform=head_transform.affine_inverse()
	var center=head_transform.origin
	for side in [-1,1]:
		G.sphere(detail,center+Vector3(side*0.205,0.32,0.375),Vector3(0.31,0.34,0.16),G.material("plain",Color("e7e4ce")))
		G.sphere(detail,center+Vector3(side*0.205,0.32,0.455),Vector3(0.145,0.20,0.045),G.material("plain",Color("0d1c25")))
	G.sphere(detail,center+Vector3(0,0.10,0.40),Vector3(0.53,0.22,0.12),G.material("plain",Color("c7ad7d")))
	G.sphere(detail,center+Vector3(0,0.08,0.46),Vector3(0.34,0.027,0.035),G.material("plain",Color("182a2b")))
	G.sphere(detail,center+Vector3(0,0.20,0.46),Vector3(0.10,0.065,0.06),G.material("plain",Color("182a2b")))

func _play(suffix: String) -> void:
	for key in animator.get_animation_list():
		if str(key).ends_with("|"+suffix):
			if animator.current_animation!=key:animator.play(key,0.25)
			return

func animate_walk(_time: float,strength=0.5) -> void:
	walking=strength>0.01;moving_left=0.15
	_play("Walk" if walking else "Idle")

func _process(delta: float) -> void:
	moving_left=maxf(0,moving_left-delta)
	if moving_left<=0 and walking:walking=false;_play("Idle")
