class_name EnemyState
extends Node

## Clase base para el State Pattern de los enemigos (HU03)

var enemy: CharacterBody2D
var state_machine: Node

func enter() -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
