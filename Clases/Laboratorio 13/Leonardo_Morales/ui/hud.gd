class_name HUD
extends CanvasLayer

## ====================================================================
## Laboratorio 12 - Sección 31 & Reto 41: HUD con Indicador de Autosave
## ====================================================================
## Escucha reactivamente a EventBus, GameState y SaveManager.
## Muestra vida, puntuación, checkpoint activo, arma y notificación de guardado en disco.

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopRow/HealthContainer/HealthBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/TopRow/HealthContainer/HPLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/TopRow/ScoreLabel
@onready var checkpoint_label: Label = $MarginContainer/VBoxContainer/StatusRow/CheckpointLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/StatusRow/WeaponLabel
@onready var autosave_badge: PanelContainer = get_node_or_null("AutosaveBadge")
@onready var autosave_label: Label = get_node_or_null("AutosaveBadge/Margin/HBox/Label")
@onready var game_over_panel: PanelContainer = $GameOverPanel

var bound_health: HealthComponent = null
var autosave_tween: Tween

func _ready() -> void:
	if game_over_panel:
		game_over_panel.visible = false

	if autosave_badge:
		autosave_badge.modulate.a = 0.0

	# Suscripción a señales globales del EventBus
	if EventBus:
		EventBus.score_changed.connect(_on_score_changed)
		EventBus.checkpoint_activated.connect(_on_checkpoint_activated)
		EventBus.player_died.connect(_on_player_died)
		EventBus.player_damaged.connect(_on_player_damaged_global)

	# Sección 31 & Reto 41: Notificaciones de persistencia en UI
	if SaveManager:
		SaveManager.save_started.connect(_on_save_started)
		SaveManager.save_finished.connect(_on_save_finished)

	# Inicializar con valores de GameState
	if GameState:
		_on_score_changed(GameState.score)
		if GameState.active_checkpoint_id != &"":
			_on_checkpoint_activated(GameState.active_checkpoint_id)

func bind_player(player: Node) -> void:
	if player == null:
		return

	var health := player.get_node_or_null("HealthComponent") as HealthComponent
	if health:
		bind_health(health)

	if player.has_signal("weapon_swapped"):
		player.connect("weapon_swapped", _on_weapon_swapped)
		if "weapon" in player and player.weapon != null:
			_on_weapon_swapped(player.weapon)

func bind_health(health: HealthComponent) -> void:
	if bound_health and bound_health.health_changed.is_connected(_on_health_changed):
		bound_health.health_changed.disconnect(_on_health_changed)

	bound_health = health
	if bound_health:
		bound_health.health_changed.connect(_on_health_changed)
		_on_health_changed(bound_health.current_health, bound_health.max_health)

func _on_health_changed(current: int, maximum: int) -> void:
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	if hp_label:
		hp_label.text = "HP: %d / %d" % [current, maximum]

func _on_player_damaged_global(current: int, maximum: int) -> void:
	_on_health_changed(current, maximum)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "PUNTOS: %04d" % new_score

func _on_checkpoint_activated(checkpoint_id: StringName) -> void:
	if checkpoint_label:
		checkpoint_label.text = "CHECKPOINT: %s [GUARDADO]" % String(checkpoint_id)
		checkpoint_label.modulate = Color(0.3, 1.0, 0.4)

func _on_weapon_swapped(weapon_data: WeaponData) -> void:
	if weapon_label and weapon_data:
		weapon_label.text = "ARMA: %s (Daño: %d) [E: Alternar]" % [weapon_data.weapon_name, weapon_data.damage]

func _on_player_died() -> void:
	if game_over_panel:
		game_over_panel.visible = true

## Sección 31 & Reto 41: Animación de Autosave
func _on_save_started() -> void:
	if autosave_badge and autosave_label:
		autosave_label.text = "GUARDANDO..."
		autosave_badge.modulate.a = 1.0

func _on_save_finished(success: bool) -> void:
	if autosave_badge == null or autosave_label == null:
		return

	if autosave_tween and autosave_tween.is_valid():
		autosave_tween.kill()

	if success:
		autosave_label.text = "AUTOSAVE [OK]"
		autosave_label.modulate = Color(0.3, 1.0, 0.45)
	else:
		autosave_label.text = "ERROR AL GUARDAR"
		autosave_label.modulate = Color(1.0, 0.25, 0.25)

	autosave_badge.modulate.a = 1.0
	autosave_tween = create_tween()
	autosave_tween.tween_interval(1.2)
	autosave_tween.tween_property(autosave_badge, "modulate:a", 0.0, 0.4)
