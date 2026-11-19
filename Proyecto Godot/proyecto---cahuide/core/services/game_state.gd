extends Node

## ====================================================================
## Proyecto Cahuide - GameState (Estado de Sesión en Runtime)
## ====================================================================
## Mantiene el progreso activo durante la partida en curso.

var current_level_id: StringName = &"level_01"
var active_checkpoint_id: StringName = &""
var score: int = 0
var enemies_killed: int = 0
var collected_relics: Array[StringName] = []

func _ready() -> void:
	_configure_mobile_inputs()

func _configure_mobile_inputs() -> void:
	# En móvil, desacoplar los clics emulados de mouse de las acciones 'attack' y 'shoot'
	# para evitar ataques involuntarios al tocar el salto o la cruceta de movimiento.
	# Los botones táctiles en pantalla (TouchScreenButton) emiten las acciones directamente.
	if OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios"):
		strip_mouse_combat_events()

## Desacopla los eventos de mouse de attack y shoot
static func strip_mouse_combat_events() -> void:
	for action in ["attack", "shoot"]:
		for ev in InputMap.action_get_events(action):
			if ev is InputEventMouseButton:
				InputMap.action_erase_event(action, ev)

func start_new_game() -> void:
	current_level_id = &"level_01"
	active_checkpoint_id = &""
	score = 0
	enemies_killed = 0
	collected_relics.clear()
	if EventBus:
		EventBus.score_changed.emit(score)

func set_checkpoint(checkpoint_id: StringName) -> void:
	active_checkpoint_id = checkpoint_id
	if EventBus:
		EventBus.checkpoint_activated.emit(checkpoint_id)

func add_score(amount: int) -> void:
	score = maxi(score + amount, 0)
	if EventBus:
		EventBus.score_changed.emit(score)

func register_enemy_kill(score_awarded: int = 100) -> void:
	enemies_killed += 1
	add_score(score_awarded)
	if EventBus:
		EventBus.enemy_defeated.emit(score_awarded)

func is_relic_collected(relic_id: StringName) -> bool:
	return relic_id in collected_relics

func register_collected_relic(relic_id: StringName, score_val: int = 50) -> void:
	if relic_id != &"" and relic_id not in collected_relics:
		collected_relics.append(relic_id)
	add_score(score_val)
