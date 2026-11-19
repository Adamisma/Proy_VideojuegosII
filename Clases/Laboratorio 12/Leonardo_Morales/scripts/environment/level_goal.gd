class_name LevelGoal
extends Area2D

## ====================================================================
## Laboratorio 12 - Sección 16: Puerta de Fin de Nivel y Transición
## ====================================================================
## Al tocar el jugador la meta:
## 1. Reinicia el checkpoint activo en GameState (los IDs son locales al nivel).
## 2. Actualiza current_level_id a next_level_id.
## 3. Guarda automáticamente la partida con SaveManager.
## 4. Dispara la transición mediante SceneFlow.

signal reached

@export var next_level_id: StringName = &""
var is_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_triggered or not body.is_in_group("player"):
		return

	is_triggered = true
	reached.emit()

	# Sección 16: Lógica de avance de nivel y persistencia
	if GameState:
		GameState.active_checkpoint_id = &""
		if next_level_id != &"":
			GameState.current_level_id = next_level_id

	if SaveManager:
		SaveManager.save_game()

	if next_level_id != &"":
		if SceneFlow:
			SceneFlow.go_to_level(next_level_id, 0.35)
	else:
		if EventBus:
			EventBus.level_completed.emit(GameState.current_level_id if GameState else &"final")
		# Volver al menú principal tras completar todos los niveles
		await get_tree().create_timer(1.0).timeout
		if SceneFlow:
			SceneFlow.change_to("res://ui/main_menu.tscn", 0.5)
