extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var energy_bar: ProgressBar = $EnergyBar
@onready var wave_label: Label = $WaveLabel

func _ready() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_energy_changed.connect(_on_energy_changed)
	EventBus.wave_started.connect(_on_wave_started)

	# Health bar: green
	var health_fill := StyleBoxFlat.new()
	health_fill.bg_color = Color(0.2, 0.8, 0.2)
	health_bar.add_theme_stylebox_override("fill", health_fill)
	var health_bg := StyleBoxFlat.new()
	health_bg.bg_color = Color(0.15, 0.15, 0.15)
	health_bar.add_theme_stylebox_override("background", health_bg)

	# Energy bar: yellow
	var energy_fill := StyleBoxFlat.new()
	energy_fill.bg_color = Color(0.95, 0.85, 0.15)
	energy_bar.add_theme_stylebox_override("fill", energy_fill)
	var energy_bg := StyleBoxFlat.new()
	energy_bg.bg_color = Color(0.15, 0.15, 0.15)
	energy_bar.add_theme_stylebox_override("background", energy_bg)

func _on_health_changed(new_health: int) -> void:
	health_bar.value = new_health

func _on_energy_changed(new_energy: int) -> void:
	energy_bar.value = new_energy
	# Low energy warning: flash below 20
	if new_energy < 20:
		var alpha := (sin(Time.get_ticks_msec() * 0.01) + 1.0) * 0.5
		energy_bar.modulate = Color(1.0, 0.4, 0.1, 0.5 + alpha * 0.5)
	else:
		energy_bar.modulate = Color.WHITE

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Wave %d" % wave_number
