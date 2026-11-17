# Laboratorio 02: Movimiento y Física 2D (CharacterBody2D)

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyectos:** `Lab01_Godot2D` y `Lab02_MovimientoFisica`  

---

## 🎯 Objetivo de la Sesión
Comprender el motor de física 2D de Godot 4, implementar el cuerpo cinemático principal (`CharacterBody2D`), gestionar la lectura vectorial de controles del jugador y aplicar fórmulas de aceleración, fricción y colisiones físicas continuas.

---

## 🛠️ Implementaciones Realizadas

1. **Cuerpo Cinemático del Jugador (`CharacterBody2D`):**
   - Configuración de capas y máscaras de colisión físicas (`collision_layer` y `collision_mask`).
   - Asignación de formas de colisión óptimas (`CapsuleShape2D` y `RectangleShape2D`) para evitar bloqueos en esquinas.

2. **Lectura Vectorial de Input:**
   - Uso de `Input.get_vector("move_left", "move_right", "move_up", "move_down")` para soporte nativo y suave tanto de teclado como de joystick análogo.

3. **Cálculo Físico en `_physics_process`:**
   - Implementación de aceleración y desaceleración usando interpolación lineal (`move_toward` / `lerp`) para eliminar frenados bruscos.
   - Uso de la propiedad nativa `velocity` y el método `move_and_slide()` propio de Godot 4 para resolver deslizamientos contra muros y obstáculos sin penetración física.

4. **Entorno de Pruebas Físicas:**
   - Creación de plataformas estáticas con `StaticBody2D` para comprobar detección de suelo (`is_on_floor()`) y colisiones laterales (`is_on_wall()`).

---

## 💡 Conceptos Clave Aprendidos
- **`_process` vs `_physics_process`:** La física debe procesarse siempre en `_physics_process` a un intervalo fijo de tiempo (`delta`), asegurando consistencia matemática sin importar los FPS de renderizado.
- **`move_and_slide()` en Godot 4:** A diferencia de Godot 3, ya no requiere pasar el vector `velocity` como parámetro ni reasignarlo manualmente.
- **Aceleración y Fricción:** Proporcionan inercia y control responsivo al avatar.
