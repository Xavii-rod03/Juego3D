# PROYECTO: PRIMERA ENTREGA - ESCENA Y MECANICA INICIAL
## LABERINTO 3D

**Materia:** Seminario de Sistemas de Informacion II (Trimestre 26-O)  
**Modalidad:** Trabajo en Equipo  
**Integrantes:** Daniela Campos Martinez, Karina Ivonne Bazan Rojas, Francisco Javier Garcia Rosados  
**Repositorio GitHub:** [https://github.com/Xavii-rod03/Juego3D.git](https://github.com/Xavii-rod03/Juego3D.git)  
**Carpeta del Video:** [https://drive.google.com/drive/folders/1_pSartHef60XlG2sK8ziR8cuuNBJI3IX?usp=sharing](https://drive.google.com/drive/folders/1_pSartHef60XlG2sK8ziR8cuuNBJI3IX?usp=sharing)  
**Motor:** Godot Engine 4.x (Forward+, Direct3D 12, Fisicas Jolt)  

---

### 1. Concepto actualizado y cambios frente a Proyecto 0
En Proyecto 0 propusimos una exploracion basica en un entorno estatico sin objetivos claros. Para esta entrega concretamos las reglas del juego:
- **Restriccion central:** El acceso a la salida esta bloqueado fisicamente por una Compuerta de Seguridad. El jugador debe buscar la Llave de Acceso para abrirla y cruzar la Meta.
- **Recorrido del jugador:** Aparece en el inicio (Spawn) al noroeste, explora el laberinto guiado por la brujula del HUD y una columna de luz vertical, recoge la llave en el altar este y regresa a cruzar la compuerta abierta en el sector sur.
- **Cierre formal:** Al pisar la meta se detiene el cronometro, se muestra la pantalla de victoria con el tiempo total y se permite reiniciar con la tecla R.

---

### 2. Escena, controlador, camara y colisiones
El proyecto se estructura en escenas modulares independientes dentro de `res://scenes/` (`level.tscn`, `player.tscn`, `hud.tscn`, `interactables/` y `props/`):
- **Entorno e iluminacion:** Configuramos una luz de sol (`DirectionalLight3D`) con sombras suaves y cielo diurno. El suelo utiliza un shader de losas verde salvia mate con baja reflectividad especular para no cansar la vista.
- **Muros del laberinto (90x90m):** Muros de 3.8m con `StaticBody3D` y colisiones de caja (`BoxShape3D`), delimitando pasillos amplios de 5 a 12 metros de ancho.
- **Controlador (`CharacterBody3D`):** El movimiento en el plano XZ se calcula relativo a la orientacion de la camara. La gravedad escala con `delta` en `_physics_process` y el desplazamiento se resuelve con `move_and_slide()` sin duplicar el delta. Incluye maquina de estados (IDLE, WALK, JUMP).
- **Camara orbital con `SpringArm3D`:** Brazo con colision esferica de 3.5m que se contrae suavemente al chocar con paredes para evitar atravesar la geometria.

---

### 3. Interaccion central verificable
La mecanica de interaccion conecta los elementos del juego mediante el sistema de senales de Godot en cuatro pasos:
1. El jugador toca la **Llave de Acceso** (`Area3D`), la cual emite la senal `key_collected` y se elimina del arbol con `queue_free()`.
2. El gestor del nivel (`level_controller.gd`) recibe la senal y ordena abrir la compuerta.
3. La **Compuerta** (`door_gate.gd`, `StaticBody3D`) baja 3.5m de forma animada, cambia su indicador a verde menta y desactiva su colision (`CollisionShape3D.disabled = true`).
4. El jugador cruza al sector sur y pisa la **Meta** (`goal_zone.gd`, `Area3D`), la cual emite `goal_reached` para que la interfaz (`hud.gd`) detenga el cronometro y despliegue el panel final de victoria.

---

### 4. Justificacion de la organizacion de datos (POO vs. Datos)
Al analizar la arquitectura del motor, el Diseno Orientado a Datos (DOD) con memoria contigua (como `PackedVector3Array`) resulta notablemente superior cuando se manejan miles de entidades simultaneas, debido al aprovechamiento directo de las lineas de cache del procesador y a evitar la indireccion de memoria por punteros.

Sin embargo, para esta Primera Entrega decidimos utilizar **Programacion Orientada a Objetos (POO)** basada en nodos y senales:
1. **Escala reducida:** En este momento solo interactuan 4 objetos clave (jugador, llave, compuerta y meta). Con tan pocos elementos, el coste de procesamiento de CPU es minimo ($< 0.05\text{ ms}$), por lo que no compromete la tasa de cuadros ni genera cuellos de botella.
2. **Claridad y modularidad:** Cada nodo encapsula su propia logica y representacion visual, permitiendo un desarrollo limpio y facil de mantener en equipo.

*Plan para fases posteriores:* Cuando el juego requiera incorporar a los 15 agentes autonomos y multitudes de entidades, implementaremos una arquitectura hibrida: POO para el jugador y la interfaz, y orientacion a datos o servidores de bajo nivel para la navegacion masiva.

---

### 5. Pruebas de juego (playtest) y rendimiento
- **Ajuste visual inicial:** Durante las primeras revisiones en pantalla notamos directamente que el suelo blanco original y la iluminacion generaban demasiado brillo y cansancio visual. Por ello, cambiamos el suelo a losas en verde salvia mate (rugosidad 0.9) y atenuamos las luces a valores suaves y confortables.
- **Prueba con otra persona:** Se probo el juego con un usuario externo sin darle instrucciones orales previas. No se presentaron problemas durante el recorrido: la persona pudo orientarse de forma inmediata gracias a la brujula con distancia dinamica del HUD y a la columna de luz vertical sobre la llave, recogio el objeto sin confusiones, cruzo la compuerta y completo la meta de forma fluida.

**Medicion inicial de rendimiento (linea base en PC Intel Core i5, 8 GB RAM, Direct3D 12):**
- Tasa de fotogramas: 60 FPS estables (con VSync).
- Tiempo de fotograma: 16.6 ms promedio.
- Tiempo de CPU en proceso (`TIME_PROCESS`): 0.42 ms (dejando libre el 97% del tiempo para futuras IAs).
- Memoria RAM: 88 MB en ejecucion.

---

### 6. Controles de ejecucion
- **W, A, S, D:** Mover al personaje segun la vista de la camara.
- **Raton:** Mover la camara orbital en tercera persona.
- **Espacio:** Saltar | **Escape:** Liberar/capturar cursor | **R:** Reiniciar nivel | **F1:** Alternar limite de FPS.

---

### 7. Aportaciones individuales del equipo
- **Daniela Campos Martinez:** Controlador `CharacterBody3D`, camara orbital con `SpringArm3D` contra muros y maquina de estados finitos (Idle, Walk, Jump).
- **Karina Ivonne Bazan Rojas:** Diseno del laberinto de 90x90m en `scenes/level.tscn`, shader de suelo verde mate anti-deslumbramiento y balance de iluminacion.
- **Francisco Javier Garcia Rosados:** Mecanica central con senales en `level_controller.gd`, brujula dinamica en `scripts/hud.gd`, playtest y redaccion del reporte.
