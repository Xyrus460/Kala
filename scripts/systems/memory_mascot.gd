extends Node3D
## The project's existing CC0 bunny, dressed for the Gema Arsip chamber.
const A = preload("res://scripts/systems/free_assets.gd")
const G = preload("res://scripts/systems/geometry.gd")
var animator: AnimationPlayer

func _ready() -> void:
	var rig = A.place(self, "res://assets/vendor/revision13/pengawas.glb", Vector3.ZERO, Vector3(-1, 3.05, -1), 0, false, "ArchiveBunnyRig")
	rig.scale = Vector3(0.85, 1, 0.85)
	var skeleton = rig.find_child("Skeleton3D", true, false) as Skeleton3D
	animator = rig.find_child("AnimationPlayer", true, false)
	for mesh in rig.find_children("*", "MeshInstance3D", true, false):
		if "Carrot" in str(mesh.name): mesh.hide(); continue
		var adapted = ArrayMesh.new()
		for surface in range(mesh.mesh.get_surface_count()):
			var source = mesh.get_active_material(surface)
			var mat = source.duplicate() as StandardMaterial3D
			var id = str(source.resource_name)
			if id in ["Eye_White", "Eye_Black"]: continue
			mat.albedo_color = Color("ced7ce") if id == "Bunny_Main" else Color("d784a7") if id == "Bunny_Secondary" else Color("ced7ce")
			mat.roughness = 0.9; mat.metallic = 0
			var arrays = mesh.mesh.surface_get_arrays(surface)
			if id == "Bunny_Secondary":
				var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
				var kept = PackedInt32Array()
				for triangle in range(0, indices.size(), 3):
					var p = (vertices[indices[triangle]] + vertices[indices[triangle + 1]] + vertices[indices[triangle + 2]]) / 3
					if p.y < -0.0055 and p.z > 0.022 and p.z < 0.030 and absf(p.x) < 0.004: continue
					for corner in range(3): kept.append(indices[triangle + corner])
				arrays[Mesh.ARRAY_INDEX] = kept
			adapted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
			adapted.surface_set_material(adapted.get_surface_count() - 1, mat)
		mesh.mesh = adapted
	# Bone attachments keep the vest and turquoise crest on the animated rig.
	var basis_transform = Transform3D.IDENTITY
	var parent: Node3D = skeleton
	while parent != self: basis_transform = parent.transform * basis_transform; parent = parent.get_parent()
	var turquoise = G.material("plain", Color("54c9c7"))
	var cloth = G.material("plain", Color("253139"))
	var chest_pose = basis_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Neck"))
	var vest = BoneAttachment3D.new(); vest.name = "TurquoiseVest"; vest.bone_name = "Neck"; skeleton.add_child(vest)
	var detail = Node3D.new(); vest.add_child(detail); detail.transform = chest_pose.affine_inverse()
	var c = chest_pose.origin
	G.sphere(detail, c + Vector3(0, -0.57, 0.03), Vector3(0.79, 1.08, 0.55), turquoise)
	for side in [-1, 1]:
		G.box(detail, c + Vector3(side * 0.25, -0.43, 0.27), Vector3(0.27, 0.86, 0.07), cloth).rotation.z = side * 0.10
		G.sphere(detail, c + Vector3(side * 0.46, -0.19, 0.01), Vector3(0.31, 0.35, 0.42), cloth)
	var head_pose = basis_transform * skeleton.get_bone_global_pose(skeleton.find_bone("Head"))
	var crest = BoneAttachment3D.new(); crest.name = "TurquoiseCrest"; crest.bone_name = "Head"; skeleton.add_child(crest)
	var hair = Node3D.new(); crest.add_child(hair); hair.transform = head_pose.affine_inverse()
	var center = head_pose.origin
	for i in range(3):
		var tuft = G.sphere(hair, center + Vector3(-0.10 + i * 0.10, 0.55 + i * 0.07, 0.14), Vector3(0.20, 0.39, 0.22), turquoise)
		tuft.rotation.z = -0.35 + i * 0.20
	var white = G.material("plain", Color("d4ddd3")); var black = G.material("plain", Color("101e24"))
	for side in [-1, 1]:
		G.sphere(hair, center + Vector3(side * 0.195, 0.30, 0.365), Vector3(0.31, 0.35, 0.16), white)
		G.sphere(hair, center + Vector3(side * 0.195, 0.29, 0.449), Vector3(0.17, 0.22, 0.055), black)
	G.sphere(hair, center + Vector3(0, 0.08, 0.40), Vector3(0.54, 0.23, 0.16), white)
	G.sphere(hair, center + Vector3(0, 0.08, 0.48), Vector3(0.32, 0.023, 0.033), black)
	G.sphere(hair, center + Vector3(0, 0.19, 0.475), Vector3(0.14, 0.10, 0.08), G.material("plain", Color("cf8da8")))
	for key in animator.get_animation_list(): animator.get_animation(key).loop_mode = Animation.LOOP_LINEAR
	animate(false)

func animate(walking: bool) -> void:
	if animator == null: return
	var suffix = "|Walk" if walking else "|Idle"
	for key in animator.get_animation_list():
		if str(key).ends_with(suffix) and animator.current_animation != key: animator.play(key, 0.25); return
