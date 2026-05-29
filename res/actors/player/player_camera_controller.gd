extends Node3D
class_name PlayerCameraController

@export var mouse_sensitivity := 0.12
@export var pitch_min := -80.0
@export var pitch_max := 85.0
@export var standing_eye_height := 1.6
@export var crouched_eye_height := 1.0
@export var eye_blend_speed := 10.0
@export var sprint_tilt_degrees := 1.5

var _pitch_degrees := 0.0
var _eye_alpha := 0.0


func handle_input(event: InputEvent, body: Node3D) -> void:
	if event is InputEventMouseMotion:
		body.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		_pitch_degrees = clamp(_pitch_degrees - event.relative.y * mouse_sensitivity, pitch_min, pitch_max)
		rotation.x = deg_to_rad(_pitch_degrees)


func update_eye_height(crouch_alpha: float, delta: float) -> void:
	_eye_alpha = move_toward(_eye_alpha, crouch_alpha, eye_blend_speed * delta)
	position.y = lerp(standing_eye_height, crouched_eye_height, _eye_alpha)


func update_state_effects(is_sprinting: bool, is_sliding: bool, delta: float) -> void:
	var target_roll := 0.0
	if is_sliding:
		target_roll = deg_to_rad(-4.0)
	elif is_sprinting:
		target_roll = deg_to_rad(-sprint_tilt_degrees)
	rotation.z = move_toward(rotation.z, target_roll, delta * 8.0)
