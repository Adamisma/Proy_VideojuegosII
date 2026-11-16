class_name HUD
extends CanvasLayer

## ====================================================================
## Proyecto Cahuide - HUD Reactivo con EventBus y Corazones Incas
## ====================================================================

signal restart_requested
signal main_menu_requested

@onready var indicador_vida: HBoxContainer = $MarginContainer/VBoxContainer/TopBar/VBoxContainer/IndicadorVida
@onready var score_label: Label = $MarginContainer/VBoxContainer/TopBar/VBoxContainer/IndicadorScore/Label
@onready var kills_label: Label = $MarginContainer/VBoxContainer/TopBar/VBoxContainer2/KillsLabel
@onready var relic_label: Label = $MarginContainer/VBoxContainer/TopBar/VBoxContainer2/RelicLabel
@onready var objective_label: Label = $MarginContainer/VBoxContainer/ObjectiveLabel
@onready var weapon_indicator: Label = get_node_or_null("MarginContainer/VBoxContainer/TopBar/VBoxContainer/WeaponLabel")

@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var victory_panel: PanelContainer = $VictoryPanel

var _enemies_defeated: int = 0
var _score: int = 0

func _ready() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	if victory_panel:
		victory_panel.visible = false

	# Si no existe nodo dedicado de arma, crearlo dinámicamente en TopBar
	if weapon_indicator == null:
		weapon_indicator = Label.new()
		weapon_indicator.name = "WeaponLabel"
		weapon_indicator.add_theme_font_size_override("font_size", 12)
		weapon_indicator.add_theme_color_override("font_color", Color(0.4, 0.85, 1.0))
		$MarginContainer/VBoxContainer/TopBar/VBoxContainer.add_child(weapon_indicator)
	update_weapon_display("Piedra Ancestral")

	# Conexión reactiva con EventBus
	if EventBus:
		EventBus.player_damaged.connect(update_health)
		EventBus.player_died.connect(show_game_over)
		EventBus.score_changed.connect(update_score)
		EventBus.enemy_defeated.connect(func(_pts: int): add_enemy_defeated())
		EventBus.relic_collected.connect(update_relics_count)
		EventBus.level_completed.connect(func(_id: StringName): show_victory())
		EventBus.ranged_weapon_swapped.connect(update_weapon_display)

	# Inicializar con GameState si existe
	if GameState:
		update_score(GameState.score)
		_enemies_defeated = GameState.enemies_killed
		_update_kills_label()

	# Botones de Game Over
	var btn_restart := get_node_or_null("GameOverPanel/VBoxContainer/HBoxContainer/BtnRestart") as Button
	if btn_restart:
		btn_restart.pressed.connect(_on_restart_pressed)
	var btn_menu := get_node_or_null("GameOverPanel/VBoxContainer/HBoxContainer/BtnMenu") as Button
	if btn_menu:
		btn_menu.pressed.connect(_on_menu_pressed)

	# Botones de Victoria
	var btn_v_restart := get_node_or_null("VictoryPanel/VBoxContainer/HBoxContainer/BtnVictoryRestart") as Button
	if btn_v_restart:
		btn_v_restart.pressed.connect(_on_restart_pressed)
	var btn_v_menu := get_node_or_null("VictoryPanel/VBoxContainer/HBoxContainer/BtnVictoryMenu") as Button
	if btn_v_menu:
		btn_v_menu.pressed.connect(_on_menu_pressed)

func bind_player(player: Node) -> void:
	if player == null:
		return
	if "health" in player and "max_health" in player:
		update_health(player.health, player.max_health)
	if player.has_signal("health_changed"):
		player.connect("health_changed", update_health)
	if player.has_signal("player_died"):
		player.connect("player_died", show_game_over)

func update_health(current_health: int, _max_health: int = 20) -> void:
	if not indicador_vida:
		return

	var corazones := indicador_vida.get_children()
	for i in range(corazones.size()):
		var heart := corazones[i] as TextureProgressBar
		if heart:
			# Cada corazón maneja 2 puntos de salud (0 = vacío, 1 = medio, 2 = lleno)
			var heart_value := clampi(current_health - (i * 2), 0, 2)
			heart.value = heart_value

func update_weapon_display(weapon_name: String) -> void:
	if weapon_indicator:
		weapon_indicator.text = "ARMA DISTANCIA: %s [E: Alternar]" % weapon_name

func update_relics_count(remaining: int, total: int) -> void:
	if relic_label:
		relic_label.text = "Reliquias: %d / %d" % [total - remaining, total]

func update_score(new_score: int) -> void:
	_score = new_score
	if score_label:
		score_label.text = "SCORE %d" % _score

func add_score(amount: int) -> void:
	_score += amount
	update_score(_score)

func add_enemy_defeated() -> void:
	_enemies_defeated += 1
	_update_kills_label()

func _update_kills_label() -> void:
	if kills_label:
		kills_label.text = "Enemigos Derrotados: %d" % _enemies_defeated

func show_game_over() -> void:
	if game_over_panel:
		game_over_panel.visible = true

func show_victory() -> void:
	if victory_panel:
		victory_panel.visible = true

func _on_restart_pressed() -> void:
	restart_requested.emit()
	if SceneFlow:
		SceneFlow.reload_current()
	else:
		get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	main_menu_requested.emit()
	if SceneFlow:
		SceneFlow.change_to("res://scenes/ui/main_menu.tscn", 0.35)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
