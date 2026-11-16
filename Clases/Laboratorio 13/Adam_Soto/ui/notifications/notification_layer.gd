class_name NotificationLayer
extends Control

## ====================================================================
## Laboratorio 13 - Sección 42: Notificaciones No Intrusivas (Toasts)
## ====================================================================
## Muestra avisos efímeros en pantalla al recoger objetos o alcanzar metas,
## sin interrumpir el flujo de juego ni abrir menús modalmente.

@onready var container: VBoxContainer = $MarginContainer/VBoxContainer

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE

func show_toast(text: String, color: Color = Color(0.3, 1.0, 0.45)) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.12, 0.16, 0.9)
	style.border_color = color
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 12
	style.content_margin_top = 6
	style.content_margin_right = 12
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)

	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)

	container.add_child(panel)

	# Animación de aparición, espera y desvanecimiento
	panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_interval(2.0)
	tween.tween_property(panel, "modulate:a", 0.0, 0.35)
	tween.tween_callback(panel.queue_free)
