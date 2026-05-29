# control_scheme_manager.gd
# Add this as an Autoload named "ControlSchemeManager" in Project Settings.
# This manager applies keyboard/mouse + gamepad bindings for named actions.

extends Node

const DEFAULT_SCHEME := "Default"

# Canonical gameplay action names used by current scripts.
const ACTIONS := [
	"move_left",
	"move_right",
	"move_forward",
	"move_back",
	"look_left",
	"look_right",
	"look_up",
	"look_down",
	"jump",
	"crouch",
	"sprint",
	"fire",
	"ads",
	"reload",
	"interact",
	"melee",
	"grenade",
	"ult",
	"switch_weapon",
]

var _schemes: Dictionary = {}
var current_scheme: String = DEFAULT_SCHEME


func _ready() -> void:
	_schemes = _build_schemes()
	set_scheme(DEFAULT_SCHEME)


func set_scheme(scheme_name: String) -> void:
	if not _schemes.has(scheme_name):
		push_error("ControlSchemeManager: unknown scheme '%s'" % scheme_name)
		return

	current_scheme = scheme_name
	_apply_scheme(_schemes[scheme_name])
	print("ControlSchemeManager: applied '%s' (%d joypad(s) connected)" % [
		scheme_name,
		Input.get_connected_joypads().size(),
	])


func get_current_scheme() -> String:
	return current_scheme


func get_available_schemes() -> Array[String]:
	var names: Array[String] = []
	for key in _schemes.keys():
		names.append(String(key))
	names.sort()
	return names


func _apply_scheme(scheme: Dictionary) -> void:
	for action in ACTIONS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_erase_events(action)

		if not scheme.has(action):
			push_warning("ControlSchemeManager: no bindings for action '%s' in scheme '%s'" % [
				action,
				current_scheme,
			])
			continue

		for event in scheme[action]:
			InputMap.action_add_event(action, event)


func _base_bindings() -> Dictionary:
	return {
		# Keyboard + left-stick movement.
		"move_forward":  [_key(KEY_W), _joy_axis(JOY_AXIS_LEFT_Y, -1.0)],
		"move_back":     [_key(KEY_S), _joy_axis(JOY_AXIS_LEFT_Y,  1.0)],
		"move_left":     [_key(KEY_A), _joy_axis(JOY_AXIS_LEFT_X, -1.0)],
		"move_right":    [_key(KEY_D), _joy_axis(JOY_AXIS_LEFT_X,  1.0)],

		# Right-stick look axes.
		"look_left":     [_joy_axis(JOY_AXIS_RIGHT_X, -1.0)],
		"look_right":    [_joy_axis(JOY_AXIS_RIGHT_X,  1.0)],
		"look_up":       [_joy_axis(JOY_AXIS_RIGHT_Y, -1.0)],
		"look_down":     [_joy_axis(JOY_AXIS_RIGHT_Y,  1.0)],

		# Shared KBM bindings.
		"jump":          [_key(KEY_SPACE)],
		"crouch":        [_key(KEY_CTRL)],
		"sprint":        [_key(KEY_SHIFT)],
		"fire":          [_mouse(MOUSE_BUTTON_LEFT)],
		"ads":           [_mouse(MOUSE_BUTTON_RIGHT)],
		"reload":        [_key(KEY_R)],
		"interact":      [_key(KEY_F)],
		"melee":         [_key(KEY_V)],
		"grenade":       [_key(KEY_G)],
		"ult":           [_key(KEY_Q)],
		"switch_weapon": [_key(KEY_TAB), _mouse(MOUSE_BUTTON_WHEEL_UP), _mouse(MOUSE_BUTTON_WHEEL_DOWN)],
	}


func _build_schemes() -> Dictionary:
	var default_scheme: Dictionary = _base_bindings().duplicate(true)
	default_scheme["jump"].append(_joy_button(JOY_BUTTON_A))
	default_scheme["crouch"].append(_joy_button(JOY_BUTTON_B))
	default_scheme["sprint"].append(_joy_button(JOY_BUTTON_LEFT_STICK))
	default_scheme["fire"].append(_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.5))
	default_scheme["ads"].append(_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.5))
	default_scheme["reload"].append(_joy_button(JOY_BUTTON_X))
	default_scheme["interact"].append(_joy_button(JOY_BUTTON_X))
	default_scheme["melee"].append(_joy_button(JOY_BUTTON_RIGHT_STICK))
	default_scheme["grenade"].append(_joy_button(JOY_BUTTON_LEFT_SHOULDER))
	default_scheme["ult"].append(_joy_button(JOY_BUTTON_Y))
	default_scheme["switch_weapon"].append(_joy_button(JOY_BUTTON_RIGHT_SHOULDER))

	var jumper_scheme: Dictionary = _base_bindings().duplicate(true)
	jumper_scheme["jump"].append(_joy_button(JOY_BUTTON_LEFT_SHOULDER))
	jumper_scheme["crouch"].append(_joy_button(JOY_BUTTON_B))
	jumper_scheme["sprint"].append(_joy_button(JOY_BUTTON_LEFT_STICK))
	jumper_scheme["fire"].append(_joy_axis(JOY_AXIS_TRIGGER_RIGHT, 0.5))
	jumper_scheme["ads"].append(_joy_axis(JOY_AXIS_TRIGGER_LEFT, 0.5))
	jumper_scheme["reload"].append(_joy_button(JOY_BUTTON_X))
	jumper_scheme["interact"].append(_joy_button(JOY_BUTTON_X))
	jumper_scheme["melee"].append(_joy_button(JOY_BUTTON_RIGHT_STICK))
	jumper_scheme["grenade"].append(_joy_button(JOY_BUTTON_RIGHT_SHOULDER))
	jumper_scheme["ult"].append(_joy_button(JOY_BUTTON_A))
	jumper_scheme["switch_weapon"].append(_joy_button(JOY_BUTTON_Y))

	return {
		"Default": default_scheme,
		"Jumper": jumper_scheme,
	}


static func _key(keycode: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = keycode
	return e


static func _mouse(button: MouseButton) -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = button
	return e


static func _joy_button(button: JoyButton) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


static func _joy_axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
