extends StaticBody2D

## This scene will be loaded when the player interacts with the stairs.
@export var target_scene: PackedScene

## Called by the player when they interact with the stairs.
func interact():
	if target_scene:
		print("Changing scene to: ", target_scene.resource_path)
		get_tree().change_scene_to_packed(target_scene)
	else:
		print("No target scene configured for these stairs.")
