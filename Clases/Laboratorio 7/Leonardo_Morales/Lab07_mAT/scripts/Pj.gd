extends CharacterBody2D

const SPEED: float = 250.0

@onready var animated_sprite: AnimatedSprite2D = $Node2D/AnimatedSprite2D

# Precargamos la escena del proyectil para instanciarla rápidamente
@export var projectile_scene: PackedScene = preload("res://scenes/projectile.tscn")

# Variables para guardar la dirección de disparo por defecto
var last_direction: Vector2 = Vector2.DOWN
var last_horizontal_direction: float = 1.0 # 1 para derecha, -1 para izquierda

func _physics_process(delta: float) -> void:
	# 1. Obtener entradas
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_axis("ui_left", "ui_right")
	input_dir.y = Input.get_axis("ui_up", "ui_down")
	
	# 2. Manejo de movimiento y última dirección registrada
	if input_dir != Vector2.ZERO:
		velocity = input_dir.normalized() * SPEED
		update_animations(input_dir)
		
		# Guardamos la dirección actual como la última dirección de movimiento
		last_direction = input_dir.normalized()
		if input_dir.x != 0:
			last_horizontal_direction = sign(input_dir.x)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
		animated_sprite.play("Stand")
		
	move_and_slide()
	
	# 3. Disparo con tecla de acción (por ejemplo, la barra espaciadora o "ui_accept")
	if Input.is_action_just_pressed("ui_select"):
		shoot()

func update_animations(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		animated_sprite.play("Avanzar")
		if dir.x < 0:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
	else:
		animated_sprite.flip_h = false
		if dir.y < 0:
			animated_sprite.play("arriba")
		else:
			animated_sprite.play("abajo")

func shoot() -> void:
	if not projectile_scene:
		return
		
	# Instanciamos el proyectil
	var projectile = projectile_scene.instantiate() as Area2D
	
	# Calculamos el punto de aparición (ligeramente separado del centro del pj para que no colisione consigo mismo)
	var spawn_offset = last_direction * 30.0 
	projectile.global_position = global_position + spawn_offset
	
	# Añadimos el proyectil a la escena principal (fuera del jugador para que no lo acompañe al moverse)
	get_tree().current_scene.add_child(projectile)
	
	# Configuramos su dirección vectorial
	projectile.set_direction(last_direction)
