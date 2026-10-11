class_name EnemyStateMachine
extends Node

## Máquina de Estados Finitos (FSM / State Pattern) para Enemigos (HU03)

@export var initial_state: EnemyState

var current_state: EnemyState
var states: Dictionary = {}

func init(enemy: CharacterBody2D) -> void:
	for child in get_children():
		if child is EnemyState:
			states[child.name.to_lower()] = child
			child.enemy = enemy
			child.state_machine = self
	
	if initial_state:
		transition_to(initial_state.name)

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func transition_to(target_state_name: String) -> void:
	var key = target_state_name.to_lower()
	if not states.has(key):
		push_warning("Estado no encontrado en la FSM: %s" % target_state_name)
		return
	
	if current_state:
		current_state.exit()
	
	current_state = states[key]
	current_state.enter()
