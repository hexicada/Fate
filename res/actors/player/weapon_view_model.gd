extends Node3D
class_name WeaponViewModel

@export_group("Weapon Identity")
@export var weapon_name: String = "Weapon"

@export_group("Pose Offsets")
@export var hip_offset := Vector3.ZERO
@export var ads_offset := Vector3.ZERO
@export var pose_lerp_speed := 16.0

@export_group("Animation Names")
@export var anim_idle: StringName = &"idle"
@export var anim_fire: StringName = &"fire"
@export var anim_reload: StringName = &"reload"
@export var anim_ads_in: StringName = &"ads_in"
@export var anim_ads_out: StringName = &"ads_out"
@export var anim_equip: StringName = &"equip"

enum Pose {
	HIP,
	ADS,
}

var _current_pose: Pose = Pose.HIP
var _anim_player: AnimationPlayer


func _ready() -> void:
	_anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	position = hip_offset
	_play_anim(anim_equip)
	if not anim_equip:
		_play_anim(anim_idle)


func _process(delta: float) -> void:
	var target_offset := ads_offset if _current_pose == Pose.ADS else hip_offset
	var blend := clampf(pose_lerp_speed * delta, 0.0, 1.0)
	position = position.lerp(target_offset, blend)


func set_pose(pose: Pose) -> void:
	if _current_pose == pose:
		return

	_current_pose = pose
	if _current_pose == Pose.ADS:
		_play_anim(anim_ads_in)
	else:
		_play_anim(anim_ads_out)
		if _anim_player and anim_idle:
			_anim_player.queue(anim_idle)


func set_pose_name(pose_name: String) -> void:
	match pose_name.to_lower():
		"ads":
			set_pose(Pose.ADS)
		"hip":
			set_pose(Pose.HIP)
		_:
			push_warning("WeaponViewModel.set_pose_name: unknown pose '%s'" % pose_name)


func on_fire() -> void:
	_play_anim(anim_fire)
	_on_fire()


func on_reload() -> void:
	_play_anim(anim_reload)
	_on_reload()


func get_pose_name() -> String:
	return "ads" if _current_pose == Pose.ADS else "hip"


func _on_fire() -> void:
	pass


func _on_reload() -> void:
	pass


func _play_anim(anim_name: StringName) -> void:
	if not anim_name:
		return
	if _anim_player and _anim_player.has_animation(anim_name):
		_anim_player.play(anim_name)
