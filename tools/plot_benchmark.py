import os
import csv
import math

# Análisis estadístico y generación de gráficas vectoriales (SVG) en Python puro
# Sin dependencias externas (no requiere numpy ni matplotlib)

results_dir = os.path.join(os.path.dirname(__file__), "..", "benchmark_results")
csv_path = os.path.join(results_dir, "benchmark_data.csv")

if not os.path.exists(csv_path):
    print(f"Error: no se encontró el archivo CSV en {csv_path}")
    exit(1)

data_oo = {"block": [], "cpu": [], "frame": [], "fps": []}
data_dod = {"block": [], "cpu": [], "frame": [], "fps": []}
runs_data = {}

with open(csv_path, mode="r", encoding="utf-8") as f:
    reader = csv.DictReader(f)
    for row in reader:
        run_id = int(row["run_id"])
        variant = row["variant"]
        t_elapsed = float(row["elapsed_s"])
        block = float(row["block_ms"])
        cpu = float(row["cpu_process_ms"])
        frame = float(row["frame_ms"])
        fps = int(row["fps"])
        
        target = data_oo if variant == "OO" else data_dod
        target["block"].append(block)
        target["cpu"].append(cpu)
        target["frame"].append(frame)
        target["fps"].append(fps)
        
        if run_id not in runs_data:
            runs_data[run_id] = {"variant": variant, "times": [], "block": []}
        runs_data[run_id]["times"].append(t_elapsed)
        runs_data[run_id]["block"].append(block)

def calc_stats(arr):
    if not arr:
        return 0.0, 0.0, 0.0, 0.0, 0.0, 0.0
    s = sorted(arr)
    n = len(s)
    
    # Mediana
    if n % 2 == 1:
        med = s[n // 2]
    else:
        med = (s[n // 2 - 1] + s[n // 2]) / 2.0
        
    # Cuartiles Q1 y Q3
    q25 = s[int(n * 0.25)]
    q75 = s[int(n * 0.75)]
    iqr = q75 - q25
    
    mean = sum(s) / n
    variance = sum((x - mean) ** 2 for x in s) / n
    std = math.sqrt(variance)
    min_val = s[0]
    max_val = s[-1]
    return med, iqr, mean, std, min_val, max_val

oo_b_med, oo_b_iqr, oo_b_mean, oo_b_std, oo_b_min, oo_b_max = calc_stats(data_oo["block"])
dod_b_med, dod_b_iqr, dod_b_mean, dod_b_std, dod_b_min, dod_b_max = calc_stats(data_dod["block"])

oo_cpu_med, oo_cpu_iqr, oo_cpu_mean, _, _, _ = calc_stats(data_oo["cpu"])
dod_cpu_med, dod_cpu_iqr, dod_cpu_mean, _, _, _ = calc_stats(data_dod["cpu"])

oo_f_med, oo_f_iqr, oo_f_mean, _, _, _ = calc_stats(data_oo["frame"])
dod_f_med, dod_f_iqr, dod_f_mean, _, _, _ = calc_stats(data_dod["frame"])

print("==========================================================================================")
print("              TABLA RESUMEN ESTADÍSTICO - BENCHMARK 1 000 ENTIDADES                       ")
print("==========================================================================================")
print("| Métrica / Variante           | Mediana (ms) | IQR (ms) | Media (ms) | Desv. Est. | Mínimo | Máximo |")
print("| :---                         | :---:        | :---:    | :---:      | :---:      | :---:  | :---:  |")
print(f"| **Bloque Instrumentado (OO)**| **{oo_b_med:.3f}**  | {oo_b_iqr:.3f}   | {oo_b_mean:.3f}    | {oo_b_std:.3f}      | {oo_b_min:.3f} | {oo_b_max:.3f} |")
print(f"| **Bloque Instrumentado(DOD)**| **{dod_b_med:.3f}**  | {dod_b_iqr:.3f}   | {dod_b_mean:.3f}    | {dod_b_std:.3f}      | {dod_b_min:.3f} | {dod_b_max:.3f} |")
print(f"| **CPU Process Profiler (OO)**| **{oo_cpu_med:.3f}**  | {oo_cpu_iqr:.3f}   | {oo_cpu_mean:.3f}    | -          | -      | -      |")
print(f"| **CPU Process Profiler(DOD)**| **{dod_cpu_med:.3f}**  | {dod_cpu_iqr:.3f}   | {dod_cpu_mean:.3f}    | -          | -      | -      |")
print(f"| **Tiempo de Fotograma (OO)** | **{oo_f_med:.3f}** | {oo_f_iqr:.3f}   | {oo_f_mean:.3f}   | -          | -      | -      |")
print(f"| **Tiempo de Fotograma (DOD)**| **{dod_f_med:.3f}** | {dod_f_iqr:.3f}   | {dod_f_mean:.3f}   | -          | -      | -      |")
print("==========================================================================================")

speedup = oo_b_med / dod_b_med if dod_b_med > 0 else 1.0
print(f"Factor de aceleración en Bloque Instrumentado: {speedup:.2f}x a favor de DOD")

# Generación de Gráfica SVG 1: Línea temporal de Bloque Instrumentado
svg_w, svg_h = 900, 480
pad_l, pad_r, pad_t, pad_b = 80, 40, 60, 60
plot_w = svg_w - pad_l - pad_r
plot_h = svg_h - pad_t - pad_b

# Escala: X de 0 a 30s, Y de 0 a 3.0 ms
y_max = 3.0

def to_svg_x(t):
    return pad_l + (t / 30.0) * plot_w

def to_svg_y(v):
    return pad_t + plot_h - (v / y_max) * plot_h

svg_lines = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{svg_w}" height="{svg_h}" style="background-color:#1e222b; font-family:sans-serif;">',
    f'<text x="{svg_w/2}" y="32" text-anchor="middle" fill="#00e5ff" font-size="18" font-weight="bold">Tiempo del Bloque Instrumentado (1 000 Entidades) - Corridas Alternadas</text>',
    f'<text x="{svg_w/2}" y="465" text-anchor="middle" fill="#a0aec0" font-size="13">Tiempo transcurrido en fase de medición (segundos)</text>',
    f'<text transform="rotate(-90)" x="{-svg_h/2}" y="30" text-anchor="middle" fill="#a0aec0" font-size="13">Tiempo de CPU (milisegundos)</text>',
    f'<rect x="{pad_l}" y="{pad_t}" width="{plot_w}" height="{plot_h}" fill="#161920" stroke="#334155" stroke-width="1.5"/>'
]

# Grilla y ejes Y
for y_val in [0.5, 1.0, 1.5, 2.0, 2.5, 3.0]:
    sy = to_svg_y(y_val)
    svg_lines.append(f'<line x1="{pad_l}" y1="{sy}" x2="{pad_l + plot_w}" y2="{sy}" stroke="#2a324b" stroke-dasharray="4,4"/>')
    svg_lines.append(f'<text x="{pad_l - 10}" y="{sy + 4}" text-anchor="end" fill="#94a3b8" font-size="11">{y_val:.1f} ms</text>')

# Grilla y ejes X
for x_val in range(0, 35, 5):
    sx = to_svg_x(x_val)
    svg_lines.append(f'<line x1="{sx}" y1="{pad_t}" x2="{sx}" y2="{pad_t + plot_h}" stroke="#2a324b" stroke-dasharray="4,4"/>')
    svg_lines.append(f'<text x="{sx}" y="{pad_t + plot_h + 20}" text-anchor="middle" fill="#94a3b8" font-size="11">{x_val} s</text>')

# Trazado de corridas
colors = {1: "#f87171", 2: "#38bdf8", 3: "#818cf8", 4: "#fb923c", 5: "#ef4444", 6: "#0284c7"}
for run_id in sorted(runs_data.keys()):
    r = runs_data[run_id]
    points = []
    # Submuestreo cada 10 puntos para SVG ligero
    for i in range(0, len(r["times"]), 10):
        t = r["times"][i]
        v = r["block"][i]
        points.append(f"{to_svg_x(t):.1f},{to_svg_y(v):.1f}")
    polyline_str = " ".join(points)
    svg_lines.append(f'<polyline fill="none" stroke="{colors[run_id]}" stroke-width="1.6" opacity="0.85" points="{polyline_str}"/>')

# Líneas de mediana
svg_lines.append(f'<line x1="{pad_l}" y1="{to_svg_y(oo_b_med)}" x2="{pad_l+plot_w}" y2="{to_svg_y(oo_b_med)}" stroke="#ef4444" stroke-width="2.5" stroke-dasharray="6,4"/>')
svg_lines.append(f'<line x1="{pad_l}" y1="{to_svg_y(dod_b_med)}" x2="{pad_l+plot_w}" y2="{to_svg_y(dod_b_med)}" stroke="#38bdf8" stroke-width="2.5" stroke-dasharray="6,4"/>')

# Leyenda
svg_lines.append(f'<rect x="{pad_l + 20}" y="{pad_t + 15}" width="250" height="70" fill="#0f172a" opacity="0.9" rx="6"/>')
svg_lines.append(f'<line x1="{pad_l+30}" y1="{pad_t+35}" x2="{pad_l+60}" y2="{pad_t+35}" stroke="#ef4444" stroke-width="3"/>')
svg_lines.append(f'<text x="{pad_l+70}" y="{pad_t+39}" fill="#fca5a5" font-size="12">OO (Mediana: {oo_b_med:.2f} ms)</text>')
svg_lines.append(f'<line x1="{pad_l+30}" y1="{pad_t+60}" x2="{pad_l+60}" y2="{pad_t+60}" stroke="#38bdf8" stroke-width="3"/>')
svg_lines.append(f'<text x="{pad_l+70}" y="{pad_t+64}" fill="#bae6fd" font-size="12">DOD (Mediana: {dod_b_med:.2f} ms)</text>')
svg_lines.append('</svg>')

svg_line_path = os.path.join(results_dir, "grafica_bloque_cpu.svg")
with open(svg_line_path, "w", encoding="utf-8") as f:
    f.write("\n".join(svg_lines))
print(f"Gráfica temporal vectorial SVG guardada en: {svg_line_path}")

# Generación de Gráfica SVG 2: Diagrama de Cajas (Boxplot)
svg_box_path = os.path.join(results_dir, "grafica_boxplot_metricas.svg")
box_svg = [
    f'<svg xmlns="http://www.w3.org/2000/svg" width="{svg_w}" height="{svg_h}" style="background-color:#1e222b; font-family:sans-serif;">',
    f'<text x="{svg_w/2}" y="32" text-anchor="middle" fill="#00e5ff" font-size="18" font-weight="bold">Distribución Comparativa de Tiempos (Mediana, IQR y Rango)</text>',
    f'<text transform="rotate(-90)" x="{-svg_h/2}" y="30" text-anchor="middle" fill="#a0aec0" font-size="13">Tiempo en milisegundos (ms)</text>',
    f'<rect x="{pad_l}" y="{pad_t}" width="{plot_w}" height="{plot_h}" fill="#161920" stroke="#334155" stroke-width="1.5"/>'
]

# Grilla eje Y para Boxplot (escala 0 a 20 ms para mostrar frame time)
y_max_box = 20.0
def to_box_y(v):
    return pad_t + plot_h - (v / y_max_box) * plot_h

for y_val in [2.0, 4.0, 6.0, 8.0, 10.0, 12.0, 14.0, 16.0, 18.0, 20.0]:
    sy = to_box_y(y_val)
    box_svg.append(f'<line x1="{pad_l}" y1="{sy}" x2="{pad_l + plot_w}" y2="{sy}" stroke="#2a324b" stroke-dasharray="4,4"/>')
    box_svg.append(f'<text x="{pad_l - 10}" y="{sy + 4}" text-anchor="end" fill="#94a3b8" font-size="11">{y_val:.1f} ms</text>')

categories = [
    ("Bloque OO", data_oo["block"], "#f87171"),
    ("Bloque DOD", data_dod["block"], "#38bdf8"),
    ("CPU OO", data_oo["cpu"], "#fca5a5"),
    ("CPU DOD", data_dod["cpu"], "#7dd3fc"),
    ("Frame OO", data_oo["frame"], "#fb923c"),
    ("Frame DOD", data_dod["frame"], "#34d399")
]

col_w = plot_w / len(categories)
for idx, (label, arr, color) in enumerate(categories):
    med, iqr, mean, std, v_min, v_max = calc_stats(arr)
    s = sorted(arr)
    q25 = s[int(len(s)*0.25)]
    q75 = s[int(len(s)*0.75)]
    
    cx = pad_l + idx * col_w + col_w / 2.0
    bx_w = col_w * 0.55
    
    # Bigotes (Min a Max o 1.5 IQR)
    box_svg.append(f'<line x1="{cx}" y1="{to_box_y(v_min)}" x2="{cx}" y2="{to_box_y(v_max)}" stroke="#94a3b8" stroke-width="1.5"/>')
    box_svg.append(f'<line x1="{cx-12}" y1="{to_box_y(v_min)}" x2="{cx+12}" y2="{to_box_y(v_min)}" stroke="#94a3b8" stroke-width="1.5"/>')
    box_svg.append(f'<line x1="{cx-12}" y1="{to_box_y(v_max)}" x2="{cx+12}" y2="{to_box_y(v_max)}" stroke="#94a3b8" stroke-width="1.5"/>')
    
    # Caja IQR (Q1 a Q3)
    y_top = to_box_y(q75)
    y_bot = to_box_y(q25)
    h_box = y_bot - y_top
    box_svg.append(f'<rect x="{cx - bx_w/2}" y="{y_top}" width="{bx_w}" height="{h_box}" fill="{color}" opacity="0.8" stroke="#ffffff" stroke-width="1.2" rx="3"/>')
    
    # Línea Mediana
    box_svg.append(f'<line x1="{cx - bx_w/2}" y1="{to_box_y(med)}" x2="{cx + bx_w/2}" y2="{to_box_y(med)}" stroke="#ffffff" stroke-width="2.5"/>')
    
    # Etiqueta
    box_svg.append(f'<text x="{cx}" y="{pad_t + plot_h + 20}" text-anchor="middle" fill="#cbd5e1" font-size="11">{label}</text>')
    box_svg.append(f'<text x="{cx}" y="{pad_t + plot_h + 36}" text-anchor="middle" fill="{color}" font-size="10" font-weight="bold">{med:.2f} ms</text>')

box_svg.append('</svg>')
with open(svg_box_path, "w", encoding="utf-8") as f:
    f.write("\n".join(box_svg))
print(f"Gráfica boxplot vectorial SVG guardada en: {svg_box_path}")
