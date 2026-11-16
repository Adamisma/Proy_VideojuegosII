extends Node2D

## Escena Main: Centraliza la puntuación y la interfaz mediante señales (Guía Lab 01 - Sec. 6.11 y 6.12)
var score: int = 0
var objetos_restantes: int = 0

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var remaining_label: Label = $CanvasLayer/RemainingLabel
@onready var victory_label: Label = $CanvasLayer/VictoryLabel

func _ready() -> void:
	# Descubrimiento dinámico de recolectables mediante el grupo 'collectible'
	var collectibles = get_tree().get_nodes_in_group("collectible")
	objetos_restantes = collectibles.size()

	for collectible in collectibles:
		collectible.collected.connect(_on_collectible_collected)

	_update_score()
	_update_remaining()

func _unhandled_input(event: InputEvent) -> void:
	# Reto de ampliación: Reiniciar la partida presionando la tecla [R]
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			get_tree().reload_current_scene()

func _on_collectible_collected(points: int) -> void:
	score += points
	objetos_restantes = max(0, objetos_restantes - 1)
	
	_update_score()
	_update_remaining()
	
	# Reto de ampliación: Mostrar mensaje de victoria al recolectar todo
	if objetos_restantes == 0 and victory_label:
		victory_label.visible = true
	
func _update_score() -> void:
	if score_label:
		score_label.text = "Puntos: %d" % score
	
func _update_remaining() -> void:
	if remaining_label:
		remaining_label.text = "Objetos restantes: %d" % objetos_restantes
