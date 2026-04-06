extends Area3D

@export var orb_type: String = "health"  # "health" | "energy"
@export var restore_amount: int = 15

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	collision_layer = 2   # Layer 2 (Floor) — picked up by player
	collision_mask = 4    # Layer 3 (Player)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	# Only collectible in Ground Mode
	var ground_state := body.get_node_or_null("StateGround")
	if not ground_state:
		return
	if body.current_state != ground_state:
		return

	if orb_type == "health":
		body.health = min(body.health + restore_amount, 100)
		EventBus.player_health_changed.emit(body.health)
	else:
		body.energy = min(body.energy + restore_amount, 100)
		EventBus.player_energy_changed.emit(body.energy)

	queue_free()
