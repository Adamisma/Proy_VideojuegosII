# Laboratorio 13: Interfaz de Usuario Avanzada, Inventario y Flujo de Escenas

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab13_UI_Inventory`  

---

## 🎯 Objetivo de la Sesión
Construir una interfaz de usuario (*UI*) desacoplada y responsiva con nodos `Control` dentro de una capa independiente `CanvasLayer`, integrando un sistema de inventario interactivo con cuadrícula de slots y barra de acceso rápido (*Hotbar*), menú de pausa con guardado y transiciones fluidas de escenas con `SceneFlow`.

---

## 🛠️ Implementaciones Realizadas

1. **Sistema de Inventario Modular:**
   - **`InventoryData` (Resource):** Almacén de datos independiente que contiene arreglos de `ItemData` (nombre, descripción, icono, cantidad, acumulable o equipable).
   - **`InventorySlot`:** Componente de celda que visualiza el icono, cantidad y maneja eventos de selección o arrastre.
   - **`Hotbar`:** Barra inferior de acceso rápido para alternar armas y consumibles en tiempo real con teclas numéricas o acceso directo.

2. **Menú de Pausa y Flujo de Escenas (`SceneFlow.gd`):**
   - Pausado del árbol con `get_tree().paused = true`, configurando `process_mode = PROCESS_MODE_ALWAYS` en el menú de pausa para mantener la UI interactiva mientras la física del juego se detiene.
   - Opciones: **Reanudar**, **Guardar Partida**, **Cargar Partida** y **Salir al Menú Principal**.
   - `SceneFlow` coordina transiciones suaves con fundidos en negro entre el menú principal, pantallas de carga y niveles jugables.

3. **Arquitectura de Audio (`AudioServer`):**
   - Estructuración de buses de sonido independientes: **Master**, **Music** y **SFX**, permitiendo control de volumen independiente desde opciones de configuración.

---

## 💡 Conceptos Clave Aprendidos
- **Separación UI / Gameplay:** La interfaz debe ser una vista pasiva que escucha eventos y muestra datos; no debe contener lógica de combate ni modificar directamente la física del personaje.
- **`process_mode` en Godot:** Permite congelar selectivamente entidades físicas mientras la interfaz de usuario continúa respondiendo a clics del ratón o gamepad.
