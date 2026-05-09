extends Node2D

const SHIP_SPEED    := 200.0
const LAND_DISTANCE := 48.0
const PLANET_NAMES  := ["Alpha","Beta","Gamma","Delta","Epsilon",
						 "Zeta","Eta","Theta","Iota","Kappa","Lambda","Mu"]

var STAR_POS: Vector2

var galaxy_name: String = ""
var planets: Array      = []
var bg_stars: Array     = []

var ship_pos:    Vector2
var ship_angle:  float   = 0.0
var ship_moving: bool    = false
var target_idx:  int     = -1
var near_idx:    int     = -1
var time_e:      float   = 0.0

var enemies: Array = []
var spaceport_ui = null  # CanvasLayer instance

const ENEMY_CHASE_RANGE   := 180.0
const ENEMY_ATTACK_RANGE  := 60.0
const ENEMY_SPEED         := 85.0
const ENEMY_PATROL_SPEED  := 38.0

# UI refs
@onready var lbl_galaxy   = $UI/TopBar/HBox/GalaxyName
@onready var lbl_credits  = $UI/TopBar/HBox/Credits
@onready var lbl_ship     = $UI/TopBar/HBox/ShipName
@onready var btn_back     = $UI/TopBar/HBox/BackBtn
@onready var btn_ship     = $UI/TopBar/HBox/ShipBtn
@onready var btn_menu_main = $UI/TopBar/HBox/MenuBtn
@onready var planet_panel = $UI/PlanetPanel
@onready var lbl_pname    = $UI/PlanetPanel/VBox/PlanetName
@onready var lbl_ptype    = $UI/PlanetPanel/VBox/PlanetType
@onready var lbl_port     = $UI/PlanetPanel/VBox/PortStatus
@onready var lbl_cargo    = $UI/PlanetPanel/VBox/CargoStatus
@onready var btn_land     = $UI/PlanetPanel/VBox/LandBtn
@onready var lbl_status   = $UI/StatusBar

func _ready() -> void:
	STAR_POS = get_viewport_rect().size / 2.0 + Vector2(0, 30)
	ship_pos = STAR_POS + Vector2(220, 0)
	galaxy_name = GameManager.current_galaxy
	lbl_galaxy.text  = "🌌 " + galaxy_name
	lbl_credits.text = "💰 %d" % GameManager.credits
	lbl_ship.text    = "🚀 " + GameManager.current_ship["name"]
	var _cred_cb := func(v): lbl_credits.text = "💰 %d" % v
	GameManager.credits_changed.connect(_cred_cb)
	tree_exiting.connect(func(): GameManager.credits_changed.disconnect(_cred_cb))
	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/galaxy_map/GalaxyMap.tscn"))
	btn_ship.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/ship_view/ShipView.tscn"))
	btn_menu_main.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main/Main.tscn"))
	btn_land.pressed.connect(_on_land)
	planet_panel.hide()
	_gen_bg_stars()
	_gen_planets()
	_gen_enemies()
	if enemies.is_empty():
		lbl_status.text = "Нажмите на планету чтобы лететь к ней"
	else:
		lbl_status.text = "⚠️ Обнаружено враждебных судов: %d — будьте осторожны!" % enemies.size()
	# Load spaceport
	spaceport_ui = preload("res://scenes/spaceport/Spaceport.tscn").instantiate()
	add_child(spaceport_ui)
	spaceport_ui.visible = false
	spaceport_ui.spaceport_closed.connect(func(): spaceport_ui.visible = false)

func _gen_bg_stars() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(galaxy_name + "_stars")
	var vp := get_viewport_rect().size

	# Nebula clouds
	for i in 18:
		bg_stars.append({
			"nebula": true,
			"pos": Vector2(rng.randf_range(0, vp.x), rng.randf_range(0, vp.y)),
			"r":   rng.randf_range(60, 180),
			"col": Color(rng.randf_range(0.05, 0.25), rng.randf_range(0.0, 0.15),
						 rng.randf_range(0.15, 0.45), rng.randf_range(0.025, 0.065)),
		})

	# Stars with colour temperature (blue/white/yellow/orange)
	var star_palettes := [
		[1.0, 1.0, 1.0],   # white
		[0.7, 0.8, 1.0],   # blue-white
		[0.5, 0.6, 1.0],   # blue
		[1.0, 0.95, 0.7],  # yellow-white
		[1.0, 0.75, 0.45], # orange
	]
	for i in 380:
		var pal: Array = star_palettes[rng.randi() % star_palettes.size()]
		var br: float  = rng.randf_range(0.3, 1.0)
		bg_stars.append({
			"nebula": false,
			"pos": Vector2(rng.randf_range(0, vp.x), rng.randf_range(0, vp.y)),
			"r":   rng.randf_range(0.4, 2.2),
			"br":  br,
			"ph":  rng.randf_range(0, TAU),
			"spd": rng.randf_range(0.4, 1.5),
			"cr":  pal[0], "cg": pal[1], "cb": pal[2],
		})

func _gen_planets() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(galaxy_name)
	var count: int = rng.randi_range(5, 12)
	var types  := ["Каменистая","Газовый гигант","Ледяная","Пустынная","Океаническая","Вулканическая","Джунгли"]
	for i in count:
		var orbit_r: float = lerp(110.0, 450.0, float(i) / max(count - 1, 1))
		var has_port: bool = rng.randf() < 0.5
		var planet := {
			"name":         galaxy_name.split(" ")[0] + " " + PLANET_NAMES[i],
			"orbit_radius": orbit_r,
			"orbit_angle":  rng.randf() * TAU,
			"orbit_speed":  0.13 / sqrt(float(i + 1)),
			"size":         rng.randf_range(10, 26),
			"color":        Color(rng.randf_range(0.2, 1.0), rng.randf_range(0.2, 1.0), rng.randf_range(0.3, 1.0)),
			"has_spaceport":has_port,
			"type":         types[rng.randi() % types.size()],
			"pos":          Vector2.ZERO,
			"goods":        {},
			"weapons":      [],
			"ships":        [],
		}
		if has_port:
			planet["goods"]   = GameData.generate_planet_goods(rng)
			planet["weapons"] = GameData.get_random_weapons(rng)
			planet["ships"]   = GameData.get_random_ships(rng)
			planet["quests"]  = GameData.generate_quests(rng, planet["name"], galaxy_name)
		planets.append(planet)

func _gen_enemies() -> void:
	var danger: int = GameManager.current_danger
	var spawn_chance: float
	if danger <= 2:
		spawn_chance = 0.10
	elif danger <= 4:
		spawn_chance = 0.35
	else:
		spawn_chance = 0.60

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(galaxy_name + "_enemies")
	var vp := get_viewport_rect().size

	var max_enemies := 3 + (danger / 2)
	for i in max_enemies:
		if rng.randf() > spawn_chance:
			continue
		var angle: float = rng.randf_range(0, TAU)
		var dist: float  = rng.randf_range(160.0, 420.0)
		var epos: Vector2 = STAR_POS + Vector2(cos(angle), sin(angle)) * dist
		epos = epos.clamp(Vector2(40, 40), vp - Vector2(40, 40))
		var hull_max: int = 60 + danger * 20
		enemies.append({
			"pos":       epos,
			"angle":     rng.randf_range(0, TAU),
			"patrol_center": epos,
			"patrol_r":  rng.randf_range(50.0, 110.0),
			"patrol_angle": rng.randf_range(0, TAU),
			"patrol_spd": rng.randf_range(0.3, 0.7) * (1 if rng.randf() > 0.5 else -1),
			"state":     "patrol",   # patrol | chase | flee
			"hull":      hull_max,
			"hull_max":  hull_max,
			"hit_flash": 0.0,
			"variant":   rng.randi() % 3,  # 0=scout 1=fighter 2=heavy
		})

func _process(delta: float) -> void:
	if spaceport_ui and spaceport_ui.visible:
		return
	time_e += delta
	_update_orbits(delta)
	_move_ship(delta)
	_update_enemies(delta)
	_check_proximity()
	queue_redraw()

func _update_enemies(delta: float) -> void:
	for e in enemies:
		var dist_to_player: float = e["pos"].distance_to(ship_pos)

		# State transitions
		match e["state"]:
			"patrol":
				if dist_to_player < ENEMY_CHASE_RANGE:
					e["state"] = "chase"
			"chase":
				if dist_to_player > ENEMY_CHASE_RANGE * 1.4:
					e["state"] = "patrol"
			"flee":
				if dist_to_player > ENEMY_CHASE_RANGE * 2.0:
					e["state"] = "patrol"

		# Movement
		match e["state"]:
			"patrol":
				e["patrol_angle"] += e["patrol_spd"] * delta
				var target: Vector2 = e["patrol_center"] + Vector2(
					cos(e["patrol_angle"]), sin(e["patrol_angle"])) * e["patrol_r"]
				var dir: Vector2 = target - e["pos"]
				if dir.length() > 2.0:
					e["pos"] += dir.normalized() * ENEMY_PATROL_SPEED * delta
					e["angle"] = atan2(dir.y, dir.x) + PI / 2.0
			"chase":
				var dir: Vector2 = ship_pos - e["pos"]
				if dir.length() > 1.0:
					e["pos"] += dir.normalized() * ENEMY_SPEED * delta
					e["angle"] = atan2(dir.y, dir.x) + PI / 2.0
			"flee":
				var dir: Vector2 = e["pos"] - ship_pos
				if dir.length() > 1.0:
					e["pos"] += dir.normalized() * ENEMY_SPEED * 0.9 * delta
					e["angle"] = atan2(dir.y, dir.x) + PI / 2.0

		# Tick down hit flash
		if e["hit_flash"] > 0.0:
			e["hit_flash"] = max(0.0, e["hit_flash"] - delta * 4.0)

func _update_orbits(delta: float) -> void:
	for p in planets:
		p["orbit_angle"] += p["orbit_speed"] * delta
		p["pos"] = STAR_POS + Vector2(cos(p["orbit_angle"]), sin(p["orbit_angle"])) * p["orbit_radius"]

func _move_ship(delta: float) -> void:
	if not ship_moving or target_idx < 0:
		return
	var target: Vector2 = planets[target_idx]["pos"]
	var dir: Vector2 = target - ship_pos
	if dir.length() < LAND_DISTANCE * 0.7:
		ship_moving = false
	else:
		ship_pos  += dir.normalized() * SHIP_SPEED * delta
		ship_angle = atan2(dir.y, dir.x) + PI / 2.0

func _check_proximity() -> void:
	var prev: int = near_idx
	near_idx = -1
	for i in planets.size():
		if ship_pos.distance_to(planets[i]["pos"]) < LAND_DISTANCE:
			near_idx = i
			break
	if near_idx != prev:
		_refresh_planet_panel()

func _refresh_planet_panel() -> void:
	if near_idx >= 0:
		var p = planets[near_idx]
		lbl_pname.text  = p["name"]
		lbl_ptype.text  = "Тип: " + p["type"]
		lbl_port.text   = "✅ Космопорт" if p["has_spaceport"] else "❌ Нет космопорта"
		lbl_port.modulate = Color.GREEN if p["has_spaceport"] else Color(1, 0.4, 0.4)
		lbl_cargo.text  = "Груз: %d/%d" % [GameManager.cargo_capacity - GameManager.cargo_free(), GameManager.cargo_capacity]
		btn_land.text   = "🛬 Войти в космопорт" if p["has_spaceport"] else "🔭 Исследовать (нет порта)"
		btn_land.disabled = false
		planet_panel.show()
		lbl_status.text = "Рядом: %s" % p["name"]
	else:
		planet_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if spaceport_ui and spaceport_ui.visible:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var mp := get_global_mouse_position()
		for i in planets.size():
			var p = planets[i]
			if mp.distance_to(p["pos"]) < p["size"] + 12:
				_fly_to(i)
				return

func _fly_to(idx: int) -> void:
	target_idx   = idx
	ship_moving  = true
	lbl_status.text = "⚡ Курс на %s..." % planets[idx]["name"]

func _on_land() -> void:
	if near_idx < 0:
		return
	var p = planets[near_idx]
	if p["has_spaceport"]:
		spaceport_ui.open_spaceport(p)
	else:
		lbl_status.text = "Планета %s необитаема. Ресурсов не обнаружено." % p["name"]

func _draw() -> void:
	var vp := get_viewport_rect().size

	# ── Deep space background gradient ──────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.005, 0.005, 0.018, 1))

	# Subtle nebula clouds in bg
	for s in bg_stars:
		if s.get("nebula", false):
			draw_circle(s["pos"], s["r"], s["col"])

	# Stars with colour variance and twinkle
	for s in bg_stars:
		if s.get("nebula", false):
			continue
		var br: float = s["br"] + sin(time_e * s.get("spd", 0.8) + s["ph"]) * 0.18
		var sz: float = s["r"] * (0.8 + sin(time_e * s.get("spd", 1.0) * 1.3 + s["ph"]) * 0.2)
		draw_circle(s["pos"], sz, Color(br * s["cr"], br * s["cg"], br * s["cb"], br))

	# ── Orbit rings ─────────────────────────────────────────────────────────
	for idx in planets.size():
		var p = planets[idx]
		var orbit_r: float = p["orbit_radius"]
		# Dashed orbit feel via many short arcs
		for seg in 48:
			var a0: float = seg / 48.0 * TAU
			var a1: float = (seg + 0.55) / 48.0 * TAU
			draw_arc(STAR_POS, orbit_r, a0, a1, 6, Color(0.15, 0.22, 0.45, 0.35), 1.0)

	# ── Central star ────────────────────────────────────────────────────────
	_draw_star()

	# ── Planets ─────────────────────────────────────────────────────────────
	for i in planets.size():
		_draw_planet(i)

	# ── Travel course line ──────────────────────────────────────────────────
	if ship_moving and target_idx >= 0:
		var td: Vector2 = planets[target_idx]["pos"]
		draw_dashed_line(ship_pos, td, Color(0.25, 0.6, 1.0, 0.35), 1.5, 12.0)
		# Arrowhead at target
		var dir: Vector2 = (td - ship_pos).normalized()
		var arr: Vector2 = td - dir * 28
		draw_line(arr, arr + dir.rotated(2.4) * 10, Color(0.4, 0.8, 1.0, 0.7), 1.5)
		draw_line(arr, arr + dir.rotated(-2.4) * 10, Color(0.4, 0.8, 1.0, 0.7), 1.5)

	# ── Enemy ships ─────────────────────────────────────────────────────────
	for e in enemies:
		_draw_enemy(e)

	# ── Player ship ─────────────────────────────────────────────────────────
	_draw_ship()

func _draw_star() -> void:
	var pulse: float = sin(time_e * 1.3) * 0.03

	# Corona layers — wide soft glow
	draw_circle(STAR_POS, 130, Color(1.0, 0.55, 0.1, 0.025 + pulse))
	draw_circle(STAR_POS, 100, Color(1.0, 0.65, 0.15, 0.05 + pulse))
	draw_circle(STAR_POS, 78,  Color(1.0, 0.72, 0.2, 0.10))
	draw_circle(STAR_POS, 60,  Color(1.0, 0.80, 0.3, 0.20))
	draw_circle(STAR_POS, 46,  Color(1.0, 0.88, 0.42, 0.55))
	draw_circle(STAR_POS, 34,  Color(1.0, 0.93, 0.6, 0.88))
	draw_circle(STAR_POS, 22,  Color(1.0, 0.97, 0.82, 0.97))
	draw_circle(STAR_POS, 13,  Color(1.0, 1.0,  0.97, 1.0))

	# Solar flare rays
	for ray in 8:
		var angle: float = ray / 8.0 * TAU + time_e * 0.08
		var r0: float = 34.0
		var r1: float = 68.0 + sin(time_e * 1.8 + ray) * 12.0
		var p0: Vector2 = STAR_POS + Vector2(cos(angle), sin(angle)) * r0
		var p1: Vector2 = STAR_POS + Vector2(cos(angle), sin(angle)) * r1
		draw_line(p0, p1, Color(1.0, 0.85, 0.3, 0.12 + sin(time_e * 2.0 + ray) * 0.06), 2.5)

func _draw_planet(i: int) -> void:
	var p   = planets[i]
	var pos: Vector2 = p["pos"]
	var col: Color   = p["color"]
	var sz:  float   = p["size"]
	var ptype: String = p.get("type", "")

	# ── Atmosphere glow ──────────────────────────────────────────────────────
	var atm_col := Color(col.r * 0.6, col.g * 0.7, col.b * 0.9, 0.12)
	draw_circle(pos, sz + 10, atm_col)
	draw_circle(pos, sz + 6,  Color(atm_col.r, atm_col.g, atm_col.b, 0.18))

	# ── Planet body ──────────────────────────────────────────────────────────
	# Base color
	draw_circle(pos, sz, col)

	# Surface bands (latitude stripes) for gas giants
	if "Газ" in ptype:
		for band in 4:
			var band_y: float = lerp(-sz * 0.7, sz * 0.7, band / 3.0)
			var band_r: float = sqrt(max(0.0, sz * sz - band_y * band_y)) * 0.95
			var bc := Color(col.r * randf_range(0.7, 1.1), col.g * randf_range(0.7, 1.1), col.b, 0.25)
			draw_line(pos + Vector2(-band_r, band_y), pos + Vector2(band_r, band_y), bc, 3.5)

	# Ice cap for icy planets
	if "Ледяная" in ptype or "Снеж" in ptype:
		draw_circle(pos + Vector2(0, -sz * 0.55), sz * 0.5, Color(0.85, 0.93, 1.0, 0.45))

	# Lava for volcanic
	if "Вулкан" in ptype:
		for lv in 3:
			var langle: float = lv / 3.0 * TAU + time_e * 0.3
			draw_circle(pos + Vector2(cos(langle), sin(langle)) * sz * 0.5, sz * 0.18,
				Color(1.0, 0.35, 0.05, 0.55))

	# ── Shadow (dark side) ───────────────────────────────────────────────────
	var light_dir: Vector2 = (pos - STAR_POS).normalized()
	var shadow_off: Vector2 = light_dir * sz * 0.28
	draw_circle(pos + shadow_off, sz * 0.88, Color(0.0, 0.0, 0.05, 0.52))

	# ── Specular highlight ───────────────────────────────────────────────────
	var spec_off: Vector2 = -light_dir * sz * 0.32
	draw_circle(pos + spec_off + Vector2(0, -sz * 0.18), sz * 0.38,
		Color(1.0, 1.0, 1.0, 0.18))

	# ── Rings (for large gas planets) ────────────────────────────────────────
	if sz > 20 and "Газ" in ptype:
		draw_arc(pos, sz + 16, 0.15, TAU - 0.15, 48, Color(col.r, col.g, col.b, 0.28), 4.0)
		draw_arc(pos, sz + 22, 0.3,  TAU - 0.3,  40, Color(col.r * 0.8, col.g * 0.8, col.b, 0.16), 2.5)

	# ── Spaceport indicator ──────────────────────────────────────────────────
	if p["has_spaceport"]:
		var pulse: float = 0.25 + abs(sin(time_e * 2.0 + i * 0.9)) * 0.22
		draw_circle(pos, sz + 12, Color(0.1, 0.85, 0.3, pulse * 0.5))
		# Station orbit dot
		var rot: float = time_e * 1.5 + i * 1.1
		var sta: Vector2 = pos + Vector2(cos(rot), sin(rot)) * (sz + 14)
		draw_circle(sta, 3.5, Color(0.3, 1.0, 0.55, 0.9))
		draw_circle(sta, 1.8, Color(1.0, 1.0, 1.0, 1.0))

	# ── Selected ring ────────────────────────────────────────────────────────
	if i == near_idx:
		draw_arc(pos, sz + 18, 0, TAU, 48, Color(1.0, 0.95, 0.2, 0.9), 2.0)
		# Corner tick marks
		for tick in 4:
			var ta: float = tick / 4.0 * TAU + PI / 4.0
			var t0: Vector2 = pos + Vector2(cos(ta), sin(ta)) * (sz + 15)
			var t1: Vector2 = pos + Vector2(cos(ta), sin(ta)) * (sz + 24)
			draw_line(t0, t1, Color(1.0, 1.0, 0.3, 0.95), 2.5)

	# ── Planet name ──────────────────────────────────────────────────────────
	var name_col := Color(col.r * 0.7 + 0.3, col.g * 0.7 + 0.3, col.b * 0.5 + 0.5, 0.92)
	draw_string(ThemeDB.fallback_font, pos + Vector2(-70, sz + 20),
		p["name"], HORIZONTAL_ALIGNMENT_CENTER, 150, 13, name_col)
	if p["has_spaceport"]:
		draw_string(ThemeDB.fallback_font, pos + Vector2(-30, sz + 34),
			"[порт]", HORIZONTAL_ALIGNMENT_CENTER, 80, 11, Color(0.25, 0.95, 0.45, 0.75))

func _draw_enemy(e: Dictionary) -> void:
	var pos: Vector2   = e["pos"]
	var angle: float   = e["angle"]
	var variant: int   = e["variant"]
	var is_chasing: bool = e["state"] == "chase"
	var hp_pct: float  = float(e["hull"]) / float(e["hull_max"])
	var flash: float   = e["hit_flash"]

	var fwd:   Vector2 = Vector2(sin(angle), -cos(angle))
	var right: Vector2 = fwd.rotated(PI / 2.0)

	# Scale by variant: 0=scout(small) 1=fighter(mid) 2=heavy(big)
	var sz: float = 13.0 if variant == 0 else (17.0 if variant == 1 else 22.0)
	var wing_spread: float = 0.9 if variant == 0 else (0.95 if variant == 1 else 1.05)

	var tip:    Vector2 = pos + fwd * sz
	var back:   Vector2 = pos - fwd * sz * 0.6
	var wing_l: Vector2 = pos - fwd * sz * 0.05 + right * sz * wing_spread
	var wing_r: Vector2 = pos - fwd * sz * 0.05 - right * sz * wing_spread
	var tail_l: Vector2 = back + right * sz * 0.38
	var tail_r: Vector2 = back - right * sz * 0.38

	# Hull color: red/orange scheme, flash white on hit
	var base_col := Color(0.82, 0.18, 0.12, 0.95)
	var acc_col  := Color(1.0,  0.42, 0.08, 0.70)
	if variant == 1:
		base_col = Color(0.75, 0.12, 0.22, 0.95)
		acc_col  = Color(1.0,  0.28, 0.35, 0.65)
	elif variant == 2:
		base_col = Color(0.55, 0.08, 0.55, 0.95)
		acc_col  = Color(0.85, 0.25, 0.85, 0.55)
	if flash > 0.0:
		base_col = base_col.lerp(Color.WHITE, flash)
		acc_col  = acc_col.lerp(Color.WHITE,  flash)

	# Engine glow — red exhaust
	var eng_alpha: float = 0.15 + (0.45 if is_chasing else 0.0)
	draw_circle(back, sz * 0.42, Color(1.0, 0.28, 0.1, eng_alpha))
	if is_chasing:
		var flicker: float = 0.65 + sin(time_e * 28.0 + float(e["hull"])) * 0.3
		draw_circle(back - fwd * 3,  sz * 0.38 * flicker, Color(1.0,  0.35, 0.08, 0.85))
		draw_circle(back - fwd * 9,  sz * 0.26 * flicker, Color(1.0,  0.52, 0.18, 0.55))
		draw_circle(back - fwd * 15, sz * 0.18 * flicker, Color(1.0,  0.72, 0.35, 0.30))

	# Hull polygon
	draw_colored_polygon([tip, wing_l, tail_l, back, tail_r, wing_r], base_col)
	draw_colored_polygon([tip, pos + right * sz * 0.18, back, pos - right * sz * 0.18], acc_col)

	# Cockpit (dark hostile tint)
	var cock: Vector2 = pos + fwd * sz * 0.35
	draw_circle(cock, sz * 0.22, Color(1.0, 0.2, 0.1, 0.85))
	draw_circle(cock, sz * 0.12, Color(1.0, 0.6, 0.3, 0.9))

	# Wing tip lights (red)
	draw_circle(wing_l, 2.0, Color(1.0, 0.15, 0.15, 0.9))
	draw_circle(wing_r, 2.0, Color(1.0, 0.15, 0.15, 0.9))

	# Chase indicator — warning arc above ship
	if is_chasing:
		var warn_pulse: float = 0.5 + sin(time_e * 5.0) * 0.4
		draw_arc(pos, sz + 10, -PI * 0.6, PI * 0.6, 20, Color(1.0, 0.2, 0.1, warn_pulse), 2.0)

	# Hull bar (only when damaged or chasing)
	if hp_pct < 1.0 or is_chasing:
		var bar_w: float = sz * 2.4
		var bar_y: float = pos.y - sz - 14
		draw_rect(Rect2(pos.x - bar_w * 0.5, bar_y, bar_w, 4), Color(0.15, 0.0, 0.0, 0.8))
		var hp_col := Color(0.1, 0.9, 0.2) if hp_pct > 0.5 else (Color(0.9, 0.7, 0.1) if hp_pct > 0.25 else Color(1.0, 0.1, 0.1))
		draw_rect(Rect2(pos.x - bar_w * 0.5, bar_y, bar_w * hp_pct, 4), hp_col)

	# Faction label
	var tag := "РАЗВЕДЧИК" if variant == 0 else ("ИСТРЕБИТЕЛЬ" if variant == 1 else "ТЯЖЁЛЫЙ")
	draw_string(ThemeDB.fallback_font, pos + Vector2(-28, sz + 16),
		tag, HORIZONTAL_ALIGNMENT_CENTER, 80, 10, Color(1.0, 0.35, 0.25, 0.7))

func _draw_ship() -> void:
	var sz:    float   = 16.0
	var fwd:   Vector2 = Vector2(sin(ship_angle), -cos(ship_angle))
	var right: Vector2 = fwd.rotated(PI / 2.0)
	var tip:   Vector2 = ship_pos + fwd * sz
	var back:  Vector2 = ship_pos - fwd * sz * 0.55

	# Engine glow (always present, brighter when moving)
	var eng_alpha: float = 0.18 + (0.4 if ship_moving else 0.0)
	draw_circle(back, 7.0, Color(0.3, 0.6, 1.0, eng_alpha))

	# Engine trail particles
	if ship_moving:
		var flicker: float = 0.6 + sin(time_e * 30.0) * 0.35
		# Main exhaust
		draw_circle(back - fwd * 3,  6.5 * flicker, Color(0.35, 0.65, 1.0, 0.80))
		draw_circle(back - fwd * 10, 4.5 * flicker, Color(0.55, 0.80, 1.0, 0.55))
		draw_circle(back - fwd * 17, 3.0 * flicker, Color(0.75, 0.92, 1.0, 0.35))
		draw_circle(back - fwd * 24, 1.8 * flicker, Color(0.9,  1.0,  1.0, 0.18))
		# Side micro-thrusters
		draw_circle(back + right * 5 - fwd * 2, 2.5 * flicker, Color(0.4, 0.7, 1.0, 0.5))
		draw_circle(back - right * 5 - fwd * 2, 2.5 * flicker, Color(0.4, 0.7, 1.0, 0.5))

	# Ship hull — main body
	var wing_l: Vector2 = ship_pos - fwd * sz * 0.1 + right * sz * 0.85
	var wing_r: Vector2 = ship_pos - fwd * sz * 0.1 - right * sz * 0.85
	var tail_l: Vector2 = back + right * sz * 0.35
	var tail_r: Vector2 = back - right * sz * 0.35

	draw_colored_polygon([tip, wing_l, tail_l, back, tail_r, wing_r],
		Color(0.18, 0.55, 0.90, 0.95))

	# Hull accent stripe
	draw_colored_polygon([tip, ship_pos + right * sz * 0.15, back, ship_pos - right * sz * 0.15],
		Color(0.55, 0.82, 1.0, 0.55))

	# Cockpit glow
	var cock: Vector2 = ship_pos + fwd * sz * 0.38
	draw_circle(cock, 3.8, Color(0.7, 0.95, 1.0, 0.85))
	draw_circle(cock, 2.0, Color(1.0, 1.0, 1.0, 0.9))

	# Wing tip lights
	draw_circle(wing_l, 2.2, Color(1.0, 0.3, 0.3, 0.9))
	draw_circle(wing_r, 2.2, Color(0.3, 1.0, 0.4, 0.9))
