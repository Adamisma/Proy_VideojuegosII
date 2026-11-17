# Laboratorio 03: Mecánicas de Plataformas y Game Feel

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab03_Platformer`  

---

## 🎯 Objetivo de la Sesión
Diseñar un controlador de plataformas 2D con alta satisfacción de control (*Game Feel*), implementando curvas de salto asimétricas, gravedad diferenciada y técnicas avanzadas de indulgencia al jugador como **Coyote Time** y **Jump Buffering**.

---

## 🛠️ Implementaciones Realizadas

1. **Salto de Altura Variable:**
   - Salto completo al mantener presionada la tecla de salto y corte inmediato de velocidad vertical al soltarla prematuramente (`cut_jump`), permitiendo saltos cortos o largos según la intención del jugador.

2. **Gravedad Asimétrica:**
   - Aplicación de un multiplicador de gravedad superior durante la caída (`fall_gravity_multiplier`), evitando la sensación de "salto lunar" o flotante y logrando un descenso rápido y dinámico.

3. **Coyote Time (Tiempo Coyote):**
   - Temporizador de gracia (`coyote_timer`) que permite saltar durante unos milisegundos después de que el personaje ha abandonado el borde de una plataforma sin haber tocado el vacío.

4. **Jump Buffering (Memoria de Salto):**
   - Almacenamiento anticipado de la pulsación de salto (`jump_buffer_timer`). Si el jugador presiona saltar justo antes de tocar el suelo, el salto se ejecuta inmediatamente al aterrizar sin perder el input.

5. **Mecánica de Dash:**
   - Impulso horizontal de alta velocidad con tiempo de reutilización (*cooldown*) para esquivar y alcanzar plataformas distantes.

---

## 💡 Conceptos Clave Aprendidos
- **Game Feel y Juiciness:** La diferencia entre una física matemáticamente correcta y una física divertida; las técnicas de indulgencia eliminan la frustración del jugador.
- **Detección de Suelo Robusta:** Uso combinado de `is_on_floor()`, velocidades verticales y temporizadores de gracia.
