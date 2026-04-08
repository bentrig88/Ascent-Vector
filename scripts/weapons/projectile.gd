extends CharacterBody3D

const SPEED := 28.0
const DRONE_SPEED := 5.0
const ROOM_HALF_SIZE := 12.0

var direction: Vector3 = Vector3.FORWARD
var is_drone_bullet: bool = false
var _speed: float = SPEED
var _initialized: bool = false

func _ready() -> void:
	collision_layer = 64   # Layer 7 (Projectile) = bit 6 = 64
	collision_mask = 25    # Walls + Grunt + Drone = 1+8+16 = 25
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 0.2)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 1.0, 0.2)
		mat.emission_energy_multiplier = 2.0
		mesh.set_surface_override_material(0, mat)

func _physics_process(delta: float) -> void:
	if not _initialized:
		_initialized = true
		if is_drone_bullet:
			_speed = DRONE_SPEED
			collision_mask = 5  # Walls + Player = 1+4
			var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
			if mesh:
				var mat := StandardMaterial3D.new()
				mat.albedo_color = Color(1.0, 0.3, 0.1)
				mat.emission_enabled = true
				mat.emission = Color(1.0, 0.3, 0.1)
				mat.emission_energy_multiplier = 2.0
				mesh.set_surface_override_material(0, mat)
	velocity = direction * _speed
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		if is_drone_bullet:
			if collider and collider.is_in_group("player"):
				EventBus.player_took_damage.emit(8, global_position)
		else:
			if collider and collider.has_method("take_damage"):
				collider.take_damage(3)
				var kb_system := get_tree().get_first_node_in_group("knockback_system")
				if kb_system:
					kb_system.apply(collider, 0.1, global_position)
		queue_free()
		return

	# Destroy on room boundary
	var pos := global_position
	if abs(pos.x) > ROOM_HALF_SIZE or abs(pos.z) > ROOM_HALF_SIZE:
		queue_free()
