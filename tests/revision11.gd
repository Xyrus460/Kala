extends Node
var game: Node3D
var checks=0
var failures=0
const ARCH=preload("res://scripts/systems/school_architecture.gd")

func check(ok: bool,label: String) -> void:
	checks+=1
	if ok: print("PASS: ",label)
	else: failures+=1; push_error("FAIL: "+label)

func room(id: String) -> void:
	game.narrative.cancel(); game.boss_revision.cancel(); game.cinematic=false; game.ui.close_panel()
	await game.enter_room(id,false,false); game.player.active=false
	if is_instance_valid(game.boss): game.boss.enabled=false
	await get_tree().physics_frame; await get_tree().physics_frame

func walk(point: Vector3,frames=720) -> bool:
	game.player.active=true; game.player.set_physics_process(false); game.player.camera.rotation=Vector3.ZERO
	Input.action_press("forward"); Input.action_press("sprint")
	var reached=false
	for i in range(frames):
		var difference=point-game.player.position; difference.y=0
		if difference.length()<0.16: reached=absf(point.y-game.player.position.y)<0.24; break
		game.player.rotation.y=atan2(-difference.x,-difference.z)
		game.player._physics_process(1.0/60); await get_tree().physics_frame
	Input.action_release("forward"); Input.action_release("sprint")
	game.player.set_physics_process(true); game.player.active=false
	if not reached:
		print("ROUTE STOP ",game.player.position," -> ",point)
		for i in range(game.player.get_slide_collision_count()): print("BLOCKER ",game.player.get_slide_collision(i).get_collider().get_path())
	return reached

func pose(p: Vector3,target: Vector3) -> void:
	game.player.position=p; game.player.last_safe_position=p; game.player.camera.look_at(target)
	game.player.active=true
	for i in range(4): await get_tree().physics_frame
	game.player.active=false

func hit(from: Vector3,to: Vector3) -> Dictionary:
	return game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1))

func _ready() -> void:
	State.save_enabled=false; State.reset(); Engine.physics_ticks_per_second=240
	game=preload("res://scenes/main/main.tscn").instantiate(); add_child(game)
	await get_tree().process_frame; game.test_mode=true; game.playing=true; game.ui.close_panel()
	State.set_flag("prologueVersion"); State.set_flag("lessonSeen")
	await room("home")
	for id in ["bedroom","nursery","bathroom"]:
		var door=game.level.chapter_world.doors[id].node
		var slab=door.get_node("DoorLeaf/SolidDoorSlab")
		check(slab.mesh.size==Vector3(1.04,2.14,0.065),id+" slab fits its opening and has separate static jamb")
	check(not hit(Vector3(-1.70,1.2,5.3),Vector3(-1.70,1.2,3.5)).is_empty(),"bathroom dead-end gap is physically closed")
	check(not hit(Vector3(1.6,1.2,6.4),Vector3(1.6,1.2,4.5)).is_empty(),"mother/stair service gap is physically closed")
	var supported=true
	for post in game.level.find_children("AnchoredBaluster*","MeshInstance3D",true,false):
		var foot: Vector3=post.position-Vector3.UP*0.5
		var support=hit(foot+Vector3.UP*0.025,foot-Vector3.UP*0.05)
		if support.is_empty(): supported=false
	check(supported,"all 36 stair balusters have a real supporting tread or floor")
	game.player.position=Vector3(0,0.05,10.5); game.player.last_safe_position=game.player.position
	check(await walk(Vector3(0,3.2,3.9)),"home steps can be climbed using the actual standing capsule")
	check(await walk(Vector3(0,0,10.5)),"home steps can be descended without falling or trapping player")
	game.chapter_flow.interact("door_bathroom")
	for i in range(100): game.level.chapter_world.update(1.0/60)
	check(await walk(Vector3(-5,0,10.5)) and await walk(Vector3(-5,0,6)) and await walk(Vector3(-5,0,2.5)) and await walk(Vector3(-3.1,0,2)),"bathroom remains reachable after closing service gaps")
	await pose(Vector3(-3.1,0.05,2),Vector3(-3.1,1.05,0.8))
	check(is_instance_valid(game.player.target) and game.player.target.parameter=="wash","shower is reachable by the player's real interaction ray")
	var original=game.player.transform
	game.narrative.start("wash"); game.narrative.set_process(false); game.narrative.advance(5)
	var shower=game.level.get_node("FurnishedHome/BathroomShower")
	check(shower.running and shower.water.visible and shower.sound.playing,"wash shows flowing water and plays shower audio")
	check(game.player.camera.has_node("WashingHands") and not game.player.active and game.ui.fade.color.a<0.01,"first-person washing is visible and movement is locked")
	game.narrative.cancel(); await get_tree().process_frame
	check(not shower.running and not shower.sound.playing and not State.flag("homeReady"),"cancelling wash stops effects without granting completion")
	check(game.player.transform.is_equal_approx(original),"cancelling shower restores player pose")
	game.narrative.start("wash"); game.narrative.set_process(false); game.narrative.advance(19)
	await get_tree().process_frame
	check(State.flag("homeReady") and not shower.running and not game.player.camera.has_node("WashingHands"),"full wash completes, restores controls and removes temporary hands")
	await room("school")
	var teacher=game.level.get_node("EnvironmentalDetail/Teacher")
	check(teacher.get_meta("identity")=="Ratna" and teacher.find_child("RatnaLongSkirt",true,false)!=null,"Bu Ratna is an adult female teacher model")
	check(game.level.has_node("ExplorableSchool") and not game.campus.rooms.schoolyard.has_node("SchoolCampus/FreeSchoolBuilding"),"school exterior and interior share one architecture with no overlapping OBJ")
	for floor_id in range(3):
		for side in [-1,1]:
			var rooms=ARCH.WEST if side<0 else ARCH.EAST
			for r in rooms:
				var z=(r[0]+r[1])*0.5; var y=floor_id*3.4
				# Approach each opening from the real corridor and return through it.
				game.player.position=Vector3(0,y+0.05,z); game.player.last_safe_position=game.player.position
				var inside_x = side*(2.65 if str(r[2])=="TANGGA" else 3.35)
				check(await walk(Vector3(inside_x,y,z),240) and await walk(Vector3(0,y,z),240),"floor %d room %s %s has a traversable doorway"%[floor_id+1,side,r[2]])
	game.player.position=Vector3(-2.6,0.05,-27.3); game.player.last_safe_position=game.player.position
	for floor_id in range(2):
		check(await walk(Vector3(-11.8,(floor_id+1)*3.4,-27.3)),"school staircase physically reaches floor %d"%(floor_id+2))
		check(await walk(Vector3(-11.8,(floor_id+1)*3.4,-29.2)) and await walk(Vector3(-2.5,(floor_id+1)*3.4,-29.2)) and await walk(Vector3(-2.5,(floor_id+1)*3.4,-27.3)),"upper landing joins corridor without an invisible ceiling or gap")
	check(await walk(Vector3(-2.5,6.8,-29.2)) and await walk(Vector3(-11.8,6.8,-29.2)) and await walk(Vector3(-11.8,6.8,-27.3)) and await walk(Vector3(-2.5,3.4,-27.3)),"school staircase descends from top floor")
	for key in ["books","lab"]:
		var p: Vector3=preload("res://scripts/systems/school_puzzles.gd").POSITIONS[key]
		var count=3 if key=="books" else 4
		var ray_clear=true
		for i in range(count):
			var q=p+Vector3(-0.9+i*0.6,1.1,0.12)
			await pose(Vector3(q.x,0.05,q.z+1.4),q)
			if not is_instance_valid(game.player.target) or game.player.target.parameter!="campus_%s_%d"%[key,i]:
				ray_clear=false; print("PUZZLE RAY BLOCKER ",key," ",i," ",game.player.ray.get_collider())
		check(ray_clear,"all "+key+" puzzle controls can be targeted in world")
		game.chapter_flow.interact("campus_"+key+"_0")
		check(int(State.data.flags.get("campus_"+key+"_step",0))==0,"wrong "+key+" sequence resets and remains solvable")
		game.chapter_flow.interact("campus_clue_"+key); game.ui.close_panel()
		check(State.data.notes.has("campus_"+key),key+" clue is retained in the journal")
		for index in preload("res://scripts/systems/school_puzzles.gd").ORDERS[key]: game.chapter_flow.interact("campus_%s_%d"%[key,index])
		check(State.flag("campus_"+key+"_done"),key+" puzzle completes using its clue")
	game.chapter_flow.interact("campus_archive"); game.ui.close_panel()
	check(State.flag("campusArchiveRead") and State.data.notes.has("campus_archive"),"two puzzle rewards unlock readable school archive")
	await room("schoolyard"); await room("school")
	check(game.level.get_node("SchoolPuzzles/Puzzle_books/Progress").text=="SELESAI" and game.level.get_node("SchoolPuzzles/Puzzle_lab/Progress").text=="SELESAI","both school puzzle states survive unloading and reloading")
	for id in ["street","loading","relay","production","office","ritual","corridor","daisy","pursuit"]:
		await room(id)
		check(game.level.has_node("FactoryArtDirection") and game.level.get_node("FactoryArtDirection").has_meta("theme"),id+" has its chapter-specific factory art treatment")
		var original_names=true
		for label in game.level.get_node("FactoryArtDirection").find_children("*","Label3D",true,false):
			for forbidden in ["POPPY", "PLAYTIME", "MAKE A FRIEND", "GAME STATION", "HOME SWEET HOME", "HUGGY"]:
				if forbidden in label.text.to_upper(): original_names=false
		check(original_names,id+" signage uses KALA names rather than reference-game names")
		var valid=true
		for child in game.level.get_node("FactoryArtDirection").find_children("*","MeshInstance3D",true,false):
			if not child.transform.is_finite(): valid=false
		check(valid,id+" decorative transforms remain finite")
	print("KALA REVISION11: %d checks, %d failures"%[checks,failures])
	shower=null; teacher=null
	game.campus.clear(game.level); game.boss_revision.cancel(); game.audio.shutdown(); game.queue_free()
	await get_tree().process_frame; await get_tree().physics_frame; await get_tree().create_timer(0.4).timeout
	get_tree().quit(0 if failures==0 else 1)
