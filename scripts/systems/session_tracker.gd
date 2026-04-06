extends Node

var waves_survived: int = 0
var _start_ticks: int = 0

func _ready() -> void:
	add_to_group("session_tracker")
	_start_ticks = Time.get_ticks_msec()
	EventBus.wave_cleared.connect(_on_wave_cleared)

func get_elapsed_seconds() -> float:
	return (Time.get_ticks_msec() - _start_ticks) / 1000.0

func reset() -> void:
	waves_survived = 0
	_start_ticks = Time.get_ticks_msec()

func _on_wave_cleared(_wave_number: int) -> void:
	waves_survived += 1
