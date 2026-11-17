# Laboratorio 09: Matemáticas Aplicadas a Videojuegos

**Curso:** Desarrollo de Videojuegos 2D con Godot  
**Estudiante:** Adam Soto  
**Proyecto:** `Lab09_MathLab`  

---

## 🎯 Objetivo de la Sesión
Comprender y programar los fundamentos matemáticos que rigen el comportamiento cinemático y balístico en los videojuegos 2D: álgebra vectorial, trigonometría, producto punto (*dot product*), interpolación y tiro parabólico.

---

## 🛠️ Implementaciones Realizadas

1. **Álgebra Vectorial y Normalización:**
   - Suma y resta de vectores para determinar desplazamientos y distancias.
   - Demostración de por qué se debe normalizar el vector de movimiento diagonal para evitar que el avatar se desplace un $41.4\%$ más rápido en diagonal ($v = \sqrt{1^2 + 1^2} \approx 1.414$).

2. **Producto Punto (`Dot Product`):**
   - Cálculo del ángulo entre el vector frontal del enemigo y la dirección hacia el jugador para simular un cono de visión realista (visión periférica):
     $$\cos(\theta) = \hat{A} \cdot \hat{B}$$

3. **Interpolación Lineal (`lerp` y `slerp`):**
   - Suavizado de giro y transición gradual de posiciones y colores a lo largo del tiempo.

4. **Trayectorias Parabólicas Balísticas:**
   - Cálculo de trayectoria de proyectiles con gravedad simulada:
     $$\vec{P}(t) = \vec{P}_0 + \vec{V}_0 t + \frac{1}{2} \vec{g} t^2$$
   - Aplicación directa para el lanzamiento de piedras y jabalinas con caída natural en el proyecto.

---

## 💡 Conceptos Clave Aprendidos
- **Vectores Unitarios:** Son la base para expresar direcciones puras sin alterar magnitudes de velocidad.
- **Predicción de Trayectorias:** Permite tanto guiar proyectiles en pantalla como dibujar líneas de puntería predictivas en tiempo real.
