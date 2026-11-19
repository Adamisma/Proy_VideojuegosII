class_name Level
extends Node2D

## ====================================================================
## Proyecto Cahuide - Controlador Base de Nivel (Level)
## ====================================================================
## Orquesta Checkpoints con reaparición segura, flujo de escena (SceneFlow),
## victoria por trofeo/medalla sagrada y coleccionables reliquia.

@export var level_id: StringName = &"level_01"
@export var level_objective: String = ""
@export var sky_speed: float = 15.0

@export_group("Configuración de niveles")
@export var next_level_path: String = ""
@export var is_final_level: bool = false
@export var transition_delay: float = 1.2

@export_group("Audio Ambiental")
@export var ambient_music: AudioStream
@export var ambient_volume_db: float = -6.0

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/player.tscn")

var level_finished: bool = false
var local_player: Player = null
var net_players: Dictionary = {} # peer_id: int -> Player

@onready var player: Player = get_node_or_null("Player")
@onready var player_spawn: Marker2D = get_node_or_null("PlayerSpawn")
@onready var hud: HUD = get_node_or_null("HUD")
@onready var ui_controller: UIController = get_node_or_null("UIController")
@onready var enemies_container: Node2D = get_node_or_null("Enemies")
@onready var sky_layer: ParallaxLayer = get_node_or_null("ParallaxBackground/ParallaxLayer_Cielo")
@onready var goal: LevelGoal = get_node_or_null("LevelGoal")
@onready var ambient_music_player: AudioStreamPlayer = get_node_or_null("AmbientMusic")

var checkpoint_positions: Dictionary = {}
var total_relics: int = 0
var collected_relics: int = 0


func _ready() -> void:
	if GameState:
		GameState.current_level_id = level_id

	_setup_ambient_music()
	_register_checkpoints()

	if NetworkManager and NetworkManager.is_multiplayer_active():
		_setup_multiplayer_players()
		if not NetworkManager.peer_left_match.is_connected(_on_peer_left_match):
			NetworkManager.peer_left_match.connect(_on_peer_left_match)
		if not NetworkManager.host_disconnected_mid_match.is_connected(_on_host_disconnected_mid_match):
			NetworkManager.host_disconnected_mid_match.connect(_on_host_disconnected_mid_match)
	else:
		_spawn_player_from_state()
		local_player = player

	# Conexión del jugador local
	if local_player:
		local_player.health_changed.connect(_on_player_health_changed)
		local_player.player_died.connect(_on_player_died)
		local_player.respawn_requested.connect(respawn_player_at_checkpoint)

	# Conexión con HUD / UI
	var active_hud: HUD = hud
	if active_hud == null and ui_controller:
		active_hud = ui_controller.get_node_or_null("HUD") as HUD

	if active_hud:
		active_hud.restart_requested.connect(_on_restart_level)
		active_hud.main_menu_requested.connect(_on_return_main_menu)
		if local_player:
			active_hud.bind_player(local_player)
		if level_objective != "":
			active_hud.set_objective_text(level_objective)

	# Configurar reliquias y meta final
	_setup_relics()
	_setup_level_goal()

	# Conectar EventBus global
	if EventBus and not EventBus.level_completed.is_connected(_on_eventbus_level_completed):
		EventBus.level_completed.connect(_on_eventbus_level_completed)

	# Conectar enemigos del nivel mediante Patrón Observador
	if enemies_container:
		for child in enemies_container.get_children():
			if child is Enemy:
				_register_enemy(child)

		enemies_container.child_entered_tree.connect(func(node: Node) -> void:
			if node is Enemy:
				_register_enemy(node)
		)


func _exit_tree() -> void:
	if EventBus and EventBus.level_completed.is_connected(_on_eventbus_level_completed):
		EventBus.level_completed.disconnect(_on_eventbus_level_completed)
	if NetworkManager:
		if NetworkManager.peer_left_match.is_connected(_on_peer_left_match):
			NetworkManager.peer_left_match.disconnect(_on_peer_left_match)
		if NetworkManager.host_disconnected_mid_match.is_connected(_on_host_disconnected_mid_match):
			NetworkManager.host_disconnected_mid_match.disconnect(_on_host_disconnected_mid_match)


func _get_active_spawn_pos() -> Vector2:
	var spawn_pos: Vector2 = player_spawn.global_position if player_spawn else Vector2(180, 616)
	var cp_id: StringName = GameState.active_checkpoint_id if GameState else &""
	if cp_id != &"" and checkpoint_positions.has(cp_id):
		spawn_pos = checkpoint_positions[cp_id]
	return spawn_pos


func _setup_multiplayer_players() -> void:
	net_players.clear()
	var spawn_pos := _get_active_spawn_pos()

	# El nodo "Player" existente en la escena corresponde al Host (peer_id = 1)
	if player:
		var p1_info: Dictionary = NetworkManager.get_player_info(1)
		player.configure_network_player(
			1,
			str(p1_info.get("name", "Jugador 1")),
			str(p1_info.get("character", "cahuide")),
			1
		)
		player.respawn_at(spawn_pos)
		net_players[1] = player

	# Instanciar al 2do jugador con el MISMO nombre de nodo en Host y Cliente para sincronía RPC
	for pid in NetworkManager.get_ordered_peer_ids():
		if pid == 1:
			continue
		var p2 := PLAYER_SCENE.instantiate() as Player
		if p2 == null:
			continue
		p2.name = "Player_%d" % pid
		var p2_info: Dictionary = NetworkManager.get_player_info(pid)
		p2.configure_network_player(
			pid,
			str(p2_info.get("name", "Jugador 2")),
			str(p2_info.get("character", "chasqui")),
			2
		)
		add_child(p2)
		p2.respawn_at(spawn_pos + Vector2(56.0, 0.0))
		net_players[pid] = p2

	var my_id := NetworkManager.get_local_peer_id()
	local_player = net_players.get(my_id, player)
	var ui_ctrl := ui_controller if ui_controller else (get_node_or_null("UIController") as UIController)
	if ui_ctrl:
		var diff_name := str(NetworkManager.get_difficulty_data().get("name", "Normal"))
		ui_ctrl.show_toast("🌐 Partida LAN iniciada (Dificultad: %s)" % diff_name, Color(0.45, 0.95, 1.0))


func _register_checkpoints() -> void:
	checkpoint_positions.clear()
	for node in get_tree().get_nodes_in_group("checkpoint"):
		var cp := node as Checkpoint
		if cp == null:
			continue
		var spawn_pos: Vector2 = cp.spawn_point.global_position if cp.spawn_point else cp.global_position
		checkpoint_positions[cp.checkpoint_id] = spawn_pos
		cp.activated.connect(_on_checkpoint_activated)


func _spawn_player_from_state() -> void:
	var target_player: Player = local_player if local_player else player
	if target_player == null:
		return

	var spawn_pos := _get_active_spawn_pos()
	if NetworkManager and NetworkManager.is_multiplayer_active() and target_player.player_slot == 2:
		spawn_pos += Vector2(56.0, 0.0)

	target_player.respawn_at(spawn_pos)


func _setup_relics() -> void:
	var relics := get_tree().get_nodes_in_group("relics")
	total_relics = relics.size()
	collected_relics = 0

	for node in relics:
		if node is Relic:
			node.relic_collected.connect(_on_relic_collected)

	_update_relics_ui()


func _setup_level_goal() -> void:
	if goal == null:
		goal = get_node_or_null("LevelGoal") as LevelGoal
	if goal:
		if not goal.goal_reached.is_connected(_on_goal_reached):
			goal.goal_reached.connect(_on_goal_reached)


func _process(delta: float) -> void:
	# Reinicio rápido con tecla [R]
	if Input.is_action_just_pressed("restart"):
		respawn_player_at_checkpoint()

	# Detección de caída al vacío: reaparece en checkpoint
	var target_player: Player = local_player if local_player else player
	if target_player and is_instance_valid(target_player) and target_player.global_position.y > 850.0:
		target_player.take_direct_damage(2) # Pierde 1 corazón de daño por caída
		respawn_player_at_checkpoint()

	# Desplazamiento sutil del cielo en Parallax
	if sky_layer:
		sky_layer.motion_offset.x -= sky_speed * delta


func _on_player_health_changed(new_health: int, max_hp: int) -> void:
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud:
		active_hud.update_health(new_health, max_hp)


func _on_player_died() -> void:
	if NetworkManager and NetworkManager.is_multiplayer_active():
		var ui_ctrl := ui_controller if ui_controller else (get_node_or_null("UIController") as UIController)
		if ui_ctrl:
			ui_ctrl.show_toast("💀 Has caído... Reapareciendo en 3s (o pulsa [R])", Color(1.0, 0.45, 0.4))
		await get_tree().create_timer(3.0).timeout
		if is_inside_tree() and local_player and is_instance_valid(local_player) and local_player.is_dead:
			respawn_player_at_checkpoint()
		return

	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud:
		active_hud.show_game_over()


func _on_relic_collected(_relic: Relic) -> void:
	collected_relics += 1
	_update_relics_ui()


func _update_relics_ui() -> void:
	var remaining := maxi(total_relics - collected_relics, 0)
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud:
		active_hud.update_relics_count(remaining, total_relics)


func _on_eventbus_level_completed(_lvl_id: StringName) -> void:
	if not level_finished:
		_on_goal_reached()


func _on_goal_reached() -> void:
	if level_finished:
		return

	level_finished = true

	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	var ui_ctrl := ui_controller if ui_controller else (get_node_or_null("UIController") as UIController)

	# Nivel final o sin siguiente nivel: pantalla de victoria completa
	if is_final_level or next_level_path == "":
		if active_hud:
			active_hud.show_victory(true)
		if ui_ctrl:
			ui_ctrl.show_toast("👑 ¡Victoria en Sacsayhuamán! Fortaleza Defendida", Color(1.0, 0.85, 0.2))
		return

	# Nivel intermedio: mensaje triunfal y desvanecimiento a negro
	if active_hud:
		active_hud.show_victory(false)
	if ui_ctrl:
		ui_ctrl.show_toast("¡Nivel Superado! Avanzando al siguiente sector...", Color(0.3, 1.0, 0.5))

	await get_tree().create_timer(transition_delay).timeout

	if NetworkManager and NetworkManager.is_multiplayer_active():
		# En LAN solo el Host ordena el cambio sincronizado de nivel
		if multiplayer.is_server():
			var next_id: StringName = &"level_02" if next_level_path.find("level_02") != -1 else &"level_01"
			NetworkManager.host_broadcast_level_change(next_id)
		return

	if SceneFlow:
		SceneFlow.change_to(next_level_path, 0.6)
	elif next_level_path != "":
		get_tree().change_scene_to_file(next_level_path)


func _register_enemy(enemy_node: Enemy) -> void:
	if not enemy_node.enemy_defeated.is_connected(_on_enemy_defeated):
		enemy_node.enemy_defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated(enemy_node: Enemy) -> void:
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud:
		if is_instance_valid(enemy_node) and "score_value" in enemy_node:
			active_hud.add_score(enemy_node.score_value)
		active_hud.add_enemy_defeated()


func _on_checkpoint_activated(checkpoint_id: StringName, _pos: Vector2) -> void:
	if GameState:
		GameState.set_checkpoint(checkpoint_id)
	if SaveManager:
		SaveManager.save_game()


func respawn_player_at_checkpoint() -> void:
	_spawn_player_from_state()
	var active_hud: HUD = hud if hud else (ui_controller.get_node_or_null("HUD") as HUD if ui_controller else null)
	if active_hud and active_hud.game_over_panel:
		active_hud.game_over_panel.visible = false


func _on_restart_level() -> void:
	if SceneFlow:
		SceneFlow.reload_current()
	else:
		get_tree().reload_current_scene()


func _on_return_main_menu() -> void:
	if NetworkManager and NetworkManager.is_lan_session:
		NetworkManager.disconnect_session(false)
	if SceneFlow:
		SceneFlow.change_to("res://scenes/ui/main_menu.tscn", 0.35)
	else:
		get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")


func _on_peer_left_match(disconnected_peer_id: int, player_name: String) -> void:
	if net_players.has(disconnected_peer_id):
		var remote_node := net_players[disconnected_peer_id] as Node
		if is_instance_valid(remote_node):
			remote_node.queue_free()
		net_players.erase(disconnected_peer_id)

	var ui_ctrl := ui_controller if ui_controller else (get_node_or_null("UIController") as UIController)
	if ui_ctrl:
		ui_ctrl.show_toast("⚠️ %s se desconectó. Puedes continuar solo." % player_name, Color(1.0, 0.55, 0.3))


func _on_host_disconnected_mid_match() -> void:
	var ui_ctrl := ui_controller if ui_controller else (get_node_or_null("UIController") as UIController)
	if ui_ctrl:
		ui_ctrl.show_toast("⚠️ Conexión perdida con el Host. Volviendo al Lobby...", Color(1.0, 0.38, 0.38))
	await get_tree().create_timer(1.8).timeout
	if is_inside_tree():
		if SceneFlow:
			SceneFlow.change_to("res://scenes/ui/lan_lobby.tscn", 0.35)
		else:
			get_tree().change_scene_to_file("res://scenes/ui/lan_lobby.tscn")

func _setup_ambient_music() -> void:
	if ambient_music == null:
		return

	if ambient_music is AudioStreamMP3:
		(ambient_music as AudioStreamMP3).loop = true

	if ambient_music_player == null:
		ambient_music_player = AudioStreamPlayer.new()
		ambient_music_player.name = "AmbientMusic"
		ambient_music_player.bus = &"Master"
		ambient_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(ambient_music_player)

	ambient_music_player.stream = ambient_music
	ambient_music_player.volume_db = ambient_volume_db
	if not ambient_music_player.playing:
		ambient_music_player.play()
