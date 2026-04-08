extends CharacterBody3D
class_name Entity

## Base class for all game entities (player and enemies).
## Provides shared health, knockback, and pit fall logic.

var health: int = 100
var knockback_cooldown: float = 0.0

var _is_falling_in_pit: bool = false

func _get_max_health() -> int:
	return 100

## Override in subclasses to define which collision layer bit to disable when falling.
func _get_collision_layer_bit() -> int:
	return 1

## Shared pit fall animation. Calls _on_pit_fall_finished() when done.
func die_in_pit() -> void:
	if _is_falling_in_pit:
		return
	_is_falling_in_pit = true
	set_collision_layer_value(_get_collision_layer_bit(), false)
	velocity = Vector3.ZERO
	_on_pit_fall_started()

	var tween := create_tween()
	tween.tween_property(self, "global_position:y", global_position.y - 3.0, 0.6).set_ease(Tween.EASE_IN)
	tween.tween_callback(_on_pit_fall_finished)

## Called when the fall tween starts. Override for pre-fall setup.
func _on_pit_fall_started() -> void:
	pass

## Called when the fall tween finishes. Override for death/respawn logic.
func _on_pit_fall_finished() -> void:
	pass
