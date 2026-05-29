extends CharacterBody3D

enum LocomotionState {
	STANDING,
	SPRINTING,
	CROUCHED,
	SLIDING,
	AIRBORNE,
	MANTLING,
}

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
@export var mantle_min_height := 0.7
@export var mantle_max_height := 1.5
@export var mantle_duration := 0.2
@export var mantle_forward_distance := 0.9
@export var mantle_wall_angle_limit := 0.4

@export_group("Slide")
@export var slide_start_speed := 9.5
@export var slide_min_start_speed := 6.5
@export var slide_duration := 0.45
@export var slide_friction := 14.0
@export var slide_cooldown := 0.2

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var head_pivot: Node3D = $HeadPivot
@onready var camera_controller: Node3D = $HeadPivot
@onready var interaction_component: RayCast3D = $HeadPivot/InteractionRayCast3D
@onready var combat_bridge: Node = $CombatBridge
@onready var mantle_probe_lower: RayCast3D = $MantleProbeLower
@onready var mantle_probe_upper: RayCast3D = $MantleProbeUpper
@onready var state_label: Label = $UI/StateLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var interaction_label: Label = $UI/InteractionLabel

var _gravity := 9.8
var _state := LocomotionState.STANDING
var _is_crouching := false
var _crouch_alpha := 0.0
var _slide_time_left := 0.0
var _slide_cooldown_left := 0.0
var _slide_speed := 0.0
var _slide_direction := Vector3.ZERO
var _mantle_time_left := 0.0
var _mantle_start_position := Vector3.ZERO
var _mantle_target_position := Vector3.ZERO
var _air_jumps_left := 0


func _ready() -> void:
	_ensure_default_input_actions()
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_apply_crouch_pose(0.0)
	camera_controller.set("standing_eye_height", standing_eye_height)
	camera_controller.set("crouched_eye_height", crouched_eye_height)
	mantle_probe_lower.enabled = true
	mantle_probe_upper.enabled = true
	_air_jumps_left = max_air_jumps
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hint_label.text = "WASD move | Shift sprint | Space jump/double jump | Ctrl crouch/slide | Jump into ledges to mantle | Esc mouse"
	_update_debug_label()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return

	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return

	camera_controller.call("handle_input", event, self)


func _physics_process(delta: float) -> void:
	if _state == LocomotionState.MANTLING:
		_update_mantle(delta)
		camera_controller.call("update_state_effects", false, false, delta)
		_update_debug_label()
		return

	if _slide_cooldown_left > 0.0:
		_slide_cooldown_left = max(_slide_cooldown_left - delta, 0.0)

	var on_floor := is_on_floor()
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")

	if on_floor:
		_air_jumps_left = max_air_jumps

	if Input.is_action_just_pressed("jump"):
		if on_floor:
			_end_slide()
			velocity.y = jump_velocity
		elif _air_jumps_left > 0:
			_air_jumps_left -= 1
			velocity.y = air_jump_velocity

	var sprint_requested := _can_sprint(move_input, on_floor)
	if _can_start_slide(sprint_requested) and Input.is_action_just_pressed("crouch"):
		_begin_slide()

	if _can_start_mantle(move_input, on_floor):
		_begin_mantle()
		camera_controller.call("update_state_effects", false, false, delta)
		_update_debug_label()
		return

	_update_slide(delta)
	_update_crouch_state(delta)
	_update_horizontal_velocity(move_input, delta)
	camera_controller.call(
		"update_state_effects",
		_state == LocomotionState.SPRINTING,
		_state == LocomotionState.SLIDING,
		delta
	)

	if not on_floor:
		velocity.y -= _gravity * delta

	move_and_slide()
	_update_state(sprint_requested)
	_update_debug_label()


func _update_horizontal_velocity(move_input: Vector2, delta: float) -> void:
	var current_horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var desired_horizontal := Vector3.ZERO

	if _state == LocomotionState.SLIDING:
		desired_horizontal = _slide_direction * _slide_speed
	else:
		var local_dir := Vector3(move_input.x, 0.0, move_input.y)
		var world_dir := (global_transform.basis * local_dir)
		world_dir.y = 0.0
		world_dir = world_dir.normalized()
		desired_horizontal = world_dir * _current_target_speed()

	var accel := ground_acceleration if is_on_floor() else air_acceleration
	var decel := ground_deceleration if is_on_floor() else air_acceleration
	var blend := accel if desired_horizontal.length() > 0.0 else decel
	current_horizontal = current_horizontal.move_toward(desired_horizontal, blend * delta)

	velocity.x = current_horizontal.x
	velocity.z = current_horizontal.z


func _update_state(sprint_requested: bool) -> void:
	if not is_on_floor():
		_state = LocomotionState.AIRBORNE
		return

	if _state == LocomotionState.SLIDING:
		return

	if _state == LocomotionState.MANTLING:
		return

	if _is_crouching:
		_state = LocomotionState.CROUCHED
		return

	if sprint_requested:
		_state = LocomotionState.SPRINTING
		return

	_state = LocomotionState.STANDING


func _current_target_speed() -> float:
	match _state:
		LocomotionState.CROUCHED:
			return crouch_speed
		LocomotionState.SPRINTING:
			return sprint_speed
		LocomotionState.AIRBORNE:
			return walk_speed
		_:
			return walk_speed


func _update_crouch_state(delta: float) -> void:
	var crouch_held := Input.is_action_pressed("crouch")

	if _state == LocomotionState.SLIDING:
		_is_crouching = true
	elif crouch_held:
		_is_crouching = true
	elif _can_stand_up():
		_is_crouching = false

	var target_alpha := 1.0 if _is_crouching else 0.0
	_crouch_alpha = move_toward(_crouch_alpha, target_alpha, crouch_blend_speed * delta)
	_apply_crouch_pose(_crouch_alpha)
	camera_controller.call("update_eye_height", _crouch_alpha, delta)


func _apply_crouch_pose(alpha: float) -> void:
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return

	var new_height: float = lerpf(standing_capsule_height, crouched_capsule_height, alpha)
	capsule.height = new_height
	collision_shape.position.y = new_height * 0.5
	body_mesh.position.y = collision_shape.position.y


func _can_stand_up() -> bool:
	if _state == LocomotionState.SLIDING:
		return false

	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return true

	var required_clearance: float = maxf(standing_capsule_height - capsule.height, 0.0)
	if required_clearance <= 0.0:
		return true

	return not test_move(global_transform, Vector3.UP * required_clearance)


func _can_sprint(move_input: Vector2, on_floor: bool) -> bool:
	if not on_floor:
		return false

	if _is_crouching:
		return false

	if not Input.is_action_pressed("sprint"):
		return false

	return move_input.y < -0.35 and move_input.length() > 0.15


func _can_start_slide(sprint_requested: bool) -> bool:
	if _slide_cooldown_left > 0.0:
		return false

	if _state == LocomotionState.SLIDING:
		return false

	if not is_on_floor():
		return false

	if not sprint_requested:
		return false

	return _horizontal_speed() >= slide_min_start_speed


func _begin_slide() -> void:
	_state = LocomotionState.SLIDING
	_is_crouching = true
	_slide_time_left = slide_duration
	_slide_speed = max(_horizontal_speed(), slide_start_speed)
	_slide_direction = -global_transform.basis.z
	_slide_direction.y = 0.0
	_slide_direction = _slide_direction.normalized()


func _update_slide(delta: float) -> void:
	if _state != LocomotionState.SLIDING:
		return

	_slide_time_left -= delta
	_slide_speed = move_toward(_slide_speed, crouch_speed, slide_friction * delta)
	if _slide_time_left <= 0.0 or _slide_speed <= crouch_speed + 0.2 or not is_on_floor():
		_end_slide()


func _end_slide() -> void:
	if _state == LocomotionState.SLIDING:
		_slide_cooldown_left = slide_cooldown
	_state = LocomotionState.STANDING
	_slide_time_left = 0.0


func _can_start_mantle(move_input: Vector2, on_floor: bool) -> bool:
	if on_floor:
		return false

	if _state == LocomotionState.SLIDING or _state == LocomotionState.MANTLING:
		return false

	if move_input.y >= -0.1:
		return false

	if velocity.y > 1.0:
		return false

	if not mantle_probe_lower.is_colliding() or mantle_probe_upper.is_colliding():
		return false

	var hit_normal: Vector3 = mantle_probe_lower.get_collision_normal()
	if absf(hit_normal.y) > mantle_wall_angle_limit:
		return false

	return true


func _begin_mantle() -> void:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var hit_point := mantle_probe_lower.get_collision_point()
	var space_state := get_world_3d().direct_space_state
	var ray_from := hit_point + forward * mantle_forward_distance + Vector3.UP * (mantle_max_height + 0.2)
	var ray_to := ray_from + Vector3.DOWN * (mantle_max_height + mantle_min_height + 2.0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [self]

	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return

	var top_point: Vector3 = hit["position"]
	var base_target := top_point + Vector3.UP * (standing_capsule_height * 0.5 + 0.05) + forward * 0.15
	var target := base_target

	if test_move(global_transform, target - global_position):
		var found_clear_target := false
		for i in range(1, 8):
			var candidate := base_target - forward * (0.15 * float(i))
			if not test_move(global_transform, candidate - global_position):
				target = candidate
				found_clear_target = true
				break

		if not found_clear_target:
			for i in range(1, 4):
				var candidate_up := base_target + Vector3.UP * (0.1 * float(i))
				if not test_move(global_transform, candidate_up - global_position):
					target = candidate_up
					found_clear_target = true
					break

		if not found_clear_target:
			return

	_state = LocomotionState.MANTLING
	velocity = Vector3.ZERO
	_is_crouching = false
	_mantle_time_left = mantle_duration
	_mantle_start_position = global_position
	_mantle_target_position = target


func _update_mantle(delta: float) -> void:
	_mantle_time_left = max(_mantle_time_left - delta, 0.0)
	var t := 1.0 - (_mantle_time_left / maxf(mantle_duration, 0.001))
	t = clampf(t, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	global_position = _mantle_start_position.lerp(_mantle_target_position, eased)

	if _mantle_time_left <= 0.0:
		global_position = _mantle_target_position
		_state = LocomotionState.STANDING


func _horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _update_debug_label() -> void:
	var name := _state_name()
	combat_bridge.call("update_from_locomotion_state", StringName(name))
	state_label.text = "State: %s | Speed: %.2f | Weapon: %s" % [
		name,
		_horizontal_speed(),
		combat_bridge.call("readiness_name")
	]
	interaction_label.text = interaction_component.call("get_interaction_hint")


func _state_name() -> String:
	match _state:
		LocomotionState.STANDING:
			return "Standing"
		LocomotionState.SPRINTING:
			return "Sprinting"
		LocomotionState.CROUCHED:
			return "Crouched"
		LocomotionState.SLIDING:
			return "Sliding"
		LocomotionState.AIRBORNE:
			return "Airborne"
		LocomotionState.MANTLING:
			return "Mantling"
		_:
			return "Unknown"


func _ensure_default_input_actions() -> void:
	_ensure_action_with_key("move_forward", KEY_W)
	_ensure_action_with_key("move_back", KEY_S)
	_ensure_action_with_key("move_left", KEY_A)
	_ensure_action_with_key("move_right", KEY_D)
	_ensure_action_with_key("jump", KEY_SPACE)
	_ensure_action_with_key("sprint", KEY_SHIFT)
	_ensure_action_with_key("crouch", KEY_CTRL)


func _ensure_action_with_key(action_name: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	var key_event := InputEventKey.new()
	key_event.keycode = keycode
	if InputMap.action_has_event(action_name, key_event):
		return

	InputMap.action_add_event(action_name, key_event)
