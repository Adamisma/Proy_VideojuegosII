class_name NetworkManager
extends Node

## NetworkManager: Administrador central de conexiones de red LAN (Godot 4 ENet)
## Gestiona el ciclo de vida del transporte ENetMultiplayerPeer, eventos de conexión/desconexión y estado.

signal connection_status_changed(text: String)
signal peer_joined(peer_id: int)
signal peer_left(peer_id: int)

const PORT: int = 7000
const MAX_CLIENTS: int = 8
const DEFAULT_ADDRESS: String = "127.0.0.1"

## Nombre o apodo del jugador local para compartir con otros peers
var local_player_nickname: String = "Jugador"


func _ready() -> void:
	# Conexión a señales de alto nivel de MultiplayerAPI
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## Crea la partida como Host (Servidor + Jugador local)
func host_game() -> Error:
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(PORT, MAX_CLIENTS)
	if error != OK:
		var err_msg := "No se pudo crear el servidor (Error: %s)." % str(error)
		connection_status_changed.emit(err_msg)
		push_error(err_msg)
		return error

	multiplayer.multiplayer_peer = peer
	var ok_msg := "Servidor LAN activo en puerto %d." % PORT
	connection_status_changed.emit(ok_msg)
	print("[NetworkManager] " + ok_msg + " (Peer ID: 1)")
	return OK


## Se conecta a un servidor existente como Cliente
func join_game(address: String) -> Error:
	var target := address.strip_edges()
	if target.is_empty():
		target = DEFAULT_ADDRESS

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_client(target, PORT)
	if error != OK:
		var err_msg := "No se pudo iniciar la conexión hacia %s (Error: %s)." % [target, str(error)]
		connection_status_changed.emit(err_msg)
		push_error(err_msg)
		return error

	multiplayer.multiplayer_peer = peer
	var status_msg := "Conectando a %s:%d..." % [target, PORT]
	connection_status_changed.emit(status_msg)
	print("[NetworkManager] " + status_msg)
	return OK


## Devuelve el Peer ID local asignado por MultiplayerAPI
func get_local_peer_id() -> int:
	return multiplayer.get_unique_id()


## Indica si la sesión actual es online/LAN (no OfflineMultiplayerPeer)
func is_online() -> bool:
	if multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer is OfflineMultiplayerPeer:
		return false
	var status := multiplayer.multiplayer_peer.get_connection_status()
	return status == MultiplayerPeer.CONNECTION_CONNECTED or status == MultiplayerPeer.CONNECTION_CONNECTING


## Indica si la instancia actual es el Servidor/Host en una sesión de red activa
func is_host() -> bool:
	if not is_online():
		return false
	return multiplayer.is_server()


## Devuelve la lista de IDs de peers remotos conectados
func get_connected_peers() -> Array[int]:
	var result: Array[int] = []
	if is_online():
		var peers_packed := multiplayer.get_peers()
		for p in peers_packed:
			result.append(p)
	return result


## Cierra la sesión de red y restablece el transporte local
func disconnect_game() -> void:
	if multiplayer.multiplayer_peer != null:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	var msg := "Sin conexión (desconectado)."
	connection_status_changed.emit(msg)
	print("[NetworkManager] " + msg)


# ==============================================================================
# Callbacks de señales de MultiplayerAPI
# ==============================================================================

func _on_peer_connected(peer_id: int) -> void:
	print("[NetworkManager] Peer conectado: ", peer_id)
	peer_joined.emit(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("[NetworkManager] Peer desconectado: ", peer_id)
	peer_left.emit(peer_id)


func _on_connected_to_server() -> void:
	var msg := "Conectado al servidor con éxito. (Mi Peer ID: %d)" % get_local_peer_id()
	print("[NetworkManager] " + msg)
	connection_status_changed.emit(msg)


func _on_connection_failed() -> void:
	var msg := "Error: Conexión fallida al servidor."
	print("[NetworkManager] " + msg)
	connection_status_changed.emit(msg)
	disconnect_game()


func _on_server_disconnected() -> void:
	var msg := "El servidor se ha desconectado o cerrado la partida."
	print("[NetworkManager] " + msg)
	connection_status_changed.emit(msg)
	disconnect_game()
