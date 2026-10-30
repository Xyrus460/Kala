extends Node3D
func _ready() -> void:
	var camera = Camera3D.new(); camera.position = Vector3(0,0,3); add_child(camera)
	var name_value = "nightstand" if OS.get_cmdline_user_args().has("--nightstand") else "cartridge_fuse"
	var scene = load("res://assets/vendor/revision10/%s.glb" % name_value)
	var model = scene.instantiate(); add_child(model)
	await get_tree().create_timer(0.2).timeout
	model.queue_free(); scene = null
	await get_tree().process_frame; await get_tree().process_frame
	await get_tree().create_timer(0.2).timeout
	print("TEXTURE PROBE DONE ",name_value)
	get_tree().quit()
