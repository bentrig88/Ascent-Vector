extends Area3D

var _active_timer: float = 0.0
var _is_active: bool = false
var _player: CharacterBody3D = null
var _hit_bodies: Array = []
var _visual: MeshInstance3D = null

func _ready() -> void:
	collision_layer = 32   # Layer 6 (PlayerMelee) = bit 5 = 32
	collision_mask = 24    # Layer 4+5 (Grunt + Drone) = 8+16 = 24
	monitoring = false
	_player = get_parent()
	body_entered.connect(_on_body_entered)

	# Create a visual indicator for the spin (ring around player)
	_visual = MeshInstance3D.new()
	var torus := CylinderMesh.new()
	torus.top_radius = 2.0
	torus.bottom_radius = 2.0
	torus.height = 0.2
	_visual.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.6, 1.0, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_visual.set_surface_override_material(0, mat)
	_visual.visible = false
	add_child(_visual)

func activate(duration: float) -> void:
	_active_timer = duration
	_is_active = true
	_hit_bodies.clear()
	monitoring = true
	# Center on player
	position = Vector3(0.0, 0.8, 0.0)
	if _visual:
		_visual.visible = true

func _physics_process(delta: float) -> void:
	if not _is_active:
		return
	_active_timer -= delta
	if _active_timer <= 0.0:
		_is_active = false
		monitoring = false
		_hit_bodies.clear()
		if _visual:
			_visual.visible = false

func _on_body_entered(body: Node3D) -> void:
	if not _is_active or body in _hit_bodies:
		return
	_hit_bodies.append(body)

	if body.has_method("take_damage"):
		body.take_damage(25)

	# Screen shake
	var cam := _player.get_node_or_null("ProxyCamera")
	if cam and cam.has_method("start_shake"):
		cam.start_shake(0.10, 0.10)

	_player.energy = max(_player.energy - 20, 0)
	EventBus.player_energy_changed.emit(_player.energy)

	var kb_system := get_tree().get_first_node_in_group("knockback_system")
	if kb_system:
		kb_system.apply(body, 1.5, _player.global_position)
