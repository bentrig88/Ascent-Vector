extends Node3D

func _ready() -> void:
	# Deferred so all children finish _ready() before wave starts
	call_deferred("_start_game")

func _start_game() -> void:
	var wave_manager := get_node_or_null("WaveManager")
	if wave_manager:
		wave_manager.start_next_wave()
