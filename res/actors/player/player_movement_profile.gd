extends Resource
class_name PlayerMovementProfile

@export_group("Movement")
@export var walk_speed := 5.5
@export var sprint_speed := 8.5
@export var crouch_speed := 3.0
@export var jump_velocity := 5.2
@export var ground_acceleration := 32.0
@export var ground_deceleration := 24.0
@export var air_acceleration := 8.0

@export_group("Air")
@export var max_air_jumps := 1
@export var air_jump_velocity := 5.2

@export_group("Crouch")
@export var standing_capsule_height := 1.8
@export var crouched_capsule_height := 1.2
@export var standing_eye_height := 1.6
@export var crouched_eye_height := 1.0
@export var crouch_blend_speed := 10.0

@export_group("Mantle")
@export var mantle_min_height := 0.35
@export var mantle_max_height := 2.6
@export var mantle_duration := 0.45
@export var mantle_forward_distance := 1.2
@export var mantle_wall_angle_limit := 0.65

@export_group("Slide")
@export var slide_start_speed := 9.5
@export var slide_min_start_speed := 6.5
@export var slide_duration := 0.45
@export var slide_friction := 14.0
@export var slide_cooldown := 0.2
