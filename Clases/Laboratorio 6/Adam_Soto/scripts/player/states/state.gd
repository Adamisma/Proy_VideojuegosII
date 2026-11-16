class_name State
extends Node

## ====================================================================
## Laboratorio 05 - Sección 6.5 & Sección 11: Clase Base de Estado
## ====================================================================
## Estructura base para la evolución de la FSM hacia el patrón State.
## Permite desacoplar la lógica de cada estado en nodos o clases independientes.

var player: CharacterBody2D

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
