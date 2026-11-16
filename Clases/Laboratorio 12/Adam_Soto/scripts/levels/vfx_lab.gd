extends Node2D

## ====================================================================
## Laboratorio 10 - Sección 10, 33 & 37: Escena Principal VFXLab
## ====================================================================
## Arena de pruebas que integra todos los sistemas visuales de la semana:
## 1. Iluminación nocturna mediante CanvasModulate + PointLight2D antorcha.
## 2. Sombras dinámicas proyectadas mediante LightOccluder2D.
## 3. Spawner desacoplado (VFXSpawner) redirigiendo partículas a VFXRoot.
## 4. Dash Trail, Land Dust y combate reactivo con shaders (Flash y Dissolve).
## 5. Pulso con TIME (cristal) y distorsión UV (zona de energía).
## 6. HUD de telemetría y pruebas en tiempo real.

const HIT_FX_SCENE: PackedScene = preload("res://scenes/vfx/fx_hit.tscn")
const DUMMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy_dummy.tscn")

@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var torch_light: PointLight2D = $TorchLight
@onready var vfx_spawner: VFXSpawner = $VFXSpawner
@onready var vfx_root: Node = $VFXRoot
@onready var enemies_container: Node2D = $Enemies
@onready var player: CharacterBody2D = $Player
@onready var hud_label: Label = $CanvasLayer/Panel/StatusLabel

var is_night_mode: bool = true
var shadows_active: bool = true

func _ready() -> void:
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Tecla M: Alternar CanvasModulate (Día / Noche) - Sección 18 & 33
		if event.keycode == KEY_M:
			is_night_mode = not is_night_mode
			canvas_modulate.color = Color(0.22, 0.24, 0.34, 1.0) if is_night_mode else Color(0.95, 0.95, 0.95, 1.0)
			_update_hud()

		# Tecla L: Alternar sombras de PointLight2D - Sección 19 & 33
		elif event.keycode == KEY_L:
			shadows_active = not shadows_active
			torch_light.shadow_enabled = shadows_active
			_update_hud()

		# Tecla K: Spawnear golpe crítico de prueba en el mouse - Reto 41
		elif event.keycode == KEY_K:
			var mouse_pos := get_global_mouse_position()
			if vfx_spawner:
				var hit := vfx_spawner.spawn_effect(HIT_FX_SCENE, mouse_pos) as FXHit
				if hit:
					hit.is_critical = true
			var camera := get_viewport().get_camera_2d() as MathCamera
			if camera:
				camera.trigger_shake(6.5)

		# Tecla B: Reaparecer Dummy si fue destruido
		elif event.keycode == KEY_B:
			_respawn_dummy_if_needed()

		# Tecla R: Reiniciar la escena
		elif event.keycode == KEY_R:
			get_tree().reload_current_scene()

func _respawn_dummy_if_needed() -> void:
	if enemies_container.get_child_count() == 0:
		var dummy := DUMMY_SCENE.instantiate() as Node2D
		dummy.position = Vector2(760, 480)
		enemies_container.add_child(dummy)
		_update_hud()

func _physics_process(_delta: float) -> void:
	_update_hud()

func _update_hud() -> void:
	if hud_label == null:
		return

	var enemy_count: int = enemies_container.get_child_count()
	var enemy_status := "VIVO" if enemy_count > 0 else "DESTRUIDO (Presiona 'B' para reaparecer)"

	var text := "=== TELEMETRÍA VFX & ILUMINACIÓN 2D ===\n"
	text += "Ambiente CanvasModulate: %s [Presiona 'M' para alternar]\n" % ("NOCHE (0.22, 0.24, 0.34)" if is_night_mode else "DÍA (Claro)")
	text += "Sombras LightOccluder2D: %s [Presiona 'L' para alternar]\n" % ("ACTIVADAS" if shadows_active else "DESACTIVADAS")
	text += "Maniquí de Pruebas: [%s]\n" % enemy_status
	text += "Efectos Activos en VFXRoot: %d\n" % vfx_root.get_child_count()

	hud_label.text = text
