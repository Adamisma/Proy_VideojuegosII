extends Area2D

## Señal para notificar la recolección desacoplada (Guía Lab 01 - Sec. 5.6 y 6.9)
signal collected(points: int)

@export var points: int = 1

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

var _is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
		
	# Comprobación semántica por grupo (Guía Lab 01 - Sec. 6.10)
	if body.is_in_group("player"):
		_is_collected = true
		collected.emit(points)
		
		# Reto de ampliación: Efecto visual de recolección (feedback antes de queue_free)
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
			
		if sprite:
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(sprite, "scale", sprite.scale * 1.4, 0.15)
			tween.tween_property(sprite, "modulate:a", 0.0, 0.15)
			tween.chain().tween_callback(queue_free)
		else:
			queue_free()
