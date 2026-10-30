extends SceneTree
func _initialize() -> void:
	call_deferred("inspect")
func inspect() -> void:
	for id in ["loading","relay","production","office","ritual","corridor","daisy"]:
		var model=load("res://assets/models/source/%s.glb"%id).instantiate(); root.add_child(model)
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			var b: AABB=mesh.global_transform*mesh.get_aabb()
			if b.size.x>3 and b.size.z>3 and b.size.y<1 and b.position.y<0.5:
				print(id," FLOOR ",mesh.name," ",b)
		model.free()
	quit()
