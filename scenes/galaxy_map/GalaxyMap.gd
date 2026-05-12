extends Node2D

const SYSTEMS = [
	# Core Federation space
	{"name": "Sol Prime",      "pos": Vector2(480, 340), "faction": "Федерация",   "danger": 1, "color": Color(0.45, 0.85, 1.0),  "size": 11, "is_hq": true},
	{"name": "Krath Station",  "pos": Vector2(750, 190), "faction": "Федерация",   "danger": 2, "color": Color(0.35, 0.65, 1.0),  "size": 9},
	{"name": "Auren Gate",     "pos": Vector2(310, 195), "faction": "Торговцы",    "danger": 2, "color": Color(0.3,  1.0,  0.6),  "size": 10, "is_hq": true},
	{"name": "Nova Reach",     "pos": Vector2(140, 360), "faction": "Независимые", "danger": 2, "color": Color(0.6,  0.9,  0.7),  "size": 8,  "is_hq": true},
	# Mid-rim
	{"name": "Vega Drift",     "pos": Vector2(230, 510), "faction": "Независимые", "danger": 3, "color": Color(0.95, 0.95, 0.3),  "size": 10},
	{"name": "Pyrox",          "pos": Vector2(840, 530), "faction": "Империя",     "danger": 3, "color": Color(1.0,  0.52, 0.22), "size": 9},
	{"name": "Helion Crossing","pos": Vector2(600, 250), "faction": "Торговцы",    "danger": 2, "color": Color(0.5,  1.0,  0.85), "size": 9},
	{"name": "Orion Breach",   "pos": Vector2(970, 280), "faction": "Империя",     "danger": 3, "color": Color(1.0,  0.7,  0.25), "size": 8,  "is_hq": true},
	{"name": "Thalara",        "pos": Vector2(380, 450), "faction": "Независимые", "danger": 3, "color": Color(0.7,  0.55, 1.0),  "size": 8},
	{"name": "Cassian Rift",   "pos": Vector2(700, 400), "faction": "Независимые", "danger": 3, "color": Color(0.55, 0.8,  0.55), "size": 8},
	# Outer rim / danger
	{"name": "Scarlet Nebula", "pos": Vector2(980, 450), "faction": "Пираты",      "danger": 4, "color": Color(1.0,  0.28, 0.28), "size": 10, "is_hq": true},
	{"name": "Echo Void",      "pos": Vector2(580, 610), "faction": "Нет",         "danger": 5, "color": Color(0.5,  0.5,  0.72), "size": 9},
	{"name": "Malachar Deep",  "pos": Vector2(160, 590), "faction": "Пираты",      "danger": 4, "color": Color(0.9,  0.35, 0.35), "size": 8},
	{"name": "Void Station",   "pos": Vector2(860, 650), "faction": "Нет",         "danger": 5, "color": Color(0.4,  0.4,  0.65), "size": 9},
	{"name": "Terminus",       "pos": Vector2(430, 650), "faction": "Пираты",      "danger": 4, "color": Color(1.0,  0.4,  0.2),  "size": 8},
	{"name": "Darkfall",       "pos": Vector2(1060,580), "faction": "Нет",         "danger": 5, "color": Color(0.35, 0.35, 0.6),  "size": 8},
]

const CONNECTIONS = [
	[0,1],[0,2],[0,3],[0,4],[0,8],[0,9],
	[1,2],[1,6],[1,7],[1,9],
	[2,3],[2,8],
	[3,4],
	[4,8],[4,12],[4,14],
	[5,9],[5,10],[5,11],
	[6,7],[6,9],
	[7,10],
	[8,9],[8,14],
	[9,11],[9,5],
	[10,13],[10,15],
	[11,14],[11,13],
	[12,14],
	[13,15],
]

# Стоимость и время прыжка рассчитываются динамически по расстоянию
const JUMP_COST_PER_PX := 2.0
const JUMP_DAY_PX      := 130.0
const JUMP_MIN_COST    := 300
const FUEL_PER_PX      := 0.12   # топливо за 1 пиксель расстояния
const TRAVEL_DUR       := 1.5    # секунд анимации перелёта

# Шанс случайной встречи в гиперпространстве (базовый + danger-множитель)
const ENCOUNTER_BASE   := 0.08
const ENCOUNTER_DANGER := 0.055

var current_idx:  int = 0
var selected_idx: int = -1
var bg_stars:     Array = []
var nebulae:      Array = []
var time_e:       float = 0.0

# ── Анимация перелёта (мерцающая точка) ───────────────────────────────────────
var _travel_active: bool    = false
var _travel_t:      float   = 0.0
var _travel_from:   Vector2 = Vector2.ZERO
var _travel_to:     Vector2 = Vector2.ZERO

# Camera pan
var cam_pan:      Vector2 = Vector2.ZERO
var _dragging:    bool    = false
var _drag_from:   Vector2 = Vector2.ZERO

@onready var info_panel   = $UI/InfoPanel
@onready var lbl_name     = $UI/InfoPanel/VBox/SystemName
@onready var lbl_faction  = $UI/InfoPanel/VBox/Faction
@onready var lbl_danger   = $UI/InfoPanel/VBox/Danger
@onready var lbl_jumpcost = $UI/InfoPanel/VBox/JumpCost
@onready var btn_enter    = $UI/InfoPanel/VBox/EnterBtn
@onready var btn_jump     = $UI/InfoPanel/VBox/JumpBtn
@onready var lbl_credits  = $UI/TopBar/HBox/Credits
@onready var lbl_day      = $UI/TopBar/HBox/Day
@onready var lbl_location = $UI/TopBar/HBox/Location
@onready var lbl_status   = $UI/StatusLabel
@onready var btn_ship     = $UI/TopBar/HBox/ShipBtn
@onready var btn_menu     = $UI/TopBar/HBox/MenuBtn

func _ready() -> void:
	current_idx = GameManager.current_galaxy_idx
	_gen_background()
	info_panel.hide()
	btn_enter.pressed.connect(_on_enter)
	btn_jump.pressed.connect(_on_jump)
	btn_ship.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ship_view/ShipView.tscn"))
	btn_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Main.tscn"))
	var _cred_cb := func(v): lbl_credits.text = "💰 %d кред." % v
	GameManager.credits_changed.connect(_cred_cb)
	tree_exiting.connect(func(): GameManager.credits_changed.disconnect(_cred_cb))
	_refresh_topbar()
	lbl_status.text = "Текущая позиция: %s" % SYSTEMS[current_idx]["name"]

func _gen_background() -> void:
	var vp := get_viewport_rect().size
	var rng := RandomNumberGenerator.new()
	rng.seed = 77421

	# Nebulae
	var neb_cols := [
		Color(0.2,0.05,0.45,0.06), Color(0.05,0.15,0.5,0.05),
		Color(0.4,0.1,0.2,0.05),   Color(0.05,0.3,0.35,0.06),
	]
	for i in 22:
		nebulae.append({
			"pos": Vector2(rng.randf_range(0,vp.x), rng.randf_range(0,vp.y)),
			"r":   rng.randf_range(80, 220),
			"col": neb_cols[rng.randi() % neb_cols.size()],
			"ph":  rng.randf_range(0, TAU),
		})

	# Stars
	var palettes := [
		[1.0,1.0,1.0],[0.7,0.8,1.0],[0.5,0.6,1.0],
		[1.0,0.95,0.7],[1.0,0.75,0.45],[0.9,0.9,1.0],
	]
	for i in 500:
		var pal: Array = palettes[rng.randi() % palettes.size()]
		bg_stars.append({
			"pos": Vector2(rng.randf_range(0,vp.x), rng.randf_range(0,vp.y)),
			"r":   rng.randf_range(0.4, 2.4),
			"br":  rng.randf_range(0.3, 1.0),
			"ph":  rng.randf_range(0, TAU),
			"spd": rng.randf_range(0.3, 1.8),
			"cr": pal[0], "cg": pal[1], "cb": pal[2],
		})

func _process(delta: float) -> void:
	time_e += delta
	if _travel_active:
		_travel_t = minf(_travel_t + delta / TRAVEL_DUR, 1.0)
		if _travel_t >= 1.0:
			_travel_active = false
	queue_redraw()

func _draw() -> void:
	var vp := get_viewport_rect().size

	# Deep space base
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.008, 0.008, 0.022, 1))

	# Nebulae
	for n in nebulae:
		var pulse: float = sin(time_e * 0.18 + n["ph"]) * 0.008
		draw_circle(n["pos"], n["r"],
			Color(n["col"].r, n["col"].g, n["col"].b, n["col"].a + pulse))
		draw_circle(n["pos"], n["r"] * 0.55,
			Color(n["col"].r * 1.3, n["col"].g * 1.3, n["col"].b * 1.3, n["col"].a * 0.6))

	# Stars
	for s in bg_stars:
		var br: float = s["br"] + sin(time_e * s["spd"] + s["ph"]) * 0.2
		var sz: float = s["r"]  + sin(time_e * s["spd"] * 1.4 + s["ph"]) * 0.25
		sz = max(0.3, sz)
		draw_circle(s["pos"], sz, Color(s["cr"]*br, s["cg"]*br, s["cb"]*br, min(br,1.0)))

	# Connection lines with glow
	for c in CONNECTIONS:
		var a: Vector2 = SYSTEMS[c[0]]["pos"] + cam_pan
		var b: Vector2 = SYSTEMS[c[1]]["pos"] + cam_pan
		# Check if either end is current
		var is_active: bool = c[0] == current_idx or c[1] == current_idx
		var alpha: float = 0.55 if is_active else 0.28
		var col: Color = Color(0.35, 0.55, 0.9, alpha) if is_active else Color(0.18, 0.28, 0.55, alpha)
		if is_active:
			draw_line(a, b, Color(col.r,col.g,col.b,0.12), 4.0)
		draw_line(a, b, col, 1.5)

	# Systems
	for i in SYSTEMS.size():
		_draw_system(i, cam_pan)

	# Мерцающая точка перелёта
	if _travel_active:
		_draw_travel_dot()

func _draw_travel_dot() -> void:
	var pos := _travel_from.lerp(_travel_to, _travel_t) + cam_pan
	var pulse := 0.7 + sin(time_e * 18.0) * 0.3
	# Шлейф
	for i in 10:
		var trail_t := _travel_t - float(i + 1) * 0.016
		if trail_t < 0.0: break
		var tp    := _travel_from.lerp(_travel_to, trail_t) + cam_pan
		var alpha := (1.0 - float(i) / 10.0) * 0.45 * pulse
		draw_circle(tp, maxf(3.0 - float(i) * 0.25, 0.5), Color(0.55, 0.85, 1.0, alpha))
	# Свечение
	draw_circle(pos, 16.0, Color(0.35, 0.72, 1.0, 0.06 * pulse))
	draw_circle(pos, 10.0, Color(0.50, 0.85, 1.0, 0.14 * pulse))
	draw_circle(pos,  6.0, Color(0.70, 0.95, 1.0, 0.32 * pulse))
	draw_circle(pos,  3.5, Color(0.88, 0.98, 1.0, 0.75))
	draw_circle(pos,  1.8, Color(1.0,  1.0,  1.0, 1.0))

func _draw_system(i: int, offset: Vector2 = Vector2.ZERO) -> void:
	var s    = SYSTEMS[i]
	var pos: Vector2 = s["pos"] + offset
	var col: Color   = s["color"]
	var sz:  float   = s["size"]
	var is_current  := (i == current_idx)
	var is_selected := (i == selected_idx)
	var danger: int  = s["danger"]

	# ── Туман войны — неизвестные системы ────────────────────────────────────
	var visited: bool = i in GameManager.visited_systems
	# «известная» — соединена с посещённой
	var known: bool = visited
	if not known:
		for c in CONNECTIONS:
			if (c[0] == i and c[1] in GameManager.visited_systems) or \
			   (c[1] == i and c[0] in GameManager.visited_systems):
				known = true
				break

	if not known:
		return  # полностью скрыта

	if not visited:
		# Частично видна: тусклое пятно + "???"
		draw_circle(pos, sz * 1.8, Color(col.r * 0.15, col.g * 0.15, col.b * 0.25, 0.45))
		draw_circle(pos, sz * 0.9, Color(col.r * 0.25, col.g * 0.25, col.b * 0.35, 0.70))
		draw_string(ThemeDB.fallback_font, pos + Vector2(-15, sz + 18),
			"???", HORIZONTAL_ALIGNMENT_CENTER, 35, 12, Color(0.35, 0.38, 0.55, 0.70))
		if is_selected:
			draw_arc(pos, sz + 13, 0, TAU, 36, Color(1.0, 1.0, 1.0, 0.60), 1.5)
		return

	# Danger zone outer glow (red tint for high danger)
	if danger >= 4:
		var d_pulse: float = 0.06 + sin(time_e * 1.8 + i) * 0.03
		draw_circle(pos, sz + 22, Color(1.0, 0.2, 0.2, d_pulse))

	# System glow — smooth gradient (10 layers, quadratic alpha falloff)
	for gi in 10:
		var t: float  = float(gi) / 9.0        # 0=outer 1=inner
		var tt: float = t * t
		var gr: float = sz + 28.0 * (1.0 - tt)
		var ga: float = 0.012 * (1.0 - t) * (1.0 - t)
		draw_circle(pos, gr, Color(col.r, col.g, col.b, ga))

	# Current position: animated ring
	if is_current:
		var pulse: float = 0.5 + sin(time_e * 2.8) * 0.35
		draw_arc(pos, sz + 16, 0, TAU, 48, Color(0.2, 1.0, 0.4, pulse), 2.5)
		draw_arc(pos, sz + 22, time_e * 0.5, time_e * 0.5 + TAU * 0.75, 32,
			Color(0.2, 1.0, 0.4, pulse * 0.4), 1.5)

	# Selected ring
	if is_selected:
		draw_arc(pos, sz + 13, 0, TAU, 48, Color(1.0, 1.0, 1.0, 0.85), 2.0)
		# Rotating selection ticks
		for t in 4:
			var ta: float = t / 4.0 * TAU + time_e * 0.8
			var p0: Vector2 = pos + Vector2(cos(ta), sin(ta)) * (sz + 10)
			var p1: Vector2 = pos + Vector2(cos(ta), sin(ta)) * (sz + 18)
			draw_line(p0, p1, Color(1.0, 1.0, 0.3, 0.9), 2.0)

	# Star body — smooth 6-layer gradient from dark edge to bright core
	draw_circle(pos, sz,        Color(col.r * 0.35, col.g * 0.35, col.b * 0.45, 0.88))
	draw_circle(pos, sz * 0.88, col)
	draw_circle(pos, sz * 0.70, Color(minf(col.r+0.18,1.0), minf(col.g+0.18,1.0), minf(col.b+0.12,1.0), 0.80))
	draw_circle(pos, sz * 0.50, Color(minf(col.r+0.30,1.0), minf(col.g+0.30,1.0), minf(col.b+0.22,1.0), 0.72))
	draw_circle(pos, sz * 0.30, Color(minf(col.r+0.42,1.0), minf(col.g+0.42,1.0), minf(col.b+0.32,1.0), 0.82))
	draw_circle(pos, sz * 0.16, Color(1.0, 1.0, 1.0, 0.92))  # bright core

	# YOU ARE HERE marker
	if is_current:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-14, -sz - 14),
			"▼", HORIZONTAL_ALIGNMENT_CENTER, 30, 14, Color(0.2, 1.0, 0.4))

	# Name label with shadow
	draw_string(ThemeDB.fallback_font, pos + Vector2(-66, sz + 19),
		s["name"], HORIZONTAL_ALIGNMENT_CENTER, 135, 13, Color(0,0,0,0.6))
	draw_string(ThemeDB.fallback_font, pos + Vector2(-65, sz + 18),
		s["name"], HORIZONTAL_ALIGNMENT_CENTER, 135, 13,
		Color(col.r*0.6+0.35, col.g*0.6+0.35, col.b*0.4+0.45, 0.95))

	# Faction tag
	draw_string(ThemeDB.fallback_font, pos + Vector2(-50, sz + 31),
		s["faction"], HORIZONTAL_ALIGNMENT_CENTER, 105, 11,
		Color(col.r*0.5+0.2, col.g*0.5+0.2, col.b*0.4+0.3, 0.65))

	# HQ badge — diamond ring + "HQ" label
	if s.get("is_hq", false):
		var hq_pulse: float = 0.55 + sin(time_e * 1.6 + float(i)) * 0.25
		var hq_r: float = sz + 7.0
		# Four diamond points
		for di in 4:
			var da: float = di / 4.0 * TAU + PI / 4.0
			var p0: Vector2 = pos + Vector2(cos(da), sin(da)) * hq_r
			var p1: Vector2 = pos + Vector2(cos(da + TAU/8.0), sin(da + TAU/8.0)) * (hq_r - 3.5)
			draw_line(p0, p1, Color(col.r * 0.7 + 0.3, col.g * 0.7 + 0.3, 0.2, hq_pulse), 1.5)
		draw_arc(pos, hq_r, 0, TAU, 32, Color(col.r * 0.6 + 0.4, col.g * 0.6 + 0.4, 0.15, hq_pulse * 0.55), 1.0)
		draw_string(ThemeDB.fallback_font, pos + Vector2(-9, -sz - 27),
			"HQ", HORIZONTAL_ALIGNMENT_LEFT, 24, 10,
			Color(col.r * 0.5 + 0.5, col.g * 0.5 + 0.5, 0.2, 0.9))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mp := get_global_mouse_position()
		if event.pressed:
			# Check if clicking a system
			for i in SYSTEMS.size():
				if mp.distance_to(SYSTEMS[i]["pos"] + cam_pan) < float(SYSTEMS[i]["size"]) + 14:
					_on_system_clicked(i)
					return
			# Start drag
			_dragging = true
			_drag_from = mp
			info_panel.hide()
			selected_idx = -1
		else:
			_dragging = false

	if event is InputEventMouseMotion and _dragging:
		cam_pan += event.relative
		queue_redraw()

func _calc_jump(from_idx: int, to_idx: int) -> Dictionary:
	var dist: float = SYSTEMS[from_idx]["pos"].distance_to(SYSTEMS[to_idx]["pos"])
	var raw_cost := int(dist * JUMP_COST_PER_PX)
	var cost: int  = maxi(JUMP_MIN_COST, (raw_cost / 50) * 50)
	var days: int  = maxi(1, int(dist / JUMP_DAY_PX))
	return {"cost": cost, "days": days, "dist": int(dist)}

func _on_system_clicked(idx: int) -> void:
	selected_idx = idx
	var s = SYSTEMS[idx]
	var visited: bool = idx in GameManager.visited_systems
	var name_txt: String = s["name"] if visited else "???"
	lbl_name.text    = name_txt
	lbl_faction.text = ("Фракция: " + s["faction"]) if visited else "Фракция: неизвестна"
	var d: int = s["danger"]
	lbl_danger.text = "Опасность: " + "★".repeat(d) + "☆".repeat(5-d)
	var is_current := (idx == current_idx)
	btn_enter.visible    = is_current
	btn_jump.visible     = not is_current
	lbl_jumpcost.visible = not is_current
	if not is_current:
		var jmp      := _calc_jump(current_idx, idx)
		var fuel_need: float = float(jmp["dist"]) * FUEL_PER_PX
		var days_txt: String = "%d день" % jmp["days"] if jmp["days"] == 1 else "%d дня" % jmp["days"]
		var rep_txt: String  = ""
		if visited:
			var standing := GameManager.get_faction_standing(s["faction"])
			rep_txt = "  |  %s: %s" % [s["faction"], standing]
		lbl_jumpcost.text = "Прыжок: %d кред. / %s  |  Топливо: %.0f%%  (%d св. лет)%s" % [
			jmp["cost"], days_txt, fuel_need, jmp["dist"], rep_txt]
		var can_jump: bool = GameManager.credits >= jmp["cost"] and GameManager.fuel >= fuel_need
		btn_jump.disabled = not can_jump
	info_panel.show()
	lbl_status.text = "%s  |  %s  |  Опасность %d/5  |  Топливо: %.0f/%.0f" % [
		name_txt, (s["faction"] if visited else "???"), d, GameManager.fuel, GameManager.max_fuel]

func _on_enter() -> void:
	var s: Dictionary = SYSTEMS[current_idx]
	GameManager.current_galaxy     = s["name"]
	GameManager.current_galaxy_idx = current_idx
	GameManager.current_danger     = s["danger"]
	GameManager.current_faction    = s["faction"]
	if not current_idx in GameManager.visited_systems:
		GameManager.visited_systems.append(current_idx)
	GameManager.save_game()
	get_tree().change_scene_to_file("res://scenes/star_system/StarSystemView.tscn")

func _on_jump() -> void:
	if selected_idx < 0 or selected_idx == current_idx:
		return
	var jmp: Dictionary = _calc_jump(current_idx, selected_idx)
	var fuel_need: float = float(jmp["dist"]) * FUEL_PER_PX
	if not GameManager.spend_credits(jmp["cost"]):
		lbl_status.text = "❌ Недостаточно кредитов!"
		return
	if not GameManager.spend_fuel(fuel_need):
		GameManager.add_credits(jmp["cost"])  # возврат
		lbl_status.text = "⛽ Недостаточно топлива! (нужно %.0f%%, есть %.0f%%)" % [fuel_need, GameManager.fuel]
		return

	var dest: Dictionary = SYSTEMS[selected_idx]
	var days_txt   := "%d день" % jmp["days"] if jmp["days"] == 1 else "%d дня" % jmp["days"]
	lbl_status.text = "⚡ Прыжок к %s... (%s)" % [dest["name"], days_txt]
	btn_jump.disabled = true
	info_panel.hide()
	AudioManager.play_sfx("jump")

	# Анимация мерцающей точки
	_travel_from   = SYSTEMS[current_idx]["pos"]
	_travel_to     = SYSTEMS[selected_idx]["pos"]
	_travel_t      = 0.0
	_travel_active = true

	var from_idx := current_idx
	var to_idx   := selected_idx
	var tween := create_tween()
	tween.tween_interval(TRAVEL_DUR)
	tween.tween_callback(func():
		current_idx  = to_idx
		selected_idx = -1
		var s: Dictionary = SYSTEMS[current_idx]
		GameManager.current_galaxy_idx = current_idx
		GameManager.current_galaxy     = s["name"]
		GameManager.current_danger     = s["danger"]
		GameManager.current_faction    = s["faction"]
		if not current_idx in GameManager.visited_systems:
			GameManager.visited_systems.append(current_idx)
		for _d in jmp["days"]:
			GameManager.advance_day()
		_refresh_topbar()

		# Случайная встреча в гиперпространстве
		var encounter_chance: float = ENCOUNTER_BASE + float(s["danger"]) * ENCOUNTER_DANGER
		if randf() < encounter_chance:
			GameManager.pending_hyperspace_encounter = true
			var hull_loss := randf_range(0.05, 0.15)
			GameManager.ship_hull_pct = maxf(0.05, GameManager.ship_hull_pct - hull_loss)
			AudioManager.play_sfx("hurt")
			lbl_status.text = "⚠  ПЕРЕХВАТ В ГИПЕРПРОСТРАНСТВЕ!  −%.0f%% корпуса  →  Прибыли: %s" % [
				hull_loss * 100, s["name"]]
		else:
			GameManager.pending_hyperspace_encounter = false
			lbl_status.text = "✅ Прибыли: %s  (прошло %s)" % [s["name"], days_txt]
		GameManager.save_game()
	)

func _refresh_topbar() -> void:
	lbl_credits.text  = "💰 %d кред." % GameManager.credits
	lbl_day.text      = "📅 День %d"   % GameManager.day
	lbl_location.text = "📍 %s"        % SYSTEMS[current_idx]["name"]
