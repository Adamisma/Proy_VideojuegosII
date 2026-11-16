extends Node2D

## Controlador del Nivel 03 - Circuito de Pruebas de Plataformas (Guía Lab 03 - Sec. 19 y 24)

@onready var player: CharacterBody2D = $Player
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var dash_bar: ProgressBar = $CanvasLayer/HUD/VBoxContainer/DashRow/DashProgressBar
@onready var state_label: Label = $CanvasLayer/HUD/VBoxContainer/StateLabel

@export var void_kill_y: float = 850.0

func _ready() -> void:
	if player and spawn_point:
		player.global_position = spawn_point.global_position
		if player.has_signal("dash_cooldown_updated"):
			player.dash_cooldown_updated.connect(_on_dash_cooldown_updated)
		if player.has_signal("movement_state_changed"):
			player.movement_state_changed.connect(_on_movement_state_changed)

func _process(_delta: float) -> void:
	# Reinicio rápido con tecla R
	if Input.is_action_just_pressed("restart") or Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()

	# Reto de ampliación: Detección de caída al vacío con respawn automático (Guía Sec. 24)
	if player and player.global_position.y > void_kill_y:
		_respawn_player()

func _respawn_player() -> void:
	if player and spawn_point:
		if player.has_method("respawn"):
			player.respawn(spawn_point.global_position)
		else:
			player.global_position = spawn_point.global_position
			player.velocity = Vector2.ZERO

func _on_dash_cooldown_updated(remaining: float, total: float) -> void:
	if dash_bar:
		var fill_pct := (1.0 - (remaining / total)) * 100.0 if total > 0.0 else 100.0
		dash_bar.value = fill_pct
		dash_bar.modulate = Color(0.3, 1.0, 0.4) if remaining <= 0.0 else Color(1.0, 0.7, 0.2)

func _on_movement_state_changed(state_name: String) -> void:
	if state_label:
		state_label.text = "Estado: %s" % state_name
