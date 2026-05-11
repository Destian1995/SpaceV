extends Node2D

const SYSTEMS = [
	# Core Federation space
	{"name": "Sol Prime",      "pos": Vector2(480, 340), "faction": "Федерация",   "danger": 1, "color": Color(0.45, 0.85, 1.0),  "size": 11},
	{"name": "Krath Station",  "pos": Vector2(750, 190), "faction": "Федерация",   "danger": 2, "color": Color(0.35, 0.65, 1.0),  "size": 9},
	{"name": "Auren Gate",     "pos": Vector2(310, 195), "faction": "Торговцы",    "danger": 2, "color": Color(0.3,  1.0,  0.6),  "size": 10},
	{"name": "Nova Reach",     "pos": Vector2(140, 360), "faction": "Независимые", "danger": 2, "color": Color(0.6,  0.9,  0.7),  "size": 8},
	# Mid-rim
	{"name": "Vega Drift",     "pos": Vector2(230, 510), "faction": "Независимые", "danger": 3, "color": Color(0.95, 0.95, 0.3),  "size": 10},
	{"name": "Pyrox",          "pos": Vector2(840, 530), "faction": "Империя",     "danger": 3, "color": Color(1.0,  0.52, 0.22), "size": 9},
	{"name": "Helion Crossing","pos": Vector2(600, 250), "faction": "Торговцы",    "danger": 2, "color": Color(0.5,  1.0,  0.85), "size": 9},
	{"name": "Orion Breach",   "pos": Vector2(970, 280), "faction": "Империя",     "danger": 3, "color": Color(1.0,  0.7,  0.25), "size": 8},
	{"name": "Thalara",        "pos": Vector2(380, 450), "faction": "Независимые", "danger": 3, "color": Color(0.7,  0.55, 1.0),  "size": 8},
	{"name": "Cassian Rift",   "pos": Vector2(700, 400), "faction": "Независимые", "danger": 3, "color": Color(0.55, 0.8,  0.55), "size": 8},
	# Outer rim / danger
	{"name": "Scarlet Nebula", "pos": Vector2(980, 450), "faction": "Пираты",      "danger": 4, "color": Color(1.0,  0.28, 0.28), "size": 10},
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

const JUMP_COST := 500
const JUMP_DAYS := 1

var current_idx:  int = 0
var selected_idx: int = -1
var bg_stars:     Array = []
var nebulae:      Array = []
var time_e:       float = 0.0

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

func _draw_system(i: int, offset: Vector2 = Vector2.ZERO) -> void:
	var s    = SYSTEMS[i]
	var pos: Vector2 = s["pos"] + offset
	var col: Color   = s["color"]
	var sz:  float   = s["size"]
	var is_current  := (i == current_idx)
	var is_selected := (i == selected_idx)
	var danger: int  = s["danger"]

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

func _on_system_clicked(idx: int) -> void:
	selected_idx = idx
	var s = SYSTEMS[idx]
	lbl_name.text   = s["name"]
	lbl_faction.text = "Фракция: " + s["faction"]
	var d: int = s["danger"]
	lbl_danger.text = "Опасность: " + "★".repeat(d) + "☆".repeat(5-d)
	var is_current := (idx == current_idx)
	btn_enter.visible    = is_current
	btn_jump.visible     = not is_current
	lbl_jumpcost.visible = not is_current
	if not is_current:
		lbl_jumpcost.text = "Прыжок: %d кред. / %d день" % [JUMP_COST, JUMP_DAYS]
		btn_jump.disabled = GameManager.credits < JUMP_COST
	info_panel.show()
	lbl_status.text = "%s  |  %s  |  Опасность %d/5" % [s["name"], s["faction"], d]

func _on_enter() -> void:
	GameManager.current_galaxy     = SYSTEMS[current_idx]["name"]
	GameManager.current_galaxy_idx = current_idx
	GameManager.current_danger     = SYSTEMS[current_idx]["danger"]
	get_tree().change_scene_to_file("res://scenes/star_system/StarSystemView.tscn")

func _on_jump() -> void:
	if selected_idx < 0 or selected_idx == current_idx:
		return
	if not GameManager.spend_credits(JUMP_COST):
		lbl_status.text = "❌ Недостаточно кредитов!"
		return
	var dest = SYSTEMS[selected_idx]
	lbl_status.text = "⚡ Прыжок к %s..." % dest["name"]
	btn_jump.disabled = true
	info_panel.hide()
	var tween := create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		current_idx  = selected_idx
		selected_idx = -1
		GameManager.current_galaxy_idx = current_idx
		GameManager.current_galaxy     = SYSTEMS[current_idx]["name"]
		GameManager.current_danger     = SYSTEMS[current_idx]["danger"]
		GameManager.advance_day()
		_refresh_topbar()
		lbl_status.text = "✅ Прибыли: %s" % dest["name"]
	)

func _refresh_topbar() -> void:
	lbl_credits.text  = "💰 %d кред." % GameManager.credits
	lbl_day.text      = "📅 День %d"   % GameManager.day
	lbl_location.text = "📍 %s"        % SYSTEMS[current_idx]["name"]
