extends SceneTree
func _initialize() -> void: call_deferred("inspect")
func inspect() -> void:
 var model=load("res://assets/models/source/school.glb").instantiate(); root.add_child(model)
 for mesh in model.find_children("*","MeshInstance3D",true,false):
  var b: AABB=mesh.global_transform*mesh.get_aabb()
  if b.size.length()<4 and ((b.get_center().x>9 and b.get_center().z>11 and b.get_center().z<16) or (b.get_center().x>-9 and b.get_center().x<-3 and b.get_center().z>-22 and b.get_center().z<-18)):
   print(mesh.get_path()," ",b)
 model.free(); quit()
