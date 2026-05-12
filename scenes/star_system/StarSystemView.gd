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
var _combat_triggered: bool = false

# Camera pan
var cam_pan:    Vector2 = Vector2.ZERO
var _dragging:  bool    = false

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

	# Load spaceport BEFORE any await so it's always ready
	spaceport_ui = preload("res://scenes/spaceport/Spaceport.tscn").instantiate()
	add_child(spaceport_ui)
	spaceport_ui.visible = false
	spaceport_ui.spaceport_closed.connect(func(): spaceport_ui.visible = false)

	# After combat — handle result
	var result := GameManager.combat_result
	GameManager.combat_result = ""
	if result == "won":
		var eid := GameManager.pending_enemy_id
		# Запоминаем убитого врага чтобы не respawn'ить при перезагрузке сцены
		if eid >= 0 and not GameManager.current_system_dead_enemies.has(eid):
			GameManager.current_system_dead_enemies.append(eid)
		for idx in range(enemies.size() - 1, -1, -1):
			if enemies[idx].get("id", -2) == eid:
				enemies.remove_at(idx)
				break
		_combat_triggered = true
		if enemies.is_empty():
			lbl_status.text = "🏆 Все враги уничтожены! Космопорты системы открыты."
		else:
			lbl_status.text = "✅ Победа! Осталось врагов: %d — космопорты заблокированы." % enemies.size()
		_refresh_planet_panel()
		await get_tree().create_timer(4.0).timeout
		_combat_triggered = false
	elif result == "lost":
		_combat_triggered = true
		lbl_status.text = "⚠ Корабль повреждён — %d%% корпуса. Найдите космопорт для ремонта!" \
			% int(GameManager.ship_hull_pct * 100)
		await get_tree().create_timer(5.0).timeout
		_combat_triggered = false
	elif result == "retreat":
		_combat_triggered = true
		lbl_status.text = "🏃 Вы отступили. Враги всё ещё в системе! Космопорты заблокированы."
		await get_tree().create_timer(5.0).timeout
		_combat_triggered = false
	else:
		_update_status_label()

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
		# Используем rng в том же порядке чтобы сохранить детерминизм расположения
		var roll_r: float = rng.randf()
		var angle:  float = rng.randf_range(0, TAU)
		var dist:   float = rng.randf_range(160.0, 420.0)
		var ang2:   float = rng.randf_range(0, TAU)
		var pat_r:  float = rng.randf_range(50.0, 110.0)
		var pat_a:  float = rng.randf_range(0, TAU)
		var pat_s:  float = rng.randf_range(0.3, 0.7) * (1 if rng.randf() > 0.5 else -1)
		var vari:   int   = rng.randi() % 3

		# Пропускаем врагов убитых в этом посещении системы
		if GameManager.current_system_dead_enemies.has(i):
			continue
		if roll_r > spawn_chance:
			continue

		var epos: Vector2 = STAR_POS + Vector2(cos(angle), sin(angle)) * dist
		epos = epos.clamp(Vector2(40, 40), vp - Vector2(40, 40))
		var hull_max: int = 60 + danger * 20
		enemies.append({
			"id":           i,
			"pos":          epos,
			"angle":        ang2,
			"patrol_center": epos,
			"patrol_r":     pat_r,
			"patrol_angle": pat_a,
			"patrol_spd":   pat_s,
			"state":        "patrol",   # patrol | chase | flee
			"hull":         hull_max,
			"hull_max":     hull_max,
			"hit_flash":    0.0,
			"variant":      vari,  # 0=scout 1=fighter 2=heavy
		})

func _update_status_label() -> void:
	if enemies.is_empty():
		lbl_status.text = "✅ Система чиста — нажмите на планету чтобы лететь к ней"
	else:
		lbl_status.text = "🔴 Враждебных судов: %d — космопорты ЗАБЛОКИРОВАНЫ! Уничтожьте их." % enemies.size()

func _process(delta: float) -> void:
	if spaceport_ui and spaceport_ui.visible:
		return
	time_e += delta
	_update_orbits(delta)
	_move_ship(delta)
	_update_enemies(delta)
	_check_proximity()
	_check_enemy_hover()
	queue_redraw()

func _check_enemy_hover() -> void:
	if _combat_triggered:
		return
	var mp := get_global_mouse_position()
	for e in enemies:
		var e_screen: Vector2 = e["pos"] + cam_pan
		var e_sz: float = 13.0 if e["variant"] == 0 else (17.0 if e["variant"] == 1 else 22.0)
		if mp.distance_to(e_screen) < e_sz + 14:
			var tag := "РАЗВЕДЧИК" if e["variant"] == 0 else ("ИСТРЕБИТЕЛЬ" if e["variant"] == 1 else "ТЯЖЁЛЫЙ")
			lbl_status.text = "⚔ [ЛКМ] Атаковать %s — ❤ %d/%d" % [tag, e["hull"], e["hull_max"]]
			return

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

		# Trigger combat when enemy reaches player
		if not _combat_triggered and e["state"] == "chase" and dist_to_player < ENEMY_ATTACK_RANGE:
			_combat_triggered = true
			_enter_combat(e)

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
		var blocked: bool = enemies.size() > 0
		lbl_pname.text = p["name"]
		lbl_ptype.text = "Тип: " + p["type"]
		lbl_cargo.text = "Груз: %d/%d" % [GameManager.cargo_capacity - GameManager.cargo_free(), GameManager.cargo_capacity]
		if blocked:
			lbl_port.text     = "🔴 ЗАБЛОКИРОВАН — уничтожьте %d врагов!" % enemies.size()
			lbl_port.modulate = Color(1.0, 0.3, 0.3)
			btn_land.text     = "🔴 Заблокирован врагами"
			btn_land.disabled = true
		elif p["has_spaceport"]:
			lbl_port.text     = "✅ Космопорт"
			lbl_port.modulate = Color.GREEN
			btn_land.text     = "🛬 Войти в космопорт"
			btn_land.disabled = false
		else:
			lbl_port.text     = "❌ Нет космопорта"
			lbl_port.modulate = Color(1.0, 0.5, 0.5)
			btn_land.text     = "🔭 Исследовать (нет порта)"
			btn_land.disabled = false
		planet_panel.show()
		if blocked:
			lbl_status.text = "🔴 %s — враги в системе! Космопорт заблокирован." % p["name"]
		else:
			lbl_status.text = "Рядом: %s" % p["name"]
	else:
		planet_panel.hide()

func _unhandled_input(event: InputEvent) -> void:
	if spaceport_ui and spaceport_ui.visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var mp := get_global_mouse_position()
		if event.pressed:
			# Check enemy ship click — player initiates attack
			for e in enemies:
				var e_screen: Vector2 = e["pos"] + cam_pan
				var e_sz: float = 13.0 if e["variant"] == 0 else (17.0 if e["variant"] == 1 else 22.0)
				if mp.distance_to(e_screen) < e_sz + 14:
					_attack_enemy(e)
					return
			# Check planet click (account for cam_pan)
			for i in planets.size():
				var p = planets[i]
				if mp.distance_to(p["pos"] + cam_pan) < p["size"] + 12:
					_fly_to(i)
					return
			# Start drag
			_dragging = true
		else:
			_dragging = false

	if event is InputEventMouseMotion and _dragging:
		cam_pan += event.relative
		queue_redraw()
		return

func _fly_to(idx: int) -> void:
	target_idx   = idx
	ship_moving  = true
	lbl_status.text = "⚡ Курс на %s..." % planets[idx]["name"]

func _attack_enemy(enemy: Dictionary) -> void:
	if _combat_triggered:
		return
	_combat_triggered = true
	var tag := "РАЗВЕДЧИК" if enemy["variant"] == 0 else ("ИСТРЕБИТЕЛЬ" if enemy["variant"] == 1 else "ТЯЖЁЛЫЙ")
	lbl_status.text = "⚔ Атакуем %s! Подготовка к бою..." % tag
	await get_tree().create_timer(0.5).timeout
	_enter_combat(enemy)

func _enter_combat(enemy: Dictionary) -> void:
	GameManager.pending_enemy_variant = enemy.get("variant", 1)
	GameManager.pending_enemy_hull    = enemy.get("hull", 80)
	GameManager.pending_enemy_id      = enemy.get("id", -1)
	lbl_status.text = "⚠ Враг атакует! Входим в боевой режим..."
	await get_tree().create_timer(0.6).timeout
	get_tree().change_scene_to_file("res://scenes/combat/CombatScene.tscn")

func _on_land() -> void:
	if near_idx < 0:
		return
	if enemies.size() > 0:
		lbl_status.text = "🔴 Нельзя! Уничтожьте %d вражеских кораблей чтобы открыть доступ к космопорту." % enemies.size()
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

	# Apply camera pan to all world objects (not background)
	draw_set_transform(cam_pan)

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

	# Reset transform (UI elements stay fixed)
	draw_set_transform(Vector2.ZERO)

func _draw_star() -> void:
	var pulse: float = sin(time_e * 1.3) * 0.018

	# ── Ultra-smooth corona: 120 thin layers, two-zone blending ─────────────
	# Zone 1: outer halo (r 220 → 60) — very faint, many circles
	var outer_n := 70
	for i in outer_n:
		var t: float   = float(i) / float(outer_n - 1)   # 0=far 1=edge-of-body
		var tt: float  = t * t
		var ttt: float = tt * t
		var r: float   = lerp(220.0, 60.0, tt)
		# Alpha: exponential ramp, each circle very faint so 70 layers sum smoothly
		var a: float   = (0.0018 + 0.008 * ttt) * (1.0 + pulse * t)
		var cr: float  = lerp(0.80, 1.0,  tt)
		var cg: float  = lerp(0.38, 0.88, tt)
		var cb: float  = lerp(0.04, 0.55, ttt)
		draw_circle(STAR_POS, r, Color(cr, cg, cb, a))

	# Zone 2: body glow (r 65 → 22) — denser, transitions to solid
	var inner_n := 50
	for i in inner_n:
		var t: float   = float(i) / float(inner_n - 1)
		var tt: float  = t * t
		var ttt: float = tt * t
		var r: float   = lerp(65.0, 22.0, tt)
		var a: float   = lerp(0.018, 0.72, ttt) + pulse * tt
		var cr: float  = lerp(1.0, 1.0,  t)
		var cg: float  = lerp(0.72, 0.97, tt)
		var cb: float  = lerp(0.14, 0.86, ttt)
		draw_circle(STAR_POS, r, Color(cr, cg, cb, a))

	# Solid core — bright centre
	draw_circle(STAR_POS, 22, Color(1.0, 0.98, 0.88, 1.0))
	draw_circle(STAR_POS, 14, Color(1.0, 1.0,  0.96, 1.0))
	draw_circle(STAR_POS,  7, Color(1.0, 1.0,  1.0,  1.0))

	# Solar flare rays — tapered lines with glow
	for ray in 8:
		var angle: float = ray / 8.0 * TAU + time_e * 0.07
		var r0: float = 28.0
		var r1: float = 70.0 + sin(time_e * 1.9 + ray * 1.3) * 14.0
		var a0: float = 0.22 + sin(time_e * 2.1 + ray) * 0.08
		var pa: Vector2 = STAR_POS + Vector2(cos(angle), sin(angle)) * r0
		var pb: Vector2 = STAR_POS + Vector2(cos(angle), sin(angle)) * r1
		draw_line(pa, pb, Color(1.0, 0.88, 0.35, a0 * 0.5), 3.5)
		draw_line(pa, pb, Color(1.0, 0.95, 0.60, a0), 1.5)

func _draw_planet(i: int) -> void:
	var p   = planets[i]
	var pos: Vector2 = p["pos"]
	var col: Color   = p["color"]
	var sz:  float   = p["size"]
	var ptype: String = p.get("type", "")

	# ── Atmosphere glow — smooth gradient (8 layers, quadratic falloff) ────────
	var atm_cr: float = clampf(col.r * 0.62 + 0.12, 0, 1)
	var atm_cg: float = clampf(col.g * 0.70 + 0.10, 0, 1)
	var atm_cb: float = clampf(col.b * 0.95 + 0.05, 0, 1)
	for ai in 8:
		var t: float  = float(ai) / 7.0           # 0=outer 1=inner
		var tt: float = t * t
		var r: float  = sz + 22.0 * (1.0 - tt)   # larger circle = outer, small alpha
		var a: float  = 0.022 * (1.0 - t) * (1.0 - t)
		draw_circle(pos, r, Color(atm_cr, atm_cg, atm_cb, a))

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
	var ship_type:  String = GameManager.current_ship.get("ship_type", "Исследовательский")
	var ship_class: String = GameManager.current_ship.get("ship_class", "C")
	var fwd:   Vector2 = Vector2(sin(ship_angle), -cos(ship_angle))
	var right: Vector2 = fwd.rotated(PI / 2.0)

	# Base size by class
	var sz: float = 13.0
	match ship_class:
		"A": sz = 20.0
		"B": sz = 16.0
		"C": sz = 13.0

	match ship_type:
		"Грузовой":            _draw_ship_cargo(ship_pos, fwd, right, sz)
		"Боевой":              _draw_ship_combat(ship_pos, fwd, right, sz)
		"Ресурсодобывающий":   _draw_ship_mining(ship_pos, fwd, right, sz)
		"Флагманский":         _draw_ship_flagship(ship_pos, fwd, right, sz)
		_:                     _draw_ship_scout(ship_pos, fwd, right, sz)

# ── Engine exhaust helper ─────────────────────────────────────────────────────
func _draw_engine(pos: Vector2, fwd: Vector2, sz: float, col: Color) -> void:
	var ef := 0.18 + (0.45 if ship_moving else 0.0)
	draw_circle(pos, sz, Color(col.r, col.g, col.b, ef))
	if ship_moving:
		var fl := 0.58 + sin(time_e * 28.0) * 0.30
		draw_circle(pos - fwd * sz * 0.6, sz * 0.80 * fl, Color(col.r, col.g, col.b, ef * 0.85))
		draw_circle(pos - fwd * sz * 1.4, sz * 0.55 * fl, Color(col.r + 0.15, col.g + 0.05, col.b, ef * 0.55))
		draw_circle(pos - fwd * sz * 2.4, sz * 0.32 * fl, Color(1.0, col.g + 0.2, 1.0, ef * 0.28))
		draw_circle(pos - fwd * sz * 3.5, sz * 0.18 * fl, Color(1.0, 1.0, 1.0, ef * 0.14))

# ── Scout / Explorer ─────────────────────────────────────────────────────────
func _draw_ship_scout(pos: Vector2, fwd: Vector2, right: Vector2, sz: float) -> void:
	var back  := pos - fwd * sz * 0.65
	var tip   := pos + fwd * sz * 1.15   # elongated nose
	var wl    := pos - fwd * sz * 0.1 + right * sz * 0.70
	var wr    := pos - fwd * sz * 0.1 - right * sz * 0.70
	var tl    := back + right * sz * 0.28
	var tr    := back - right * sz * 0.28

	_draw_engine(back, fwd, sz * 0.45, Color(0.30, 0.65, 1.0))

	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(0.18, 0.52, 0.90, 0.95))
	draw_colored_polygon([tip, pos + right * sz * 0.14, back, pos - right * sz * 0.14],
		Color(0.50, 0.80, 1.0, 0.52))

	var cock := pos + fwd * sz * 0.62
	draw_circle(cock, sz * 0.26, Color(0.65, 0.92, 1.0, 0.88))
	draw_circle(cock, sz * 0.14, Color(1.0,  1.0,  1.0, 0.94))
	draw_circle(wl, 2.0, Color(1.0, 0.28, 0.28, 0.88))
	draw_circle(wr, 2.0, Color(0.28, 1.0, 0.45, 0.88))

# ── Cargo / Freighter ─────────────────────────────────────────────────────────
func _draw_ship_cargo(pos: Vector2, fwd: Vector2, right: Vector2, sz: float) -> void:
	# Wide rectangular hull with side cargo pods
	var back  := pos - fwd * sz * 0.75
	var tip   := pos + fwd * sz * 0.80
	var wl    := pos + right * sz * 1.20   # very wide
	var wr    := pos - right * sz * 1.20
	var tl    := back + right * sz * 1.05
	var tr    := back - right * sz * 1.05

	# Dual side engines
	_draw_engine(back + right * sz * 0.55, fwd, sz * 0.38, Color(0.55, 0.75, 0.40))
	_draw_engine(back - right * sz * 0.55, fwd, sz * 0.38, Color(0.55, 0.75, 0.40))

	# Main boxy hull
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(0.45, 0.50, 0.38, 0.92))
	# Central body accent (darker)
	draw_colored_polygon([tip, pos + right * sz * 0.35, back, pos - right * sz * 0.35],
		Color(0.60, 0.65, 0.48, 0.65))
	# Cargo module stripes
	for stripe in 3:
		var sy: float = lerp(-sz * 0.55, sz * 0.55, float(stripe) / 2.0)
		var sx: float = sz * 0.80
		draw_line(pos + right * sz * 0.40 + fwd * sy * 0.3,
				  pos - right * sz * 0.40 + fwd * sy * 0.3,
				  Color(0.75, 0.80, 0.58, 0.30), 2.0)

	var cock := pos + fwd * sz * 0.55
	draw_circle(cock, sz * 0.22, Color(0.78, 0.92, 0.72, 0.85))
	draw_circle(cock, sz * 0.12, Color(1.0,  1.0,  0.90, 0.92))
	draw_circle(wl, 2.2, Color(1.0, 0.85, 0.20, 0.88))
	draw_circle(wr, 2.2, Color(1.0, 0.85, 0.20, 0.88))

# ── Combat / Warship ──────────────────────────────────────────────────────────
func _draw_ship_combat(pos: Vector2, fwd: Vector2, right: Vector2, sz: float) -> void:
	# Aggressive delta-wing silhouette
	var back  := pos - fwd * sz * 0.60
	var tip   := pos + fwd * sz * 1.10
	var wl    := pos - fwd * sz * 0.55 + right * sz * 1.35  # swept far back
	var wr    := pos - fwd * sz * 0.55 - right * sz * 1.35
	var tl    := back + right * sz * 0.22
	var tr    := back - right * sz * 0.22

	# Twin engines
	_draw_engine(back + right * sz * 0.30, fwd, sz * 0.40, Color(0.80, 0.30, 0.20))
	_draw_engine(back - right * sz * 0.30, fwd, sz * 0.40, Color(0.80, 0.30, 0.20))

	# Hull
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(0.22, 0.28, 0.45, 0.96))
	# Spine accent
	draw_colored_polygon([tip, pos + right * sz * 0.12, back, pos - right * sz * 0.12],
		Color(0.42, 0.58, 0.88, 0.60))
	# Wing edge line (sharp highlight)
	draw_line(tip, wl, Color(0.50, 0.70, 1.0, 0.45), 1.5)
	draw_line(tip, wr, Color(0.50, 0.70, 1.0, 0.45), 1.5)
	# Gun barrels
	draw_line(tip, tip + fwd * sz * 0.55, Color(0.55, 0.72, 1.0, 0.75), 2.5)
	draw_circle(tip + fwd * sz * 0.52, sz * 0.10, Color(0.70, 0.90, 1.0, 0.85))

	var cock := pos + fwd * sz * 0.42
	draw_circle(cock, sz * 0.20, Color(0.55, 0.78, 1.0, 0.88))
	draw_circle(cock, sz * 0.11, Color(1.0,  1.0,  1.0, 0.95))
	draw_circle(wl, 2.0, Color(1.0, 0.20, 0.20, 0.92))
	draw_circle(wr, 2.0, Color(1.0, 0.20, 0.20, 0.92))

# ── Mining / Resource ─────────────────────────────────────────────────────────
func _draw_ship_mining(pos: Vector2, fwd: Vector2, right: Vector2, sz: float) -> void:
	# Squat and wide with forward drill arms
	var back  := pos - fwd * sz * 0.65
	var tip   := pos + fwd * sz * 0.70
	var wl    := pos + right * sz * 1.10
	var wr    := pos - right * sz * 1.10
	var tl    := back + right * sz * 0.90
	var tr    := back - right * sz * 0.90

	# Single heavy engine
	_draw_engine(back, fwd, sz * 0.55, Color(0.90, 0.55, 0.15))

	# Boxy body
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(0.50, 0.38, 0.22, 0.94))
	draw_colored_polygon([tip, pos + right * sz * 0.30, back, pos - right * sz * 0.30],
		Color(0.72, 0.55, 0.30, 0.55))

	# Drill arms (forward protruding)
	var drill_off := sz * 0.55
	for side in [-1, 1]:
		var arm_base: Vector2 = pos + right * float(side) * drill_off + fwd * sz * 0.10
		var arm_tip:  Vector2 = arm_base + fwd * sz * 0.85
		draw_line(arm_base, arm_tip, Color(0.72, 0.60, 0.35, 0.80), 3.0)
		# Drill tip
		draw_circle(arm_tip, sz * 0.14, Color(0.95, 0.75, 0.25, 0.92))
		draw_circle(arm_tip, sz * 0.07, Color(1.0, 0.95, 0.65, 0.95))

	var cock := pos + fwd * sz * 0.40
	draw_circle(cock, sz * 0.22, Color(1.0, 0.88, 0.55, 0.85))
	draw_circle(cock, sz * 0.12, Color(1.0, 1.0,  0.85, 0.92))
	draw_circle(wl, 2.2, Color(1.0, 0.65, 0.10, 0.88))
	draw_circle(wr, 2.2, Color(1.0, 0.65, 0.10, 0.88))

# ── Flagship ──────────────────────────────────────────────────────────────────
func _draw_ship_flagship(pos: Vector2, fwd: Vector2, right: Vector2, sz: float) -> void:
	# Massive multi-section capital ship
	var back  := pos - fwd * sz * 0.80
	var tip   := pos + fwd * sz * 1.20
	var wl    := pos - fwd * sz * 0.10 + right * sz * 1.50
	var wr    := pos - fwd * sz * 0.10 - right * sz * 1.50
	var tl    := back + right * sz * 0.55
	var tr    := back - right * sz * 0.55

	# Triple engine bank
	_draw_engine(back,                    fwd, sz * 0.52, Color(0.70, 0.55, 1.0))
	_draw_engine(back + right * sz * 0.65, fwd, sz * 0.38, Color(0.60, 0.45, 0.90))
	_draw_engine(back - right * sz * 0.65, fwd, sz * 0.38, Color(0.60, 0.45, 0.90))

	# Main hull body
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(0.28, 0.24, 0.42, 0.96))
	# Gold spine
	draw_colored_polygon([tip, pos + right * sz * 0.20, back, pos - right * sz * 0.20],
		Color(0.85, 0.72, 0.28, 0.70))
	# Wing highlights
	draw_line(tip, wl, Color(0.72, 0.60, 1.0, 0.50), 2.0)
	draw_line(tip, wr, Color(0.72, 0.60, 1.0, 0.50), 2.0)
	draw_line(wl, tl,  Color(0.72, 0.60, 1.0, 0.30), 1.5)
	draw_line(wr, tr,  Color(0.72, 0.60, 1.0, 0.30), 1.5)

	# Secondary weapons
	for side in [-1, 1]:
		var turret: Vector2 = pos + right * float(side) * sz * 0.75 + fwd * sz * 0.35
		draw_circle(turret, sz * 0.18, Color(0.55, 0.45, 0.75, 0.85))
		draw_line(turret, turret + fwd * sz * 0.42, Color(0.75, 0.65, 1.0, 0.72), 2.0)

	# Bridge / Cockpit — large command module
	var cock := pos + fwd * sz * 0.58
	draw_circle(cock, sz * 0.30, Color(0.72, 0.62, 1.0, 0.88))
	draw_circle(cock, sz * 0.18, Color(0.90, 0.82, 1.0, 0.90))
	draw_circle(cock, sz * 0.09, Color(1.0,  1.0,  1.0, 0.96))

	# Running lights — gold on wings
	draw_circle(wl, 3.0, Color(1.0, 0.90, 0.30, 0.92))
	draw_circle(wr, 3.0, Color(1.0, 0.90, 0.30, 0.92))
	draw_circle(tl, 2.2, Color(0.80, 0.60, 1.0, 0.82))
	draw_circle(tr, 2.2, Color(0.80, 0.60, 1.0, 0.82))
