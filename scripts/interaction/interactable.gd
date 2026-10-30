class_name KalaInteractable
extends Area3D

@export var action_id = ""
@export var caption = "Periksa"
@export var tool_only = false
@export var parameter = ""
var indicator: Label3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	monitoring = false
	add_to_group("interactables")

func available() -> bool:
	if action_id == "fragment": return State.flag("fragmentRevealed_" + parameter) and not State.owns("fragment_" + parameter)
	if action_id == "search": return not State.flag("searched_" + parameter)
	if action_id == "item": return not State.owns(parameter)
	if action_id == "evidence": return not State.data.evidence.has(parameter)
	if action_id == "tool": return not State.flag("lenteraOwned")
	if action_id == "cell": return not State.flag("relayCellHeld") and not State.flag("relayPower")
	if action_id == "latch": return not State.flag("archiveOpen")
	return true

func _process(_delta: float) -> void:
	# Collected/hidden items cannot keep stealing the next interaction ray.
	collision_layer = 2 if available() else 0
