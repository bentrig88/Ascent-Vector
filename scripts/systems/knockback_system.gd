extends Node

const TILE_SIZE := 2.0

func _ready() -> void:
	add_to_group("knockback_system")

func apply(target: Node3D, force_tiles: float, source_pos: Vector3) -> void:
	if not target is CharacterBody3D:
		return

	var body := target as CharacterBody3D

	# Skip knockback if on cooldown (damage still applies, handled by caller)
	if body.get("knockback_cooldown") != null and body.knockback_cooldown > 0.0:
		return

	# Direction is XZ only
	var delta_pos := target.global_position - source_pos
	delta_pos.y = 0.0
	if delta_pos.length_squared() < 0.0001:
		delta_pos = Vector3.FORWARD

	var direction := delta_pos.normalized()
	var mass: float = body.get("mass") if body.get("mass") != null else 1.0
	var impulse := direction * (force_tiles * TILE_SIZE / mass)

	body.velocity += impulse

	if body.get("knockback_cooldown") != null:
		body.knockback_cooldown = 0.3

	# Check if displacement lands target in a pit
	var gm := get_tree().get_first_node_in_group("grid_manager")
	if gm and gm.is_over_pit(target.global_position):
		if target.has_method("trigger_fall_sequence"):
			target.trigger_fall_sequence()
		elif target.has_method("die_in_pit"):
			target.die_in_pit()
