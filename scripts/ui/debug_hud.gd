extends CanvasLayer

const GRUNT_SCENE = preload("res://scenes/enemies/grunt.tscn")
const DRONE_SCENE = preload("res://scenes/enemies/drone.tscn")

var _god_mode: bool = false
var _infinite_energy: bool = false
var _visible: bool = false

@onready var stats_label: Label = $StatsPanel/StatsLabel
@onready var panel: Control = $StatsPanel

func _ready() -> void:
	visible = false
	panel.visible = false
	# Wire buttons
	$ButtonContainer/SpawnGruntBtn.pressed.connect(spawn_grunt)
	$ButtonContainer/SpawnDroneBtn.pressed.connect(spawn_drone)
	$ButtonContainer/KillAllBtn.pressed.connect(kill_all_enemies)
	$ButtonContainer/GodModeBtn.pressed.connect(toggle_god_mode)
	$ButtonContainer/InfEnergyBtn.pressed.connect(toggle_infinite_energy)
	$ButtonContainer/ResetFloorBtn.pressed.connect(reset_floor)
	$ButtonContainer/HitboxesBtn.pressed.connect(toggle_hitboxes)

func _process(_delta: float) -> void:
	_update_stats()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_TAB:
		_visible = not _visible
		visible = _visible
		panel.visible = _visible

func _update_stats() -> void:
	if not _visible:
		return
	var player := get_tree().get_first_node_in_group("player")
	var wm := get_tree().get_first_node_in_group("wave_manager")
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	var gm := get_tree().get_first_node_in_group("grid_manager")

	var hp: int = player.health if player else 0
	var energy: int = player.energy if player else 0
	var wave: int = wm.wave_number if wm else 0

	stats_label.text = (
		"HP: %d  Energy: %d\nWave: %d  Enemies: %d\nGod: %s  Inf.Energy: %s" % [
			hp, energy, wave, enemy_count,
			"ON" if _god_mode else "OFF",
			"ON" if _infinite_energy else "OFF"
		]
	)

func spawn_grunt() -> void:
	var grunt := GRUNT_SCENE.instantiate()
	grunt.global_position = Vector3(randf_range(-8, 8), 0.5, randf_range(-8, 8))
	get_tree().current_scene.add_child(grunt)

func spawn_drone() -> void:
	var drone := DRONE_SCENE.instantiate()
	drone.global_position = Vector3(randf_range(-8, 8), 2.0, randf_range(-8, 8))
	get_tree().current_scene.add_child(drone)

func kill_all_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy.has_method("_die"):
			enemy._die()
		else:
			enemy.queue_free()

func toggle_god_mode() -> void:
	_god_mode = not _god_mode
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.is_invincible = _god_mode
		player.god_mode = _god_mode

func toggle_infinite_energy() -> void:
	_infinite_energy = not _infinite_energy
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.infinite_energy = _infinite_energy

func reset_floor() -> void:
	get_tree().reload_current_scene()

func toggle_hitboxes() -> void:
	get_tree().debug_collisions_hint = not get_tree().debug_collisions_hint
