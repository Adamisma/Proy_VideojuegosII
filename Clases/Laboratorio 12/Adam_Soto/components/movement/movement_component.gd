class_name MovementComponent
extends Node

## ====================================================================
## Laboratorio 11 - Sección 16 & 17: MovementComponent Reutilizable
## ====================================================================
## Extrae la lógica de aceleración, desaceleración y velocidad deseada.
## Devuelve un cálculo matemático en float sin alterar directamente el cuerpo del actor.

@export var max_speed: float = 260.0
@export var acceleration: float = 1500.0
@export var deceleration: float = 1900.0

func configure_from_stats(stats: CharacterStats) -> void:
	if stats:
		max_speed = stats.move_speed
		acceleration = stats.acceleration
		deceleration = stats.deceleration

## Sección 17: Cálculo desacoplado de velocidad horizontal
func calculate_horizontal_velocity(
	current_velocity_x: float,
	input_axis: float,
	delta: float
) -> float:
	var target := input_axis * max_speed
	var rate := acceleration if input_axis != 0.0 else deceleration
	return move_toward(current_velocity_x, target, rate * delta)
