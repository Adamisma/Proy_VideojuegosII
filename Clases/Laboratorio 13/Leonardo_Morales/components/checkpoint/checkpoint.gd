class_name Checkpoint
extends Area2D

## ====================================================================
## Laboratorio 12 - Secciones 11 & 29: Checkpoint con ID Único
## ====================================================================
## Detecta al jugador, activa su estado y emite su ID identificable
## para que GameState y SaveManager persistan el progreso sin acoplamiento.

signal activated(checkpoint_id: StringName, spawn_position: Vector2)

@export var checkpoint_id: StringName
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var visual_rect: ColorRect = get_node_or_null("VisualRect")
@onready var label: Label = get_node_or_null("Label")

var is_active: bool = false

func _ready() -> void:
	add_to_group("checkpoint")
	body_entered.connect(_on_body_entered)

	if label and checkpoint_id != &"":
		label.text = String(checkpoint_id)

	# Si al cargar la escena este checkpoint ya es el activo en GameState, encenderlo visualmente
	if GameState and GameState.active_checkpoint_id == checkpoint_id and checkpoint_id != &"":
		_set_activated_visual(false)

func _on_body_entered(body: Node2D) -> void:
	if is_active:
		return

	if not body.is_in_group("player"):
		return

	if checkpoint_id == &"":
		push_error("Checkpoint sin ID válido asignado.")
		return

	is_active = true
	_set_activated_visual(true)

	var spawn_pos: Vector2 = spawn_point.global_position if spawn_point else global_position
	activated.emit(checkpoint_id, spawn_pos)

func _set_activated_visual(animate: bool) -> void:
	is_active = true
	var active_color := Color(0.2, 1.0, 0.45, 1.0) # Verde esmeralda brillante

	if visual_rect:
		if animate:
			var tween := create_tween()
			tween.tween_property(visual_rect, "color", active_color, 0.25)
			tween.parallel().tween_property(visual_rect, "scale", Vector2(1.2, 1.2), 0.12)
			tween.tween_property(visual_rect, "scale", Vector2(1.0, 1.0), 0.15)
		else:
			visual_rect.color = active_color

	if sprite:
		if animate:
			var tween := create_tween()
			tween.tween_property(sprite, "modulate", active_color, 0.25)
		else:
			sprite.modulate = active_color
