extends CharacterBody3D

const SPEED := 18.0
const ROOM_HALF_SIZE := 12.0

var direction: Vector3 = Vector3.FORWARD

func _ready() -> void:
	collision_layer = 64   # Layer 7 (Projectile) = bit 6 = 64
	collision_mask = 25    # Walls + Grunt + Drone = 1+8+16 = 25
	# Make projectile visible with a bright yellow color
	var mesh := get_node_or_null("MeshInstance3D") as MeshInstance3D
	if mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 1.0, 0.2)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 1.0, 0.2)
		mat.emission_energy_multiplier = 2.0
		mesh.set_surface_override_material(0, mat)

func _physics_process(delta: float) -> void:
	velocity = direction * SPEED
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		if collider and collider.has_method("take_damage"):
			collider.take_damage(8)
			var kb_system := get_tree().get_first_node_in_group("knockback_system")
			if kb_system:
				kb_system.apply(collider, 0.1, global_position)
		queue_free()
		return

	# Destroy on room boundary
	var pos := global_position
	if abs(pos.x) > ROOM_HALF_SIZE or abs(pos.z) > ROOM_HALF_SIZE:
		queue_free()
