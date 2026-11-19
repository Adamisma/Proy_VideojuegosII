class_name LanLobby
extends Control

## ====================================================================
## Proyecto Cahuide - Interfaz de Lobby Multijugador LAN (US-05)
## ====================================================================

const CHAR_KEYS: Array[String] = ["cahuide", "chasqui", "guardian"]
const MAP_KEYS: Array[String] = ["level_01", "level_02"]
const DIFF_KEYS: Array[String] = ["facil", "normal", "dificil"]

# Panel de conexión inicial
@onready var connection_panel: PanelContainer = $MarginContainer/VBoxContainer/ContentArea/ConnectionPanel
@onready var name_input: LineEdit = $MarginContainer/VBoxContainer/ContentArea/ConnectionPanel/VBox/NameRow/NameInput
@onready var local_ip_label: Label = $MarginContainer/VBoxContainer/ContentArea/ConnectionPanel/VBox/Columns/HostBox/LocalIpLabel
@onready var host_port_input: LineEdit = $MarginContainer/VBoxContainer/ContentArea/ConnectionPanel/VBox/Columns/HostBox/HostPortRow/HostPortInput
@onready var btn_host: Button = $MarginContainer/VBoxContainer/ContentArea/ConnectionPanel/VBox/Columns/HostBox/BtnHost
@onready var join_ip_input: LineEdit = $MarginContainer/VBoxContainer/ContentArea/ConnectionPanel/VBox/Columns/JoinBox/JoinIpRow/JoinIpInput
@onready var join_port_input: LineEdit = $MarginContainer/VBoxContainer/ContentArea/ConnectionPanel/VBox/Columns/JoinBox/JoinPortRow/JoinPortInput
@onready var btn_join: Button = $MarginContainer/VBoxContainer/ContentArea/ConnectionPanel/VBox/Columns/JoinBox/BtnJoin
@onready var btn_back_menu: Button = $MarginContainer/VBoxContainer/ContentArea/ConnectionPanel/VBox/BtnBackMenu

# Panel de sala pre-partida
@onready var room_panel: PanelContainer = $MarginContainer/VBoxContainer/ContentArea/RoomPanel
@onready var room_info_label: Label = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/RoomInfoLabel
@onready var p1_name_label: Label = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/PlayersRow/P1Card/VBox/P1Name
@onready var p1_char_label: Label = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/PlayersRow/P1Card/VBox/P1Char
@onready var p1_ready_label: Label = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/PlayersRow/P1Card/VBox/P1Ready
@onready var p2_name_label: Label = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/PlayersRow/P2Card/VBox/P2Name
@onready var p2_char_label: Label = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/PlayersRow/P2Card/VBox/P2Char
@onready var p2_ready_label: Label = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/PlayersRow/P2Card/VBox/P2Ready

@onready var char_select: OptionButton = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/ConfigRow/CharBox/CharSelect
@onready var char_desc_label: Label = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/ConfigRow/CharBox/CharDesc
@onready var map_select: OptionButton = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/ConfigRow/OptionsBox/MapRow/MapSelect
@onready var diff_select: OptionButton = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/ConfigRow/OptionsBox/DiffRow/DiffSelect
@onready var options_hint_label: Label = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/ConfigRow/OptionsBox/OptionsHint

@onready var btn_ready: Button = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/ActionsRow/BtnReady
@onready var btn_start: Button = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/ActionsRow/BtnStart
@onready var btn_leave_room: Button = $MarginContainer/VBoxContainer/ContentArea/RoomPanel/VBox/ActionsRow/BtnLeaveRoom

# Barra de estado / errores
@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusPanel/StatusLabel

var _updating_ui: bool = false


func _ready() -> void:
	_populate_dropdowns()
	_refresh_local_ips()

	btn_host.pressed.connect(_on_host_pressed)
	btn_join.pressed.connect(_on_join_pressed)
	btn_back_menu.pressed.connect(_on_back_menu_pressed)

	char_select.item_selected.connect(_on_char_selected)
	map_select.item_selected.connect(_on_options_changed)
	diff_select.item_selected.connect(_on_options_changed)
	btn_ready.pressed.connect(_on_ready_pressed)
	btn_start.pressed.connect(_on_start_pressed)
	btn_leave_room.pressed.connect(_on_leave_room_pressed)

	if NetworkManager:
		NetworkManager.lobby_updated.connect(_refresh_room_ui)
		NetworkManager.connection_status_changed.connect(_set_status)
		NetworkManager.connection_succeeded.connect(_on_connection_succeeded)
		NetworkManager.connection_failed_with_reason.connect(_on_connection_failed)

	if NetworkManager and NetworkManager.is_multiplayer_active():
		_show_room_view()
		_refresh_room_ui()
	else:
		_show_connection_view()
		_set_status("Elige 'Crear Partida' o ingresa la IP del Host para unirte por LAN.", false)


func _exit_tree() -> void:
	if NetworkManager:
		if NetworkManager.lobby_updated.is_connected(_refresh_room_ui):
			NetworkManager.lobby_updated.disconnect(_refresh_room_ui)
		if NetworkManager.connection_status_changed.is_connected(_set_status):
			NetworkManager.connection_status_changed.disconnect(_set_status)
		if NetworkManager.connection_succeeded.is_connected(_on_connection_succeeded):
			NetworkManager.connection_succeeded.disconnect(_on_connection_succeeded)
		if NetworkManager.connection_failed_with_reason.is_connected(_on_connection_failed):
			NetworkManager.connection_failed_with_reason.disconnect(_on_connection_failed)


func _populate_dropdowns() -> void:
	char_select.clear()
	for key in CHAR_KEYS:
		var info: Dictionary = NetworkManager.CHARACTERS[key]
		char_select.add_item(str(info["name"]))

	map_select.clear()
	for key in MAP_KEYS:
		var info: Dictionary = NetworkManager.MAPS[key]
		map_select.add_item(str(info["name"]))

	diff_select.clear()
	for key in DIFF_KEYS:
		var info: Dictionary = NetworkManager.DIFFICULTIES[key]
		diff_select.add_item(str(info["name"]))


func _refresh_local_ips() -> void:
	if NetworkManager == null:
		return
	var ips := NetworkManager.get_local_lan_ips()
	local_ip_label.text = "Tu IP LAN: %s  (Local: 127.0.0.1)" % ", ".join(ips)


func _show_connection_view() -> void:
	connection_panel.visible = true
	room_panel.visible = false
	btn_host.disabled = false
	btn_join.disabled = false


func _show_room_view() -> void:
	connection_panel.visible = false
	room_panel.visible = true


func _set_status(text: String, is_error: bool) -> void:
	if status_label == null:
		return
	status_label.text = text
	status_label.modulate = Color(1.0, 0.42, 0.42, 1.0) if is_error else Color(0.95, 0.92, 0.72, 1.0)


func _parse_port(raw: String) -> int:
	var cleaned := raw.strip_edges()
	if not cleaned.is_valid_int():
		return -1
	return int(cleaned)


func _on_host_pressed() -> void:
	if NetworkManager == null:
		return
	var port := _parse_port(host_port_input.text)
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Jugador 1"
	var err := NetworkManager.host_game(port, player_name)
	if err == OK:
		_show_room_view()
		_refresh_room_ui()


func _on_join_pressed() -> void:
	if NetworkManager == null:
		return
	var ip := join_ip_input.text.strip_edges()
	var port := _parse_port(join_port_input.text)
	var player_name := name_input.text.strip_edges()
	if player_name.is_empty():
		player_name = "Jugador 2"
	btn_host.disabled = true
	btn_join.disabled = true
	var err := NetworkManager.join_game(ip, port, player_name)
	if err != OK:
		btn_host.disabled = false
		btn_join.disabled = false


func _on_connection_succeeded() -> void:
	_show_room_view()
	_refresh_room_ui()


func _on_connection_failed(_reason: String) -> void:
	_show_connection_view()


func _on_char_selected(index: int) -> void:
	if _updating_ui or NetworkManager == null:
		return
	if index >= 0 and index < CHAR_KEYS.size():
		NetworkManager.request_set_character(CHAR_KEYS[index])


func _on_options_changed(_index: int) -> void:
	if _updating_ui or NetworkManager == null or not NetworkManager.is_host():
		return
	var map_key := MAP_KEYS[clampi(map_select.selected, 0, MAP_KEYS.size() - 1)]
	var diff_key := DIFF_KEYS[clampi(diff_select.selected, 0, DIFF_KEYS.size() - 1)]
	NetworkManager.set_game_options(map_key, diff_key)


func _on_ready_pressed() -> void:
	if NetworkManager:
		NetworkManager.request_toggle_ready()


func _on_start_pressed() -> void:
	if NetworkManager and NetworkManager.can_start_match():
		btn_start.disabled = true
		_set_status("Iniciando partida cooperativa...", false)
		NetworkManager.start_match()


func _on_leave_room_pressed() -> void:
	if NetworkManager:
		NetworkManager.disconnect_session(true)
	_show_connection_view()


func _on_back_menu_pressed() -> void:
	if NetworkManager:
		NetworkManager.disconnect_session(false)
	if SceneFlow:
		SceneFlow.change_to("res://scenes/ui/main_menu.tscn", 0.3)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _refresh_room_ui() -> void:
	if NetworkManager == null or not NetworkManager.is_multiplayer_active():
		return

	_updating_ui = true

	var is_srv := NetworkManager.is_host()
	var my_id := NetworkManager.get_local_peer_id()
	var ips := NetworkManager.get_local_lan_ips()
	if is_srv:
		room_info_label.text = "👑 SALA HOST  |  IP LAN: %s  |  Puerto: %d  (Local: 127.0.0.1)" % [ips[0], NetworkManager.current_port]
	else:
		room_info_label.text = "🔗 CONECTADO COMO CLIENTE  |  Puerto: %d" % NetworkManager.current_port

	# Mostrar datos de Jugador 1 (Host, peer_id = 1)
	if NetworkManager.players.has(1):
		var p1: Dictionary = NetworkManager.players[1]
		var c1: Dictionary = NetworkManager.get_character_data(str(p1.get("character", "cahuide")))
		p1_name_label.text = "P1 (Host): %s" % str(p1.get("name", "Jugador 1"))
		p1_char_label.text = "Personaje: %s" % str(c1.get("name", "Cahuide"))
		var r1 := bool(p1.get("ready", false))
		p1_ready_label.text = "✔ LISTO" if r1 else "⏳ No listo"
		p1_ready_label.modulate = Color(0.35, 1.0, 0.45) if r1 else Color(1.0, 0.85, 0.35)

	# Buscar Jugador 2 (primer peer != 1)
	var p2_id := -1
	for pid in NetworkManager.get_ordered_peer_ids():
		if pid != 1:
			p2_id = pid
			break

	if p2_id != -1:
		var p2: Dictionary = NetworkManager.players[p2_id]
		var c2: Dictionary = NetworkManager.get_character_data(str(p2.get("character", "chasqui")))
		p2_name_label.text = "P2 (Cliente): %s" % str(p2.get("name", "Jugador 2"))
		p2_char_label.text = "Personaje: %s" % str(c2.get("name", "Chasqui"))
		var r2 := bool(p2.get("ready", false))
		p2_ready_label.text = "✔ LISTO" if r2 else "⏳ No listo"
		p2_ready_label.modulate = Color(0.35, 1.0, 0.45) if r2 else Color(1.0, 0.85, 0.35)
	else:
		p2_name_label.text = "P2 (Cliente): Esperando conexión..."
		p2_char_label.text = "Comparte tu IP LAN y puerto %d" % NetworkManager.current_port
		p2_ready_label.text = "— Sin conectar"
		p2_ready_label.modulate = Color(0.7, 0.7, 0.7)

	# Sincronizar selector de personaje propio
	var my_info: Dictionary = NetworkManager.get_player_info(my_id)
	var my_char_key := str(my_info.get("character", "cahuide"))
	var char_idx := CHAR_KEYS.find(my_char_key)
	if char_idx != -1:
		char_select.select(char_idx)
	var my_char_data: Dictionary = NetworkManager.get_character_data(my_char_key)
	char_desc_label.text = str(my_char_data.get("desc", ""))

	# Sincronizar opciones de partida (solo el Host puede cambiarlas)
	var map_key := str(NetworkManager.game_options.get("map", "level_01"))
	var diff_key := str(NetworkManager.game_options.get("difficulty", "normal"))
	var map_idx := MAP_KEYS.find(map_key)
	if map_idx != -1:
		map_select.select(map_idx)
	var diff_idx := DIFF_KEYS.find(diff_key)
	if diff_idx != -1:
		diff_select.select(diff_idx)

	map_select.disabled = not is_srv
	diff_select.disabled = not is_srv
	var diff_desc := str(NetworkManager.DIFFICULTIES.get(diff_key, {}).get("desc", ""))
	if is_srv:
		options_hint_label.text = diff_desc
	else:
		options_hint_label.text = "%s (Solo el Host configura opciones)" % diff_desc

	# Botón Listo
	var am_ready := bool(my_info.get("ready", false))
	btn_ready.text = "✖ Cancelar Listo" if am_ready else "✔ ¡Estoy Listo!"

	# Botón Iniciar Partida (solo Host cuando ambos están listos)
	btn_start.visible = is_srv
	if is_srv:
		var can_start := NetworkManager.can_start_match()
		btn_start.disabled = not can_start
		if NetworkManager.players.size() < NetworkManager.MAX_PLAYERS:
			btn_start.text = "⏳ Esperando al 2do jugador..."
		elif not can_start:
			btn_start.text = "⏳ Ambos deben marcar Listo"
		else:
			btn_start.text = "⚔️ Iniciar Partida LAN"

	_updating_ui = false
