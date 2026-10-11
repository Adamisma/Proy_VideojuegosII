class_name Relic
extends Area2D

## Reliquia Ancestral - Meta final del Nivel 1 (HU05)

signal relic_collected

@onready var sprite: Sprite2D = $Sprite2D
var _collected: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Efecto de levitación continua
	var tween = create_tween().set_loops()
	tween.tween_property(sprite, "position:y", -10.0, 1.0).set_trans(Tween.TRANS_SINE)
	tween.tween_property(sprite, "position:y", 0.0, 1.0).set_trans(Tween.TRANS_SINE)

func _on_body_entered(body: Node2D) -> void:
	if _collected:
		return
	if body.is_in_group("player"):
		_collected = true
		relic_collected.emit()
		
		# Efecto visual de recolección
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.3)
		tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
		tween.tween_callback(queue_free)
