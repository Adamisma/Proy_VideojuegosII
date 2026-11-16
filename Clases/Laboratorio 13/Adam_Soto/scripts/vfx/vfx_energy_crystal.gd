extends Area2D
class_name VFXEnergyCrystal

## ====================================================================
## Laboratorio 10 - Sección 24 & Reto 41: Cristal de Energía con Pulso y Luz
## ====================================================================
## Objeto interactivo que demuestra:
## 1. Shader de pulso procedural continuo (pulse.gdshader) impulsado por TIME.
## 2. Iluminación local mediante PointLight2D contextual.
## 3. Feedback declarativo con Tween y Easing al ser recolectado o golpeado (Sección 18).

@onready var visual: Node2D = $Visual
@onready var light: PointLight2D = $PointLight2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_collected or not (body.is_in_group("player") or body.name.to_lower().contains("player")):
		return

	is_collected = true
	collision_shape.set_deferred("disabled", true)

	# Sección 18: Tween y easing declarativo (TRANS_SINE / EASE_OUT)
	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(1.4, 1.4), 0.12).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(light, "energy", 2.5, 0.12)
	tween.tween_property(visual, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(light, "energy", 0.0, 0.25)
	tween.tween_callback(queue_free)

