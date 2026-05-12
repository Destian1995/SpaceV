extends Node2D

var time_e: float = 0.0
var stars: Array = []
var nebula_points: Array = []
var shooting_stars: Array = []
var meteors: Array = []
var next_meteor: float = 0.0

func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99

	# Stars — 3 layers (far, mid, near) for parallax feel
	for i in 400:
		var layer: int = rng.randi() % 3
		stars.append({
			"pos":   Vector2(rng.randf_range(0, 1920), rng.randf_range(0, 1080)),
			"size":  rng.randf_range(0.4, 1.8) + float(layer) * 0.4,
			"speed": rng.randf_range(0.25, 0.9) + float(layer) * 0.3,
			"phase": rng.randf_range(0, TAU),
			"layer": layer,
			"cr":    rng.randf_range(0.65, 1.0),
			"cg":    rng.randf_range(0.70, 1.0),
			"cb":    1.0,
		})

	# Nebula clouds — more varied
	for i in 80:
		nebula_points.append({
			"pos":   Vector2(rng.randf_range(-100, 2000), rng.randf_range(-80, 1160)),
			"r":     rng.randf_range(35, 160),
			"color": Color(
				rng.randf_range(0.05, 0.35),
				rng.randf_range(0.0,  0.18),
				rng.randf_range(0.25, 0.72),
				rng.randf_range(0.025, 0.055)),
			"ph":    rng.randf_range(0, TAU),
			"spd":   rng.randf_range(0.02, 0.06),
		})

	$UI/VBox/StartButton.pressed.connect(_on_start)
	$UI/VBox/QuitButton.pressed.connect(_on_quit)

	# Кнопка "Продолжить" — только если есть сохранение
	var continue_btn := $UI/VBox/ContinueButton
	if GameManager.has_save():
		continue_btn.visible = true
		continue_btn.pressed.connect(_on_continue)
	else:
		continue_btn.visible = false

func _on_continue() -> void:
	if GameManager.load_game():
		get_tree().change_scene_to_file("res://scenes/galaxy_map/GalaxyMap.tscn")

func _process(delta: float) -> void:
	time_e += delta

	# Spawn shooting stars randomly
	next_meteor -= delta
	if next_meteor <= 0:
		next_meteor = randf_range(1.8, 5.0)
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = int(time_e * 1000)
		shooting_stars.append({
			"pos":   Vector2(rng2.randf_range(0, 1600), rng2.randf_range(0, 300)),
			"vel":   Vector2(rng2.randf_range(380, 680), rng2.randf_range(140, 280)),
			"life":  0.7,
			"max_life": 0.7,
			"len":   rng2.randf_range(60, 140),
		})

	# Update shooting stars
	for i in range(shooting_stars.size() - 1, -1, -1):
		var s: Dictionary = shooting_stars[i]
		s["life"] -= delta
		s["pos"] += s["vel"] * delta
		if s["life"] <= 0:
			shooting_stars.remove_at(i)

	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size

	# ── Deep space gradient ───────────────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.004, 0.004, 0.018, 1))

	# Subtle radial fade from center (darker edges)
	for r in [900, 700, 500, 350]:
		var alpha := 0.008 * (1.0 - float(r) / 900.0)
		draw_circle(vp * 0.5, float(r), Color(0.05, 0.1, 0.35, alpha))

	# ── Nebula clouds (animated) ──────────────────────────────────────────────
	for n in nebula_points:
		var drift := Vector2(sin(time_e * n["spd"] + n["ph"]) * 10, cos(time_e * n["spd"] * 0.7 + n["ph"]) * 7)
		draw_circle(n["pos"] + drift, n["r"], n["color"])
		draw_circle(n["pos"] + drift, n["r"] * 0.5,
			Color(n["color"].r * 1.4, n["color"].g * 1.3, n["color"].b * 1.1, n["color"].a * 0.55))

	# ── Galaxy spiral (right side, more vivid) ────────────────────────────────
	var cx: float = vp.x * 0.74
	var cy: float = vp.y * 0.40
	for arm in 2:
		var arm_offset: float = arm * PI
		for i in 180:
			var t: float = float(i) / 180.0
			var angle: float = t * TAU * 2.8 + arm_offset + time_e * 0.025
			var r: float = t * 200.0
			var px: float = cx + cos(angle) * r
			var py: float = cy + sin(angle) * r * 0.36
			var alpha: float = (1.0 - t) * 0.18 * (0.7 + sin(t * TAU * 3) * 0.3)
			var sz: float = lerp(2.8, 0.3, t)
			draw_circle(Vector2(px, py), sz, Color(0.52, 0.62, 1.0, alpha))
	# Galactic core glow
	draw_circle(Vector2(cx, cy), 22, Color(0.8, 0.85, 1.0, 0.06))
	draw_circle(Vector2(cx, cy), 10, Color(0.9, 0.92, 1.0, 0.12))
	draw_circle(Vector2(cx, cy), 5,  Color(1.0, 1.0, 1.0, 0.18))

	# ── Stars (twinkle with per-layer brightness) ─────────────────────────────
	for s in stars:
		var br: float = 0.65 + sin(time_e * s["speed"] + s["phase"]) * 0.32
		var sz: float = s["size"] * (0.8 + sin(time_e * s["speed"] * 1.3 + s["phase"]) * 0.18)
		sz = maxf(sz, 0.3)
		draw_circle(s["pos"], sz, Color(s["cr"] * br, s["cg"] * br, s["cb"] * br, br * 0.9))

	# ── Shooting stars ────────────────────────────────────────────────────────
	for s in shooting_stars:
		var alpha: float = (s["life"] / s["max_life"])
		var vel_n: Vector2 = s["vel"].normalized()
		var tail: Vector2 = s["pos"] - vel_n * s["len"] * alpha
		draw_line(s["pos"], tail, Color(0.85, 0.92, 1.0, alpha * 0.85), 1.8)
		draw_line(s["pos"], tail * 0.4 + s["pos"] * 0.6, Color(1.0, 1.0, 1.0, alpha), 1.0)
		draw_circle(s["pos"], 2.0 * alpha, Color(1.0, 1.0, 1.0, alpha))

	# ── Title glow layers ─────────────────────────────────────────────────────
	var title_x: float = vp.x * 0.5
	var title_y: float = vp.y * 0.28
	var glow_alpha: float = 0.055 + sin(time_e * 1.05) * 0.018
	for g in range(7, 0, -1):
		draw_circle(Vector2(title_x, title_y), float(g) * 30, Color(0.18, 0.38, 1.0, glow_alpha))
	# Bright inner spark
	draw_circle(Vector2(title_x, title_y), 6, Color(0.6, 0.8, 1.0, 0.22 + sin(time_e * 2.2) * 0.08))

	# ── Decorative horizontal lines ───────────────────────────────────────────
	var line_y: float = vp.y * 0.50
	var la: float = 0.14 + sin(time_e * 0.65) * 0.04
	draw_line(Vector2(title_x - 280, line_y), Vector2(title_x + 280, line_y),
		Color(0.28, 0.55, 1.0, la), 1.0)
	# Side dots
	for side in [-1, 1]:
		draw_circle(Vector2(title_x + side * 280, line_y), 2.5, Color(0.4, 0.7, 1.0, la * 2))

func _on_start() -> void:
	# Новая игра — сброс прогресса
	GameManager.credits           = 500000
	GameManager.day               = 1
	GameManager.current_galaxy    = "Sol Prime"
	GameManager.current_galaxy_idx= 0
	GameManager.current_danger    = 1
	GameManager.current_faction   = "Федерация"
	GameManager.ship_hull_pct     = 1.0
	GameManager.visited_systems   = [0]
	GameManager.fuel              = 100.0
	GameManager.total_damage_dealt    = 0
	GameManager.total_damage_absorbed = 0
	GameManager.total_ships_destroyed = 0
	GameManager.total_battles_won     = 0
	GameManager.faction_reputation    = {
		"Федерация": 0, "Торговцы": 0, "Независимые": 0,
		"Пираты": -50, "Империя": 0, "Нет": 0,
	}
	get_tree().change_scene_to_file("res://scenes/galaxy_map/GalaxyMap.tscn")

func _on_quit() -> void:
	get_tree().quit()
