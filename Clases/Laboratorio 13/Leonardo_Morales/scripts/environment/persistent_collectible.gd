class_name PersistentCollectible
extends Area2D

## ====================================================================
## Laboratorio 12 - Sección 28: Coleccionable Persistente con ID Único
## ====================================================================
## Comprueba en _ready() si ya fue recogido en GameState.collected_items.
## Al recogerse, se registra en GameState, suma puntuación y activa autosave.

signal collected(points: int)

@export var item_id: StringName
@export var points: int = 25

var is_collected: bool = false

func _ready() -> void:
	# Si ya fue recolectado en esta partida, destruirlo inmediatamente
	if GameState and GameState.is_item_collected(item_id) and item_id != &"":
		queue_free()
		return

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return

	if not body.is_in_group("player"):
		return

	is_collected = true
	collected.emit(points)

	if GameState:
		if item_id != &"":
			GameState.register_collected_item(item_id)
		GameState.add_score(points)

	# Autosave al recolectar según Sección 28
	if SaveManager:
		SaveManager.save_game()

	# Animación de recogida
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.parallel().tween_property(self, "position:y", position.y - 20.0, 0.25)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
