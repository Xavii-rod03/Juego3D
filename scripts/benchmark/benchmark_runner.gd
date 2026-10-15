extends Node3D
class_name BenchmarkRunner

## Controlador del Protocolo de Medición de Benchmark (Tarea 2)
## Ejecuta 3 corridas por variante (OO y DOD) alternando el orden:
## 1: OO, 2: DOD, 3: DOD, 4: OO, 5: OO, 6: DOD
## Cada corrida cuenta con 5 segundos de calentamiento y 30 segundos de medición.
## Exporta los datos a CSV distinguiendo tiempo instrumentado, tiempo de CPU y tiempo de fotograma.

signal benchmark_finished(summary_text: String)
signal status_updated(phase_name: String, run_info: String, time_remaining: float)

enum Phase {
	IDLE,
	WARMUP,
	MEASURING,
	FINISHED
}

@export var entity_count: int = 1000
@export var warmup_duration: float = 5.0
@export var measurement_duration: float = 30.0
@export var fixed_seed: int = 133742

# Orden alternado de 6 corridas (3 de OO y 3 de DOD)
var run_sequence: Array[String] = ["OO", "DOD", "DOD", "OO", "OO", "DOD"]
var current_run_index: int = 0
var current_phase: Phase = Phase.IDLE
var phase_timer: float = 0.0

var oo_instance: BenchmarkOO = null
var dod_instance: BenchmarkDOD = null

# Almacenamiento de muestras
# Diccionario con claves: variant, run_id, sample_idx, time_s, block_ms, cpu_process_ms, frame_ms, fps
var recorded_samples: Array[Dictionary] = []

@onready var benchmark_container: Node3D = $BenchmarkContainer
@onready var ui_layer: CanvasLayer = $BenchmarkUI

func _ready() -> void:
	# Crear carpeta para resultados si no existe
	DirAccess.make_dir_recursive_absolute("res://benchmark_results")
	print("[BENCHMARK] Sistema listo. Presiona ESPACIO o ENTER para iniciar el protocolo completo.")

func start_full_protocol() -> void:
	recorded_samples.clear()
	current_run_index = 0
	_start_run(current_run_index)

func _start_run(index: int) -> void:
	if index >= run_sequence.size():
		_finish_all_runs()
		return
		
	var variant = run_sequence[index]
	_setup_variant(variant)
	
	current_phase = Phase.WARMUP
	phase_timer = warmup_duration
	print("[BENCHMARK] Iniciando Corrida %d/%d (%s) - Fase: CALENTAMIENTO (%.1fs)" % [
		index + 1, run_sequence.size(), variant, warmup_duration
	])

func _setup_variant(variant: String) -> void:
	# Limpiar instancias anteriores
	if is_instance_valid(oo_instance):
		oo_instance.cleanup()
		oo_instance.queue_free()
		oo_instance = null
	if is_instance_valid(dod_instance):
		dod_instance.cleanup()
		dod_instance.queue_free()
		dod_instance = null
		
	if variant == "OO":
		oo_instance = BenchmarkOO.new()
		benchmark_container.add_child(oo_instance)
		oo_instance.init_benchmark(entity_count, fixed_seed)
	elif variant == "DOD":
		dod_instance = BenchmarkDOD.new()
		benchmark_container.add_child(dod_instance)
		dod_instance.init_benchmark(entity_count, fixed_seed)

func _process(delta: float) -> void:
	if current_phase == Phase.IDLE or current_phase == Phase.FINISHED:
		return
		
	phase_timer -= delta
	var current_variant = run_sequence[current_run_index]
	
	# Ejecutar paso de simulación y medir tiempo de bloque instrumentado
	var block_time_usec: int = 0
	if current_variant == "OO" and is_instance_valid(oo_instance):
		block_time_usec = oo_instance.simulate_step(delta)
	elif current_variant == "DOD" and is_instance_valid(dod_instance):
		block_time_usec = dod_instance.simulate_step(delta)
		
	var block_ms = float(block_time_usec) / 1000.0
	var cpu_process_ms = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var frame_ms = delta * 1000.0
	var fps = Engine.get_frames_per_second()
	
	var phase_str = "CALENTAMIENTO" if current_phase == Phase.WARMUP else "MEDICIÓN"
	emit_signal("status_updated", phase_str, "Corrida %d/%d (%s)" % [current_run_index + 1, run_sequence.size(), current_variant], max(0.0, phase_timer))
	
	# Si estamos en fase de medición, guardar muestra
	if current_phase == Phase.MEASURING:
		var elapsed_in_run = measurement_duration - phase_timer
		recorded_samples.append({
			"run_id": current_run_index + 1,
			"variant": current_variant,
			"elapsed_s": snapped(elapsed_in_run, 0.001),
			"block_ms": snapped(block_ms, 0.0001),
			"cpu_process_ms": snapped(cpu_process_ms, 0.0001),
			"frame_ms": snapped(frame_ms, 0.0001),
			"fps": fps
		})
	
	# Transición de fases
	if phase_timer <= 0.0:
		if current_phase == Phase.WARMUP:
			current_phase = Phase.MEASURING
			phase_timer = measurement_duration
			print("[BENCHMARK] Calentamiento finalizado. Iniciando MEDICIÓN activa (%.1fs)..." % measurement_duration)
		elif current_phase == Phase.MEASURING:
			print("[BENCHMARK] Corrida %d/%d (%s) completada." % [current_run_index + 1, run_sequence.size(), current_variant])
			current_run_index += 1
			_start_run(current_run_index)

func _finish_all_runs() -> void:
	current_phase = Phase.FINISHED
	_setup_variant("") # Limpiar entidades de la pantalla
	
	# Exportar a CSV
	var csv_path = "res://benchmark_results/benchmark_data.csv"
	_export_to_csv(csv_path)
	
	# Calcular resumen estadístico (Mediana y Rango Intercuartil)
	var summary = _calculate_statistics()
	print(summary)
	emit_signal("benchmark_finished", summary)

func _export_to_csv(filepath: String) -> void:
	var file = FileAccess.open(filepath, FileAccess.WRITE)
	if not file:
		push_error("No se pudo escribir en el archivo CSV: " + filepath)
		return
		
	# Cabecera CSV
	file.store_line("run_id,variant,elapsed_s,block_ms,cpu_process_ms,frame_ms,fps")
	for s in recorded_samples:
		var line = "%d,%s,%.3f,%.4f,%.4f,%.4f,%d" % [
			s["run_id"], s["variant"], s["elapsed_s"], s["block_ms"], s["cpu_process_ms"], s["frame_ms"], s["fps"]
		]
		file.store_line(line)
	file.close()
	print("[BENCHMARK] Datos exportados exitosamente a: %s (Total muestras: %d)" % [filepath, recorded_samples.size()])

func _calculate_statistics() -> String:
	var oo_blocks: Array[float] = []
	var dod_blocks: Array[float] = []
	var oo_cpu: Array[float] = []
	var dod_cpu: Array[float] = []
	var oo_frames: Array[float] = []
	var dod_frames: Array[float] = []
	
	for s in recorded_samples:
		if s["variant"] == "OO":
			oo_blocks.append(s["block_ms"])
			oo_cpu.append(s["cpu_process_ms"])
			oo_frames.append(s["frame_ms"])
		else:
			dod_blocks.append(s["block_ms"])
			dod_cpu.append(s["cpu_process_ms"])
			dod_frames.append(s["frame_ms"])
			
	var text = "\n=======================================================\n"
	text += "   RESULTADOS ESTADÍSTICOS DEL BENCHMARK (1 000 ENTIDADES)   \n"
	text += "=======================================================\n"
	text += "Métrica: Bloque Instrumentado (Simulación en CPU):\n"
	text += "  - OO:  Mediana = %.3f ms | IQR = %.3f ms | Min = %.3f | Max = %.3f\n" % _get_stats(oo_blocks)
	text += "  - DOD: Mediana = %.3f ms | IQR = %.3f ms | Min = %.3f | Max = %.3f\n" % _get_stats(dod_blocks)
	text += "-------------------------------------------------------\n"
	text += "Métrica: Tiempo CPU Profiler (TIME_PROCESS):\n"
	text += "  - OO:  Mediana = %.3f ms | IQR = %.3f ms\n" % [_median(oo_cpu), _iqr(oo_cpu)]
	text += "  - DOD: Mediana = %.3f ms | IQR = %.3f ms\n" % [_median(dod_cpu), _iqr(dod_cpu)]
	text += "-------------------------------------------------------\n"
	text += "Métrica: Tiempo Total de Fotograma (Frame Time):\n"
	text += "  - OO:  Mediana = %.3f ms | IQR = %.3f ms\n" % [_median(oo_frames), _iqr(oo_frames)]
	text += "  - DOD: Mediana = %.3f ms | IQR = %.3f ms\n" % [_median(dod_frames), _iqr(dod_frames)]
	text += "=======================================================\n"
	return text

func _get_stats(values: Array[float]) -> Array:
	if values.is_empty():
		return [0.0, 0.0, 0.0, 0.0]
	var sorted = values.duplicate()
	sorted.sort()
	var med = _median(sorted)
	var iqr = _iqr(sorted)
	var min_val = sorted[0]
	var max_val = sorted[sorted.size() - 1]
	return [med, iqr, min_val, max_val]

func _median(sorted_values: Array[float]) -> float:
	if sorted_values.is_empty():
		return 0.0
	var arr = sorted_values.duplicate()
	arr.sort()
	var n = arr.size()
	if n % 2 == 1:
		return arr[n / 2]
	else:
		return (arr[n / 2 - 1] + arr[n / 2]) / 2.0

func _iqr(sorted_values: Array[float]) -> float:
	if sorted_values.size() < 4:
		return 0.0
	var arr = sorted_values.duplicate()
	arr.sort()
	var q1 = arr[int(arr.size() * 0.25)]
	var q3 = arr[int(arr.size() * 0.75)]
	return q3 - q1

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			if current_phase == Phase.IDLE or current_phase == Phase.FINISHED:
				start_full_protocol()
		elif event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/level.tscn")
