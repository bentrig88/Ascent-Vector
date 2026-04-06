extends CanvasLayer

const AUTO_RESTART_DELAY := 4.0

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var waves_label: Label = $VBoxContainer/WavesLabel
@onready var time_label: Label = $VBoxContainer/TimeLabel
@onready var restart_label: Label = $VBoxContainer/RestartLabel

var _restart_timer: float = 0.0
var _active: bool = false

func _ready() -> void:
	visible = false
	EventBus.game_over.connect(_on_game_over)

func _process(delta: float) -> void:
	if not _active:
		return
	_restart_timer -= delta
	restart_label.text = "Restarting in %d..." % max(0, int(_restart_timer) + 1)
	if _restart_timer <= 0.0:
		_active = false
		get_tree().reload_current_scene()

func _on_game_over(waves_survived: int, elapsed_seconds: float) -> void:
	visible = true
	_active = true
	_restart_timer = AUTO_RESTART_DELAY

	var minutes := int(elapsed_seconds) / 60
	var seconds := int(elapsed_seconds) % 60
	waves_label.text = "Waves Survived: %d" % waves_survived
	time_label.text = "Time: %02d:%02d" % [minutes, seconds]
