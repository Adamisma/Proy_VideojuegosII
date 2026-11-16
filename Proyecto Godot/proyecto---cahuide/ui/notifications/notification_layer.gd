class_name NotificationLayer
extends Control

## ====================================================================
## Proyecto Cahuide - Notificaciones Flotantes Discretas (Toasts)
## ====================================================================
## Minimalista y optimizado para no saturar la pantalla (pensado en móvil).
## Muestra una única notificación a la vez con reemplazo fluido.

@onready var container: PanelContainer = $CenterContainer/ToastPanel
@onready var label: Label = $CenterContainer/ToastPanel/Margin/Label

var active_tween: Tween

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	container.modulate.a = 0.0

func show_toast(message: String, accent_color: Color = Color(1.0, 0.85, 0.2, 1.0)) -> void:
	if label == null or container == null:
		return

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	label.text = message
	label.add_theme_color_override("font_color", accent_color)

	container.modulate.a = 0.0
	active_tween = create_tween()
	active_tween.tween_property(container, "modulate:a", 1.0, 0.15)
	active_tween.tween_interval(1.8)
	active_tween.tween_property(container, "modulate:a", 0.0, 0.3)
