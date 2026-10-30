extends Node3D
const A = preload("res://scripts/systems/free_assets.gd")
var leaves: Array[Node3D] = []
var opened = true
var interaction: KalaInteractable

func _ready() -> void:
	name = "OperableEntranceDoors"
	opened = bool(State.data.flags.get("campusDoorsOpen", true))
	for side in [-1, 1]:
		var hinge = Node3D.new(); hinge.name = "LeftHinge" if side < 0 else "RightHinge"
		hinge.position.x = side * 1.16; add_child(hinge)
		var leaf = A.place(hinge, "res://assets/vendor/kenney_building/door-rotate-square-c.glb", Vector3(-side * 0.56, 0, 0), Vector3(1.12, 2.48, 0.11), 0, true, "DoorLeaf", PI / 2)
		for mesh in leaf.find_children("*", "MeshInstance3D", true, false):
			var material = StandardMaterial3D.new(); material.albedo_color = Color("768b80") if mesh.name != "handle" else Color("b0b5b2")
			material.metallic = 0.12 if mesh.name != "handle" else 0.8; material.roughness = 0.58
			mesh.material_override = material
		hinge.set_meta("side", side); hinge.rotation.y = side * PI * 0.49 if opened else 0.0; leaves.append(hinge)
	interaction = KalaInteractable.new(); interaction.name = "EntranceHandle"; interaction.action_id = "campus_door"
	interaction.position = Vector3(0, 1.25, 0.14)
	var shape = CollisionShape3D.new(); var box = BoxShape3D.new(); box.size = Vector3(2.6, 2.5, 0.42); shape.shape = box
	interaction.add_child(shape); add_child(interaction); _caption()

func toggle() -> bool:
	# Do not close a solid leaf through someone standing in the threshold.
	var player = get_tree().get_first_node_in_group("kala_player")
	if opened and is_instance_valid(player):
		var point = to_local(player.global_position)
		if absf(point.x) < 1.45 and absf(point.z) < 1.25: return false
	opened = not opened; State.set_flag("campusDoorsOpen", opened); _caption()
	return true

func _caption() -> void:
	interaction.caption = "Tutup pintu sekolah" if opened else "Buka pintu sekolah"

func _physics_process(delta: float) -> void:
	for hinge in leaves:
		hinge.rotation.y = move_toward(hinge.rotation.y, float(hinge.get_meta("side")) * PI * 0.49 if opened else 0.0, delta * 1.8)
