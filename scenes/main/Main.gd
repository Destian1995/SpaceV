extends Node2D

var time_e: float = 0.0
var stars: Array = []
var nebula_points: Array = []

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in 300:
		stars.append({
			"pos":   Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1080)),
			"size":  rng.randf_range(0.5, 2.2),
			"speed": rng.randf_range(0.3, 1.2),
			"phase": rng.randf_range(0, TAU),
			"color": Color(rng.randf_range(0.7,1.0), rng.randf_range(0.7,1.0), 1.0, rng.randf_range(0.4,0.9)),
		})
	for i in 60:
		nebula_points.append({
			"pos":   Vector2(rng.randf_range(200, 900), rng.randf_range(200, 800)),
			"r":     rng.randf_range(40, 140),
			"color": Color(rng.randf_range(0.1,0.4), rng.randf_range(0.0,0.2), rng.randf_range(0.3,0.7), 0.04),
		})

	$UI/VBox/StartButton.pressed.connect(_on_start)
	$UI/VBox/QuitButton.pressed.connect(_on_quit)

func _process(delta: float) -> void:
	time_e += delta
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size

	# Deep space background
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.006, 0.006, 0.022, 1))

	# Nebula clouds
	for n in nebula_points:
		draw_circle(n["pos"] + Vector2(sin(time_e * 0.05) * 8, cos(time_e * 0.04) * 6), n["r"], n["color"])

	# Stars with twinkle
	for s in stars:
		var br: float = s["size"] * (0.7 + sin(time_e * s["speed"] + s["phase"]) * 0.3)
		draw_circle(s["pos"], br, s["color"])

	# Distant galaxy spiral hint
	var cx: float = vp.x * 0.72
	var cy: float = vp.y * 0.42
	for i in 120:
		var t: float = float(i) / 120.0
		var angle: float = t * TAU * 2.5 + time_e * 0.03
		var r: float = t * 180.0
		var px: float = cx + cos(angle) * r
		var py: float = cy + sin(angle) * r * 0.38
		var alpha: float = (1.0 - t) * 0.12
		draw_circle(Vector2(px, py), lerp(2.5, 0.3, t), Color(0.5, 0.6, 1.0, alpha))

	# Title glow layers
	var title_x: float = vp.x * 0.5
	var title_y: float = vp.y * 0.3
	var glow_alpha: float = 0.06 + sin(time_e * 1.1) * 0.02
	for g in range(5, 0, -1):
		draw_circle(Vector2(title_x, title_y - 10), float(g) * 28, Color(0.2, 0.4, 1.0, glow_alpha))

	# Horizontal divider lines
	var line_y: float = vp.y * 0.52
	var line_alpha: float = 0.18 + sin(time_e * 0.7) * 0.05
	draw_line(Vector2(title_x - 260, line_y), Vector2(title_x + 260, line_y), Color(0.3, 0.6, 1.0, line_alpha), 1.0)

func _on_start() -> void:
	get_tree().change_scene_to_file("res://scenes/galaxy_map/GalaxyMap.tscn")

func _on_quit() -> void:
	get_tree().quit()
