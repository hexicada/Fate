extends Node
class_name PlayerCombatBridge

enum WeaponReadiness {
	READY,
	LOWERED,
	SLIDE,
}

var readiness := WeaponReadiness.READY


func update_from_locomotion_state(state_name: StringName) -> void:
	match state_name:
		"Sprinting":
			readiness = WeaponReadiness.LOWERED
		"Sliding":
			readiness = WeaponReadiness.SLIDE
		_:
			readiness = WeaponReadiness.READY


func readiness_name() -> String:
	match readiness:
		WeaponReadiness.LOWERED:
			return "Lowered"
		WeaponReadiness.SLIDE:
			return "Slide"
		_:
			return "Ready"
