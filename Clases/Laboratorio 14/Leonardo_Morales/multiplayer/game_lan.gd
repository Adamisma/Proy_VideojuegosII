extends Node2D

## GameLAN: Controlador de la arena de juego multijugador LAN
## Gestiona el ciclo de vida de la partida, spawning determinista en servidor,
## puntos de inicio no superpuestos y el HUD informativo de sesión.

const PLAYER_SCENE: PackedScene = preload("res://multiplayer/player_net.tscn")

@onready var players_container: Node2D = $Players
@onready var spawn_points_node: Node2D = $SpawnPoints
@onready var role_badge: Label = $HUD/MarginContainer/PanelContainer/HBoxContainer/RoleBadge
@onready var peer_id_label: Label = $HUD/MarginContainer/PanelContainer/HBoxContainer/PeerIdLabel
@onready var players_count_label: Label = $HUD/MarginContainer/PanelContainer/HBoxContainer/PlayersCountLabel
@onready var peers_list_label: Label = $HUD/MarginContainer/PanelContainer/HBoxContainer/PeersListLabel
@onready var disconnect_btn: Button = $HUD/MarginContainer/PanelContainer/HBoxContainer/DisconnectBtn


func _ready() -> void:
	if disconnect_btn:
		disconnect_btn.pressed.connect(_on_disconnect_pressed)

	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connection_failed.connect(_on_connection_failed)

	# Paso 20 y 23: En la arquitectura Godot 4 High-Level, el Servidor es el único que instancia actores
	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_spawn_player)
		multiplayer.peer_disconnected.connect(_despawn_player)

		# Paso 23: El Host se spawnea a sí mismo con su peer_id (que es 1)
		_spawn_player(multiplayer.get_unique_id())

		# Salvaguarda: Si algún peer ya estuviese conectado antes de entrar a la arena, spawnearlo
		for p_id: int in multiplayer.get_peers():
			_spawn_player(p_id)

	# Actualizaciones reactivas del HUD cuando cambian los jugadores o peers
	if players_container:
		players_container.child_entered_tree.connect(func(_node: Node) -> void: _update_hud())
		players_container.child_exiting_tree.connect(func(_node: Node) -> void: _update_hud())

	multiplayer.peer_connected.connect(func(_id: int) -> void: _update_hud())
	multiplayer.peer_disconnected.connect(func(_id: int) -> void: _update_hud())
	_update_hud()


## Paso 30: Calcula el punto de spawn según el peer_id para evitar superposición física
func _get_spawn_position(peer_id: int) -> Vector2:
	if spawn_points_node == null:
		return Vector2.ZERO

	var markers: Array[Node] = spawn_points_node.get_children()
	if markers.is_empty():
		return Vector2.ZERO

	var index: int = abs(peer_id) % markers.size()
	var marker: Marker2D = markers[index] as Marker2D
	return marker.global_position if marker else Vector2.ZERO


## Paso 22 y 23: Instanciación autoritativa en el servidor con nombre determinista
func _spawn_player(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	var node_name := str(peer_id)
	if players_container.has_node(node_name):
		return

	var player: PlayerNet = PLAYER_SCENE.instantiate() as PlayerNet
	player.name = node_name

	if peer_id == multiplayer.get_unique_id():
		player.player_nickname = network_manager.local_player_nickname

	# El parámetro 'true' fuerza nombre legible para que MultiplayerSpawner replique coherentemente
	players_container.add_child(player, true)
	player.global_position = _get_spawn_position(peer_id)

	print("[GameLAN] Spawneado jugador para Peer ID: ", peer_id, " en posición: ", player.global_position)
	_update_hud()


## Paso 24: Destrucción autoritativa al recibir desconexión de un peer
func _despawn_player(peer_id: int) -> void:
	if not multiplayer.is_server():
		return

	var player: Node = players_container.get_node_or_null(str(peer_id))
	if player != null:
		player.queue_free()
		print("[GameLAN] Despawneado jugador para Peer ID: ", peer_id)

	_update_hud()


## Retos de ampliación: HUD con Rol, Peer ID, conteo y lista de participantes
func _update_hud() -> void:
	var my_id: int = network_manager.get_local_peer_id()
	var is_host: bool = network_manager.is_host()

	if role_badge:
		role_badge.text = "[HOST - Servidor]" if is_host else "[CLIENT - Cliente]"
		role_badge.self_modulate = Color(0.4, 0.9, 0.4) if is_host else Color(0.4, 0.7, 1.0)

	if peer_id_label:
		peer_id_label.text = "Mi ID: %d" % my_id

	var count: int = 0
	var peer_names: Array[String] = []
	if players_container:
		count = players_container.get_child_count()
		for c in players_container.get_children():
			peer_names.append(c.name)

	if players_count_label:
		players_count_label.text = "Jugadores: %d" % max(1, count)

	if peers_list_label:
		if peer_names.is_empty():
			peer_names.append(str(my_id))
		peers_list_label.text = "Peers: " + str(peer_names)


func _on_disconnect_pressed() -> void:
	network_manager.disconnect_game()
	get_tree().change_scene_to_file("res://network/network_menu.tscn")


func _on_server_disconnected() -> void:
	get_tree().change_scene_to_file("res://network/network_menu.tscn")


func _on_connection_failed() -> void:
	get_tree().change_scene_to_file("res://network/network_menu.tscn")
