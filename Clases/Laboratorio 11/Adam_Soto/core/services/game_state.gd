extends Node

## ====================================================================
## Laboratorio 11 - Sección 22: GameState (Autoload de Sesión)
## ====================================================================
## Almacena datos globales persistentes entre cambios de escena.
## No guarda referencias a nodos efímeros ni acapara lógica de gameplay.

var score: int = 0
var active_checkpoint: StringName = &""
var current_level: StringName = &"architecture_lab"

func add_score(amount: int) -> void:
	score += amount
	if EventBus:
		EventBus.score_changed.emit(score)

func set_checkpoint(checkpoint_id: StringName) -> void:
	active_checkpoint = checkpoint_id
	if EventBus:
		EventBus.checkpoint_activated.emit(checkpoint_id)

func reset_run() -> void:
	score = 0
	active_checkpoint = &""
	current_level = &"architecture_lab"
	if EventBus:
		EventBus.score_changed.emit(score)
