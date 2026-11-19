# Laboratorio 05: Animaciones y Máquina de Estados Finitos (FSM)

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab05_AnimationFSM`  

---

## 🎯 Objetivo de la Sesión
Implementar una **Máquina de Estados Finitos (Finite State Machine - FSM)** para gestionar de manera escalable y sin condiciones espagueti el comportamiento del personaje, vinculando cada estado a su respectiva animación mediante `AnimationPlayer` y `AnimatedSprite2D`.

---

## 🛠️ Implementaciones Realizadas

1. **Estructura de la FSM (State Pattern):**
   - Definición de estados discretos:
     - `IDLE`: En reposo en el suelo.
     - `WALK` / `RUN`: Desplazamiento horizontal.
     - `JUMP`: Ascenso tras presionar la tecla de salto.
     - `FALL`: Caída libre o tras alcanzar el ápice del salto.
     - `DASH`: Impulso rápido temporal con inmunidad o velocidad fija.
     - `ATTACK`: Ejecución de combo o ataque cuerpo a cuerpo sin poder iniciar otros estados hasta finalizar.

2. **Controlador de Animaciones:**
   - Creación de hojas de sprites (*spritesheets*) y `SpriteFrames` para cada acción.
   - Sincronización precisa entre la duración del fotograma y la lógica física del estado.
   - Manejo del giro horizontal (`scale.x = 1` o `-1`) según la dirección del movimiento sin deformar las colisiones.

3. **Lógica de Transiciones:**
   - Métodos explícitos `enter_state()`, `exit_state()` y `update_state(delta)` que limpian flags y preparan el siguiente estado sin fugas lógicas.

---

## 💡 Conceptos Clave Aprendidos
- **Ventajas de una FSM:** Previene bugs comunes como poder saltar mientras se ataca, o atacar indefinidamente en el aire si la lógica no lo permite explícitamente.
- **Acoplamiento Débil:** El estado físico le notifica al reproductor de animación qué reproducir, manteniendo la lógica matemática separada del arte visual.
