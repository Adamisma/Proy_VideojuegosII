class_name HUD
extends CanvasLayer

## Interfaz de Usuario durante la partida (HUD)

signal restart_requested
signal main_menu_requested

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/TopBar/HealthLabel
@onready var kills_label: Label = $MarginContainer/VBoxContainer/TopBar/KillsLabel
@onready var objective_label: Label = $MarginContainer/VBoxContainer/ObjectiveLabel

@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var victory_panel: PanelContainer = $VictoryPanel

var _enemies_defeated: int = 0

func _ready() -> void:
	game_over_panel.visible = false
	victory_panel.visible = false
	_update_kills_label()
	
	# Conectar botones de Game Over
	$GameOverPanel/VBoxContainer/HBoxContainer/BtnRestart.pressed.connect(_on_restart_pressed)
	$GameOverPanel/VBoxContainer/HBoxContainer/BtnMenu.pressed.connect(_on_menu_pressed)
	
	# Conectar botones de Victoria
	$VictoryPanel/VBoxContainer/HBoxContainer/BtnVictoryRestart.pressed.connect(_on_restart_pressed)
	$VictoryPanel/VBoxContainer/HBoxContainer/BtnVictoryMenu.pressed.connect(_on_menu_pressed)

func update_health(current: int, maximum: int) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	if health_label:
		health_label.text = "Salud: %d / %d" % [current, maximum]

func add_enemy_defeated() -> void:
	_enemies_defeated += 1
	_update_kills_label()

func _update_kills_label() -> void:
	if kills_label:
		kills_label.text = "Enemigos Derrotados: %d" % _enemies_defeated

func show_game_over() -> void:
	game_over_panel.visible = true

func show_victory() -> void:
	victory_panel.visible = true

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_menu_pressed() -> void:
	main_menu_requested.emit()
