extends Camera3D

const GROUND_ZOOM := 12.0
const AIR_ZOOM := 16.0
const FOLLOW_SPEED := 5.0
const ZOOM_SPEED := 0.5
const ROOM_HALF_SIZE := 9.0  # half of 10-tile * 2 units room

var _target: Node3D = null
var _target_zoom: float = GROUND_ZOOM
var _current_zoom: float = GROUND_ZOOM
var _zoom_elapsed: float = 0.0

# Screen shake
var _shake_timer: float = 0.0
var _shake_intensity: float = 0.0
var _base_position: Vector3 = Vector3.ZERO

## Computed in _ready from the camera's actual back direction so the player stays centered.
var _camera_offset := Vector3.ZERO

func _ready() -> void:
	projection = PROJECTION_ORTHOGONAL
	size = GROUND_ZOOM
	# 45° isometric rotation: Y=45, X=30
	rotation_degrees = Vector3(-30.0, 45.0, 0.0)

	EventBus.player_state_changed.connect(_on_player_state_changed)
	_target = get_parent()
	# Detach from parent so the camera doesn't inherit the player's transform
	top_level = true
	# Compute offset along the camera's back direction so the target stays centered
	var back_dir := global_transform.basis.z  # local +Z = away from where camera looks
	_camera_offset = back_dir * 40.0

func start_shake(duration: float, intensity: float) -> void:
	_shake_timer = duration
	_shake_intensity = intensity

func _process(delta: float) -> void:
	if not _target:
		return

	# Soft-follow with lerp
	var target_pos := _target.global_position
	var clamped := Vector3(
		clamp(target_pos.x, -ROOM_HALF_SIZE, ROOM_HALF_SIZE),
		target_pos.y,
		clamp(target_pos.z, -ROOM_HALF_SIZE, ROOM_HALF_SIZE)
	)
	_base_position = _base_position.lerp(clamped, FOLLOW_SPEED * delta)

	# Screen shake
	var shake_offset := Vector3.ZERO
	if _shake_timer > 0.0:
		_shake_timer -= delta
		shake_offset = Vector3(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		if _shake_timer <= 0.0:
			_shake_timer = 0.0

	global_position = _base_position + _camera_offset + shake_offset

	# Zoom interpolation using smoothstep
	_zoom_elapsed += delta
	var t: float = clamp(_zoom_elapsed / ZOOM_SPEED, 0.0, 1.0)
	var smooth_t: float = t * t * (3.0 - 2.0 * t)
	_current_zoom = lerp(_current_zoom, _target_zoom, smooth_t)
	size = _current_zoom

func _on_player_state_changed(new_state: String) -> void:
	if new_state == "air":
		_target_zoom = AIR_ZOOM
	else:
		_target_zoom = GROUND_ZOOM
	_zoom_elapsed = 0.0
	_current_zoom = size
