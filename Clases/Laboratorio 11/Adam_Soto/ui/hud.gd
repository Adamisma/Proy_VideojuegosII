class_name HUD
extends CanvasLayer

## ====================================================================
## Laboratorio 11 - Sección 29: HUD Desacoplado
## ====================================================================
## El HUD observa datos y reacciona a eventos, sin poseer ni manipular la lógica
## interna del jugador ni del juego.
## - Contrato directo: bind_player(player) / bind_health(health_comp)
## - Contrato global: Escucha EventBus (score_changed, checkpoint_activated, player_died)

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopRow/HealthContainer/HealthBar
@onready var hp_label: Label = $MarginContainer/VBoxContainer/TopRow/HealthContainer/HPLabel
@onready var score_label: Label = $MarginContainer/VBoxContainer/TopRow/ScoreLabel
@onready var checkpoint_label: Label = $MarginContainer/VBoxContainer/StatusRow/CheckpointLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/StatusRow/WeaponLabel
@onready var game_over_panel: PanelContainer = $GameOverPanel

var bound_health: HealthComponent = null

func _ready() -> void:
	if game_over_panel:
		game_over_panel.visible = false

	# Suscripción a señales globales del EventBus (Sección 19 & 20)
	if EventBus:
		EventBus.score_changed.connect(_on_score_changed)
		EventBus.checkpoint_activated.connect(_on_checkpoint_activated)
		EventBus.player_died.connect(_on_player_died)
		EventBus.player_damaged.connect(_on_player_damaged_global)

	# Inicializar con valores de GameState si existe
	if GameState:
		_on_score_changed(GameState.score)
		if GameState.active_checkpoint != &"":
			_on_checkpoint_activated(GameState.active_checkpoint)

## Sección 29: Inyección explícita del jugador para conectar componentes locales
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
		checkpoint_label.modulate = Color(0.3, 1.0, 0.4) # Verde fluorescente

func _on_weapon_swapped(weapon_data: WeaponData) -> void:
	if weapon_label and weapon_data:
		weapon_label.text = "ARMA: %s (Daño: %d) [E: Alternar]" % [weapon_data.weapon_name, weapon_data.damage]

func _on_player_died() -> void:
	if game_over_panel:
		game_over_panel.visible = true
