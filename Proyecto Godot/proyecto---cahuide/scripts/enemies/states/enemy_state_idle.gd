class_name EnemyStateIdle
extends EnemyState

## Estado IDLE (HU03)

@export var idle_duration: float = 1.5
var _timer: float = 0.0

func enter() -> void:
	_timer = idle_duration
	if enemy:
		enemy.velocity.x = 0.0
		enemy.play_animation("idle")

func update(delta: float) -> void:
	if enemy.can_see_player():
		state_machine.transition_to("chase")
		return
		
	_timer -= delta
	if _timer <= 0.0:
		state_machine.transition_to("patrol")

func physics_update(delta: float) -> void:
	if enemy:
		enemy.apply_gravity(delta)
		enemy.move_and_slide()
