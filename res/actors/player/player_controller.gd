extends CharacterBody3D

@export var movement_profile: PlayerMovementProfile

var walk_speed: float
var sprint_speed: float
var crouch_speed: float
var jump_velocity: float
var ground_acceleration: float
var ground_deceleration: float
var air_acceleration: float
var max_air_jumps: int
var air_jump_velocity: float
var standing_capsule_height: float
var crouched_capsule_height: float
var standing_eye_height: float
var crouched_eye_height: float
var crouch_blend_speed: float
var mantle_min_height: float
var mantle_max_height: float
var mantle_duration: float
var mantle_forward_distance: float
var mantle_wall_angle_limit: float
var slide_start_speed: float
var slide_min_start_speed: float
var slide_duration: float
var slide_friction: float
var slide_cooldown: float

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var body_mesh: MeshInstance3D = $BodyMesh
@onready var head_pivot: Node3D = $HeadPivot
@onready var camera_controller: PlayerCameraController = $HeadPivot
@onready var interaction_component: PlayerInteractionComponent = $HeadPivot/InteractionRayCast3D
@onready var mantle_probe_lower: RayCast3D = $MantleProbeLower
@onready var mantle_probe_upper: RayCast3D = $MantleProbeUpper
@onready var state_label: Label = $UI/StateLabel
@onready var hint_label: Label = $UI/HintLabel
@onready var interaction_label: Label = $UI/InteractionLabel
@onready var combat_bridge: PlayerCombatBridge = $CombatBridge
@onready var weapon_anchor: WeaponAnchor = $HeadPivot/Camera3D/ViewModelRoot/UpperFP/WeaponAnchor

var _gravity := 9.8
var _state := PlayerLocomotionState.Value.STANDING
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
	_apply_movement_profile()
	_apply_crouch_pose(0.0)
	camera_controller.standing_eye_height = standing_eye_height
	camera_controller.crouched_eye_height = crouched_eye_height
	mantle_probe_lower.enabled = true
	mantle_probe_upper.enabled = true
	_air_jumps_left = max_air_jumps
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hint_label.text = "WASD/Left stick move | Mouse/Right stick look | Shift/L3 sprint | Space/A jump | Ctrl/B crouch/slide | Esc mouse"
	combat_bridge.update_from_locomotion_state(_state)
	_update_debug_label()


func _apply_movement_profile() -> void:
	if movement_profile == null:
		movement_profile = PlayerMovementProfile.new()

	walk_speed = movement_profile.walk_speed
	sprint_speed = movement_profile.sprint_speed
	crouch_speed = movement_profile.crouch_speed
	jump_velocity = movement_profile.jump_velocity
	ground_acceleration = movement_profile.ground_acceleration
	ground_deceleration = movement_profile.ground_deceleration
	air_acceleration = movement_profile.air_acceleration
	max_air_jumps = movement_profile.max_air_jumps
	air_jump_velocity = movement_profile.air_jump_velocity
	standing_capsule_height = movement_profile.standing_capsule_height
	crouched_capsule_height = movement_profile.crouched_capsule_height
	standing_eye_height = movement_profile.standing_eye_height
	crouched_eye_height = movement_profile.crouched_eye_height
	crouch_blend_speed = movement_profile.crouch_blend_speed
	mantle_min_height = movement_profile.mantle_min_height
	mantle_max_height = movement_profile.mantle_max_height
	mantle_duration = movement_profile.mantle_duration
	mantle_forward_distance = movement_profile.mantle_forward_distance
	mantle_wall_angle_limit = movement_profile.mantle_wall_angle_limit
	slide_start_speed = movement_profile.slide_start_speed
	slide_min_start_speed = movement_profile.slide_min_start_speed
	slide_duration = movement_profile.slide_duration
	slide_friction = movement_profile.slide_friction
	slide_cooldown = movement_profile.slide_cooldown


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

	camera_controller.handle_input(event, self)


func _physics_process(delta: float) -> void:
	camera_controller.update_controller_look(self, delta)

	if _state == PlayerLocomotionState.Value.MANTLING:
		_update_mantle(delta)
		camera_controller.update_state_effects(false, false, delta)
		combat_bridge.update_from_locomotion_state(_state)
		if weapon_anchor:
			var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
			weapon_anchor.set_ads_enabled(lowered)
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
		camera_controller.update_state_effects(false, false, delta)
		combat_bridge.update_from_locomotion_state(_state)
		if weapon_anchor:
			var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
			weapon_anchor.set_ads_enabled(lowered)
		_update_debug_label()
		return

	_update_slide(delta)
	_update_crouch_state(delta)
	_update_horizontal_velocity(move_input, delta)
	camera_controller.update_state_effects(
		_state == PlayerLocomotionState.Value.SPRINTING,
		_state == PlayerLocomotionState.Value.SLIDING,
		delta
	)

	if not on_floor:
		velocity.y -= _gravity * delta

	move_and_slide()
	_update_state(sprint_requested)
	combat_bridge.update_from_locomotion_state(_state)
	if weapon_anchor:
		var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
		weapon_anchor.set_ads_enabled(lowered)
	_update_debug_label()


func _update_horizontal_velocity(move_input: Vector2, delta: float) -> void:
	var current_horizontal := Vector3(velocity.x, 0.0, velocity.z)
	var desired_horizontal := Vector3.ZERO

	if _state == PlayerLocomotionState.Value.SLIDING:
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
		_state = PlayerLocomotionState.Value.AIRBORNE
		return

	if _state == PlayerLocomotionState.Value.SLIDING:
		return

	if _state == PlayerLocomotionState.Value.MANTLING:
		return

	if _is_crouching:
		_state = PlayerLocomotionState.Value.CROUCHED
		return

	if sprint_requested:
		_state = PlayerLocomotionState.Value.SPRINTING
		return

	_state = PlayerLocomotionState.Value.STANDING


func _current_target_speed() -> float:
	match _state:
		PlayerLocomotionState.Value.CROUCHED:
			return crouch_speed
		PlayerLocomotionState.Value.SPRINTING:
			return sprint_speed
		PlayerLocomotionState.Value.AIRBORNE:
			return walk_speed
		_:
			return walk_speed


func _update_crouch_state(delta: float) -> void:
	var crouch_held := Input.is_action_pressed("crouch")

	if _state == PlayerLocomotionState.Value.SLIDING:
		_is_crouching = true
	elif crouch_held:
		_is_crouching = true
	elif _can_stand_up():
		_is_crouching = false

	var target_alpha := 1.0 if _is_crouching else 0.0
	_crouch_alpha = move_toward(_crouch_alpha, target_alpha, crouch_blend_speed * delta)
	_apply_crouch_pose(_crouch_alpha)
	camera_controller.update_eye_height(_crouch_alpha, delta)


func _apply_crouch_pose(alpha: float) -> void:
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return

	var new_height: float = lerpf(standing_capsule_height, crouched_capsule_height, alpha)
	capsule.height = new_height
	collision_shape.position.y = new_height * 0.5
	body_mesh.position.y = collision_shape.position.y


func _can_stand_up() -> bool:
	if _state == PlayerLocomotionState.Value.SLIDING:
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

	if _state == PlayerLocomotionState.Value.SLIDING:
		return false

	if not is_on_floor():
		return false

	if not sprint_requested:
		return false

	return _horizontal_speed() >= slide_min_start_speed


func _begin_slide() -> void:
	_state = PlayerLocomotionState.Value.SLIDING
	_is_crouching = true
	_slide_time_left = slide_duration
	_slide_speed = max(_horizontal_speed(), slide_start_speed)
	_slide_direction = -global_transform.basis.z
	_slide_direction.y = 0.0
	_slide_direction = _slide_direction.normalized()


func _update_slide(delta: float) -> void:
	if _state != PlayerLocomotionState.Value.SLIDING:
		return

	_slide_time_left -= delta
	_slide_speed = move_toward(_slide_speed, crouch_speed, slide_friction * delta)
	if _slide_time_left <= 0.0 or _slide_speed <= crouch_speed + 0.2 or not is_on_floor():
		_end_slide()


func _end_slide() -> void:
	if _state == PlayerLocomotionState.Value.SLIDING:
		_slide_cooldown_left = slide_cooldown
	_state = PlayerLocomotionState.Value.STANDING
	_slide_time_left = 0.0
	combat_bridge.update_from_locomotion_state(_state)
	if weapon_anchor:
		var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
		weapon_anchor.set_ads_enabled(lowered)


func _can_start_mantle(move_input: Vector2, on_floor: bool) -> bool:
	if on_floor:
		return false

	if _state == PlayerLocomotionState.Value.SLIDING or _state == PlayerLocomotionState.Value.MANTLING:
		return false

	# Very permissive input: only hard back-pushing or almost no movement blocks it.
	# We want mantle to trigger on "any contact" with a valid ledge.
	if move_input.y > 0.45 or (move_input.length() < 0.05 and _horizontal_speed() < 0.8):
		return false

	# Extremely loose vertical velocity. We want reach-up even near jump apex or slight rise.
	if velocity.y > 7.5:
		return false

	# Main check: broad multi-direction, multi-height ledge finder.
	# This is designed to trigger whenever the player is in reasonable contact
	# with a ledge, including from angled approaches and ledges slightly above head.
	if _find_ledge_target() == null:
		return false

	return true


# Improved forgiving ledge detection.
# Uses a fan of forward directions (for angled approaches) and many heights
# (to catch ledges at or slightly above head height). Prefers any reasonable
# wall contact while airborne.
func _find_ledge_target() -> Variant:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	if forward.length() < 0.01:
		return null

	var space_state := get_world_3d().direct_space_state

	# Fan of directions to support angled approaches (not just perfectly straight-on).
	var dirs: Array[Vector3] = [forward]
	var side_angle := 0.45  # ~26 degrees left/right
	dirs.append(forward.rotated(Vector3.UP, side_angle))
	dirs.append(forward.rotated(Vector3.UP, -side_angle))
	# A bit wider for very forgiving "any contact"
	dirs.append(forward.rotated(Vector3.UP, side_angle * 1.6))
	dirs.append(forward.rotated(Vector3.UP, -side_angle * 1.6))

	# Heights from low (waist) to above head. Higher values enable "slightly higher than head" ledges.
	var test_heights: Array[float] = [0.5, 0.8, 1.1, 1.4, 1.7, 2.0, 2.3, 2.6]

	var wall_hit := {}
	for d in dirs:
		for h in test_heights:
			var from_pos := global_position + Vector3(0.0, h, 0.0)
			var to_pos := from_pos + d * (mantle_forward_distance + 0.5)
			var query := PhysicsRayQueryParameters3D.create(from_pos, to_pos)
			query.exclude = [self]
			var hit := space_state.intersect_ray(query)
			if not hit.is_empty():
				var normal: Vector3 = hit.get("normal", Vector3.UP)
				if absf(normal.y) <= mantle_wall_angle_limit:
					wall_hit = hit
					break
		if not wall_hit.is_empty():
			break

	if wall_hit.is_empty():
		# Fallback: use the probe data if the broad search missed but probes have contact.
		# This helps "any time in contact".
		if mantle_probe_lower.is_colliding():
			var n := mantle_probe_lower.get_collision_normal()
			if absf(n.y) <= mantle_wall_angle_limit:
				wall_hit = {
					"position": mantle_probe_lower.get_collision_point(),
					"normal": n
				}

	if wall_hit.is_empty():
		return null

	var hit_point: Vector3 = wall_hit["position"]

	# Search for ledge top, starting quite high to support above-head reaches.
	var search_up := mantle_max_height + 1.3
	var ray_from := hit_point + forward * 0.25 + Vector3.UP * search_up
	var ray_to := hit_point + forward * 0.25 - Vector3.UP * (search_up + 3.2)
	var top_query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	top_query.exclude = [self]
	var top_hit := space_state.intersect_ray(top_query)
	if top_hit.is_empty():
		return null

	var top_point: Vector3 = top_hit["position"]

	var base_target := top_point + Vector3.UP * (standing_capsule_height * 0.5 + 0.07) + forward * 0.1
	var target := base_target

	# Generous clearance search so it succeeds from many contact angles/positions.
	if test_move(global_transform, target - global_position):
		var found_clear_target := false
		for i in range(1, 14):
			var candidate := base_target - forward * (0.1 * float(i))
			if not test_move(global_transform, candidate - global_position):
				target = candidate
				found_clear_target = true
				break

		if not found_clear_target:
			for i in range(1, 6):
				var candidate_up := base_target + Vector3.UP * (0.08 * float(i))
				if not test_move(global_transform, candidate_up - global_position):
					target = candidate_up
					found_clear_target = true
					break

		if not found_clear_target:
			return null

	return target


func _begin_mantle() -> void:
	var target = _find_ledge_target()
	if target == null:
		return

	_state = PlayerLocomotionState.Value.MANTLING
	velocity = Vector3.ZERO
	_is_crouching = false
	_mantle_time_left = mantle_duration
	_mantle_start_position = global_position
	_mantle_target_position = target
	combat_bridge.update_from_locomotion_state(_state)
	if weapon_anchor:
		var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
		weapon_anchor.set_ads_enabled(lowered)


func _update_mantle(delta: float) -> void:
	_mantle_time_left = max(_mantle_time_left - delta, 0.0)
	var t := 1.0 - (_mantle_time_left / maxf(mantle_duration, 0.001))
	t = clampf(t, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	global_position = _mantle_start_position.lerp(_mantle_target_position, eased)

	if _mantle_time_left <= 0.0:
		global_position = _mantle_target_position
		_state = PlayerLocomotionState.Value.STANDING
		combat_bridge.update_from_locomotion_state(_state)
		if weapon_anchor:
			var lowered = combat_bridge.readiness != PlayerCombatBridge.WeaponReadiness.READY
			weapon_anchor.set_ads_enabled(lowered)


func _horizontal_speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


func _update_debug_label() -> void:
	var state_name := PlayerLocomotionState.name_for(_state)
	var weapon_ready := combat_bridge.readiness_name() if combat_bridge else "-"
	state_label.text = "State: %s | Speed: %.2f | Weapon: %s" % [
		state_name,
		_horizontal_speed(),
		weapon_ready
	]
	interaction_label.text = interaction_component.get_interaction_hint()


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
