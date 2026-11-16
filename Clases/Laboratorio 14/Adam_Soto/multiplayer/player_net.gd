class_name PlayerNet
extends CharacterBody2D

## PlayerNet: Actor multijugador sincronizado en red (Godot 4 High-Level API)
## Gestiona la autoridad de control, replicación de posición/animación y cámara local.

@export var speed: float = 220.0
@export var current_anim: String = "idle"
@export var player_nickname: String = ""

@onready var visuals: Node2D = $Visuals
@onready var anim_sprite: AnimatedSprite2D = $Visuals/AnimatedSprite2D
@onready var name_label: Label = $NameLabel
@onready var camera: Camera2D = $Camera2D
@onready var synchronizer: MultiplayerSynchronizer = $MultiplayerSynchronizer


func _enter_tree() -> void:
	# Paso 22 y 25: El nombre del nodo es el peer_id. Asignamos la autoridad de red de forma determinista.
	var peer_id: int = name.to_int()
	if peer_id > 0:
		set_multiplayer_authority(peer_id, true)


func _ready() -> void:
	var peer_id: int = name.to_int()
	var is_local: bool = is_multiplayer_authority()

	# Paso 27: La cámara solo debe estar habilitada para el peer local que controla este actor
	if camera:
		camera.enabled = is_local

	# Paso 28 y Reto de ampliación: Mostrar identificador, apodo y distinción de [TÚ]
	_setup_display_name(peer_id, is_local)

	# Reto de ampliación: Tonalidad de color distintiva según el Peer ID
	_apply_peer_color(peer_id)

	# Asegurar configuración del MultiplayerSynchronizer (Paso 29)
	_configure_synchronizer()


func _setup_display_name(peer_id: int, is_local: bool) -> void:
	if not name_label:
		return

	# Si es el jugador local y tiene un apodo configurado, usarlo
	if is_local and not network_manager.local_player_nickname.is_empty():
		player_nickname = network_manager.local_player_nickname

	var base_title: String = player_nickname
	if base_title.is_empty():
		base_title = "Host (1)" if peer_id == 1 else "Peer %d" % peer_id

	name_label.text = base_title + (" [TÚ]" if is_local else "")


func _apply_peer_color(peer_id: int) -> void:
	if not visuals:
		return
	# Algoritmo de tono basado en la proporción áurea para colores claramente diferenciables
	var hue: float = fmod(float(peer_id) * 0.381966, 1.0)
	var tint: Color = Color.from_hsv(hue, 0.70, 1.0)
	visuals.modulate = tint


func _configure_synchronizer() -> void:
	if synchronizer == null:
		return

	# Si no trae configuración asignada en el editor o archivo .tscn, crearla en runtime
	if synchronizer.replication_config == null:
		var config := SceneReplicationConfig.new()

		# 1. Posición continua (Paso 29)
		config.add_property(NodePath(".:position"))
		config.property_set_replication_mode(NodePath(".:position"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
		config.property_set_spawn(NodePath(".:position"), true)

		# 2. Animación actual (Reto de ampliación)
		config.add_property(NodePath(".:current_anim"))
		config.property_set_replication_mode(NodePath(".:current_anim"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
		config.property_set_spawn(NodePath(".:current_anim"), true)

		# 3. Orientación visual (flip / scale)
		config.add_property(NodePath("Visuals:scale"))
		config.property_set_replication_mode(NodePath("Visuals:scale"), SceneReplicationConfig.REPLICATION_MODE_ALWAYS)
		config.property_set_spawn(NodePath("Visuals:scale"), true)

		# 4. Apodo del jugador al aparecer
		config.add_property(NodePath(".:player_nickname"))
		config.property_set_replication_mode(NodePath(".:player_nickname"), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
		config.property_set_spawn(NodePath(".:player_nickname"), true)

		synchronizer.replication_config = config


func _physics_process(_delta: float) -> void:
	# Paso 26: Control local estricto. Si no somos la autoridad, no leemos teclado local
	if not is_multiplayer_authority():
		_sync_remote_visuals()
		return

	# Lectura de input local exclusivamente
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * speed
	move_and_slide()

	# Gestión de animación y orientación horizontal
	var desired_anim := "idle"
	if direction.length_squared() > 0.01:
		desired_anim = "run"
		if direction.x < -0.01 and visuals:
			visuals.scale.x = -1.0
		elif direction.x > 0.01 and visuals:
			visuals.scale.x = 1.0

	current_anim = desired_anim
	_play_anim(current_anim)


func _sync_remote_visuals() -> void:
	# Actualizar animación recibida a través de la replicación de red
	_play_anim(current_anim)


func _play_anim(anim_name: String) -> void:
	if anim_sprite and anim_sprite.sprite_frames:
		if anim_sprite.sprite_frames.has_animation(anim_name):
			if anim_sprite.animation != anim_name or not anim_sprite.is_playing():
				anim_sprite.play(anim_name)
