extends Node

## ====================================================================
## Proyecto Cahuide - SceneFlow (Navegación con Fade Transicional)
## ====================================================================
## Administra cambios de escena con cortinilla de fundido suave y protección de inputs.

const LEVELS: Dictionary = {
	&"level_01": "res://scenes/levels/level_01.tscn",
	&"level_02": "res://scenes/levels/level_02.tscn"
}

var is_changing_scene: bool = false
var fade_layer: CanvasLayer
var fade_rect: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
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

func go_to_level(level_id: StringName, duration: float = 0.3) -> void:
	if is_changing_scene:
		return

	var path: String = LEVELS.get(level_id, "res://scenes/levels/level_01.tscn")
	if GameState:
		GameState.current_level_id = level_id

	_perform_transition(path, duration)

func change_to(scene_path: String, duration: float = 0.3) -> void:
	if is_changing_scene:
		return
	_perform_transition(scene_path, duration)

func reload_current(duration: float = 0.25) -> void:
	if is_changing_scene:
		return
	is_changing_scene = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween_out := create_tween()
	tween_out.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween_out.finished

	get_tree().reload_current_scene()
	await get_tree().process_frame

	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_changing_scene = false

func _perform_transition(scene_path: String, duration: float) -> void:
	is_changing_scene = true
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween_out := create_tween()
	tween_out.tween_property(fade_rect, "color:a", 1.0, duration)
	await tween_out.finished

	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneFlow: No se pudo cargar: " + scene_path)

	await get_tree().process_frame

	var tween_in := create_tween()
	tween_in.tween_property(fade_rect, "color:a", 0.0, duration)
	await tween_in.finished

	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_changing_scene = false
