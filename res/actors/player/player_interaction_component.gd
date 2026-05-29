extends RayCast3D
class_name PlayerInteractionComponent

@export var interaction_distance := 2.6

var current_target_name := ""


func _ready() -> void:
	target_position = Vector3(0.0, 0.0, -interaction_distance)
	collide_with_bodies = true
	collide_with_areas = true
	enabled = true


func _physics_process(_delta: float) -> void:
	force_raycast_update()
	if is_colliding():
		var collider := get_collider()
		if collider is Node:
			current_target_name = collider.name
		else:
			current_target_name = "Object"
	else:
		current_target_name = ""


func get_interaction_hint() -> String:
	if current_target_name.is_empty():
		return ""
	return "Interact: %s" % current_target_name
