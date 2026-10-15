extends CanvasLayer

@onready var phase_label: Label = %PhaseLabel
@onready var run_label: Label = %RunLabel
@onready var timer_label: Label = %TimerLabel
@onready var block_time_label: Label = %BlockTimeLabel
@onready var cpu_time_label: Label = %CpuTimeLabel
@onready var frame_time_label: Label = %FrameTimeLabel
@onready var fps_label: Label = %FpsLabel
@onready var summary_box: PanelContainer = %SummaryBox
@onready var summary_text_label: RichTextLabel = %SummaryTextLabel

var runner: BenchmarkRunner = null

func _ready() -> void:
	runner = get_parent() as BenchmarkRunner
	if runner:
		runner.status_updated.connect(_on_status_updated)
		runner.benchmark_finished.connect(_on_benchmark_finished)
	summary_box.visible = false

func _process(_delta: float) -> void:
	fps_label.text = "%d FPS" % Engine.get_frames_per_second()
	cpu_time_label.text = "%.3f ms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0)
	frame_time_label.text = "%.3f ms" % (Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0 + Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)

func _on_status_updated(phase_name: String, run_info: String, time_remaining: float) -> void:
	phase_label.text = phase_name
	run_label.text = run_info
	timer_label.text = "Tiempo restante: %.1f s" % time_remaining
	
	if phase_name == "CALENTAMIENTO":
		phase_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2))
	elif phase_name == "MEDICIÓN":
		phase_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4))
	else:
		phase_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))

func _on_benchmark_finished(summary: String) -> void:
	phase_label.text = "BENCHMARK COMPLETADO"
	phase_label.add_theme_color_override("font_color", Color(0.0, 0.9, 1.0))
	summary_box.visible = true
	summary_text_label.text = summary + "\n\nDatos guardados en:\nres://benchmark_results/benchmark_data.csv"
