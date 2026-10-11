class_name EnemyStateHurt
extends EnemyState

## Estado HURT (HU03)

@export var hurt_duration: float = 0.35
var _timer: float = 0.0

func enter() -> void:
	_timer = hurt_duration
	if enemy:
		enemy.play_animation("hurt")

func update(delta: float) -> void:
	_timer -= delta
	if _timer <= 0.0:
		if enemy and enemy.health <= 0:
			state_machine.transition_to("dead")
		elif enemy and enemy.player:
			state_machine.transition_to("chase")
		else:
			state_machine.transition_to("patrol")

func physics_update(delta: float) -> void:
	if enemy:
		enemy.apply_gravity(delta)
		# Dejar que el knockback se desacelere naturalmente
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 400.0 * delta)
		enemy.move_and_slide()
