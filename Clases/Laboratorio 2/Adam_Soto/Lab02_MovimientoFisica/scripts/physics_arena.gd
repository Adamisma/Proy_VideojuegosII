extends Node2D

## Controlador de la escena PhysicsArena (Guía Lab 02 - Sec. 7 y 12)
## Gestiona el HUD de diagnóstico en tiempo real y el reinicio de prueba

@onready var player: CharacterBody2D = $Player
@onready var speed_label: Label = $CanvasLayer/HUDPanel/VBoxContainer/SpeedLabel
@onready var sprint_label: Label = $CanvasLayer/HUDPanel/VBoxContainer/SprintLabel

func _ready() -> void:
	if player and player.has_signal("speed_updated"):
		player.speed_updated.connect(_on_player_speed_updated)

func _unhandled_input(event: InputEvent) -> void:
	# Reinicio rápido de la arena de físicas con tecla [R]
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()

func _on_player_speed_updated(current_speed: float, is_sprinting: bool) -> void:
	if speed_label:
		speed_label.text = "Velocidad: %4.1f px/s" % current_speed
		
	if sprint_label:
		if is_sprinting:
			sprint_label.text = "Estado: [SPRINT ACTIVO]"
			sprint_label.modulate = Color(0.3, 1.0, 0.4)
		else:
			sprint_label.text = "Estado: [Normal - Shift para Sprint]"
			sprint_label.modulate = Color(0.8, 0.8, 0.8)
