extends Node

## ====================================================================
## Laboratorio 12 - Secciones 9 & 34: SceneFlow con Catálogo y Fade Transicional
## ====================================================================
## Centraliza la navegación entre escenas y niveles del juego.
## Desacopla la lógica de niveles de las rutas de ficheros concretas.

const LEVELS: Dictionary = {
	&"level_01": "res://levels/level_01.tscn",
	&"level_02": "res://levels/level_02.tscn",
	&"level_03": "res://levels/level_03.tscn",
}

var is_changing_scene: bool = false
var fade_layer: CanvasLayer
var fade_rect: ColorRect

func _ready() -> void:
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 128

	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fade_layer.add_child(fade_rect)
	add_child(fade_layer)

func has_level(level_id: StringName) -> bool:
	return LEVELS.has(level_id)

func get_level_path(level_id: StringName) -> String:
	return LEVELS.get(level_id, "")

## Transición dedicada para niveles del catálogo
func go_to_level(level_id: StringName, duration: float = 0.25) -> void:
	if is_changing_scene:
		return

	if not has_level(level_id):
		push_error("SceneFlow Error: Nivel desconocido '%s'" % str(level_id))
		return

	var path: String = LEVELS[level_id]
	if GameState:
		GameState.current_level_id = level_id

	_perform_transition(path, duration)

## Transición genérica para cualquier escena (ej. menú principal)
func change_to(scene_path: String, duration: float = 0.25) -> void:
	if is_changing_scene:
		return
	_perform_transition(scene_path, duration)

func _perform_transition(scene_path: String, duration: float) -> void:
	is_changing_scene = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween_out := create_tween()
	tween_out.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween_out.finished

	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneFlow Error: No se pudo cargar: " + scene_path)

	await get_tree().process_frame

	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_changing_scene = false
