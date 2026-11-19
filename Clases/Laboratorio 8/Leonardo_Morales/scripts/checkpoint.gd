extends Area2D

## ====================================================================
## Laboratorio 04 - Sección 18.2 & Reto 26: Script del Checkpoint
## ====================================================================
## Administra el punto de control local. Al activarse por primera vez:
## 1. Actualiza su estado visual (indicador de activación con tween de escala y color verde esmeralda).
## 2. Emite la señal 'activated' con la posición global del Marker2D ($SpawnPoint).

signal activated(new_spawn_position: Vector2)

@onready var spawn_point: Marker2D = $SpawnPoint
@onready var sprite: Sprite2D = $Sprite2D

var is_active: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if sprite:
		# Color inactivo: grisáceo translúcido (Sección 21: Legibilidad)
		sprite.modulate = Color(0.5, 0.55, 0.65, 0.75)

func _on_body_entered(body: Node2D) -> void:
	if is_active:
		return

	if not body.is_in_group("player"):
		return

	is_active = true

	# Reto 26: Feedback visual inmediato al activar checkpoint
	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(0.2, 1.0, 0.45, 1.0), 0.2)
		tween.parallel().tween_property(sprite, "scale", sprite.scale * 1.25, 0.12)
		tween.tween_property(sprite, "scale", sprite.scale, 0.15)

	print("[Checkpoint] Activado en posición: ", spawn_point.global_position)
	activated.emit(spawn_point.global_position)
