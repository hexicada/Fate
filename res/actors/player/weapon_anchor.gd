extends Node3D
class_name WeaponAnchor

@export_group("Anchor Pose")
@export var hip_position := Vector3.ZERO
@export var hip_rotation_degrees := Vector3.ZERO
@export var ads_position := Vector3.ZERO
@export var ads_rotation_degrees := Vector3.ZERO
@export var transition_speed := 12.0

var _ads_enabled := false


func _ready() -> void:
	position = hip_position
	rotation_degrees = hip_rotation_degrees


func _process(delta: float) -> void:
	var target_position := ads_position if _ads_enabled else hip_position
	var target_rotation := ads_rotation_degrees if _ads_enabled else hip_rotation_degrees
	var blend := clampf(transition_speed * delta, 0.0, 1.0)

	position = position.lerp(target_position, blend)
	rotation_degrees = Vector3(
		lerp_angle(rotation_degrees.x, target_rotation.x, blend),
		lerp_angle(rotation_degrees.y, target_rotation.y, blend),
		lerp_angle(rotation_degrees.z, target_rotation.z, blend)
	)


func set_ads_enabled(enabled: bool) -> void:
	_ads_enabled = enabled


func is_ads_enabled() -> bool:
	return _ads_enabled


func get_active_view_model() -> Node3D:
	for child in get_children():
		if child.has_method("set_pose_name") and child.has_method("on_fire") and child.has_method("on_reload"):
			return child
	return null
