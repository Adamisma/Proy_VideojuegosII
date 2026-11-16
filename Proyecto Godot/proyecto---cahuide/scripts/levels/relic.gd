class_name Relic
extends Area2D

## ====================================================================
## Proyecto Cahuide - Reliquia Ancestral (Coleccionable Opcional)
## ====================================================================
## Otorga +50 puntos de puntuación y alimenta las estadísticas de la partida.

signal relic_collected(relic_node: Relic)

@export var relic_id: StringName
@export var score_value: int = 50

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
var _collected: bool = false

func _ready() -> void:
	add_to_group("relics")
	body_entered.connect(_on_body_entered)

	# Si ya fue recolectada según GameState, destruirla
	if GameState and relic_id != &"" and GameState.is_relic_collected(relic_id):
		queue_free()
		return

	# Efecto de levitación continua
	if sprite:
		var tween := create_tween().set_loops()
		tween.tween_property(sprite, "position:y", -10.0, 1.0).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if _collected or not body.is_in_group("player"):
		return

	_collected = true

	if GameState:
		GameState.register_collected_relic(relic_id, score_value)
	elif EventBus:
		EventBus.score_changed.emit(score_value)

	var all_relics := get_tree().get_nodes_in_group("relics")
	var remaining := maxi(all_relics.size() - 1, 0)
	if EventBus:
		EventBus.relic_collected.emit(remaining, all_relics.size())

	relic_collected.emit(self)

	# Efecto visual de recolección y desvanecimiento
	var tween := create_tween()
	tween.tween_property(self, "scale", scale * 1.7, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
