extends Node

## ====================================================================
## Laboratorio 13 - GameState (Estado de Sesión con Inventario)
## ====================================================================
## Administra el estado en tiempo de ejecución: nivel, checkpoint, puntos,
## ítems de escenario recogidos y datos serializables del inventario del jugador.

var current_level_id: StringName = &"level_01"
var active_checkpoint_id: StringName = &""
var score: int = 0
var collected_items: Array[StringName] = []
var inventory_data: Array = []

func start_new_game() -> void:
	current_level_id = &"level_01"
	active_checkpoint_id = &""
	score = 0
	collected_items.clear()
	inventory_data.clear()
	if EventBus:
		EventBus.score_changed.emit(score)

func set_checkpoint(checkpoint_id: StringName) -> void:
	active_checkpoint_id = checkpoint_id
	if EventBus:
		EventBus.checkpoint_activated.emit(checkpoint_id)

func add_score(amount: int) -> void:
	score = maxi(score + amount, 0)
	if EventBus:
		EventBus.score_changed.emit(score)

func is_item_collected(item_id: StringName) -> bool:
	return item_id in collected_items

func register_collected_item(item_id: StringName) -> void:
	if item_id != &"" and item_id not in collected_items:
		collected_items.append(item_id)
