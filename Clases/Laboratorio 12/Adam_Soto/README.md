# Laboratorio 12: Persistencia de Datos y Sistema de Checkpoints

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab12_Persistence`  

---

## 🎯 Objetivo de la Sesión
Implementar el ciclo completo de guardado y carga de partidas en almacenamiento secundario persistente (`user://`), serializar estructuras de datos complejas en formato JSON y diseñar un sistema de puntos de control (*Checkpoints*) con reaparición segura.

---

## 🛠️ Implementaciones Realizadas

1. **Administrador de Guardado (`SaveManager.gd`):**
   - Manejo del directorio virtual seguro de Godot (`user://save_game.json`).
   - Métodos de serialización estructurada:
     - Estado del jugador (vida actual, arma seleccionada, posición en coordenadas mundiales).
     - Estado de progreso (puntuación, monedas recolectadas, identificador de checkpoint activo).
     - Metadatos (fecha, hora y versión de la partida).
   - Manejo de excepciones con `FileAccess.open()` y validación contra partidas corruptas o inexistentes.

2. **Puntos de Control Físicos (`Checkpoint.tscn` / `checkpoint.gd`):**
   - Nodo `Area2D` con detección del jugador.
   - Activación única por punto con retroalimentación visual (cambio de textura/luz o animación de tótem activado).
   - Notificación global a través de `EventBus.checkpoint_activated.emit(global_position)` para que el `SaveManager` registre la nueva posición de reaparición (*respawn*).

3. **Flujo de Reaparición (*Respawn Flow*):**
   - Cuando la salud del jugador llega a 0, el juego reubica al jugador en la posición del último checkpoint activo restableciendo su salud y evitando reiniciar todo el nivel desde cero.

---

## 💡 Conceptos Clave Aprendidos
- **`res://` vs `user://`:** En un juego exportado a ejecutable (.exe), la ruta `res://` es de solo lectura (empaquetada en el binario). Cualquier escritura de datos persistentes debe realizarse obligatoriamente en `user://` (mapeada a `AppData` en Windows).
- **Serialización en JSON:** Facilita la depuración, legibilidad y migración de datos guardados.
