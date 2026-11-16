extends Node2D

## ====================================================================
## Laboratorio 04: TileSet, TileMapLayer y Construcción de Niveles 2D
## Script de Nivel (Level04)
## ====================================================================
## Administra la orquestación del escenario de forma desacoplada:
## - Punto de inicio y respawn mediante Marker2D y Checkpoints
## - Conexión dinámica por grupos de Hazards (lava, pinchos y vacío)
## - Manejo de victoria (Meta / Goal) y HUD
## - Reinicio rápido con tecla [R]

@onready var player: CharacterBody2D = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var victory_panel: PanelContainer = $UI/VictoryPanel
@onready var victory_label: Label = $UI/VictoryPanel/VBox/VictoryLabel
@onready var checkpoint_status_label: Label = $UI/HUD/HBoxContainer/CheckpointStatus
@onready var coins_label: Label = $UI/HUD/HBoxContainer/CoinsLabel

var respawn_position: Vector2
var checkpoints_activated: int = 0
var coins_collected: int = 0

func _ready() -> void:
	# Inicializar punto de reaparición semántico (Sección 15)
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

## Conexión desacoplada de peligros mediante grupos (Sección 17)
func _connect_hazards() -> void:
	for hazard in get_tree().get_nodes_in_group("hazard"):
		if not hazard.player_touched_hazard.is_connected(_on_player_touched_hazard):
			hazard.player_touched_hazard.connect(_on_player_touched_hazard)

## Conexión desacoplada de checkpoints mediante grupos (Sección 18.3)
func _connect_checkpoints() -> void:
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		if not checkpoint.activated.is_connected(_on_checkpoint_activated):
			checkpoint.activated.connect(_on_checkpoint_activated)

## Conexión de monedas coleccionables (Reto 26)
func _connect_collectibles() -> void:
	for collectible in get_tree().get_nodes_in_group("collectible"):
		if not collectible.collected.is_connected(_on_coin_collected):
			collectible.collected.connect(_on_coin_collected)

## Conexión de la meta final (Reto 26)
func _connect_goals() -> void:
	for goal in get_tree().get_nodes_in_group("goal"):
		if not goal.goal_reached.is_connected(_on_goal_reached):
			goal.goal_reached.connect(_on_goal_reached)

## Callback al entrar en contacto con una trampa / vacío
func _on_player_touched_hazard() -> void:
	_respawn_player()

## Callback al activar un nuevo punto de control
func _on_checkpoint_activated(new_spawn_position: Vector2) -> void:
	respawn_position = new_spawn_position
	checkpoints_activated += 1
	_update_ui()

## Callback al recoger moneda
func _on_coin_collected(amount: int) -> void:
	coins_collected += amount
	_update_ui()

## Callback al alcanzar la meta
func _on_goal_reached() -> void:
	if victory_panel:
		victory_panel.visible = true
	print("[Level04] ¡Meta alcanzada! ¡Felicidades, nivel completado!")

## Respawn sin números mágicos y con reinicio de física (Sección 19 & Reto 26)
func _respawn_player() -> void:
	player.global_position = respawn_position
	player.velocity = Vector2.ZERO

	# Reto 26: Transición visual breve de parpadeo durante respawn
	var tween := create_tween()
	player.modulate = Color(1.0, 0.4, 0.4, 0.5)
	tween.tween_property(player, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.25)

## Actualiza información en el HUD
func _update_ui() -> void:
	if checkpoint_status_label:
		checkpoint_status_label.text = "Checkpoints: %d/2" % checkpoints_activated
	if coins_label:
		coins_label.text = "Monedas: %d" % coins_collected
