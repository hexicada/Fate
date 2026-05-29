extends Node
class_name PlayerCombatBridge

enum WeaponReadiness {
	READY,
	LOWERED,
	SLIDE,
}

var readiness := WeaponReadiness.READY


func update_from_locomotion_state(state: int) -> void:
	match state:
		PlayerLocomotionState.Value.SPRINTING:
			readiness = WeaponReadiness.LOWERED
		PlayerLocomotionState.Value.SLIDING:
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
