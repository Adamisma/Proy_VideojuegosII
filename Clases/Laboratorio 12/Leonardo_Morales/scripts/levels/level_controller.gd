class_name LevelController
extends Node2D

## ====================================================================
## Laboratorio 12 - Secciones 13, 14 & 15: LevelController
## ====================================================================
## Administra la orquestación del nivel:
## 1. Descubre y registra todos los Checkpoints mediante el grupo "checkpoint".
## 2. Consulta GameState.active_checkpoint_id para posicionar al jugador.
## 3. Si el checkpoint no existe o es nulo, recurre de forma segura a DefaultSpawn.
## 4. Escucha activación de checkpoints para actualizar GameState y lanzar autosave.

@export var level_id: StringName = &"level_01"
@export var next_level_id: StringName = &"level_02"

@onready var player: Player = get_node_or_null("Player")
@onready var default_spawn: Marker2D = get_node_or_null("DefaultSpawn")
@onready var hud: HUD = get_node_or_null("HUD")

var checkpoint_positions: Dictionary = {}

func _ready() -> void:
	if GameState:
		GameState.current_level_id = level_id

	_register_checkpoints()
	_spawn_player_from_state()

	if hud and player:
		hud.bind_player(player)

	if player:
		player.respawn_requested.connect(_on_player_respawn_requested)

func _unhandled_input(event: InputEvent) -> void:
	# [R] Reaparición rápida en checkpoint activo
	if event.is_action_pressed("restart"):
		_on_player_respawn_requested()

	# [Escape] Pausa o regreso al Menú Principal
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if SceneFlow:
			SceneFlow.change_to("res://ui/main_menu.tscn", 0.25)

## Sección 13: Registro dinámico de checkpoints en la escena
func _register_checkpoints() -> void:
	checkpoint_positions.clear()
	for node in get_tree().get_nodes_in_group("checkpoint"):
		var checkpoint := node as Checkpoint
		if checkpoint == null:
			continue

		var spawn_pos: Vector2 = checkpoint.spawn_point.global_position if checkpoint.spawn_point else checkpoint.global_position
		checkpoint_positions[checkpoint.checkpoint_id] = spawn_pos
		checkpoint.activated.connect(_on_checkpoint_activated)

## Sección 14: Selección segura del punto de aparición
func _spawn_player_from_state() -> void:
	if player == null:
		return

	var spawn_position := default_spawn.global_position if default_spawn else Vector2(100, 400)
	var cp_id := GameState.active_checkpoint_id if GameState else &""

	if cp_id != &"" and checkpoint_positions.has(cp_id):
		spawn_position = checkpoint_positions[cp_id]
	elif cp_id != &"":
		push_warning("LevelController: Checkpoint '%s' no encontrado. Usando DefaultSpawn." % String(cp_id))

	if player.has_method("respawn_at"):
		player.respawn_at(spawn_position)
	else:
		player.global_position = spawn_position
		player.velocity = Vector2.ZERO

	if hud and hud.game_over_panel:
		hud.game_over_panel.visible = false

## Sección 15: Activar checkpoint y autosave
func _on_checkpoint_activated(checkpoint_id: StringName, _spawn_position: Vector2) -> void:
	if GameState:
		GameState.set_checkpoint(checkpoint_id)

	if SaveManager:
		var success := SaveManager.save_game()
		if not success:
			push_warning("LevelController: No se pudo completar autosave.")

func _on_player_respawn_requested() -> void:
	_spawn_player_from_state()
