class_name LevelGoal
extends Area2D

## ====================================================================
## Proyecto Cahuide - Trofeo Sagrado / Meta de Fin de Nivel
## ====================================================================
## Recoger este trofeo en la parte final completa la misión y otorga la victoria.

signal goal_reached

@export var next_level_id: StringName = &""
@export var bonus_score: int = 500

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
var is_reached: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	# Animación de levitación y resplandor continuo
	if sprite:
		var tween := create_tween().set_loops()
		tween.tween_property(sprite, "position:y", -8.0, 0.9).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "position:y", 4.0, 0.9).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if is_reached or not body.is_in_group("player"):
		return

	if NetworkManager and NetworkManager.is_multiplayer_active():
		if not multiplayer.is_server():
			return
		_rpc_trigger_goal.rpc()
		return

	_do_trigger_goal()

@rpc("authority", "call_local", "reliable")
func _rpc_trigger_goal() -> void:
	_do_trigger_goal()

func _do_trigger_goal() -> void:
	if is_reached:
		return
	is_reached = true
	goal_reached.emit()

	if GameState:
		GameState.add_score(bonus_score)
		GameState.active_checkpoint_id = &""
		if NetworkManager and NetworkManager.is_multiplayer_active() and multiplayer.is_server():
			NetworkManager.host_broadcast_score(GameState.score, GameState.enemies_killed)

	if SaveManager and (NetworkManager == null or not NetworkManager.is_multiplayer_active()):
		SaveManager.save_game()

	if EventBus:
		EventBus.level_completed.emit(GameState.current_level_id if GameState else &"level_01")

	# Animación de recogida triunfal
	var tween := create_tween()
	tween.tween_property(self, "scale", scale * 1.6, 0.4)
	tween.parallel().tween_property(self, "modulate", Color(2.5, 2.2, 0.8, 0.0), 0.5)
