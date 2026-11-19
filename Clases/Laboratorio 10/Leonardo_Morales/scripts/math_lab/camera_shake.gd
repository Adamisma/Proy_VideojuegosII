class_name MathCamera
extends Camera2D

## ====================================================================
## Laboratorio 09 - Sección 16: Shake Matemático de Cámara
## ====================================================================
## Produce una vibración de cámara suave y transitoria combinando:
## 1. Dos osciladores armónicos ortogonales con frecuencias inconmensurables (f_x != f_y)
##    para evitar trayectorias diagonales monótonas:
##      offset = (sin(t * f_x), sin(t * f_y)) * fuerza
## 2. Una envolvente de decaimiento exponencial continuo que amortigua la intensidad sin saltos:
##      I(t) = I_0 * e^(-decay_rate * t)

@export_category("Shake Dynamics")
@export var decay_rate: float = 8.0 ## Tasa de decaimiento exponencial (λ). Mayor valor = amortiguación más rápida.
@export var shake_frequency_x: float = 22.0 ## Frecuencia angular de oscilación horizontal en rad/s
@export var shake_frequency_y: float = 31.0 ## Frecuencia angular de oscilación vertical en rad/s

var shake_time: float = 0.0
var shake_strength: float = 0.0

## Dispara o superpone una sacudida con una intensidad inicial dada
func trigger_shake(strength: float) -> void:
	shake_strength = max(shake_strength, max(strength, 0.0))
	shake_time = 0.0

func _process(delta: float) -> void:
	# Umbral de corte para desactivar el efecto y retornar exactamente a reposo
	if shake_strength < 0.05:
		shake_strength = 0.0
		offset = Vector2.ZERO
		return

	shake_time += delta

	# Fórmula: Decaimiento exponencial independiente de la tasa de frames
	# I_(t + Δt) = I_t * e^(-λ * Δt)
	shake_strength *= exp(-decay_rate * delta)

	# Fórmula: Síntesis de ondas de Lissajous bidimensionales moduladas por la envolvente
	offset = Vector2(
		sin(shake_time * shake_frequency_x),
		sin(shake_time * shake_frequency_y)
	) * shake_strength
