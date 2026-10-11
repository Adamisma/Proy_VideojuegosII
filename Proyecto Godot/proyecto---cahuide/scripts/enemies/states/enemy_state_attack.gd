class_name EnemyStateAttack
extends EnemyState

## Estado ATTACK (HU03 & HU04)

@export var attack_duration: float = 0.8
@export var attack_windup: float = 0.3
var _timer: float = 0.0
var _has_attacked: bool = false

func enter() -> void:
	_timer = attack_duration
	_has_attacked = false
	if enemy:
		enemy.velocity.x = 0.0
		# Orientar hacia el jugador
		if enemy.player:
			var dir = sign(enemy.player.global_position.x - enemy.global_position.x)
			if dir != 0:
				enemy.set_facing(dir)
		enemy.play_animation("attack")

func update(delta: float) -> void:
	_timer -= delta
	
	# Ejecutar el ataque en el momento del windup
	if not _has_attacked and _timer <= (attack_duration - attack_windup):
		_has_attacked = true
		if enemy:
			enemy.execute_attack()
			
	if _timer <= 0.0:
		# Al terminar el ataque, volver a perseguir o patrullar
		if enemy and enemy.is_player_in_attack_range():
			# Pequeña pausa antes de volver a atacar
			state_machine.transition_to("idle")
		elif enemy and enemy.can_see_player():
			state_machine.transition_to("chase")
		else:
			state_machine.transition_to("patrol")

func physics_update(delta: float) -> void:
	if enemy:
		enemy.apply_gravity(delta)
		enemy.velocity.x = move_toward(enemy.velocity.x, 0.0, 500.0 * delta)
		enemy.move_and_slide()
