extends Node

const HEALTH_ORB_SCENE = preload("res://scenes/pickups/health_orb.tscn")
const ENERGY_ORB_SCENE = preload("res://scenes/pickups/energy_orb.tscn")
const FLOOR_Y := 0.4

func _ready() -> void:
	EventBus.enemy_died.connect(_on_enemy_died)

func _on_enemy_died(_enemy_type: String, world_pos: Vector3, over_pit: bool) -> void:
	if over_pit:
		return

	# Freeze-frame on kill
	Engine.time_scale = 0.05
	get_tree().create_timer(0.05, true).timeout.connect(_restore_time_scale)

	# Spawn orb at floor position
	var orb
	if randi() % 2 == 0:
		orb = HEALTH_ORB_SCENE.instantiate()
	else:
		orb = ENERGY_ORB_SCENE.instantiate()

	get_parent().add_child(orb)
	orb.global_position = Vector3(world_pos.x, FLOOR_Y, world_pos.z)

func _restore_time_scale() -> void:
	Engine.time_scale = 1.0
