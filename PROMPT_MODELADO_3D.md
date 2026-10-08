# PROMPT Y BITÁCORA DE MODELADO 3D CON INTELIGENCIA ARTIFICIAL

**Proyecto:** Laberinto 3D  
**Entrega:** Tarea 1 - Modelado y Animación con IA    
**Fecha:** Octubre 2026  
 

---

## 1. Prompt Exacto Utilizado

### Pront:
> *"Personaje explorador aventurero estilizado en bajo poligonaje (low-poly), proporciones humanoides, vistiendo un traje de explorador con mochila propulsora y casco con visor, pose en T simétrica, flujo de aristas limpio, recurso listo para videojuego, apto para sombreado plano, sin geometría flotante interna y topología optimizada."*

---

## 2. Parámetros y Ajustes de Generación

| Parámetro | Configuración | Razón Técnica |
| :--- | :--- | :--- |
| **Plataforma / Motor** | Tripo3D / Meshy.ai | Generación de malla 3D y texturas PBR a partir de texto |
| **Postura (Pose)** | T-Pose Simétrica | Estándar para retargeting, rigging y animación en la Tarea 2 |
| **Límite Poligonal** | $\approx 3,000$ a $4,000$ triángulos | Optimizado para tiempo real |
| **Espacio de Color** | sRGB (Albedo), Linear (Roughness, Metallic) | Cumplimiento del estándar PBR en Godot 4.x |
| **Texturizado** | Textura difusa / PBR $1024 \times 1024$ | Balance ideal entre nitidez visual y consumo de VRAM |

