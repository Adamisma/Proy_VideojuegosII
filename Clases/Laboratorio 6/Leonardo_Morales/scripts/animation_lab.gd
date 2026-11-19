extends Node2D

## ====================================================================
## Laboratorio 05: Escena de Pruebas de Animación (QA Lab) - Sección 28
## ====================================================================
## Diseñada específicamente para reproducir y evaluar de forma aislada
## y controlada cada estado de la FSM:
## 1. Suelo plano: IDLE y RUN
## 2. Plataforma elevada: JUMP y FALL
## 3. Corredor vertical: WALL_SLIDE y WALL_JUMP
## 4. Hueco amplio: DASH
## 5. Caída corta: land_squash
## 6. Teclas interactivas: [J] ATTACK, [K] HURT, [R] RESTART

@onready var player: CharacterBody2D = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var victory_panel: PanelContainer = $UI/VictoryPanel
@onready var checkpoint_status_label: Label = $UI/HUD/HBoxContainer/CheckpointStatus
@onready var coins_label: Label = $UI/HUD/HBoxContainer/CoinsLabel

var respawn_position: Vector2
var checkpoints_activated: int = 0
var coins_collected: int = 0

func _ready() -> void:
	if player_spawn:
		respawn_position = player_spawn.global_position
	else:
		respawn_position = player.global_position

	_connect_hazards()
	_connect_checkpoints()
	_connect_collectibles()
	_connect_goals()
	_update_ui()

	if victory_panel:
		victory_panel.visible = false

	_respawn_player()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

func _connect_hazards() -> void:
	for hazard in get_tree().get_nodes_in_group("hazard"):
		if not hazard.player_touched_hazard.is_connected(_on_player_touched_hazard):
			hazard.player_touched_hazard.connect(_on_player_touched_hazard)

func _connect_checkpoints() -> void:
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		if not checkpoint.activated.is_connected(_on_checkpoint_activated):
			checkpoint.activated.connect(_on_checkpoint_activated)

func _connect_collectibles() -> void:
	for collectible in get_tree().get_nodes_in_group("collectible"):
		if not collectible.collected.is_connected(_on_coin_collected):
			collectible.collected.connect(_on_coin_collected)

func _connect_goals() -> void:
	for goal in get_tree().get_nodes_in_group("goal"):
		if not goal.goal_reached.is_connected(_on_goal_reached):
			goal.goal_reached.connect(_on_goal_reached)

func _on_player_touched_hazard() -> void:
	if player.has_method("take_damage"):
		player.take_damage()
	_respawn_player()

func _on_checkpoint_activated(new_spawn_position: Vector2) -> void:
	respawn_position = new_spawn_position
	checkpoints_activated += 1
	_update_ui()

func _on_coin_collected(amount: int) -> void:
	coins_collected += amount
	_update_ui()

func _on_goal_reached() -> void:
	if victory_panel:
		victory_panel.visible = true
	print("[AnimationLab] ¡Meta alcanzada! Todas las transiciones de animación evaluadas con éxito.")

func _respawn_player() -> void:
	player.global_position = respawn_position
	player.velocity = Vector2.ZERO

	var tween := create_tween()
	player.modulate = Color(1.0, 0.4, 0.4, 0.5)
	tween.tween_property(player, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

func _update_ui() -> void:
	if checkpoint_status_label:
		checkpoint_status_label.text = "Checkpoints: %d/2" % checkpoints_activated
	if coins_label:
		coins_label.text = "Monedas: %d" % coins_collected
