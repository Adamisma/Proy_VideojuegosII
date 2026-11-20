extends Node

## ====================================================================
## Proyecto Cahuide - AudioManager Centralizado (Arquitectura de Audio)
## ====================================================================
## Administra la reproducción de música con crossfades, un pool eficiente
## de AudioStreamPlayers para SFX sin asignación dinámica de memoria,
## y control centralizado de buses (Master, Music, SFX).

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"

const SFX_POOL_SIZE: int = 16

var _music_player_a: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _active_music_player: AudioStreamPlayer = null
var _music_tween: Tween

var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_audio_buses()
	_init_music_players()
	_init_sfx_pool()


func _ensure_audio_buses() -> void:
	# Asegurar que existan los buses Music y SFX aunque no se haya cargado default_bus_layout
	if AudioServer.get_bus_index(BUS_MUSIC) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_MUSIC)
		AudioServer.set_bus_send(idx, BUS_MASTER)

	if AudioServer.get_bus_index(BUS_SFX) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, BUS_SFX)
		AudioServer.set_bus_send(idx, BUS_MASTER)


func _init_music_players() -> void:
	_music_player_a = AudioStreamPlayer.new()
	_music_player_a.name = "MusicPlayerA"
	_music_player_a.bus = BUS_MUSIC
	_music_player_a.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player_a)

	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.name = "MusicPlayerB"
	_music_player_b.bus = BUS_MUSIC
	_music_player_b.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music_player_b)


func _init_sfx_pool() -> void:
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFX_Player_%d" % i
		p.bus = BUS_SFX
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(p)
		_sfx_pool.append(p)


# ====================================================================
# CONTROL DE MÚSICA
# ====================================================================
func play_music(stream: AudioStream, fade_duration: float = 0.8, volume_db: float = 0.0) -> void:
	if stream == null:
		return

	# Si ya está sonando la misma pista, no reiniciar
	if _active_music_player != null and _active_music_player.stream == stream and _active_music_player.playing:
		return

	var incoming := _music_player_b if _active_music_player == _music_player_a else _music_player_a
	var outgoing := _active_music_player

	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween().set_parallel(true)

	incoming.stream = stream
	incoming.volume_db = -80.0
	incoming.play()

	_music_tween.tween_property(incoming, "volume_db", volume_db, fade_duration)
	if outgoing and outgoing.playing:
		_music_tween.tween_property(outgoing, "volume_db", -80.0, fade_duration)
		_music_tween.chain().tween_callback(outgoing.stop)

	_active_music_player = incoming


func stop_music(fade_duration: float = 0.8) -> void:
	if _active_music_player == null or not _active_music_player.playing:
		return

	if _music_tween and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_active_music_player, "volume_db", -80.0, fade_duration)
	_music_tween.tween_callback(_active_music_player.stop)
	_active_music_player = null


# ====================================================================
# CONTROL DE EFECTOS DE SONIDO (SFX POOL)
# ====================================================================
func play_sfx(stream: AudioStream, pitch_variance: float = 0.08, volume_db: float = 0.0) -> AudioStreamPlayer:
	if stream == null:
		return null

	var player := _get_available_sfx_player()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance) if pitch_variance > 0.0 else 1.0
	player.play()
	return player


func _get_available_sfx_player() -> AudioStreamPlayer:
	# Buscar uno inactivo en el pool
	for player in _sfx_pool:
		if not player.playing:
			return player
	# Si todos están activos, usar round-robin reciclado
	var selected := _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	return selected


# ====================================================================
# CONTROL DE VOLUMEN POR BUSES (0.0 A 1.0 LINEAL)
# ====================================================================
func set_bus_volume(bus_name: String, linear_vol: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		var clamped := clampf(linear_vol, 0.0001, 1.0)
		var db := linear_to_db(clamped) if linear_vol > 0.0 else -80.0
		AudioServer.set_bus_volume_db(idx, db)
		AudioServer.set_bus_mute(idx, linear_vol <= 0.0001)


func get_bus_volume(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 1.0
	if AudioServer.is_bus_mute(idx):
		return 0.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))


func set_master_volume(linear_vol: float) -> void:
	set_bus_volume(BUS_MASTER, linear_vol)


func set_music_volume(linear_vol: float) -> void:
	set_bus_volume(BUS_MUSIC, linear_vol)


func set_sfx_volume(linear_vol: float) -> void:
	set_bus_volume(BUS_SFX, linear_vol)
