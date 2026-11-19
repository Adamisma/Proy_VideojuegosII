extends Node2D

## ====================================================================
## Laboratorio 06: Escena de Pruebas de Combate (Combat QA Lab) - Sección 28
## ====================================================================
## Entorno controlado para validar:
## 1. Activación de hitbox de ataque (espada)
## 2. Daño y reducción reactiva en EnemyDummy
## 3. already_hit con múltiples objetivos en un mismo swing
## 4. Daño por contacto e invulnerabilidad en el jugador
## 5. HUD de vida reactivo
## 6. Flujo de muerte y reaparición con vida restaurada

@onready var player: CharacterBody2D = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var health_hud: Control = $UI/HealthHUD
@onready var victory_panel: PanelContainer = $UI/VictoryPanel
@onready var checkpoint_status_label: Label = $UI/HUD/HBoxContainer/CheckpointStatus

var respawn_position: Vector2
var checkpoints_activated: int = 0

func _ready() -> void:
	if player_spawn:
		respawn_position = player_spawn.global_position
	else:
		respawn_position = player.global_position

	# Vincular el HUD reactivo al HealthComponent del Player (Sección 21)
	if health_hud and player.has_node("HealthComponent"):
		health_hud.bind_health_component(player.get_node("HealthComponent"))

	# Conectar solicitud de respawn del Player al morir (Sección 26 y 27)
	player.respawn_requested.connect(_on_player_respawn_requested)

	_connect_checkpoints()
	_connect_goals()

	if victory_panel:
		victory_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		get_tree().reload_current_scene()

func _connect_checkpoints() -> void:
	for checkpoint in get_tree().get_nodes_in_group("checkpoint"):
		if not checkpoint.activated.is_connected(_on_checkpoint_activated):
			checkpoint.activated.connect(_on_checkpoint_activated)

func _connect_goals() -> void:
	for goal in get_tree().get_nodes_in_group("goal"):
		if not goal.goal_reached.is_connected(_on_goal_reached):
			goal.goal_reached.connect(_on_goal_reached)

func _on_checkpoint_activated(new_spawn_pos: Vector2) -> void:
	respawn_position = new_spawn_pos
	checkpoints_activated += 1
	if checkpoint_status_label:
		checkpoint_status_label.text = "Checkpoints: %d/2" % checkpoints_activated

func _on_goal_reached() -> void:
	if victory_panel:
		victory_panel.visible = true
	print("[CombatLab] ¡Todas las pruebas de combate superadas con éxito!")

## Sección 27: Flujo de respawn limpio
func _on_player_respawn_requested() -> void:
	player.respawn_at(respawn_position)
