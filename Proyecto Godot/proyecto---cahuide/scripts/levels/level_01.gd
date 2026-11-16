class_name Level01
extends Node2D

## ====================================================================
## Proyecto Cahuide - Nivel 1: "🌅 El Despertar de la Resistencia"
## ====================================================================
## Fortaleza ancestral de Sacsayhuamán.
## - Orquesta Checkpoints con reaparición segura.
## - Victoria al alcanzar el Trofeo Sagrado al final del nivel.
## - Reliquias como coleccionables opcionales con bonificación de puntuación.
## - Integración desacoplada con EventBus, GameState y SaveManager.

@export var level_id: StringName = &"level_01"
@export var sky_speed: float = 15.0

@onready var player: Player = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var hud: HUD = get_node_or_null("HUD")
@onready var ui_controller: UIController = get_node_or_null("UIController")
@onready var enemies_container: Node2D = get_node_or_null("Enemies")
@onready var sky_layer: ParallaxLayer = get_node_or_null("ParallaxBackground/ParallaxLayer_Cielo")
@onready var goal: LevelGoal = get_node_or_null("LevelGoal")

var checkpoint_positions: Dictionary = {}
var total_relics: int = 0
var collected_relics: int = 0

func _ready() -> void:
	if GameState:
		GameState.current_level_id = level_id

	_register_checkpoints()
	_spawn_player_from_state()

	# Conexión del jugador
	if player:
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
		player.respawn_requested.connect(respawn_player_at_checkpoint)

	# Conexión con HUD / UI
	var active_hud: HUD = hud
	if active_hud == null and ui_controller:
		active_hud = ui_controller.get_node_or_null("HUD") as HUD

	if active_hud:
		active_hud.restart_requested.connect(_on_restart_level)
		active_hud.main_menu_requested.connect(_on_return_main_menu)
		if player:
			active_hud.bind_player(player)

	# Configurar reliquias y meta final
	_setup_relics()
	_setup_level_goal()

	# Conectar enemigos del nivel mediante Patrón Observador
	if enemies_container:
		for child in enemies_container.get_children():
			if child is Enemy:
				_register_enemy(child)

		enemies_container.child_entered_tree.connect(func(node: Node) -> void:
			if node is Enemy:
				_register_enemy(node)
		)

	# Suscripción a eventos de completitud
	if EventBus:
		EventBus.level_completed.connect(func(_id: StringName):
			if active_hud:
				active_hud.show_victory()
		)

func _register_checkpoints() -> void:
	checkpoint_positions.clear()
	for node in get_tree().get_nodes_in_group("checkpoint"):
		var cp := node as Checkpoint
		if cp == null:
			continue
		var spawn_pos: Vector2 = cp.spawn_point.global_position if cp.spawn_point else cp.global_position
		checkpoint_positions[cp.checkpoint_id] = spawn_pos
		cp.activated.connect(_on_checkpoint_activated)

func _spawn_player_from_state() -> void:
	if player == null:
		return

	var spawn_pos: Vector2 = player_spawn.global_position if player_spawn else Vector2(180, 616)
	var cp_id: StringName = GameState.active_checkpoint_id if GameState else &""

	if cp_id != &"" and checkpoint_positions.has(cp_id):
		spawn_pos = checkpoint_positions[cp_id]

	player.respawn_at(spawn_pos)

func _setup_relics() -> void:
	var relics := get_tree().get_nodes_in_group("relics")
	total_relics = relics.size()
	collected_relics = 0

	for node in relics:
		if node is Relic:
			node.relic_collected.connect(_on_relic_collected)

	_update_relics_ui()

func _setup_level_goal() -> void:
	if goal:
		goal.goal_reached.connect(_on_goal_reached)

func _process(delta: float) -> void:
	# Reinicio rápido con tecla [R]
	if Input.is_action_just_pressed("restart"):
		respawn_player_at_checkpoint()

	# Detección de caída al vacío: reaparece en checkpoint
	if player and player.global_position.y > 850.0:
		player.take_direct_damage(2) # Pierde 1 corazón de daño por caída
		respawn_player_at_checkpoint()

	# Desplazamiento sutil del cielo en Parallax
	if sky_layer:
		sky_layer.motion_offset.x -= sky_speed * delta

func _on_player_health_changed(new_health: int, max_hp: int) -> void:
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud:
		active_hud.update_health(new_health, max_hp)

func _on_player_died() -> void:
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud:
		active_hud.show_game_over()

func _on_relic_collected(_relic: Relic) -> void:
	collected_relics += 1
	_update_relics_ui()

func _update_relics_ui() -> void:
	var remaining := maxi(total_relics - collected_relics, 0)
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud:
		active_hud.update_relics_count(remaining, total_relics)

func _on_goal_reached() -> void:
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud:
		active_hud.show_victory()

func _register_enemy(enemy_node: Enemy) -> void:
	if not enemy_node.enemy_defeated.is_connected(_on_enemy_defeated):
		enemy_node.enemy_defeated.connect(_on_enemy_defeated)

func _on_enemy_defeated(enemy_node: Enemy) -> void:
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud:
		if is_instance_valid(enemy_node) and "score_value" in enemy_node:
			active_hud.add_score(enemy_node.score_value)
		active_hud.add_enemy_defeated()

func _on_checkpoint_activated(checkpoint_id: StringName, _pos: Vector2) -> void:
	if GameState:
		GameState.set_checkpoint(checkpoint_id)
	if SaveManager:
		SaveManager.save_game()

func respawn_player_at_checkpoint() -> void:
	_spawn_player_from_state()
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud and active_hud.game_over_panel:
		active_hud.game_over_panel.visible = false

func _on_restart_level() -> void:
	if SceneFlow:
		SceneFlow.reload_current()
	else:
		get_tree().reload_current_scene()

func _on_return_main_menu() -> void:
	if SceneFlow:
		SceneFlow.change_to("res://scenes/ui/main_menu.tscn", 0.35)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
