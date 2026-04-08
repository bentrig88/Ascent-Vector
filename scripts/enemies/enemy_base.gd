extends Entity
class_name EnemyBase

## Base class for all enemies. Subclasses override _get_enemy_type(),
## _get_max_health(), _get_collision_layer_bit(), and _get_health_bar_config().

const HEALTH_BAR_SCENE = preload("res://scenes/ui/enemy_health_bar.tscn")

var mass: float = 1.0

var _player: CharacterBody3D = null
var _health_bar: Node3D = null
var _anim_player: AnimationPlayer = null
var _original_body_mat: Material = null
var _stagger_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	health = _get_max_health()

	_anim_player = get_node_or_null("AnimationPlayer") as AnimationPlayer
	var body_mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if body_mesh:
		_original_body_mat = body_mesh.get_surface_override_material(0)

	_create_health_bar()
	call_deferred("_find_systems")
	_enemy_ready()

## Override in subclasses for additional setup.
func _enemy_ready() -> void:
	pass

func _get_enemy_type() -> String:
	return "enemy"

func _get_health_bar_config() -> Dictionary:
	return {
		"color": Color(0.9, 0.15, 0.1),
		"width": 0.6,
		"height": 0.06,
		"y": 1.85,
	}

func _create_health_bar() -> void:
	var config := _get_health_bar_config()
	_health_bar = HEALTH_BAR_SCENE.instantiate()
	_health_bar.bar_color = config["color"]
	_health_bar.bar_width = config["width"]
	_health_bar.bar_height = config["height"]
	_health_bar.max_health = _get_max_health()
	_health_bar.position = Vector3(0.0, config["y"], 0.0)
	add_child(_health_bar)

func _update_health_bar() -> void:
	if _health_bar:
		_health_bar.update_health(health)

func _find_systems() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_find_extra_systems()

## Override in subclasses for additional system lookups.
func _find_extra_systems() -> void:
	pass

func take_damage(amount: int) -> void:
	health -= amount
	_update_health_bar()
	_on_take_damage()
	_stagger_timer = 0.35
	if _anim_player:
		_anim_player.stop()
	_restore_body_material()
	_flash_hit()
	if health <= 0:
		_die()

## Override in subclasses for additional take_damage behavior (e.g. cancel attack).
func _on_take_damage() -> void:
	pass

func _die() -> void:
	var gm := get_tree().get_first_node_in_group("grid_manager")
	var over_pit := false
	if gm:
		over_pit = gm.is_over_pit(global_position)
	EventBus.enemy_died.emit(_get_enemy_type(), global_position, over_pit)
	queue_free()

## Pit fall hooks — called by Entity.die_in_pit()
func _on_pit_fall_started() -> void:
	set_physics_process(false)

func _on_pit_fall_finished() -> void:
	EventBus.enemy_died.emit(_get_enemy_type(), global_position, true)
	queue_free()

func _flash_hit() -> void:
	if _anim_player and _anim_player.has_animation("hit"):
		_anim_player.stop()
		_anim_player.play("hit")
		return
	# Fallback code-based blink for enemies without hit animation
	var mesh := get_node_or_null("MeshInstance3D")
	if not mesh:
		return
	var original_mat: Material = mesh.get_surface_override_material(0)
	var black_mat := StandardMaterial3D.new()
	black_mat.albedo_color = Color(0.05, 0.05, 0.05)
	var white_mat := StandardMaterial3D.new()
	white_mat.albedo_color = Color.WHITE
	for color in [black_mat, white_mat, black_mat, white_mat, black_mat]:
		if not is_instance_valid(self):
			return
		mesh.set_surface_override_material(0, color)
		await get_tree().create_timer(0.05).timeout
	if is_instance_valid(self) and mesh:
		mesh.set_surface_override_material(0, original_mat)

func _restore_body_material() -> void:
	var mesh := get_node_or_null("MeshInstance3D")
	if mesh and _original_body_mat:
		mesh.set_surface_override_material(0, _original_body_mat)
