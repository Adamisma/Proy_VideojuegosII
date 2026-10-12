class_name PowerUpSol
extends Area2D

## PowerUp del Sol: Otorga +1 de vida máxima/resistencia y habilita el ataque a distancia

@export var float_distance: float = 8.0  # Altura a la que sube y baja
@export var float_speed: float = 1.2     # Velocidad del movimiento de levitación

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_start_floating_animation()

# Efecto de levitación continua (flotando suavemente como moneda)
func _start_floating_animation() -> void:
	if not sprite:
		return
		
	var start_y = sprite.position.y
	var tween = create_tween().set_loops() # Bucle infinito
	
	# Sube suavemente y luego baja a la posición inicial
	tween.tween_property(sprite, "position:y", start_y - float_distance, float_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "position:y", start_y, float_speed).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("apply_powerup_sol"):
		body.apply_powerup_sol()
		_play_pickup_effect()

func _play_pickup_effect() -> void:
	# Deshabilitar colisiones para evitar doble recogida
	$CollisionShape2D.set_deferred("disabled", true)
	
	# Efecto visual de desaparición (se agranda y se desvanece)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.25)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	
	await tween.finished
	queue_free()
