extends Node

## ====================================================================
## Laboratorio 11 - Sección 23 & Reto 43: SceneFlow con Fade Transicional
## ====================================================================
## Centraliza la navegación entre escenas del proyecto sin que los actores ni
## la UI conozcan rutas concretas ni acoplamientos rígidos.
## Reto 43: Incorpora transición suave de oscurecimiento (fade) mediante CanvasLayer.

var is_changing_scene: bool = false
var fade_layer: CanvasLayer
var fade_rect: ColorRect

func _ready() -> void:
	# Capa superior de transición visual
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 128
	
	fade_rect = ColorRect.new()
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	fade_layer.add_child(fade_rect)
	add_child(fade_layer)

func change_to(scene_path: String, duration: float = 0.25) -> void:
	if is_changing_scene:
		return
	is_changing_scene = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween.finished

	call_deferred("_change_deferred", scene_path, duration)

func _change_deferred(scene_path: String, duration: float) -> void:
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		push_error("SceneFlow Error: No se pudo cargar: " + scene_path)

	var tween := create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_changing_scene = false
