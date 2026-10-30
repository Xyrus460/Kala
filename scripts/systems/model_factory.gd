extends RefCounted
const Character = preload("res://scripts/systems/character_model.gd")

static func make(id: String) -> Node3D:
	if id.begins_with("npc_"): return Character.create(id.trim_prefix("npc_"))
	if id == "actor_daisy": return Character.create("Daisy")
	if id in ["tumbal", "nightmare"]:
		# Preserve the reference mask, ribcage, two arms and spiked halo.
		var root = load("res://assets/models/source/tumbal.glb").instantiate() as Node3D
		root.name = "Pemegang" if id == "tumbal" else "Nightmare"
		var names = {"Source_1245": "FinalBody", "Source_1267": "FinalHead", "Source_1276": "BackPortal",
			"Source_1249": "FinalLeg0", "Source_1252": "FinalKnee0", "Source_1255": "FinalFoot0",
			"Source_1258": "FinalLeg1", "Source_1261": "FinalKnee1", "Source_1264": "FinalFoot1",
			"Source_1282": "FinalArm0", "Source_1285": "FinalElbow0", "Source_1288": "FinalWrist0",
			"Source_1292": "FinalArm1", "Source_1295": "FinalElbow1", "Source_1298": "FinalWrist1"}
		for old in names:
			var joint = root.find_child(old, true, false)
			if joint != null: joint.name = names[old]
		# Effects have a stable portal path independent of the imported hierarchy.
		var portal = root.find_child("BackPortal", true, false) as Node3D
		var pose = portal.transform
		portal.owner = null
		portal.get_parent().remove_child(portal); root.add_child(portal); portal.transform = pose
		# This oversized emissive sphere was hidden by the browser's combat loop.
		# GLB does not preserve that runtime visibility and it obscured the mask.
		var core = root.find_child("Source_1275", true, false) as Node3D
		core.name = "FinalCore"; core.hide()
		root.set_meta("final_reference", true)
		return root
	if id != "hands": return load("res://assets/models/source/%s.glb" % id).instantiate()
	var root = Node3D.new(); root.name = "SculptedHands"
	var sculpt = load("res://assets/models/revision06/hands_repaired.glb").instantiate() as Node3D
	sculpt.name = "RepairedSculpt"; root.add_child(sculpt)
	return root
