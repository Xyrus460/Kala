extends Node

# The coordinator outlives the game node so render targets
# can actually be released before the OpenGL renderer destroys its context.
func finish(game: Node) -> void:
	var tree = get_tree()
	game.queue_free()
	await tree.process_frame
	await tree.physics_frame
	await tree.process_frame
	if DisplayServer.get_name() != "headless":
		for i in range(4): await RenderingServer.frame_post_draw
	await tree.create_timer(0.1).timeout
	tree.quit()

