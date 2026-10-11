class_name EnemyStateDead
extends EnemyState

## Estado DEAD (HU03)

@export var death_duration: float = 1.0
var _timer: float = 0.0

func enter() -> void:
	_timer = death_duration
	if enemy:
		enemy.velocity = Vector2.ZERO
		enemy.disable_collisions()
		enemy.play_animation("dead")
		enemy.emit_defeat()

func update(delta: float) -> void:
	_timer -= delta
	if enemy:
		# Efecto de desvanecimiento gradual
		enemy.modulate.a = max(0.0, _timer / death_duration)
		
	if _timer <= 0.0:
		if enemy:
			enemy.queue_free()

func physics_update(delta: float) -> void:
	if enemy:
		enemy.apply_gravity(delta)
		enemy.move_and_slide()
