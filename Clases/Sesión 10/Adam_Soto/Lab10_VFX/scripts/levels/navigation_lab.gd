extends Node2D

## ====================================================================
## Laboratorio 08 - Sección 8, 39 & 40: Escena Principal NavigationLab
## ====================================================================
## Administra la arena de pruebas de navegación, el control de depuración,
## la conmutación de avoidance en tiempo de ejecución y la telemetría en el HUD.

@onready var navigation_region: NavigationRegion2D = $NavigationRegion2D
@onready var player: PlayerTopDown = $PlayerTarget
@onready var enemies_container: Node2D = $Enemies
@onready var dynamic_crate: DynamicCrate = $DynamicObstacles/DynamicCrate
@onready var debug_ui_label: Label = $DebugUI/Panel/StatusLabel

var all_enemies: Array[EnemyNavigator] = []
var avoidance_globally_active: bool = true

func _ready() -> void:
	# Asegurar que el polígono de navegación tenga sus triángulos generados
	if navigation_region != null and navigation_region.navigation_polygon != null:
		if navigation_region.navigation_polygon.get_polygon_count() == 0:
			navigation_region.navigation_polygon.make_polygons_from_outlines()

	# Recopilar todos los agentes enemigos en la escena
	for child in enemies_container.get_children():
		if child is EnemyNavigator:
			all_enemies.append(child)

	_update_debug_text()

func _unhandled_input(event: InputEvent) -> void:
	# Conmutación de Avoidance con la tecla 'T' (QA y Demostración)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_T:
			avoidance_globally_active = not avoidance_globally_active
			for enemy in all_enemies:
				if is_instance_valid(enemy):
					enemy.toggle_avoidance(avoidance_globally_active)
			_update_debug_text()

		# Tecla 'K': Aplicar daño directo al Enemigo 1 para demostrar inmediatamente el estado FLEE (Reto 44)
		elif event.keycode == KEY_K:
			if all_enemies.size() > 0 and is_instance_valid(all_enemies[0]):
				var target_enemy := all_enemies[0]
				if target_enemy.health:
					target_enemy.health.take_damage(80.0) # Reduce vida al 20%, activando FLEE

		# Tecla 'R': Reiniciar escena
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene()

func _physics_process(_delta: float) -> void:
	_update_debug_text()

func _update_debug_text() -> void:
	if debug_ui_label == null:
		return

	var text := "=== ESTADO DE AGENTES NAVIGATOR ===\n"
	text += "Avoidance Global (RVO2): %s [Presiona 'T' para alternar]\n\n" % ("ACTIVADO (ON)" if avoidance_globally_active else "DESACTIVADO (OFF)")

	for i in range(all_enemies.size()):
		var enemy := all_enemies[i]
		if is_instance_valid(enemy):
			var state_name: String = EnemyNavigator.EnemyState.keys()[enemy.current_state]
			var hp: float = enemy.health.current_health if enemy.health else 0.0
			var max_hp: float = enemy.health.max_health if enemy.health else 100.0
			var dist: float = enemy.navigation_agent.distance_to_target() if enemy.has_navigation_target else 0.0
			var path_pts: int = enemy.navigation_agent.get_current_navigation_path().size()
			var avoidance_str: String = "ON" if enemy.navigation_agent.avoidance_enabled else "OFF"

			text += "Enemigo %d: Estado: [%s] | HP: %.0f/%.0f | Dist: %.1f px | Puntos Ruta: %d | Avoidance: %s\n" % [
				i + 1,
				state_name,
				hp,
				max_hp,
				dist,
				path_pts,
				avoidance_str
			]
		else:
			text += "Enemigo %d: ELIMINADO\n" % (i + 1)

	debug_ui_label.text = text
