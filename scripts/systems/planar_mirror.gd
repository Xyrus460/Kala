extends Node3D

var surface: MeshInstance3D
var viewport: SubViewport
var reflection: Camera3D
var dimensions = Vector2(0.90, 1.05)

func _ready() -> void:
	name = "WorkingMirror"
	viewport = SubViewport.new(); viewport.name = "ReflectionViewport"
	viewport.size = Vector2i(512, int(512 * dimensions.y / dimensions.x))
	viewport.world_3d = get_world_3d()
	viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	viewport.msaa_3d = Viewport.MSAA_2X if RenderingServer.get_current_rendering_method() == "forward_plus" else Viewport.MSAA_DISABLED
	add_child(viewport)
	reflection = Camera3D.new(); reflection.cull_mask = (1 << 19) - 1
	viewport.add_child(reflection)
	reflection.current = true
	surface = MeshInstance3D.new(); surface.name = "ReflectiveGlass"
	var quad = QuadMesh.new(); quad.size = dimensions; surface.mesh = quad
	surface.layers = 1 << 19
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = viewport.get_texture()
	surface.material_override = material
	surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(surface)

func _process(_delta: float) -> void:
	var viewer = get_viewport().get_camera_3d()
	if viewer == null: return
	var normal = global_basis.z.normalized()
	var eye = viewer.global_position
	var distance = normal.dot(eye - global_position)
	if distance < 0.10 or eye.distance_to(global_position) > 7:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	reflection.global_position = eye - normal * distance * 2
	reflection.global_basis = Basis.looking_at(normal, global_basis.y)
	var offset = reflection.global_basis.inverse() * (global_position - reflection.global_position)
	reflection.set_frustum(dimensions.y, Vector2(offset.x, offset.y), distance + 0.015, 80.0)

func _exit_tree() -> void:
	set_process(false)
	if is_instance_valid(surface) and surface.material_override is StandardMaterial3D:
		surface.material_override.albedo_texture = null
	if is_instance_valid(viewport):
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		viewport.world_3d = null
