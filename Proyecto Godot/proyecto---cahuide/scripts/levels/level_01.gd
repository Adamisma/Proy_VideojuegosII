class_name Level01
extends Node2D

## HU05 — Construir el Nivel 1: "🌅 El Despertar de la Resistencia"
## Inspirado en la fortaleza ancestral de Sacsayhuamán

@onready var player: Player = $Player
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var hud: HUD = $HUD
@onready var relic: Relic = $Relic
@onready var enemies_container: Node2D = $Enemies

func _ready() -> void:
	# Posicionar al jugador en el punto de inicio
	if player and player_spawn:
		player.global_position = player_spawn.global_position
		player.health_changed.connect(_on_player_health_changed)
		player.player_died.connect(_on_player_died)
		
	# Conectar interfaz HUD
	if hud:
		hud.restart_requested.connect(_on_restart_level)
		hud.main_menu_requested.connect(_on_return_main_menu)
		if player:
			hud.update_health(player.health, player.max_health)
			
	# Conectar meta final (Reliquia Ancestral)
	if relic:
		relic.relic_collected.connect(_on_relic_collected)
		
	# Conectar enemigos del nivel
	if enemies_container:
		for child in enemies_container.get_children():
			if child is Enemy:
				child.enemy_defeated.connect(_on_enemy_defeated)

func _process(_delta: float) -> void:
	# Reinicio rápido con tecla [R]
	if Input.is_action_just_pressed("restart"):
		_on_restart_level()
		
	# Detección de caída al vacío
	if player and player.global_position.y > 800.0:
		player.take_direct_damage(100)

func _on_player_health_changed(new_health: int, max_health: int) -> void:
	if hud:
		hud.update_health(new_health, max_health)

func _on_player_died() -> void:
	if hud:
		hud.show_game_over()

func _on_relic_collected() -> void:
	if hud:
		hud.show_victory()

func _on_enemy_defeated(_enemy: Enemy) -> void:
	if hud:
		hud.add_enemy_defeated()

func _on_restart_level() -> void:
	get_tree().reload_current_scene()

func _on_return_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
