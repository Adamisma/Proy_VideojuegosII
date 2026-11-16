extends Node2D

var score: int = 0
var objetos_restantes: int = 0

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var remaining_label: Label = $CanvasLayer/RemainingLabel
@onready var victory_label: Label = $CanvasLayer/VictoryLabel

func _ready() -> void:
	var collectibles = get_tree().get_nodes_in_group("collectible")
	
	objetos_restantes = collectibles.size()

	for collectible in collectibles:
		collectible.collected.connect(_on_collectible_collected)

	_update_score()
	_update_remaining()
	
func _on_collectible_collected(points: int) -> void:
	score += points
	objetos_restantes -= 1
	
	_update_score()
	_update_remaining()
	
	if objetos_restantes == 0:
		$CanvasLayer/VictoryLabel.visible = true
	
func _update_score() -> void:
	score_label.text = "Puntos: %d" % score
	
func _update_remaining() -> void:
	remaining_label.text = "Objetos restantes: %d" % objetos_restantes
