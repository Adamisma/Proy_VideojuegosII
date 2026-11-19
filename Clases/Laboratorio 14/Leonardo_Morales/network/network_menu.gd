extends Control

## NetworkMenu: Menú principal de conexión LAN (Host / Join / Disconnect)
## Administra la interfaz de inicio de sesión de red según los pasos 10 y 18 de la guía.

@onready var address_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/AddressInput
@onready var nickname_input: LineEdit = $CenterContainer/PanelContainer/VBoxContainer/NicknameContainer/NicknameInput
@onready var host_button: Button = $CenterContainer/PanelContainer/VBoxContainer/HostButton
@onready var join_button: Button = $CenterContainer/PanelContainer/VBoxContainer/JoinButton
@onready var disconnect_button: Button = $CenterContainer/PanelContainer/VBoxContainer/DisconnectButton
@onready var status_label: Label = $CenterContainer/PanelContainer/VBoxContainer/StatusLabel
@onready var peer_id_label: Label = $CenterContainer/PanelContainer/VBoxContainer/PeerIdLabel


func _ready() -> void:
	host_button.pressed.connect(_on_host_button_pressed)
	join_button.pressed.connect(_on_join_button_pressed)
	disconnect_button.pressed.connect(_on_disconnect_button_pressed)

	network_manager.connection_status_changed.connect(_on_connection_status_changed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	_refresh_peer_info()


func _on_host_button_pressed() -> void:
	_save_nickname()
	var error: Error = network_manager.host_game()
	if error == OK:
		_refresh_peer_info()
		# Flujo: El host puede abrir la escena de juego inmediatamente (Paso 18)
		_open_lan_game()
	else:
		host_button.disabled = false
		join_button.disabled = false


func _on_join_button_pressed() -> void:
	_save_nickname()
	var target_ip: String = address_input.text.strip_edges()
	if target_ip.is_empty():
		target_ip = "127.0.0.1"

	host_button.disabled = true
	join_button.disabled = true
	if disconnect_button:
		disconnect_button.visible = true

	var error: Error = network_manager.join_game(target_ip)
	if error != OK:
		host_button.disabled = false
		join_button.disabled = false
		if disconnect_button:
			disconnect_button.visible = false


func _on_disconnect_button_pressed() -> void:
	network_manager.disconnect_game()
	_refresh_peer_info()


func _on_connected_to_server() -> void:
	_refresh_peer_info()
	# Flujo: El cliente abre la escena de juego cuando connected_to_server confirma la conexión (Paso 18)
	_open_lan_game()


func _on_connection_failed() -> void:
	host_button.disabled = false
	join_button.disabled = false
	_refresh_peer_info()


func _on_server_disconnected() -> void:
	host_button.disabled = false
	join_button.disabled = false
	_refresh_peer_info()


func _on_connection_status_changed(msg: String) -> void:
	if status_label:
		status_label.text = "Estado: " + msg


func _refresh_peer_info() -> void:
	var online: bool = network_manager.is_online()
	if disconnect_button:
		disconnect_button.visible = online
	if host_button:
		host_button.disabled = online
	if join_button:
		join_button.disabled = online

	if peer_id_label:
		if online:
			var id: int = network_manager.get_local_peer_id()
			var role: String = "HOST" if network_manager.is_host() else "CLIENT"
			peer_id_label.text = "Peer ID: %d (%s)" % [id, role]
		else:
			peer_id_label.text = "Peer ID: Sin conexión"


func _save_nickname() -> void:
	if nickname_input and not nickname_input.text.strip_edges().is_empty():
		network_manager.local_player_nickname = nickname_input.text.strip_edges()


func _open_lan_game() -> void:
	get_tree().change_scene_to_file("res://multiplayer/game_lan.tscn")
