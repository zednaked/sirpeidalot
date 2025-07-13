extends Node2D
@onready var timeshader : float = 0.0
@export var target_scene: PackedScene



func _physics_process(delta: float) -> void:
	timeshader += .01 
	
	$Control/ColorRect.material.set("shader_parameter/time", timeshader)
	pass


func _on_button_pressed() -> void:
	if target_scene:
		print("Changing scene to: ", target_scene.resource_path)
		get_tree().change_scene_to_packed(target_scene)
	else:
		print("No target scene configured for these stairs.")
