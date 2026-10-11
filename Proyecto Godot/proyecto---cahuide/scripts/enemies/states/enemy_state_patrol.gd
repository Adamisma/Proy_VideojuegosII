class_name EnemyStatePatrol
extends EnemyState

## Estado PATROL (HU03)

@export var patrol_duration: float = 3.5
var _timer: float = 0.0

func enter() -> void:
	_timer = patrol_duration
	if enemy:
		enemy.play_animation("walk")

func update(delta: float) -> void:
	if enemy.can_see_player():
		state_machine.transition_to("chase")
		return
		
	_timer -= delta
	if _timer <= 0.0:
		state_machine.transition_to("idle")

func physics_update(delta: float) -> void:
	if not enemy:
		return
		
	enemy.apply_gravity(delta)
	
	# Cambiar dirección si choca con pared o llega al borde del suelo
	if enemy.is_at_edge_or_wall():
		enemy.flip_direction()
		
	enemy.velocity.x = enemy.direction * enemy.patrol_speed
	enemy.move_and_slide()
