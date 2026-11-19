extends Node2D
class_name ArchitectureLab

## ====================================================================
## Laboratorio 11: Escena Demostrativa de Arquitectura Profesional
## ====================================================================
## Orquestador del nivel que demuestra el desacoplamiento en 5 capas:
## 1. PRESENTACIÓN: HUD desacoplado (ui/hud.tscn) con reactividad a señales.
## 2. GAMEPLAY: Player (CharacterBody2D) y EnemyDummy coordinando su lógica.
## 3. COMPONENTES: HealthComponent, MovementComponent, Hitbox, Hurtbox.
## 4. DATOS: CharacterStats (player_stats, enemy_stats) y WeaponData (sword, dagger).
## 5. SERVICIOS: EventBus, GameState, SceneFlow con transición fade.

@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var spawn_point_initial: Marker2D = $Checkpoints/InitialSpawn
@onready var checkpoint_a: Area2D = $Checkpoints/CheckpointA
@onready var checkpoint_b: Area2D = $Checkpoints/CheckpointB
@onready var telemetry_label: Label = $HUD/TelemetryPanel/Margin/VBox/TelemetryContent

var current_spawn_position: Vector2

func _ready() -> void:
	current_spawn_position = spawn_point_initial.global_position

	# Sección 29: Inyección de dependencias hacia el HUD
	if hud and player:
		hud.bind_player(player)

	# Conexión con ciclo de vida del jugador
	if player:
		player.respawn_requested.connect(_on_player_respawn_requested)

	# Conexión a checkpoints del nivel
	if checkpoint_a and checkpoint_a.has_signal("activated"):
		checkpoint_a.activated.connect(_on_checkpoint_activated.bind("cp_alfa"))
	if checkpoint_b and checkpoint_b.has_signal("activated"):
		checkpoint_b.activated.connect(_on_checkpoint_activated.bind("cp_beta"))

	# EventBus listeners para telemetría
	if EventBus:
		EventBus.player_died.connect(_on_eventbus_player_died)
		EventBus.score_changed.connect(_on_eventbus_score_changed)
		EventBus.checkpoint_activated.connect(_on_eventbus_checkpoint_activated)

	_update_telemetry()

func _unhandled_input(event: InputEvent) -> void:
	# [R] Reiniciar en checkpoint activo
	if event.is_action_pressed("restart"):
		_respawn_player()
	
	# [F] Probar SceneFlow con Fade Transicional (Reto 43)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_test_sceneflow_transition()

func _on_checkpoint_activated(spawn_pos: Vector2, checkpoint_id: String) -> void:
	current_spawn_position = spawn_pos
	if GameState:
		GameState.set_checkpoint(StringName(checkpoint_id))
	_update_telemetry()

func _on_player_respawn_requested() -> void:
	_respawn_player()

func _respawn_player() -> void:
	if player:
		player.respawn_at(current_spawn_position)
		if hud and hud.game_over_panel:
			hud.game_over_panel.visible = false
	_update_telemetry()

func _test_sceneflow_transition() -> void:
	print("[ArchitectureLab] Probando SceneFlow con Fade CanvasLayer...")
	if SceneFlow:
		SceneFlow.change_to("res://scenes/levels/architecture_lab.tscn", 0.3)

func _on_eventbus_player_died() -> void:
	print("[EventBus] Evento recibido: player_died")
	_update_telemetry()

func _on_eventbus_score_changed(score: int) -> void:
	_update_telemetry()

func _on_eventbus_checkpoint_activated(cp_id: StringName) -> void:
	_update_telemetry()

func _update_telemetry() -> void:
	if telemetry_label == null:
		return

	var player_hp: String = "%d / %d" % [player.health.current_health, player.health.max_health] if player and player.health else "N/A"
	var player_speed: String = "%.0f px/s" % player.stats.move_speed if player and player.stats else "N/A"
	var weapon_info: String = "%s (DMG: %d)" % [player.weapon.weapon_name, player.weapon.damage] if player and player.weapon else "N/A"
	var score_val: String = str(GameState.score) if GameState else "0"
	var cp_val: String = String(GameState.active_checkpoint) if GameState and GameState.active_checkpoint != &"" else "Ninguno"

	telemetry_label.text = """[Arquitectura en 5 Capas Activa]
• Servicios: EventBus (OK) | GameState (Score: %s, CP: %s)
• WeaponData (Reto 43): %s  [E: Alternar]
• Componentes Player: Health (%s) | Movement (%s)
• Transición: SceneFlow Fade listo [F: Recargar nivel]""" % [score_val, cp_val, weapon_info, player_hp, player_speed]
