class_name EnemyStateChase
extends EnemyState

## Estado CHASE (HU03)

@export var lose_interest_time: float = 2.0
var _lost_timer: float = 0.0

func enter() -> void:
	_lost_timer = 0.0
	if enemy:
		enemy.play_animation("run")

func update(delta: float) -> void:
	if not enemy.player:
		state_machine.transition_to("patrol")
		return
		
	# Si el jugador está dentro del rango de ataque
	if enemy.is_player_in_attack_range():
		state_machine.transition_to("attack")
		return
		
	# Si el jugador se aleja demasiado
	if not enemy.can_see_player():
		_lost_timer += delta
		if _lost_timer >= lose_interest_time:
			state_machine.transition_to("patrol")
	else:
		_lost_timer = 0.0

func physics_update(delta: float) -> void:
	if not enemy or not enemy.player:
		return
		
	enemy.apply_gravity(delta)
	
	# Moverse hacia la posición del jugador
	var dir_to_player = sign(enemy.player.global_position.x - enemy.global_position.x)
	if dir_to_player != 0 and dir_to_player != enemy.direction:
		enemy.set_facing(dir_to_player)
	
	# Si hay un acantilado o pared enfrente, no caerse a lo loco a menos que esté en suelo
	if enemy.is_at_edge_or_wall():
		enemy.velocity.x = 0.0
	else:
		enemy.velocity.x = enemy.direction * enemy.chase_speed
		
	enemy.move_and_slide()
