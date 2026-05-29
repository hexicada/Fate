extends RefCounted
class_name PlayerLocomotionState

enum Value {
	STANDING,
	SPRINTING,
	CROUCHED,
	SLIDING,
	AIRBORNE,
	MANTLING,
}


static func name_for(state: int) -> String:
	match state:
		Value.STANDING:
			return "Standing"
		Value.SPRINTING:
			return "Sprinting"
		Value.CROUCHED:
			return "Crouched"
		Value.SLIDING:
			return "Sliding"
		Value.AIRBORNE:
			return "Airborne"
		Value.MANTLING:
			return "Mantling"
		_:
			return "Unknown"
