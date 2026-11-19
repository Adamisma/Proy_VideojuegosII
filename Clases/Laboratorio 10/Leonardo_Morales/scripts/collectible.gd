extends Area2D

## ====================================================================
## Laboratorio 04 - Reto 26: Coleccionable (Moneda)
## ====================================================================
signal collected(points: int)

@export var points: int = 1
var is_collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.is_in_group("player"):
		is_collected = true
		collected.emit(points)
		
		# Feedback visual de recolección (Tween hacia arriba y desvanecimiento)
		set_deferred("monitoring", false)
		var tween := create_tween()
		tween.parallel().tween_property(self, "position:y", position.y - 20.0, 0.25)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.25)
		tween.tween_callback(queue_free)
