class_name MovementComponent
extends Node

## ====================================================================
## Proyecto Cahuide - MovementComponent
## ====================================================================

@export var max_speed: float = 260.0
@export var acceleration: float = 1600.0
@export var deceleration: float = 1900.0

func configure_from_stats(stats: CharacterStats) -> void:
	if stats != null:
		max_speed = stats.move_speed
		acceleration = stats.acceleration
		deceleration = stats.deceleration

func calculate_horizontal_velocity(current_vx: float, input_axis: float, delta: float) -> float:
	var target := input_axis * max_speed
	var rate: float = acceleration if input_axis != 0.0 else deceleration
	return move_toward(current_vx, target, rate * delta)
