extends Node

## ====================================================================
## Proyecto Cahuide - NetworkManager (Multijugador LAN - US-05)
## ====================================================================
## Administra sesiones cooperativas LAN de 2 jugadores usando
## Godot High-Level Multiplayer (ENetMultiplayerPeer + RPCs).
## - Host (peer_id = 1): autoridad de lobby, enemigos, coleccionables y nivel.
## - Cliente (peer_id > 1): autoridad local sobre su propio Player para baja latencia.

const DEFAULT_PORT: int = 7777
const MAX_PLAYERS: int = 2
const CONNECTION_TIMEOUT_SEC: float = 6.0

const CHARACTERS: Dictionary = {
	"cahuide": {
		"name": "Cahuide (Guerrero)",
		"short": "Cahuide",
		"desc": "Equilibrado: combate cuerpo a cuerpo y Piedra Ancestral.",
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"badge_color": Color(1.0, 0.85, 0.25, 1.0),
		"speed_mult": 1.0,
		"max_health": 20,
		"melee_bonus": 0,
		"ranged_bonus": 0,
		"start_weapon": 0
	},
	"chasqui": {
		"name": "Chasqui Andino",
		"short": "Chasqui",
		"desc": "Ágil: +15% velocidad, +5 daño a distancia e inicia con Lanza Inca.",
		"tint": Color(0.72, 1.0, 0.90, 1.0),
		"badge_color": Color(0.35, 0.95, 0.82, 1.0),
		"speed_mult": 1.15,
		"max_health": 18,
		"melee_bonus": 0,
		"ranged_bonus": 5,
		"start_weapon": 1
	},
	"guardian": {
		"name": "Guardián Solar",
		"short": "Guardián",
		"desc": "Fuerza solar: +10 daño cuerpo a cuerpo y armadura dorada.",
		"tint": Color(1.0, 0.88, 0.56, 1.0),
		"badge_color": Color(1.0, 0.62, 0.22, 1.0),
		"speed_mult": 0.95,
		"max_health": 20,
		"melee_bonus": 10,
		"ranged_bonus": 0,
		"start_weapon": 0
	}
}

const DIFFICULTIES: Dictionary = {
	"facil": {
		"name": "Fácil",
		"enemy_hp_mult": 0.75,
		"enemy_speed_mult": 0.90,
		"desc": "Enemigos con menos vida (-25%) y menor velocidad."
	},
	"normal": {
		"name": "Normal",
		"enemy_hp_mult": 1.0,
		"enemy_speed_mult": 1.0,
		"desc": "Balance cooperativo estándar."
	},
	"dificil": {
		"name": "Difícil",
		"enemy_hp_mult": 1.40,
		"enemy_speed_mult": 1.15,
		"desc": "Enemigos reforzados (+40% vida) y más rápidos."
	}
}

const MAPS: Dictionary = {
	"level_01": {
		"name": "Nivel 1 - Sacsayhuamán",
		"level_id": &"level_01"
	},
	"level_02": {
		"name": "Nivel 2 - Fortaleza",
		"level_id": &"level_02"
	}
}

signal lobby_updated
signal connection_status_changed(status_text: String, is_error: bool)
signal connection_succeeded
signal connection_failed_with_reason(reason: String)
signal peer_left_match(peer_id: int, player_name: String)
signal host_disconnected_mid_match
signal partner_health_updated(peer_id: int, current_hp: int, max_hp: int, is_dead: bool)

var is_lan_session: bool = false
var match_started: bool = false
var players: Dictionary = {} # peer_id: int -> { name, character, ready, slot }
var game_options: Dictionary = {
	"map": "level_01",
	"difficulty": "normal"
}
var local_player_name: String = "Jugador"
var current_port: int = DEFAULT_PORT

var _connect_timer: Timer
var _is_connecting: bool = false
var _pending_ip: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_connect_timer = Timer.new()
	_connect_timer.one_shot = true
	_connect_timer.wait_time = CONNECTION_TIMEOUT_SEC
	_connect_timer.timeout.connect(_on_connection_timeout)
	add_child(_connect_timer)

	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


# ====================================================================
# CONSULTAS DE ESTADO
# ====================================================================
func is_multiplayer_active() -> bool:
	if not is_lan_session:
		return false
	var peer := multiplayer.multiplayer_peer
	if peer == null or peer is OfflineMultiplayerPeer:
		return false
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func is_host() -> bool:
	if not is_multiplayer_active():
		return true
	return multiplayer.is_server()


func get_local_peer_id() -> int:
	if is_multiplayer_active():
		return multiplayer.get_unique_id()
	return 1


func get_character_data(char_id: String) -> Dictionary:
	return CHARACTERS.get(char_id, CHARACTERS["cahuide"])


func get_difficulty_data() -> Dictionary:
	var diff_key: String = str(game_options.get("difficulty", "normal"))
	return DIFFICULTIES.get(diff_key, DIFFICULTIES["normal"])


func get_player_info(peer_id: int) -> Dictionary:
	return players.get(peer_id, {
		"name": "Jugador %d" % peer_id,
		"character": "cahuide",
		"ready": false,
		"slot": 1 if peer_id == 1 else 2
	})


func get_ordered_peer_ids() -> Array[int]:
	var ids: Array[int] = []
	for key in players.keys():
		ids.append(int(key))
	ids.sort()
	return ids


func get_local_lan_ips() -> PackedStringArray:
	var wifi_ips := PackedStringArray()
	var other_ips := PackedStringArray()
	for addr in IP.get_local_addresses():
		if addr.find(":") != -1:
			continue # Ignorar IPv6 para simplicidad en LAN
		if addr.begins_with("192.168."):
			if not wifi_ips.has(addr):
				wifi_ips.append(addr)
		elif addr.begins_with("10.") or _is_private_172(addr):
			if not other_ips.has(addr):
				other_ips.append(addr)
	var result := PackedStringArray()
	result.append_array(wifi_ips)
	result.append_array(other_ips)
	if result.is_empty():
		result.append("127.0.0.1")
	return result


func _is_private_172(addr: String) -> bool:
	if not addr.begins_with("172."):
		return false
	var parts := addr.split(".")
	if parts.size() != 4:
		return false
	var second := int(parts[1])
	return second >= 16 and second <= 31


# ====================================================================
# CONEXIÓN HOST / CLIENTE (ENet LAN)
# ====================================================================
func host_game(port: int = DEFAULT_PORT, player_name: String = "Jugador 1") -> Error:
	disconnect_session(false)

	if port < 1024 or port > 65535:
		var msg := "Puerto inválido (%d). Usa un valor entre 1024 y 65535." % port
		connection_status_changed.emit(msg, true)
		connection_failed_with_reason.emit(msg)
		return ERR_INVALID_PARAMETER

	var peer := ENetMultiplayerPeer.new()
	# max_clients = 1 -> Host + 1 Cliente = 2 jugadores en total
	var err := peer.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		var msg := "No se pudo abrir el servidor en el puerto %d (¿puerto en uso?)." % port
		connection_status_changed.emit(msg, true)
		connection_failed_with_reason.emit(msg)
		return err

	multiplayer.multiplayer_peer = peer
	is_lan_session = true
	match_started = false
	current_port = port
	local_player_name = player_name.strip_edges()
	if local_player_name.is_empty():
		local_player_name = "Jugador 1"

	players.clear()
	players[1] = {
		"name": local_player_name,
		"character": "cahuide",
		"ready": false,
		"slot": 1
	}

	var ips := get_local_lan_ips()
	connection_status_changed.emit(
		"Partida creada en %s:%d — Esperando al 2do jugador..." % [ips[0], port],
		false
	)
	connection_succeeded.emit()
	lobby_updated.emit()
	return OK


func join_game(host_ip: String, port: int = DEFAULT_PORT, player_name: String = "Jugador 2") -> Error:
	disconnect_session(false)

	var clean_ip := host_ip.strip_edges()
	if clean_ip.is_empty():
		clean_ip = "127.0.0.1"

	if port < 1024 or port > 65535:
		var msg := "Puerto inválido (%d). Usa un valor entre 1024 y 65535." % port
		connection_status_changed.emit(msg, true)
		connection_failed_with_reason.emit(msg)
		return ERR_INVALID_PARAMETER

	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(clean_ip, port)
	if err != OK:
		var msg := "No se pudo iniciar la conexión hacia %s:%d (IP inválida o error de red)." % [clean_ip, port]
		connection_status_changed.emit(msg, true)
		connection_failed_with_reason.emit(msg)
		return err

	multiplayer.multiplayer_peer = peer
	is_lan_session = true
	match_started = false
	_is_connecting = true
	_pending_ip = clean_ip
	current_port = port
	local_player_name = player_name.strip_edges()
	if local_player_name.is_empty():
		local_player_name = "Jugador 2"

	players.clear()
	_connect_timer.start(CONNECTION_TIMEOUT_SEC)
	connection_status_changed.emit("Conectando con %s:%d..." % [clean_ip, port], false)
	return OK


func disconnect_session(notify: bool = true) -> void:
	if _connect_timer and not _connect_timer.is_stopped():
		_connect_timer.stop()

	_is_connecting = false
	_pending_ip = ""

	var peer := multiplayer.multiplayer_peer
	if peer != null and not (peer is OfflineMultiplayerPeer):
		peer.close()
	multiplayer.multiplayer_peer = null

	is_lan_session = false
	match_started = false
	players.clear()

	if notify:
		connection_status_changed.emit("Desconectado de la sesión LAN.", false)
		lobby_updated.emit()


# ====================================================================
# CALLBACKS DE RED (ENet / MultiplayerAPI)
# ====================================================================
func _on_peer_connected(peer_id: int) -> void:
	if not is_lan_session:
		return
	if multiplayer.is_server():
		# Si ya hay 2 jugadores o la partida ya inició, desconectar al entrante
		if match_started or players.size() >= MAX_PLAYERS:
			var enet := multiplayer.multiplayer_peer as ENetMultiplayerPeer
			if enet:
				enet.disconnect_peer(peer_id)
			return
		connection_status_changed.emit("Jugador conectado (ID %d). Sincronizando lobby..." % peer_id, false)


func _on_peer_disconnected(peer_id: int) -> void:
	if not is_lan_session:
		return

	var left_name: String = str(players.get(peer_id, {}).get("name", "Jugador %d" % peer_id))
	players.erase(peer_id)

	if match_started:
		peer_left_match.emit(peer_id, left_name)
	else:
		connection_status_changed.emit("%s se ha desconectado del lobby." % left_name, true)
		if multiplayer.is_server():
			# Resetear estado listo del host al irse el compañero
			if players.has(1):
				players[1]["ready"] = false
			_rpc_sync_lobby.rpc(players, game_options)
		lobby_updated.emit()


func _on_connected_to_server() -> void:
	_is_connecting = false
	if _connect_timer and not _connect_timer.is_stopped():
		_connect_timer.stop()

	connection_status_changed.emit("¡Conectado al Host (%s:%d)!" % [_pending_ip, current_port], false)
	connection_succeeded.emit()
	# Registrarse en el Host
	_rpc_register_player.rpc_id(1, local_player_name, "chasqui")


func _on_connection_failed() -> void:
	var ip_str := _pending_ip
	var port_val := current_port
	disconnect_session(false)
	var msg := "Error de conexión: no se encontró el host en %s:%d." % [ip_str, port_val]
	connection_status_changed.emit(msg, true)
	connection_failed_with_reason.emit(msg)


func _on_connection_timeout() -> void:
	if not _is_connecting:
		return
	var ip_str := _pending_ip
	var port_val := current_port
	disconnect_session(false)
	var msg := "Timeout (%ds): el host %s:%d no respondió. Verifica IP, puerto y firewall." % [int(CONNECTION_TIMEOUT_SEC), ip_str, port_val]
	connection_status_changed.emit(msg, true)
	connection_failed_with_reason.emit(msg)


func _on_server_disconnected() -> void:
	var was_in_match := match_started
	disconnect_session(false)
	var msg := "Se perdió la conexión con el Host."
	connection_status_changed.emit(msg, true)
	if was_in_match:
		host_disconnected_mid_match.emit()
	else:
		connection_failed_with_reason.emit(msg)
	lobby_updated.emit()


# ====================================================================
# SINCRONIZACIÓN DE LOBBY Y OPCIONES (RPCs)
# ====================================================================
func request_set_character(character_id: String) -> void:
	if not is_multiplayer_active():
		return
	if not CHARACTERS.has(character_id):
		return
	if multiplayer.is_server():
		_apply_character_change(1, character_id)
	else:
		_rpc_set_character.rpc_id(1, character_id)


func request_toggle_ready() -> void:
	if not is_multiplayer_active():
		return
	var my_id := multiplayer.get_unique_id()
	var current_ready: bool = bool(players.get(my_id, {}).get("ready", false))
	var next_ready := not current_ready
	if multiplayer.is_server():
		_apply_ready_change(1, next_ready)
	else:
		_rpc_set_ready.rpc_id(1, next_ready)


func set_game_options(map_key: String, difficulty_key: String) -> void:
	if not is_multiplayer_active() or not multiplayer.is_server():
		return
	if MAPS.has(map_key):
		game_options["map"] = map_key
	if DIFFICULTIES.has(difficulty_key):
		game_options["difficulty"] = difficulty_key
	_rpc_sync_lobby.rpc(players, game_options)


func can_start_match() -> bool:
	if not is_multiplayer_active() or not multiplayer.is_server():
		return false
	if players.size() < MAX_PLAYERS:
		return false
	for p_data in players.values():
		if not bool(p_data.get("ready", false)):
			return false
	return true


func start_match() -> void:
	if not can_start_match():
		return
	_rpc_begin_match.rpc(game_options)


func _apply_character_change(peer_id: int, character_id: String) -> void:
	if not players.has(peer_id):
		return
	players[peer_id]["character"] = character_id
	_rpc_sync_lobby.rpc(players, game_options)


func _apply_ready_change(peer_id: int, is_ready: bool) -> void:
	if not players.has(peer_id):
		return
	players[peer_id]["ready"] = is_ready
	_rpc_sync_lobby.rpc(players, game_options)


@rpc("any_peer", "reliable")
func _rpc_register_player(player_name: String, character_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		return

	var clean_name := player_name.strip_edges()
	if clean_name.is_empty():
		clean_name = "Jugador 2"
	var chosen_char := character_id if CHARACTERS.has(character_id) else "chasqui"

	players[sender_id] = {
		"name": clean_name,
		"character": chosen_char,
		"ready": false,
		"slot": 2
	}
	connection_status_changed.emit("%s se unió a la sala. ¡Elijan personaje y marquen Listo!" % clean_name, false)
	_rpc_sync_lobby.rpc(players, game_options)


@rpc("any_peer", "reliable")
func _rpc_set_character(character_id: String) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	if CHARACTERS.has(character_id):
		_apply_character_change(sender_id, character_id)


@rpc("any_peer", "reliable")
func _rpc_set_ready(is_ready: bool) -> void:
	if not multiplayer.is_server():
		return
	var sender_id := multiplayer.get_remote_sender_id()
	_apply_ready_change(sender_id, is_ready)


@rpc("authority", "call_local", "reliable")
func _rpc_sync_lobby(synced_players: Dictionary, synced_options: Dictionary) -> void:
	players = synced_players.duplicate(true)
	game_options = synced_options.duplicate(true)
	lobby_updated.emit()


@rpc("authority", "call_local", "reliable")
func _rpc_begin_match(options: Dictionary) -> void:
	game_options = options.duplicate(true)
	match_started = true

	var map_key: String = str(game_options.get("map", "level_01"))
	var map_info: Dictionary = MAPS.get(map_key, MAPS["level_01"])
	var target_level_id: StringName = map_info.get("level_id", &"level_01")

	if GameState:
		GameState.start_new_game()
		GameState.current_level_id = target_level_id

	if SceneFlow:
		SceneFlow.go_to_level(target_level_id, 0.35)
	else:
		get_tree().change_scene_to_file("res://scenes/levels/%s.tscn" % String(target_level_id))


# ====================================================================
# SINCRONIZACIÓN GLOBAL DE PARTIDA (Nivel, Puntaje, Vida de Compañero)
# ====================================================================
func host_broadcast_level_change(level_id: StringName) -> void:
	if not is_multiplayer_active() or not multiplayer.is_server():
		return
	_rpc_change_level.rpc(String(level_id))


@rpc("authority", "call_local", "reliable")
func _rpc_change_level(level_id_str: String) -> void:
	var target_id := StringName(level_id_str)
	if GameState:
		GameState.current_level_id = target_id
		GameState.active_checkpoint_id = &""
	if SceneFlow:
		SceneFlow.go_to_level(target_id, 0.5)
	else:
		get_tree().change_scene_to_file("res://scenes/levels/%s.tscn" % level_id_str)


func host_broadcast_score(new_score: int, new_kills: int) -> void:
	if not is_multiplayer_active() or not multiplayer.is_server():
		return
	_rpc_sync_score.rpc(new_score, new_kills)


@rpc("authority", "call_remote", "reliable")
func _rpc_sync_score(new_score: int, new_kills: int) -> void:
	if GameState:
		GameState.score = new_score
		GameState.enemies_killed = new_kills
	if EventBus:
		EventBus.score_changed.emit(new_score)


func broadcast_local_health(current_hp: int, max_hp: int, is_dead_flag: bool) -> void:
	if not is_multiplayer_active():
		return
	_rpc_partner_health.rpc(current_hp, max_hp, is_dead_flag)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _rpc_partner_health(current_hp: int, max_hp: int, is_dead_flag: bool) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	partner_health_updated.emit(sender_id, current_hp, max_hp, is_dead_flag)
