class_name Checkpoint
extends Area2D

## ====================================================================
## Proyecto Cahuide - Altar / Estandarte de Punto de Control (Checkpoint)
## ====================================================================

signal activated(checkpoint_id: StringName, spawn_position: Vector2)

@export var checkpoint_id: StringName = &"cp_mid"
@onready var spawn_point: Marker2D = $SpawnPoint
@onready var visual_banner: Sprite2D = get_node_or_null("Sprite2D")
@onready var glow_rect: ColorRect = get_node_or_null("GlowRect")

var is_active: bool = false

func _ready() -> void:
	add_to_group("checkpoint")
	body_entered.connect(_on_body_entered)

	# Si al cargar ya era el activo en GameState, iluminarlo
	if GameState and GameState.active_checkpoint_id == checkpoint_id and checkpoint_id != &"":
		_set_activated_visual(false)

func _on_body_entered(body: Node2D) -> void:
	if is_active or not body.is_in_group("player"):
		return

	is_active = true
	_set_activated_visual(true)

	var spawn_pos: Vector2 = spawn_point.global_position if spawn_point else global_position
	activated.emit(checkpoint_id, spawn_pos)

	if GameState:
		GameState.set_checkpoint(checkpoint_id)

	if SaveManager:
		SaveManager.save_game()

func _set_activated_visual(animate: bool) -> void:
	is_active = true
	var active_color := Color(1.8, 1.5, 0.4, 1.0) # Oro solar brillante

	if visual_banner:
		if animate:
			var tween := create_tween()
			tween.tween_property(visual_banner, "modulate", active_color, 0.3)
			tween.parallel().tween_property(visual_banner, "scale", visual_banner.scale * 1.15, 0.15)
			tween.tween_property(visual_banner, "scale", visual_banner.scale, 0.15)
		else:
			visual_banner.modulate = active_color

	if glow_rect:
		glow_rect.visible = true
		glow_rect.modulate = active_color
