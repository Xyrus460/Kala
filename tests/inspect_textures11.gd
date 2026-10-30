extends Node
var game: Node3D
var seen={}
func _ready() -> void:
 State.save_enabled=false; State.reset()
 game=preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
 await get_tree().process_frame; game.test_mode=true; game.playing=true; game.ui.close_panel()
 await game.enter_room("home",false,false)
 await get_tree().create_timer(0.5).timeout
 for mesh in game.find_children("*","MeshInstance3D",true,false):
  if mesh.mesh==null: continue
  for i in range(mesh.mesh.get_surface_count()):
   var mat=mesh.get_active_material(i)
   if mat==null: continue
   for prop in mat.get_property_list():
    var v=mat.get(prop.name)
    if v is Texture2D and not seen.has(v.get_rid()):
     seen[v.get_rid()]=true
     print("TEX ",RenderingServer.texture_get_native_handle(v.get_rid())," ",v.get_width(),"x",v.get_height()," ",v.resource_path," ",mesh.get_path()," ",prop.name)
 await game.enter_room("school",false,false)
 await get_tree().create_timer(0.5).timeout
 await game.quit_game()
