class_name HUD
extends CanvasLayer

## Interfaz de Usuario durante la partida (HUD)

signal restart_requested
signal main_menu_requested

# Referencias ajustadas a tu nueva estructura visual
@onready var indicador_vida: HBoxContainer = $MarginContainer/VBoxContainer/TopBar/VBoxContainer/IndicadorVida
@onready var score_label: Label = $MarginContainer/VBoxContainer/TopBar/VBoxContainer/IndicadorScore/Label
@onready var kills_label: Label = $MarginContainer/VBoxContainer/TopBar/VBoxContainer2/KillsLabel
@onready var relic_label: Label = $MarginContainer/VBoxContainer/TopBar/VBoxContainer2/RelicLabel
@onready var objective_label: Label = $MarginContainer/VBoxContainer/ObjectiveLabel

@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var victory_panel: PanelContainer = $VictoryPanel

var _enemies_defeated: int = 0
var _score: int = 0

func _ready() -> void:
	game_over_panel.visible = false
	victory_panel.visible = false
	_update_kills_label()
	update_score(_score)
	
	# Conectar con el jugador si existe en la escena
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(update_health)
		player.player_died.connect(show_game_over)
		update_health(player.health, player.max_health)
	
	# Conectar botones de Game Over
	$GameOverPanel/VBoxContainer/HBoxContainer/BtnRestart.pressed.connect(_on_restart_pressed)
	$GameOverPanel/VBoxContainer/HBoxContainer/BtnMenu.pressed.connect(_on_menu_pressed)
	
	# Conectar botones de Victoria
	$VictoryPanel/VBoxContainer/HBoxContainer/BtnVictoryRestart.pressed.connect(_on_restart_pressed)
	$VictoryPanel/VBoxContainer/HBoxContainer/BtnVictoryMenu.pressed.connect(_on_menu_pressed)

# Lógica para llenar/vaciar medios corazones
func update_health(current_health: int, _max_health: int) -> void:
	if not indicador_vida:
		return
		
	var corazones = indicador_vida.get_children()
	
	for i in range(corazones.size()):
		var heart = corazones[i] as TextureProgressBar
		if heart:
			# Cada corazón maneja 2 puntos de salud (0 = vacío, 1 = medio, 2 = lleno)
			var heart_value = clamp(current_health - (i * 2), 0, 2)
			heart.value = heart_value
			
func update_relics_count(remaining: int, total: int) -> void:
	if relic_label:
		relic_label.text = "Reliquias restantes: %d" % remaining

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
	game_over_panel.visible = true

func show_victory() -> void:
	victory_panel.visible = true

func _on_restart_pressed() -> void:
	restart_requested.emit()

func _on_menu_pressed() -> void:
	main_menu_requested.emit()
