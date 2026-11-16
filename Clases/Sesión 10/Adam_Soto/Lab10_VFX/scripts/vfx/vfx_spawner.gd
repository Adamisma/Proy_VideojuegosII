class_name VFXSpawner
extends Node

## ====================================================================
## Laboratorio 10 - Sección 13: Spawner Desacoplado de Efectos Visuales
## ====================================================================
## Instancia escenas de efectos visuales (partículas, destellos, luces) en una raíz común (VFXRoot)
## para evitar acoplamiento directo entre entidades del gameplay (Player, Enemy) y la presentación.

@export var vfx_root: Node

func spawn_effect(
	scene: PackedScene,
	global_pos: Vector2,
	rotation_radians: float = 0.0
) -> Node2D:
	if scene == null:
		return null

	var instance := scene.instantiate() as Node2D
	if instance == null:
		return null

	var parent := vfx_root
	if parent == null:
		parent = get_tree().current_scene

	parent.add_child(instance)
	instance.global_position = global_pos
	instance.global_rotation = rotation_radians
	return instance
