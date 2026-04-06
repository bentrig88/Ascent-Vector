extends Area3D

const RECHARGE_RATE := 25.0
const LOCK_IN_TIME := 0.5

var _player: CharacterBody3D = null
var _is_in_use: bool = false
var _lock_in_timer: float = 0.0
var _energy_at_start: int = 0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if not _is_in_use or not _player:
		return

	# Recharge
	var old_energy: int = _player.energy
	_player.energy = min(_player.energy + int(RECHARGE_RATE * delta), 100)
	if _player.energy != old_energy:
		EventBus.player_energy_changed.emit(_player.energy)

	# Lock-in phase
	if _lock_in_timer > 0.0:
		_lock_in_timer -= delta
		return

	# After lock-in: any input cancels
	if Input.is_anything_pressed():
		unplug()

func _on_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	if _is_in_use:
		return
	if body.energy == 100:
		return

	_player = body
	_is_in_use = true
	_lock_in_timer = LOCK_IN_TIME
	_energy_at_start = _player.energy
	_player.block_input()
	EventBus.player_plugged_in.emit()

func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		unplug()

func unplug() -> void:
	if not _is_in_use:
		return
	var energy_gained := float(_player.energy - _energy_at_start) if _player else 0.0
	_is_in_use = false
	if _player:
		_player.unblock_input()
		EventBus.player_unplugged.emit(energy_gained)
	_player = null
