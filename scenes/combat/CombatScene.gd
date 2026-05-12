extends Node2D

# ══════════════════════════════════════════════════════════════════════════════
# CombatScene — multi-enemy 2.5D battle
# Controls: LMB → move destination | 1/2/3/4 or buttons → weapon | E → retreat
# ══════════════════════════════════════════════════════════════════════════════

const PLAYER_SPEED       := 160.0
const PLAYER_ROT_SPEED   := 4.5
const LASER_SPEED        := 680.0
const MISSILE_SPEED      := 260.0
const MISSILE_TURN_SPEED := 2.6
const HUD_HEIGHT         := 140.0
const ARENA_TOP          := 60.0

# ── Weapon accuracy table ─────────────────────────────────────────────────────
const WEAPON_STATS := {
	"pulse":      {"accuracy": 0.74, "cooldown": 0.18, "miss_spread": 0.55},  # скорострел
	"energy":     {"accuracy": 0.82, "cooldown": 0.40, "miss_spread": 0.48},  # лазер
	"emp":        {"accuracy": 0.85, "cooldown": 0.52, "miss_spread": 0.38},  # электропушка
	"turbolaser": {"accuracy": 0.80, "cooldown": 0.55, "miss_spread": 0.44},  # двойной залп
	"plasma":     {"accuracy": 0.62, "cooldown": 0.78, "miss_spread": 0.70},  # веер x3
	"torpedo":    {"accuracy": 0.96, "cooldown": 2.20, "miss_spread": 0.15},  # самонаведение, 5 шт
	"missile":    {"accuracy": 0.92, "cooldown": 1.50, "miss_spread": 0.22},
	"kinetic":    {"accuracy": 0.52, "cooldown": 2.00, "miss_spread": 0.90},
	"railgun":    {"accuracy": 0.88, "cooldown": 3.80, "miss_spread": 0.28},  # сверхтяжёлое
}

# ── Variant definitions ───────────────────────────────────────────────────────
# variant: 0=scout 1=fighter 2=heavy 3=dreadnought(danger5 only)
const VARIANT_NAMES := ["Пиратский разведчик", "Пиратский истребитель",
						"Тяжёлый пиратский корабль", "Пиратский дредноут"]

# ── Player state ──────────────────────────────────────────────────────────────
var finished: bool = false

var player_pos:         Vector2 = Vector2.ZERO
var player_angle:       float   = -PI / 2.0
var player_hull:        int     = 100
var player_shields:     int     = 50
var player_max_hull:    int     = 100
var player_max_shields: int     = 50

var player_weapons:      Array      = []
var weapon_cooldowns:    Dictionary = {}
var selected_weapon_idx: int        = 0
var auto_fire_timer:     float      = 0.0
var target_enemy_idx:    int        = 0   # which enemy auto-fire aims at

var move_target:     Vector2 = Vector2.ZERO
var has_move_target: bool    = false

# ── Ship upgrades ─────────────────────────────────────────────────────────────
const UPG_CD := {
	"volley": 8.0, "emergency_shields": 12.0, "boost": 15.0,
	"overload": 10.0, "shield_injector": 18.0,
}
var upgrade_cooldowns:  Dictionary = {}  # id -> remaining cooldown
var boost_timer:        float      = 0.0  # seconds of boost remaining
var overload_next_shot: bool       = false
var drone_repair_acc:   float      = 0.0

# ── Enemies (array of dicts) ──────────────────────────────────────────────────
var enemies: Array[Dictionary] = []

# ── Projectiles & FX ─────────────────────────────────────────────────────────
var projectiles:       Array[Dictionary] = []
var enemy_projectiles: Array[Dictionary] = []
var particles:         Array[Dictionary] = []
var bg_stars:          Array[Dictionary] = []

var time_e:      float   = 0.0
var screen_shake: Vector2 = Vector2.ZERO
var damage_flash: float   = 0.0
var hit_stun:     float   = 0.0

# ── Завершение боя и итоговая статистика ──────────────────────────────────────
var ending_battle:   bool  = false  # враги мертвы — ждём конца анимации взрыва
var ending_timer:    float = 0.0
var _pending_defeat: bool  = false
var _pending_earned: int   = 0
var _damage_dealt:    int  = 0   # нанесено врагам
var _damage_absorbed: int  = 0   # получено игроком
var _ships_destroyed: int  = 0   # уничтожено кораблей

# ── Пауза ──────────────────────────────────────────────────────────────────────
var is_paused: bool = false

# ── След двигателя ────────────────────────────────────────────────────────────
var engine_trail: Array[Dictionary] = []

# ── UI ────────────────────────────────────────────────────────────────────────
var _ui_layer:           CanvasLayer
var _status_lbl:         Label
var _weapon_rects:       Array      = []   # index -> Rect2 (click detection)
var _upgrade_btn_rects:  Dictionary = {}   # uid -> Rect2 (click detection)

signal combat_finished(result: String, credits_earned: int)

# ══════════════════════════════════════════════════════════════════════════════
# Lifecycle
# ══════════════════════════════════════════════════════════════════════════════

func _ready() -> void:
	_gen_bg()
	_init_combat()
	_build_ui()

func _gen_bg() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55432
	var vp  := get_viewport_rect().size
	var sky_h := vp.y * 0.55
	for _i in 260:
		bg_stars.append({
			"pos": Vector2(rng.randf_range(0, vp.x), rng.randf_range(0, sky_h)),
			"r":   rng.randf_range(0.3, 2.0),  "br":  rng.randf_range(0.3, 1.0),
			"ph":  rng.randf_range(0, TAU),     "spd": rng.randf_range(0.3, 1.4),
			"cr":  rng.randf_range(0.75, 1.0),  "cg":  rng.randf_range(0.75, 1.0), "cb": 1.0,
		})

# ── Enemy count / composition based on ship power + danger ───────────────────

func _calc_enemy_fleet() -> Array:
	var danger: int   = GameManager.current_danger
	var ship          := GameManager.current_ship
	var ship_price: int = ship.get("price", 8000)
	var ship_type: String = ship.get("ship_type", "Исследовательский")
	var ship_class: String = ship.get("ship_class", "C")

	# Ship power score 1–10
	var power := 1
	match ship_type:
		"Исследовательский": power = 2
		"Грузовой":          power = 1
		"Ресурсодобывающий": power = 2
		"Боевой":            power = 5
		"Флагманский":       power = 9
	if ship_class == "B": power += 1
	if ship_class == "A": power += 3
	if ship_price >= 50000: power += 1

	# Base count: danger drives the count, ship power adds extra attackers
	var base_count: int = 1
	if danger >= 2: base_count = 1 + (power / 4)
	if danger >= 3: base_count = 1 + (power / 3)
	if danger >= 4: base_count = 2 + (power / 3)
	if danger >= 5: base_count = 2 + (power / 2)
	base_count = clampi(base_count, 1, 6)

	# Build enemy list with specific variant for the main enemy
	var fleet: Array = []
	var main_variant: int = GameManager.pending_enemy_variant
	var main_hull: int    = GameManager.pending_enemy_hull

	fleet.append(_make_enemy_data(main_variant, main_hull, danger, true))

	# Additional enemies
	for i in base_count - 1:
		var v: int
		if danger == 5 and i == 0 and power >= 6:
			v = 3  # dreadnought on danger 5 vs powerful ships
		elif danger >= 4:
			v = randi() % 3
		elif danger >= 3:
			v = randi() % 2
		else:
			v = 0
		fleet.append(_make_enemy_data(v, -1, danger, false))

	return fleet

func _make_enemy_data(variant: int, preset_hull: int, danger: int, is_main: bool) -> Dictionary:
	var base_hull: int
	var attack_interval: float
	var move_speed: float
	var orbit_dir: float = 1.0 if randf() > 0.5 else -1.0

	match variant:
		0:  # Scout
			base_hull = 55 + danger * 12
			attack_interval = max(1.2, 3.2 - float(danger) * 0.25)
			move_speed = 75.0
		1:  # Fighter
			base_hull = 95 + danger * 18
			attack_interval = max(1.0, 2.8 - float(danger) * 0.22)
			move_speed = 60.0
		2:  # Heavy
			base_hull = 170 + danger * 28
			attack_interval = max(1.5, 3.5 - float(danger) * 0.20)
			move_speed = 42.0
		3:  # Dreadnought (danger 5 only)
			base_hull = 380 + danger * 45
			attack_interval = max(2.0, 4.0 - float(danger) * 0.18)
			move_speed = 28.0
		_:
			base_hull = 80
			attack_interval = 2.5
			move_speed = 55.0

	var hull: int = base_hull
	if is_main and preset_hull > 0:
		hull = preset_hull
	var max_hull := maxi(base_hull, hull)

	return {
		"variant":     variant,
		"hull":        hull,
		"max_hull":    max_hull,
		"name":        VARIANT_NAMES[clampi(variant, 0, VARIANT_NAMES.size() - 1)],
		"pos":         Vector2.ZERO,  # set in _init_combat
		"angle":       PI / 2.0,
		"atk_timer":   randf_range(0.3, attack_interval),
		"atk_interval":attack_interval,
		"move_speed":  move_speed,
		"orbit_dir":   orbit_dir,
		"is_main":     is_main,
	}

func _init_combat() -> void:
	var vp    := get_viewport_rect().size
	var arena := vp.y - HUD_HEIGHT

	player_pos   = Vector2(vp.x * 0.22, arena * 0.68)
	player_angle = -PI / 2.0
	move_target  = player_pos

	player_max_hull    = GameManager.current_ship["hull"]
	player_max_shields = GameManager.current_ship["shields"]
	player_hull        = maxi(1, int(GameManager.ship_hull_pct * float(player_max_hull)))
	player_shields     = int(player_max_shields * randf_range(0.65, 1.0))

	player_weapons.clear()
	for wname in GameManager.equipped_weapons:
		for w in GameData.WEAPONS:
			if w["name"] == wname:
				var wd: Dictionary = w.duplicate()
				# Инициализируем патроны для оружий с боезапасом
				if wd.has("ammo"):
					wd["ammo_left"] = wd["ammo"]
				player_weapons.append(wd)
				break
	if player_weapons.is_empty():
		player_weapons.append({"name": "Импульсное орудие", "damage": 25, "type": "pulse"})
	weapon_cooldowns.clear()
	for w in player_weapons:
		weapon_cooldowns[w["name"]] = 0.0
	selected_weapon_idx = 0
	auto_fire_timer = 0.0

	upgrade_cooldowns.clear()
	for uid in UPG_CD:
		upgrade_cooldowns[uid] = 0.0
	boost_timer        = 0.0
	overload_next_shot = false
	drone_repair_acc   = 0.0

	# Build enemy fleet
	enemies.clear()
	var fleet: Array = _calc_enemy_fleet()
	var count := fleet.size()
	for i in count:
		var e: Dictionary = fleet[i]
		# Spread enemies in a rough arc on the right side
		var angle_off := (float(i) - float(count - 1) * 0.5) * 0.55
		var base_dist := 220.0 + float(i) * 40.0
		e["pos"] = Vector2(vp.x * 0.72 + cos(angle_off) * base_dist * 0.3,
						   arena   * 0.28 + sin(angle_off) * base_dist * 0.25)
		e["pos"] = e["pos"].clamp(Vector2(80, ARENA_TOP + 20), Vector2(vp.x - 80, arena - 60))
		enemies.append(e)

	target_enemy_idx = 0

func _build_ui() -> void:
	_ui_layer = CanvasLayer.new()
	_ui_layer.layer = 10
	add_child(_ui_layer)

	_status_lbl = Label.new()
	_status_lbl.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_status_lbl.offset_top    = 6
	_status_lbl.offset_bottom = 38
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 15)
	_status_lbl.add_theme_color_override("font_color", Color(0.92, 0.97, 1.0))
	_ui_layer.add_child(_status_lbl)

	var enemy_count := enemies.size()
	var threat_txt  := ""
	if enemy_count == 1:
		threat_txt = enemies[0]["name"]
	else:
		threat_txt = "%d вражеских корабля" % enemy_count if enemy_count < 5 \
			else "%d вражеских кораблей" % enemy_count
	_status_lbl.text = "⚔  %s  |  ЛКМ — движение  |  E — отступить  |  ПРОБЕЛ — пауза" % threat_txt

	# Метка паузы
	var pause_lbl := Label.new()
	pause_lbl.name = "PauseLbl"
	pause_lbl.set_anchors_preset(Control.PRESET_CENTER)
	pause_lbl.offset_left   = -160; pause_lbl.offset_right  = 160
	pause_lbl.offset_top    = -40;  pause_lbl.offset_bottom = 40
	pause_lbl.text          = "⏸  ПАУЗА"
	pause_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	pause_lbl.add_theme_font_size_override("font_size", 38)
	pause_lbl.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0, 0.92))
	pause_lbl.visible = false
	_ui_layer.add_child(pause_lbl)

	# Weapons and retreat are drawn in _draw_hud and clicked via _input (no Button nodes)

# ══════════════════════════════════════════════════════════════════════════════
# Input
# ══════════════════════════════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if finished: return
	if event is InputEventMouseButton:
		var mbe := event as InputEventMouseButton
		if mbe.pressed and mbe.button_index == MOUSE_BUTTON_LEFT:
			var vp := get_viewport_rect().size
			# Click in HUD area — weapons, retreat button, upgrade abilities
			if mbe.position.y >= vp.y - HUD_HEIGHT:
				# Weapon row click
				for i in _weapon_rects.size():
					if (_weapon_rects[i] as Rect2).has_point(mbe.position):
						selected_weapon_idx = i
						get_viewport().set_input_as_handled()
						break
				# Upgrade ability click
				for uid: String in _upgrade_btn_rects:
					if (_upgrade_btn_rects[uid] as Rect2).has_point(mbe.position):
						_activate_upgrade(uid)
						get_viewport().set_input_as_handled()
						break
			if mbe.position.y < vp.y - HUD_HEIGHT:
				# Check if clicking on an enemy to switch target
				var clicked_enemy := false
				for i in enemies.size():
					var e: Dictionary = enemies[i]
					if e["hull"] > 0 and mbe.position.distance_to(e["pos"]) < 38:
						target_enemy_idx = i
						_status_lbl.text = "🎯  Цель: %s" % e["name"]
						clicked_enemy = true
						break
				if not clicked_enemy:
					move_target     = mbe.position
					has_move_target = true
				get_viewport().set_input_as_handled()
	if event is InputEventKey:
		var ke := event as InputEventKey
		if ke.pressed and not ke.echo:
			match ke.keycode:
				KEY_E: _try_retreat()
				KEY_SPACE:
					if not finished and not ending_battle:
						is_paused = not is_paused
						var pl := _ui_layer.get_node_or_null("PauseLbl")
						if pl: pl.visible = is_paused
				KEY_1: selected_weapon_idx = 0
				KEY_2: selected_weapon_idx = mini(1, player_weapons.size() - 1)
				KEY_3: selected_weapon_idx = mini(2, player_weapons.size() - 1)
				KEY_4: selected_weapon_idx = mini(3, player_weapons.size() - 1)

# ══════════════════════════════════════════════════════════════════════════════
# Main loop
# ══════════════════════════════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if finished: return
	time_e += delta

	# Бой завершён — ждём окончания анимации взрыва
	if ending_battle:
		ending_timer -= delta
		_update_particles(delta)
		_update_engine_trail(delta)
		queue_redraw()
		if ending_timer <= 0.0:
			_finalize_end()
		return

	if is_paused:
		queue_redraw()
		return

	if hit_stun > 0: hit_stun -= delta

	_handle_player_movement(delta)
	_handle_auto_fire(delta)
	_tick_upgrades(delta)

	for w in player_weapons:
		var cd: float = weapon_cooldowns.get(w["name"], 0.0)
		if cd > 0:
			weapon_cooldowns[w["name"]] = maxf(0.0, cd - delta)

	# Update all enemies
	for i in enemies.size():
		var e: Dictionary = enemies[i]
		if e["hull"] <= 0: continue
		_enemy_move(e, delta)
		e["atk_timer"] -= delta
		if e["atk_timer"] <= 0:
			e["atk_timer"] = e["atk_interval"]
			_enemy_fire(e)

	# Auto-pick target if current is dead
	if target_enemy_idx >= enemies.size() or enemies[target_enemy_idx]["hull"] <= 0:
		for i in enemies.size():
			if enemies[i]["hull"] > 0:
				target_enemy_idx = i
				break

	_update_projectiles(delta)
	_update_particles(delta)
	_update_engine_trail(delta)
	_check_battle_end()
	queue_redraw()

# ── Player movement ───────────────────────────────────────────────────────────

func _handle_player_movement(delta: float) -> void:
	if hit_stun > 0: return
	var vp    := get_viewport_rect().size
	var arena := vp.y - HUD_HEIGHT

	if has_move_target:
		var to   := move_target - player_pos
		var dist := to.length()
		if dist < 18.0:
			has_move_target = false
		else:
			var desired := atan2(to.x, -to.y)
			player_angle  = lerp_angle(player_angle, desired, PLAYER_ROT_SPEED * delta)
			var spd_mult := 2.5 if boost_timer > 0 else 1.0
			player_pos   += to.normalized() * minf(PLAYER_SPEED * spd_mult * delta, dist - 14.0)
	else:
		# Face nearest living enemy
		var te := _get_target_pos()
		if te != Vector2.ZERO:
			var des := atan2((te - player_pos).x, -(te - player_pos).y)
			player_angle = lerp_angle(player_angle, des, 1.2 * delta)

	player_pos = player_pos.clamp(Vector2(32, ARENA_TOP), Vector2(vp.x - 32, arena - 32))

func _get_target_pos() -> Vector2:
	if target_enemy_idx < enemies.size() and enemies[target_enemy_idx]["hull"] > 0:
		return enemies[target_enemy_idx]["pos"]
	return Vector2.ZERO

# ── Enemy movement ────────────────────────────────────────────────────────────

func _enemy_move(e: Dictionary, delta: float) -> void:
	var vp    := get_viewport_rect().size
	var arena := vp.y - HUD_HEIGHT
	var to_p: Vector2 = player_pos - (e["pos"] as Vector2)
	e["angle"] = atan2(to_p.x, -to_p.y)
	var dist: float = to_p.length()
	var spd: float = e["move_speed"]

	if dist > 300.0:
		e["pos"] += to_p.normalized() * spd * delta
	elif dist < 160.0:
		e["pos"] -= to_p.normalized() * spd * 0.6 * delta
	else:
		var perp := Vector2(-to_p.y, to_p.x).normalized()
		e["pos"] += perp * float(e["orbit_dir"]) * spd * 0.55 * delta

	e["pos"] = (e["pos"] as Vector2).clamp(Vector2(40, ARENA_TOP), Vector2(vp.x - 40, arena - 40))

# ── Auto-fire (player) ────────────────────────────────────────────────────────

func _handle_auto_fire(delta: float) -> void:
	if finished or hit_stun > 0: return
	var tpos := _get_target_pos()
	if tpos == Vector2.ZERO: return

	auto_fire_timer -= delta
	if auto_fire_timer > 0: return

	selected_weapon_idx = clampi(selected_weapon_idx, 0, player_weapons.size() - 1)
	var w: Dictionary = player_weapons[selected_weapon_idx]
	var cd: float     = weapon_cooldowns.get(w["name"], 0.0)
	if cd > 0.05:
		auto_fire_timer = 0.1
		return

	var wtype: String     = w.get("type", "energy")
	var stats: Dictionary = WEAPON_STATS.get(wtype, WEAPON_STATS["energy"])
	var accuracy: float   = stats["accuracy"]
	var miss_sp:  float   = stats["miss_spread"]
	var wcd:      float   = stats["cooldown"]
	var dmg_mult := 3 if overload_next_shot else 1
	if overload_next_shot:
		overload_next_shot = false
		_status_lbl.text = "💥  ПЕРЕГРУЗКА ОРУДИЙ — тройной урон!"

	var to_e  := tpos - player_pos
	var aim   := atan2(to_e.x, -to_e.y)
	var fwd   := Vector2(sin(aim), -cos(aim))
	var hit   := randf() < accuracy
	var offset := 0.0 if hit else randf_range(miss_sp * 0.6, miss_sp) * (1.0 if randf() > 0.5 else -1.0)
	if not hit: _status_lbl.text = "↗  Промах!"

	match wtype:
		"pulse":
			# Скорострел — одиночный лёгкий снаряд
			projectiles.append(_make_proj(player_pos + fwd * 24, aim + offset,
				w["damage"] * dmg_mult, "energy", false, target_enemy_idx))
		"energy":
			# Лазерные пушки — одиночный точный выстрел
			projectiles.append(_make_proj(player_pos + fwd * 28, aim + offset,
				w["damage"] * dmg_mult, "energy", false, target_enemy_idx))
		"emp":
			# Электропушка
			projectiles.append(_make_proj(player_pos + fwd * 28, aim + offset * 0.5,
				w["damage"] * dmg_mult, "emp", false, target_enemy_idx))
		"turbolaser":
			# Турболазерные батареи — двойной залп
			for side: float in [-0.07, 0.07]:
				var sp_off := 0.0 if hit else randf_range(miss_sp * 0.3, miss_sp * 0.7)
				projectiles.append(_make_proj(player_pos + fwd * 28, aim + side + sp_off,
					w["damage"] * dmg_mult, "energy", false, target_enemy_idx))
		"plasma":
			# Плазменные пушки — веер из 3 снарядов
			var dmg: int = int(w["damage"] * 0.55) * dmg_mult
			for sp: float in [-0.14, 0.0, 0.14]:
				var sp_off := 0.0 if randf() < accuracy else randf_range(miss_sp * 0.4, miss_sp)
				projectiles.append(_make_proj(player_pos + fwd * 28, aim + sp + sp_off,
					dmg, "plasma", false, target_enemy_idx))
		"torpedo":
			# Торпеды Z-120 — проверка боезапаса
			var ammo_left: int = w.get("ammo_left", 0)
			if ammo_left <= 0:
				_status_lbl.text = "⚠  Торпеды израсходованы!"
				auto_fire_timer = 0.3
				return
			w["ammo_left"] = ammo_left - 1
			_status_lbl.text = "🚀  Торпеда! Осталось: %d" % w["ammo_left"]
			projectiles.append(_make_proj(player_pos + fwd * 28, aim + offset * 0.2,
				w["damage"] * dmg_mult, "missile", true, target_enemy_idx))
		"missile":
			projectiles.append(_make_proj(player_pos + fwd * 28, aim + offset * 0.3,
				w["damage"] * dmg_mult, "missile", true, target_enemy_idx))
		"railgun":
			# Рельсовая пушка — сверхтяжёлый одиночный выстрел
			_status_lbl.text = "💥  РЕЛЬСОВАЯ ПУШКА — %d урона!" % (w["damage"] * dmg_mult)
			projectiles.append(_make_proj(player_pos + fwd * 32, aim + offset * 0.15,
				w["damage"] * dmg_mult, "kinetic", false, target_enemy_idx))
		"kinetic":
			projectiles.append(_make_proj(player_pos + fwd * 28, aim + offset,
				w["damage"] * dmg_mult, "kinetic", false, target_enemy_idx))
		_:
			projectiles.append(_make_proj(player_pos + fwd * 28, aim + offset,
				w["damage"] * dmg_mult, wtype, false, target_enemy_idx))

	weapon_cooldowns[w["name"]] = wcd
	auto_fire_timer = wcd
	_create_muzzle_flash(player_pos + fwd * 24, Color(0.3, 0.85, 1.0))
	AudioManager.play_sfx("laser")

func _make_proj(pos: Vector2, angle: float, dmg: int, typ: String,
				is_m: bool, target_idx: int = -1) -> Dictionary:
	return {"pos": pos, "angle": angle, "damage": dmg, "type": typ,
			"is_missile": is_m, "target_idx": target_idx}

# ── Enemy fire ────────────────────────────────────────────────────────────────

func _enemy_fire(e: Dictionary) -> void:
	var variant: int  = e["variant"]
	var to_p: Vector2 = player_pos - (e["pos"] as Vector2)
	e["angle"] = atan2(to_p.x, -to_p.y)
	var fwd  := Vector2(sin(e["angle"]), -cos(e["angle"]))
	_create_muzzle_flash(e["pos"] + fwd * 26, Color(1.0, 0.35, 0.15))

	# Dreadnought has its own heavy attack pattern
	if variant == 3:
		_enemy_fire_dreadnought(e, fwd)
		return

	var roll := randi() % (3 + variant)
	match roll:
		0:
			for _i in (1 + variant):
				enemy_projectiles.append(_make_proj(e["pos"] + fwd * 28,
					e["angle"] + randf_range(-0.14, 0.14),
					int(8 + variant * 5), "energy", false))
			_status_lbl.text = "⚡  %s открывает огонь!" % e["name"]
		1:
			enemy_projectiles.append(_make_proj(e["pos"] + fwd * 28,
				e["angle"], int(20 + variant * 10), "missile", true))
			_status_lbl.text = "🚀  %s выпускает ракету!" % e["name"]
		2:
			for _i in (2 + variant * 2):
				enemy_projectiles.append(_make_proj(e["pos"] + fwd * 28,
					e["angle"] + randf_range(-0.42, 0.42),
					int(5 + variant * 3), "energy", false))
			_status_lbl.text = "💥  %s — шквальный залп!" % e["name"]
		3:
			if variant >= 1:
				enemy_projectiles.append(_make_proj(e["pos"] + fwd * 28,
					e["angle"] + randf_range(-0.04, 0.04),
					int(32 + variant * 14), "plasma", false))
				_status_lbl.text = "☄  %s — плазма!" % e["name"]
		4:
			for sp: float in [-0.11, 0.11]:
				enemy_projectiles.append(_make_proj(e["pos"] + fwd * 28,
					e["angle"] + sp, int(18 + variant * 8), "missile", true))
			_status_lbl.text = "💀  %s — двойной залп!" % e["name"]

func _enemy_fire_dreadnought(e: Dictionary, fwd: Vector2) -> void:
	var pattern := randi() % 4
	match pattern:
		0:  # Heavy plasma barrage
			for sp: float in [-0.18, -0.06, 0.06, 0.18]:
				enemy_projectiles.append(_make_proj(e["pos"] + fwd * 36,
					e["angle"] + sp, 55, "plasma", false))
			_status_lbl.text = "☄☄  ДРЕДНОУТ — плазменный залп по площади!"
		1:  # Quad missile
			for sp: float in [-0.22, -0.08, 0.08, 0.22]:
				enemy_projectiles.append(_make_proj(e["pos"] + fwd * 36,
					e["angle"] + sp, 70, "missile", true))
			_status_lbl.text = "🚀🚀  ДРЕДНОУТ — четыре ракеты!"
		2:  # Heavy kinetic
			enemy_projectiles.append(_make_proj(e["pos"] + fwd * 36,
				e["angle"] + randf_range(-0.02, 0.02), 140, "kinetic", false))
			_status_lbl.text = "💥  ДРЕДНОУТ — рельсотрон! УКЛОНЯЙСЯ!"
		3:  # EMP + laser combo
			enemy_projectiles.append(_make_proj(e["pos"] + fwd * 36,
				e["angle"], 30, "emp", false))
			for sp: float in [-0.12, 0.0, 0.12]:
				enemy_projectiles.append(_make_proj(e["pos"] + fwd * 36,
					e["angle"] + sp, 38, "energy", false))
			_status_lbl.text = "⚡☄  ДРЕДНОУТ — ЭМИ-удар и лазерный шторм!"

# ── Upgrades ─────────────────────────────────────────────────────────────────

func _tick_upgrades(delta: float) -> void:
	# Tick cooldowns
	for uid in upgrade_cooldowns:
		if upgrade_cooldowns[uid] > 0:
			upgrade_cooldowns[uid] = maxf(0.0, upgrade_cooldowns[uid] - delta)

	# Boost timer
	if boost_timer > 0:
		boost_timer = maxf(0.0, boost_timer - delta)

	# Repair drones passive
	if "repair_drones" in GameManager.ship_upgrades and player_hull < player_max_hull:
		drone_repair_acc += 2.0 * delta
		if drone_repair_acc >= 1.0:
			player_hull      = mini(player_hull + int(drone_repair_acc), player_max_hull)
			drone_repair_acc = fmod(drone_repair_acc, 1.0)

	var threshold := int(float(player_max_hull) * 0.15)

	# AUTO: emergency_shields — fires when shields are completely depleted
	if "emergency_shields" in GameManager.ship_upgrades:
		if upgrade_cooldowns.get("emergency_shields", 0.0) <= 0 \
				and player_shields == 0 and player_hull > threshold:
			_activate_upgrade("emergency_shields")

	# AUTO: shield_injector — fires when shields drop below 20%
	if "shield_injector" in GameManager.ship_upgrades:
		var sh_low := int(float(player_max_shields) * 0.20)
		if upgrade_cooldowns.get("shield_injector", 0.0) <= 0 \
				and player_shields < sh_low and player_hull > threshold:
			_activate_upgrade("shield_injector")

	# (upgrade button visuals are drawn in _draw_hud — no Button nodes to update)

func _activate_upgrade(uid: String) -> void:
	if finished: return
	if uid not in GameManager.ship_upgrades:
		_status_lbl.text = "🔒  Улучшение «%s» не установлено!" % uid
		return
	var cd: float = upgrade_cooldowns.get(uid, 0.0)
	if cd > 0.05:
		_status_lbl.text = "⏳  Перезарядка: %.1f сек" % cd
		return

	match uid:
		"volley":
			# Fire every equipped weapon simultaneously
			if player_shields < 30:
				_status_lbl.text = "❌  Синхронный залп — недостаточно щита! (нужно 30)"
				return
			player_shields = maxi(0, player_shields - 30)
			var tpos := _get_target_pos()
			if tpos == Vector2.ZERO: return
			var to_e  := tpos - player_pos
			var aim   := atan2(to_e.x, -to_e.y)
			var fwd   := Vector2(sin(aim), -cos(aim))
			for w: Dictionary in player_weapons:
				var wtype: String = w.get("type", "energy")
				projectiles.append(_make_proj(player_pos + fwd * 28, aim,
					w["damage"], wtype, wtype == "missile", target_enemy_idx))
			_create_muzzle_flash(player_pos + fwd * 28, Color(1.0, 0.85, 0.2))
			_status_lbl.text = "⚡  СИНХРОННЫЙ ЗАЛП — все орудия!"
			upgrade_cooldowns[uid] = UPG_CD[uid]

		"emergency_shields":
			var hull_cost: int = maxi(1, int(float(player_hull) * 0.10))
			if player_hull - hull_cost <= 0:
				return
			player_hull    = maxi(1, player_hull - hull_cost)
			var restored   := mini(hull_cost * 3, player_max_shields - player_shields)
			player_shields = mini(player_shields + restored, player_max_shields)
			_status_lbl.text = "🛡  АВТО: Аварийные щиты +%d  (−%d корпус)" % [restored, hull_cost]
			upgrade_cooldowns[uid] = UPG_CD[uid]

		"boost":
			if player_shields < 25:
				_status_lbl.text = "❌  Форсаж — недостаточно щита! (нужно 25)"
				return
			player_shields = maxi(0, player_shields - 25)
			boost_timer    = 5.0
			_status_lbl.text = "🔥  ФОРСАЖ ДВИГАТЕЛЯ — скорость ×2.5 на 5 сек!"
			upgrade_cooldowns[uid] = UPG_CD[uid]

		"overload":
			if player_shields < 25:
				_status_lbl.text = "❌  Перегрузка орудий — недостаточно щита! (нужно 25)"
				return
			player_shields     = maxi(0, player_shields - 25)
			overload_next_shot = true
			_status_lbl.text   = "💥  ПЕРЕГРУЗКА ОРУДИЙ — следующий выстрел ×3!"
			upgrade_cooldowns[uid] = UPG_CD[uid]

		"shield_injector":
			var hull_cost: int = maxi(1, int(float(player_hull) * 0.10))
			if player_hull - hull_cost <= 0:
				return
			player_hull    = maxi(1, player_hull - hull_cost)
			var target_sh  := int(float(player_max_shields) * 0.50)
			player_shields = maxi(player_shields, target_sh)
			_status_lbl.text = "💉  АВТО: Щитовой инжектор — щиты до 50%%  (−%d корпус)" % hull_cost
			upgrade_cooldowns[uid] = UPG_CD[uid]

# ── Retreat ───────────────────────────────────────────────────────────────────

func _try_retreat() -> void:
	if finished or ending_battle: return
	var spd: int = GameManager.current_ship.get("speed", 200)
	# More enemies = harder to retreat
	var living := 0
	for e in enemies:
		if e["hull"] > 0: living += 1
	var chance := clampf(float(spd) / 450.0 - float(living - 1) * 0.12, 0.10, 0.70)
	if randf() < chance:
		finished = true
		_save_hull()
		GameManager.combat_result = "retreat"
		GameManager.record_combat_result(_damage_dealt, _damage_absorbed, _ships_destroyed, false)
		_status_lbl.text = "🏃  Отступление удалось!"
		await get_tree().create_timer(1.4).timeout
		get_tree().change_scene_to_file("res://scenes/star_system/StarSystemView.tscn")
	else:
		_status_lbl.text = "❌  Отступить не удалось! Окружены %d кораблями." % living

# ── Projectiles ───────────────────────────────────────────────────────────────

func _update_projectiles(delta: float) -> void:
	var vp    := get_viewport_rect().size
	var srect := Rect2(Vector2(-30, -30), vp + Vector2(60, 60))

	for i in range(projectiles.size() - 1, -1, -1):
		var p   := projectiles[i]
		var fwd := Vector2(sin(p["angle"]), -cos(p["angle"]))

		# Missiles home toward their target enemy
		if p["is_missile"]:
			var tidx: int = p.get("target_idx", 0)
			if tidx < enemies.size() and enemies[tidx]["hull"] > 0:
				var tpos: Vector2 = enemies[tidx]["pos"] as Vector2
				var des  := atan2((tpos - p["pos"]).x, -(tpos - p["pos"]).y)
				p["angle"] = lerp_angle(p["angle"], des, MISSILE_TURN_SPEED * delta)
				fwd = Vector2(sin(p["angle"]), -cos(p["angle"]))

		p["pos"] += fwd * (MISSILE_SPEED if p["is_missile"] else LASER_SPEED) * delta

		# Check hit against all living enemies
		var hit_enemy := false
		for ei in enemies.size():
			var e: Dictionary = enemies[ei]
			if e["hull"] <= 0: continue
			var hit_r: float = 28.0 + float(e["variant"]) * 5.0
			if p["pos"].distance_to(e["pos"]) < hit_r:
				_enemy_take_damage(e, ei, p["damage"], p["type"])
				_create_particles(e["pos"], Color(1.0, 0.65, 0.2), 12)
				hit_enemy = true
				break
		if hit_enemy:
			projectiles.remove_at(i); continue
		if not srect.has_point(p["pos"]):
			projectiles.remove_at(i)

	for i in range(enemy_projectiles.size() - 1, -1, -1):
		var p := enemy_projectiles[i]
		if p["is_missile"]:
			var des := atan2((player_pos - p["pos"]).x, -(player_pos - p["pos"]).y)
			p["angle"] = lerp_angle(p["angle"], des, MISSILE_TURN_SPEED * delta)
		var fwd := Vector2(sin(p["angle"]), -cos(p["angle"]))
		p["pos"] += fwd * (MISSILE_SPEED if p["is_missile"] else LASER_SPEED) * delta
		if p["pos"].distance_to(player_pos) < 26:
			_player_take_damage(p["damage"])
			_create_particles(player_pos, Color(0.4, 0.6, 1.0), 10)
			enemy_projectiles.remove_at(i); continue
		if not srect.has_point(p["pos"]):
			enemy_projectiles.remove_at(i)

# ── Damage ────────────────────────────────────────────────────────────────────

func _player_take_damage(amount: int) -> void:
	_damage_absorbed += amount  # весь входящий урон считается поглощённым
	if player_shields > 0:
		var absorb := mini(amount, player_shields)
		player_shields -= absorb
		amount         -= absorb
		if absorb > 0:
			AudioManager.play_sfx("shield")
	if amount > 0:
		AudioManager.play_sfx("hurt")
	player_hull  = maxi(player_hull - amount, 0)
	damage_flash = 0.40
	hit_stun     = 0.18
	screen_shake = Vector2(randf_range(-8, 8), randf_range(-8, 8))

func _enemy_take_damage(e: Dictionary, _ei: int, amount: int, dtype: String) -> void:
	if dtype == "emp":
		e["atk_interval"] = minf(e["atk_interval"] + 1.4, 7.0)
		_status_lbl.text = "⚡  ЭМИ нарушил системы %s!" % e["name"]
	_damage_dealt += mini(amount, maxi(e["hull"], 0))  # только реально нанесённый урон
	e["hull"] = maxi(e["hull"] - amount, 0)
	particles.append({"pos": e["pos"], "vel": Vector2.ZERO,
		"life": 0.26, "max_life": 0.26,
		"color": Color(1.0, 0.82, 0.3, 0.8), "type": "flash", "size": 40.0})
	if e["hull"] <= 0:
		_ships_destroyed += 1
		_create_explosion(e["pos"], Color(1.0, 0.45, 0.1), 100)
		AudioManager.play_sfx("explosion")

# ── Battle end ────────────────────────────────────────────────────────────────

func _save_hull() -> void:
	GameManager.ship_hull_pct = clampf(float(player_hull) / float(player_max_hull), 0.0, 1.0)

func _check_battle_end() -> void:
	if finished or ending_battle: return

	if player_hull <= 0:
		_pending_defeat = true
		GameManager.ship_hull_pct = 0.05
		GameManager.combat_result = "lost"
		_status_lbl.text = "💀  ВАШ КОРАБЛЬ УНИЧТОЖЕН!"
		_create_explosion(player_pos, Color(0.3, 0.55, 1.0), 80)
		ending_battle = true
		ending_timer  = 2.2   # ждём анимацию взрыва игрока
		return

	var all_dead := true
	for e in enemies:
		if e["hull"] > 0:
			all_dead = false
			break
	if all_dead:
		_save_hull()
		GameManager.combat_result = "won"
		_pending_earned = 0
		for e in enemies:
			_pending_earned += int(e["max_hull"] * randf_range(12, 24))
		GameManager.add_credits(_pending_earned)
		var count := enemies.size()
		var msg := "🏆  ПОБЕДА! "
		msg += ("%d противников уничтожено! " % count) if count > 1 else ("%s уничтожен! " % enemies[0]["name"])
		msg += "+%d кред." % _pending_earned
		_status_lbl.text = msg
		ending_battle = true
		ending_timer  = 1.8   # ждём анимацию взрыва последнего врага

func _finalize_end() -> void:
	finished = true
	var victory := not _pending_defeat
	GameManager.record_combat_result(_damage_dealt, _damage_absorbed, _ships_destroyed, victory)

	# Обновление репутации у фракций
	var faction := GameManager.current_faction
	if victory:
		if faction == "Пираты" or faction == "Нет":
			# Уничтожали пиратов — хорошие ребята довольны
			GameManager.change_reputation("Федерация",   _ships_destroyed * 3)
			GameManager.change_reputation("Торговцы",    _ships_destroyed * 2)
			GameManager.change_reputation("Независимые", _ships_destroyed)
			GameManager.change_reputation("Пираты",     -_ships_destroyed * 5)
		else:
			# Уничтожали корабли другой фракции — они злятся
			GameManager.change_reputation(faction, -_ships_destroyed * 4)
			GameManager.change_reputation("Пираты", _ships_destroyed)

	if _pending_defeat:
		AudioManager.play_sfx("defeat")
	else:
		AudioManager.play_sfx("victory")
		_status_lbl.text = ("📊  ИТОГИ БОЯ  |  Нанесено: %d  |  Получено: %d  |  Уничтожено: %d  |  +%d кред." %
			[_damage_dealt, _damage_absorbed, _ships_destroyed, _pending_earned])
	GameManager.save_game()
	_exit_to_system()

func _exit_to_system() -> void:
	await get_tree().create_timer(3.2).timeout
	get_tree().change_scene_to_file("res://scenes/star_system/StarSystemView.tscn")

# ── Particles ─────────────────────────────────────────────────────────────────

func _create_explosion(pos: Vector2, color: Color, count: int) -> void:
	for _i in count:
		var a := randf() * TAU; var sp := randf_range(60, 280)
		particles.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * sp,
			"life": randf_range(0.4, 1.4), "max_life": 1.4,
			"color": color, "type": "explosion", "size": randf_range(3.0, 9.0)})

func _create_particles(pos: Vector2, color: Color, count: int, typ: String = "spark") -> void:
	for _i in count:
		var a := randf() * TAU; var sp := randf_range(30, 120)
		particles.append({"pos": pos, "vel": Vector2(cos(a), sin(a)) * sp,
			"life": randf_range(0.18, 0.6), "max_life": 0.6,
			"color": color, "type": typ, "size": randf_range(1.5, 4.5)})

func _create_muzzle_flash(pos: Vector2, color: Color) -> void:
	particles.append({"pos": pos, "vel": Vector2.ZERO, "life": 0.08, "max_life": 0.08,
		"color": color, "type": "muzzle", "size": 16.0})

func _update_particles(delta: float) -> void:
	for i in range(particles.size() - 1, -1, -1):
		var p := particles[i]
		p["life"] -= delta
		if p.get("vel") and p["vel"] != Vector2.ZERO:
			p["pos"] += p["vel"] * delta
			p["vel"]  = Vector2(p["vel"].x * 0.90, p["vel"].y * 0.90 + 48.0 * delta)
		if p["life"] <= 0: particles.remove_at(i)

func _update_engine_trail(delta: float) -> void:
	# Добавляем новую точку если игрок движется
	if has_move_target and not finished and not is_paused:
		engine_trail.append({
			"pos":      player_pos,
			"life":     0.45,
			"max_life": 0.45,
			"angle":    player_angle,
		})
	# Обновляем жизнь точек
	for i in range(engine_trail.size() - 1, -1, -1):
		engine_trail[i]["life"] -= delta
		if engine_trail[i]["life"] <= 0:
			engine_trail.remove_at(i)

# ══════════════════════════════════════════════════════════════════════════════
# DRAWING
# ══════════════════════════════════════════════════════════════════════════════

func _draw() -> void:
	var vp    := get_viewport_rect().size
	var arena := vp.y - HUD_HEIGHT

	screen_shake *= 0.80
	if screen_shake.length() < 0.5: screen_shake = Vector2.ZERO
	var sk := screen_shake

	_draw_space_background(vp, arena, sk)

	for p in particles:
		var alpha: float = float(p["life"]) / float(p["max_life"])
		match p["type"]:
			"explosion":
				draw_circle(p["pos"] + sk, p["size"] * (1.4 + (1.0 - alpha) * 0.8),
					Color(p["color"].r, p["color"].g, p["color"].b, alpha * 0.88))
				draw_circle(p["pos"] + sk, p["size"] * 0.4, Color(1.0, 0.98, 0.85, alpha))
			"spark", "trail":
				draw_circle(p["pos"] + sk, p["size"] * alpha,
					Color(p["color"].r, p["color"].g, p["color"].b, alpha * 0.82))
			"muzzle":
				draw_circle(p["pos"], p["size"] * alpha,       Color(1, 0.92, 0.45, alpha))
				draw_circle(p["pos"], p["size"] * alpha * 0.4, Color(1, 1,    1,    alpha))
			"flash":
				draw_circle(p["pos"] + sk, p["size"] * alpha,
					Color(p["color"].r, p["color"].g, p["color"].b, alpha * 0.70))

	for p in projectiles:
		_draw_projectile(p, Vector2(sin(p["angle"]), -cos(p["angle"])), false)
	for p in enemy_projectiles:
		_draw_projectile(p, Vector2(sin(p["angle"]), -cos(p["angle"])), true)

	# Shadows
	for e in enemies:
		if e["hull"] > 0: _draw_ship_shadow(e["pos"] + sk, 1.0)
	if player_hull > 0: _draw_ship_shadow(player_pos + sk, 1.0)

	# Enemy ships (dead ones show wreck)
	for i in enemies.size():
		var e: Dictionary = enemies[i]
		if e["hull"] > 0:
			var is_target := i == target_enemy_idx
			_draw_enemy_ship(e["pos"] + sk, e["angle"], e["variant"], e, is_target)

	# След двигателя
	for pt in engine_trail:
		var alpha: float = float(pt["life"]) / float(pt["max_life"])
		var sz:    float = alpha * 5.5
		var fwd   := Vector2(sin(pt["angle"]), -cos(pt["angle"]))
		var back  := (pt["pos"] as Vector2) - fwd * 14.0
		draw_circle(back + sk, sz,       Color(0.28, 0.62, 1.0, alpha * 0.55))
		draw_circle(back + sk, sz * 0.5, Color(0.55, 0.85, 1.0, alpha * 0.80))

	if player_hull > 0:
		_draw_player_ship(player_pos + sk, player_angle)

	if has_move_target and not finished:
		_draw_move_marker(move_target + sk)

	var mouse := get_viewport().get_mouse_position()
	if mouse.y < arena:
		_draw_cursor(mouse, vp, arena)

	if damage_flash > 0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(vp.x, arena)),
			Color(1.0, 0.06, 0.06, damage_flash * 0.25))
		damage_flash = maxf(0.0, damage_flash - 0.03)

	_draw_hud(vp, arena)

# ── Space background ──────────────────────────────────────────────────────────

func _draw_space_background(vp: Vector2, arena: float, sk: Vector2) -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(vp.x, arena)), Color(0.004, 0.005, 0.014))
	draw_circle(vp * Vector2(0.70, 0.18) + sk * 0.04, 320, Color(0.10, 0.03, 0.24, 0.08))
	draw_circle(vp * Vector2(0.25, 0.30) + sk * 0.04, 240, Color(0.03, 0.06, 0.28, 0.07))
	draw_circle(vp * Vector2(0.50, 0.20) + sk * 0.03, 400, Color(0.06, 0.02, 0.18, 0.05))
	draw_circle(vp * Vector2(0.82, 0.45) + sk * 0.05, 180, Color(0.16, 0.04, 0.08, 0.06))

	for s in bg_stars:
		var br: float = s["br"] + sin(time_e * s["spd"] + s["ph"]) * 0.16
		draw_circle(s["pos"] + sk * 0.06, s["r"],
			Color(s["cr"] * br, s["cg"] * br, s["cb"] * br, br * 0.85))

	var planet_cx := vp.x * 0.42
	var planet_cy := arena + 380.0
	var planet_r  := 600.0

	for layer in 12:
		var t   := float(layer) / 12.0
		var r   := planet_r + float(layer) * 28.0
		var alp := (1.0 - t) * (1.0 - t) * 0.14
		draw_arc(Vector2(planet_cx, planet_cy) + sk * 0.02, r,
			PI + 0.18, TAU - 0.18, 64, Color(0.18 + t * 0.08, 0.48 + t * 0.18, 0.72 + t * 0.10, alp),
			float(layer) * 3.0 + 6.0)

	draw_arc(Vector2(planet_cx, planet_cy) + sk * 0.02, planet_r,
		PI + 0.22, TAU - 0.22, 80, Color(0.10, 0.30, 0.55, 0.82), 3.0)
	draw_arc(Vector2(planet_cx, planet_cy) + sk * 0.02, planet_r - 4,
		PI + 0.22, TAU - 0.22, 80, Color(0.35, 0.65, 1.00, 0.28), 8.0)

	var planet_center := Vector2(planet_cx, planet_cy) + sk * 0.02
	var fill_col      := Color(0.06, 0.18, 0.38, 0.92)
	for si in 60:
		var t    := float(si) / 59.0
		var y    := (planet_cy - planet_r) + t * (arena - (planet_cy - planet_r))
		if y > arena: break
		var dy   := y - planet_cy
		var disc := planet_r * planet_r - dy * dy
		if disc <= 0.0: continue
		var hw := sqrt(disc)
		draw_line(Vector2(clampf(planet_cx - hw, 0, vp.x), y),
				  Vector2(clampf(planet_cx + hw, 0, vp.x), y), fill_col, 1.0)
	draw_arc(planet_center, planet_r * 0.78,
		PI + 0.55, PI + 1.05, 20, Color(0.25, 0.65, 1.0, 0.10), 14.0)

	draw_line(Vector2(0, arena), Vector2(vp.x, arena), Color(0.12, 0.28, 0.55, 0.45), 1.5)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _draw_ship_shadow(pos: Vector2, _scale_f: float) -> void:
	var arena := get_viewport_rect().size.y - HUD_HEIGHT
	var depth_t := clampf((pos.y - ARENA_TOP) / (arena - ARENA_TOP - 40), 0.0, 1.0)
	draw_circle(Vector2(pos.x, pos.y + 18.0 + depth_t * 14.0),
		(32.0 + depth_t * 8.0) * 0.5, Color(0, 0, 0, 0.18))

func _draw_projectile(p: Dictionary, fwd: Vector2, enemy: bool) -> void:
	match p["type"]:
		"missile":
			var mc := Color(1.0, 0.52, 0.18) if not enemy else Color(0.9, 0.25, 0.10)
			draw_circle(p["pos"], 5.5, mc)
			draw_line(p["pos"], p["pos"] - fwd * 14, Color(mc.r, mc.g, mc.b, 0.65), 2.5)
		"plasma":
			var pc := Color(0.55, 0.12, 1.00) if not enemy else Color(0.82, 0.08, 0.82)
			draw_circle(p["pos"], 5.5, Color(pc.r, pc.g, pc.b, 0.95))
			draw_circle(p["pos"], 2.8, Color(0.9, 0.7, 1.0))
		"kinetic":
			draw_line(p["pos"], p["pos"] + fwd * 24, Color(0.92, 0.92, 0.74, 0.95), 5.0)
			draw_circle(p["pos"] + fwd * 12, 2.8, Color(1.0, 1.0, 0.82, 0.85))
		"emp":
			draw_circle(p["pos"], 6.5, Color(0.18, 1.0, 0.82, 0.88))
			draw_arc(p["pos"], 9, 0, TAU, 16, Color(0.18, 1.0, 0.82, 0.50), 1.5)
		_:
			var lc := Color(0.28, 0.80, 1.0) if not enemy else Color(1.0, 0.28, 0.18)
			draw_line(p["pos"], p["pos"] + fwd * 36, Color(lc.r, lc.g, lc.b, 0.94), 3.2)
			draw_line(p["pos"] + fwd * 7, p["pos"] + fwd * 30,
				Color(lc.r + 0.3, lc.g + 0.1, lc.b + 0.1, 0.60), 1.5)

func _draw_move_marker(pos: Vector2) -> void:
	var t := fmod(time_e * 2.8, TAU)
	var alp := 0.55 + sin(t) * 0.25
	draw_arc(pos, 16, t, t + TAU * 0.75, 20, Color(0.35, 0.90, 1.0, alp), 2.0)
	draw_circle(pos, 3, Color(0.5, 1.0, 1.0, alp * 0.8))

func _draw_cursor(mouse: Vector2, _vp: Vector2, _arena: float) -> void:
	var sz := 13.0; var c := Color(0.38, 0.95, 1.0, 0.80)
	draw_line(mouse - Vector2(sz, 0), mouse - Vector2(5, 0), c, 1.5)
	draw_line(mouse + Vector2(5, 0),  mouse + Vector2(sz, 0), c, 1.5)
	draw_line(mouse - Vector2(0, sz), mouse - Vector2(0, 5), c, 1.5)
	draw_line(mouse + Vector2(0, 5),  mouse + Vector2(0, sz), c, 1.5)
	draw_arc(mouse, sz * 0.55, 0, TAU, 20, Color(0.35, 0.92, 1.0, 0.22), 1.0)

# ══════════════════════════════════════════════════════════════════════════════
# Ship drawing
# ══════════════════════════════════════════════════════════════════════════════

func _draw_player_ship(pos: Vector2, angle: float) -> void:
	var ship_type: String = GameManager.current_ship.get("ship_type", "Исследовательский")
	var off := Vector2.ZERO
	if damage_flash > 0.18:
		off = Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.5))
	var p := pos + off
	if player_shields > 0 and player_max_shields > 0:
		var sp := float(player_shields) / float(player_max_shields)
		draw_arc(p, 34, 0, TAU, 56, Color(0.22, 0.62, 1.0, 0.08 + sp * 0.28), 2.5)
		draw_arc(p, 28, 0, TAU, 40, Color(0.40, 0.78, 1.0, (0.08 + sp * 0.28) * 0.40), 1.5)
	match ship_type:
		"Боевой":            _draw_ship_combat(p, angle,  Color(0.18, 0.50, 0.90))
		"Грузовой":          _draw_ship_cargo(p, angle,   Color(0.30, 0.70, 0.35))
		"Ресурсодобывающий": _draw_ship_mining(p, angle,  Color(0.80, 0.50, 0.15))
		"Флагманский":       _draw_ship_flagship(p, angle, Color(0.72, 0.60, 0.15))
		_:                   _draw_ship_scout(p, angle,   Color(0.22, 0.60, 0.90))

func _draw_enemy_ship(pos: Vector2, angle: float, variant: int,
					  e: Dictionary, is_target: bool) -> void:
	# Dreadnought is much larger + purple-black
	if variant == 3:
		_draw_ship_dreadnought(pos, angle, e, is_target)
		return

	var sz    := 18.0 + float(variant) * 5.0
	var fwd   := Vector2(sin(angle), -cos(angle))
	var right := fwd.rotated(PI / 2.0)

	var hc_arr: Array = [Color(0.72, 0.16, 0.12), Color(0.58, 0.10, 0.22), Color(0.38, 0.05, 0.40)]
	var ac_arr: Array = [Color(1.0, 0.32, 0.10), Color(1.0, 0.18, 0.28), Color(0.88, 0.20, 0.88)]
	var hc: Color = hc_arr[clampi(variant, 0, 2)]
	var ac: Color = ac_arr[clampi(variant, 0, 2)]

	var tip := pos + fwd * sz; var back := pos - fwd * sz * 0.58
	var wl  := pos - fwd * sz * 0.05 + right * sz * 0.95
	var wr  := pos - fwd * sz * 0.05 - right * sz * 0.95
	var tl  := back + right * sz * 0.42; var tr := back - right * sz * 0.42

	var ef := 0.44 + sin(time_e * 20.0) * 0.22
	draw_circle(back,            sz * 0.42, Color(1.0, 0.18, 0.08, ef))
	draw_circle(back - fwd * 6,  sz * 0.28, Color(1.0, 0.38, 0.14, ef * 0.65))
	draw_circle(back - fwd * 12, sz * 0.17, Color(1.0, 0.58, 0.25, ef * 0.35))

	var doff := Vector2(0, sz * 0.14)
	draw_colored_polygon([tip+doff, wl+doff, tl+doff, back+doff, tr+doff, wr+doff],
		Color(hc.r * 0.4, hc.g * 0.4, hc.b * 0.4, 0.80))
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(hc.r, hc.g, hc.b, 0.95))
	draw_colored_polygon([tip, pos + right * sz * 0.18, back, pos - right * sz * 0.18],
		Color(ac.r, ac.g, ac.b, 0.58))

	var cock := pos + fwd * sz * 0.36
	draw_circle(cock, sz * 0.22, Color(1.0, 0.16, 0.10, 0.88))
	draw_circle(cock, sz * 0.12, Color(1.0, 0.55, 0.28, 0.92))
	draw_circle(wl, 2.5, Color(1.0, 0.10, 0.10, 0.92))
	draw_circle(wr, 2.5, Color(1.0, 0.10, 0.10, 0.92))

	# Target indicator
	if is_target:
		draw_arc(pos, sz + 20, 0, TAU, 32, Color(1.0, 0.9, 0.1, 0.55 + sin(time_e * 6) * 0.2), 2.0)

	# Attack charge arc
	var acd := clampf(1.0 - e["atk_timer"] / e["atk_interval"], 0.0, 1.0)
	draw_arc(pos, sz + 18, -PI * 0.55, PI * 0.55, 24,
		Color(1.0, 0.18 + acd * 0.5, 0.08, 0.30 + acd * 0.40), 2.0)

	_draw_enemy_hp_bar(pos, sz, e)

func _draw_ship_dreadnought(pos: Vector2, angle: float, e: Dictionary, is_target: bool) -> void:
	var sz    := 42.0
	var fwd   := Vector2(sin(angle), -cos(angle))
	var right := fwd.rotated(PI / 2.0)
	var ef    := 0.55 + sin(time_e * 14.0) * 0.22
	var back  := pos - fwd * sz * 0.52

	# 4 massive engines
	for side: float in [-1.5, -0.5, 0.5, 1.5]:
		var ep := back + right * side * sz * 0.36
		draw_circle(ep,            sz * 0.28, Color(0.70, 0.02, 0.85, ef))
		draw_circle(ep - fwd * 8,  sz * 0.18, Color(0.88, 0.12, 1.00, ef * 0.60))
		draw_circle(ep - fwd * 16, sz * 0.10, Color(1.00, 0.50, 1.00, ef * 0.30))

	var tip := pos + fwd * sz * 1.10
	var wl  := pos - fwd * sz * 0.08 + right * sz * 1.30
	var wr  := pos - fwd * sz * 0.08 - right * sz * 1.30
	var tl  := back + right * sz * 0.70
	var tr  := back - right * sz * 0.70

	var doff := Vector2(0, sz * 0.16)
	draw_colored_polygon([tip+doff, wl+doff, tl+doff, back+doff, tr+doff, wr+doff],
		Color(0.08, 0.01, 0.12, 0.85))
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(0.22, 0.04, 0.30, 0.95))
	# Armored spine
	draw_colored_polygon([tip, pos + right * sz * 0.28, back, pos - right * sz * 0.28],
		Color(0.55, 0.05, 0.70, 0.55))
	# Rim light
	draw_arc(pos, sz * 0.70, PI * 0.52, PI * 1.48, 26, Color(0.75, 0.10, 1.00, 0.32), sz * 0.20)

	# Heavy turrets on wings
	for side: float in [-1.0, 1.0]:
		var turret: Vector2 = pos + right * float(side) * sz * 0.90 + fwd * sz * 0.05
		draw_circle(turret, 8.0, Color(0.30, 0.02, 0.38, 0.92))
		draw_circle(turret, 4.5, Color(0.80, 0.10, 1.00, 0.85))
		draw_line(turret, turret + fwd * 18.0, Color(0.75, 0.25, 0.90, 0.90), 3.5)
		# Side cannons
		draw_line(turret + right * float(side) * 4, turret + right * float(side) * 4 + fwd * 14,
			Color(0.60, 0.15, 0.75, 0.80), 2.0)

	# Central cannon
	draw_line(pos + fwd * sz * 0.55, pos + fwd * sz * 1.18,
		Color(0.90, 0.30, 1.00, 0.88), 5.0)
	draw_line(pos + fwd * sz * 0.55, pos + fwd * sz * 1.18,
		Color(1.00, 0.80, 1.00, 0.40), 2.0)

	# Bridge
	var ck := pos + fwd * sz * 0.42
	draw_circle(ck, 8.0, Color(0.60, 0.05, 0.78, 0.90))
	draw_circle(ck, 4.5, Color(1.00, 0.60, 1.00, 0.95))
	draw_circle(wl, 3.0, Color(1.0, 0.10, 0.10, 0.92))
	draw_circle(wr, 3.0, Color(1.0, 0.10, 0.10, 0.92))

	# Target & attack
	if is_target:
		draw_arc(pos, sz + 22, 0, TAU, 40, Color(1.0, 0.9, 0.1, 0.55 + sin(time_e * 6) * 0.2), 2.5)
	var acd := clampf(1.0 - e["atk_timer"] / e["atk_interval"], 0.0, 1.0)
	draw_arc(pos, sz + 20, -PI * 0.55, PI * 0.55, 28,
		Color(0.80, 0.05, 1.00, 0.25 + acd * 0.55), 3.0)

	_draw_enemy_hp_bar(pos, sz, e)

func _draw_enemy_hp_bar(pos: Vector2, sz: float, e: Dictionary) -> void:
	var ep := float(e["hull"]) / float(e["max_hull"])
	var bw := sz * 3.2
	draw_rect(Rect2(pos.x - bw * 0.5, pos.y - sz - 30, bw, 8), Color(0.10, 0, 0, 0.90))
	var ec := Color(0.1, 0.9, 0.2) if ep > 0.5 else (Color(0.9, 0.72, 0.1) if ep > 0.25 else Color(1.0, 0.1, 0.1))
	draw_rect(Rect2(pos.x - bw * 0.5, pos.y - sz - 30, bw * ep, 8), ec)
	draw_string(ThemeDB.fallback_font, Vector2(pos.x - 44, pos.y - sz - 34),
		e["name"], HORIZONTAL_ALIGNMENT_LEFT, 90, 11, Color(1.0, 0.55, 0.45, 0.82))

# ── Player ship silhouettes (unchanged from before) ───────────────────────────

func _draw_ship_scout(pos: Vector2, angle: float, col: Color) -> void:
	var sz := 22.0; var fwd := Vector2(sin(angle), -cos(angle)); var right := fwd.rotated(PI/2.0)
	var ef := 0.50 + sin(time_e * 24.0) * 0.22; var back := pos - fwd * sz * 0.55
	draw_circle(back, sz*0.38, Color(col.r*0.5, col.g*0.8, 1.0, ef))
	draw_circle(back - fwd*7, sz*0.26, Color(col.r*0.6, col.g*0.9, 1.0, ef*0.70))
	draw_circle(back - fwd*14, sz*0.15, Color(0.80, 0.95, 1.0, ef*0.38))
	var tip := pos + fwd*sz; var wl := pos - fwd*sz*0.04 + right*sz*0.80
	var wr  := pos - fwd*sz*0.04 - right*sz*0.80
	var tl  := back + right*sz*0.30; var tr := back - right*sz*0.30
	var doff := Vector2(0, sz*0.12)
	draw_colored_polygon([tip+doff, wl+doff, tl+doff, back+doff, tr+doff, wr+doff],
		Color(col.r*0.3, col.g*0.4, col.b*0.55, 0.75))
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(col.r, col.g, col.b, 0.95))
	draw_colored_polygon([tip, pos+right*sz*0.15, back, pos-right*sz*0.15],
		Color(col.r+0.2, col.g+0.2, col.b+0.1, 0.55))
	draw_arc(pos, sz*0.70, PI*0.6, PI*1.4, 18, Color(col.r+0.3, col.g+0.3, 1.0, 0.35), sz*0.16)
	var ck := pos + fwd*sz*0.40
	draw_circle(ck, 5.5, Color(0.62, 0.92, 1.0, 0.92)); draw_circle(ck, 3.0, Color(1,1,1,0.95))
	draw_circle(wl, 2.5, Color(1.0, 0.22, 0.22, 0.90)); draw_circle(wr, 2.5, Color(0.22, 1.0, 0.40, 0.90))

func _draw_ship_combat(pos: Vector2, angle: float, col: Color) -> void:
	var sz := 24.0; var fwd := Vector2(sin(angle), -cos(angle)); var right := fwd.rotated(PI/2.0)
	var ef := 0.55 + sin(time_e * 28.0) * 0.22; var back := pos - fwd*sz*0.50
	for side: float in [-1.0, 1.0]:
		var ep := back + right*side*sz*0.45
		draw_circle(ep, sz*0.30, Color(col.r*0.4, col.g*0.6, 1.0, ef))
		draw_circle(ep - fwd*6, sz*0.20, Color(col.r*0.5, col.g*0.75, 1.0, ef*0.65))
	var tip := pos + fwd*sz*1.05; var wl := pos - fwd*sz*0.10 + right*sz*1.05
	var wr  := pos - fwd*sz*0.10 - right*sz*1.05
	var tl  := back + right*sz*0.48; var tr := back - right*sz*0.48
	var doff := Vector2(0, sz*0.13)
	draw_colored_polygon([tip+doff, wl+doff, tl+doff, back+doff, tr+doff, wr+doff],
		Color(col.r*0.28, col.g*0.35, col.b*0.60, 0.78))
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(col.r, col.g, col.b, 0.95))
	draw_colored_polygon([tip, pos+right*sz*0.22, back, pos-right*sz*0.22],
		Color(col.r+0.18, col.g+0.18, 1.0, 0.52))
	draw_arc(pos, sz*0.75, PI*0.55, PI*1.45, 20, Color(0.55, 0.80, 1.0, 0.32), sz*0.18)
	draw_line(pos+fwd*sz*0.55, pos+fwd*sz*1.12, Color(0.70, 0.80, 0.90, 0.85), 3.5)
	var ck := pos + fwd*sz*0.40
	draw_circle(ck, 5.0, Color(0.55, 0.85, 1.0, 0.90)); draw_circle(ck, 2.8, Color(1,1,1,0.95))
	draw_circle(wl, 2.5, Color(1.0,0.22,0.22,0.90)); draw_circle(wr, 2.5, Color(0.22,1.0,0.40,0.90))

func _draw_ship_cargo(pos: Vector2, angle: float, col: Color) -> void:
	var sz := 26.0; var fwd := Vector2(sin(angle), -cos(angle)); var right := fwd.rotated(PI/2.0)
	var ef := 0.45 + sin(time_e * 18.0) * 0.18; var back := pos - fwd*sz*0.60
	for side: float in [-1.0, 1.0]:
		var ep := back + right*side*sz*0.58
		draw_circle(ep, sz*0.32, Color(col.r*0.4, col.g*0.85, col.b*0.4, ef))
	var tip := pos + fwd*sz*0.75; var wl := pos + right*sz*1.20; var wr := pos - right*sz*1.20
	var tl := back + right*sz*1.10; var tr := back - right*sz*1.10
	var doff := Vector2(0, sz*0.16)
	draw_colored_polygon([tip+doff, wl+doff, tl+doff, back+doff, tr+doff, wr+doff],
		Color(col.r*0.25, col.g*0.42, col.b*0.28, 0.80))
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(col.r, col.g, col.b, 0.92))
	draw_arc(pos, sz*0.75, PI*0.55, PI*1.45, 20, Color(col.r+0.2, 1.0, col.g+0.2, 0.22), sz*0.16)
	var ck := pos + fwd*sz*0.50
	draw_circle(ck, 4.5, Color(0.62, 0.92, 1.0, 0.88)); draw_circle(ck, 2.5, Color(1,1,1,0.95))
	draw_circle(wl, 2.5, Color(1.0,0.22,0.22,0.90)); draw_circle(wr, 2.5, Color(0.22,1.0,0.40,0.90))

func _draw_ship_mining(pos: Vector2, angle: float, col: Color) -> void:
	var sz := 22.0; var fwd := Vector2(sin(angle), -cos(angle)); var right := fwd.rotated(PI/2.0)
	var ef := 0.42 + sin(time_e * 16.0) * 0.18; var back := pos - fwd*sz*0.55
	draw_circle(back, sz*0.38, Color(1.0, col.g*0.7, col.b*0.1, ef))
	var tip := pos+fwd*sz*0.72; var wl := pos+right*sz*1.05; var wr := pos-right*sz*1.05
	var tl := back+right*sz*0.85; var tr := back-right*sz*0.85
	var doff := Vector2(0, sz*0.15)
	draw_colored_polygon([tip+doff, wl+doff, tl+doff, back+doff, tr+doff, wr+doff],
		Color(col.r*0.35, col.g*0.28, 0.05, 0.78))
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(col.r, col.g, col.b, 0.92))
	for side: float in [-1.0, 1.0]:
		var arm_base: Vector2 = pos + right*float(side)*sz*0.80 + fwd*sz*0.30
		var arm_tip:  Vector2 = arm_base + fwd*sz*0.65
		draw_line(arm_base, arm_tip, Color(0.75, 0.65, 0.45, 0.85), 4.0)
		draw_circle(arm_tip, 4.5, Color(1.0, 0.75, 0.30, 0.88))
	var ck := pos + fwd*sz*0.35
	draw_circle(ck, 4.5, Color(0.92, 0.80, 0.55, 0.88)); draw_circle(ck, 2.3, Color(1,1,1,0.95))
	draw_circle(wl, 2.5, Color(1.0,0.22,0.22,0.90)); draw_circle(wr, 2.5, Color(0.22,1.0,0.40,0.90))

func _draw_ship_flagship(pos: Vector2, angle: float, col: Color) -> void:
	var sz := 34.0; var fwd := Vector2(sin(angle), -cos(angle)); var right := fwd.rotated(PI/2.0)
	var ef := 0.50 + sin(time_e * 22.0) * 0.20; var back := pos - fwd*sz*0.55
	for side: float in [-1.0, 0.0, 1.0]:
		var ep := back + right*side*sz*0.50
		draw_circle(ep, sz*0.30, Color(col.r*0.7, col.g*0.6, 0.15, ef))
	var tip := pos+fwd*sz*1.05; var wl := pos-fwd*sz*0.05+right*sz*1.15
	var wr  := pos-fwd*sz*0.05-right*sz*1.15
	var tl  := back+right*sz*0.60; var tr := back-right*sz*0.60
	var doff := Vector2(0, sz*0.14)
	draw_colored_polygon([tip+doff, wl+doff, tl+doff, back+doff, tr+doff, wr+doff],
		Color(col.r*0.30, col.g*0.28, 0.05, 0.80))
	draw_colored_polygon([tip, wl, tl, back, tr, wr], Color(col.r, col.g, col.b, 0.95))
	draw_colored_polygon([tip, pos+right*sz*0.22, back, pos-right*sz*0.22],
		Color(1.0, 0.92, 0.45, 0.55))
	for side: float in [-1.0, 1.0]:
		var turret: Vector2 = pos + right*float(side)*sz*0.75 + fwd*sz*0.10
		draw_circle(turret, 5.0, Color(col.r+0.1, col.g+0.05, 0.10, 0.90))
		draw_line(turret, turret + fwd*12.0, Color(0.85, 0.80, 0.40, 0.88), 2.5)
	var ck := pos + fwd*sz*0.42
	draw_circle(ck, 6.5, Color(0.72, 0.92, 1.0, 0.90)); draw_circle(ck, 3.5, Color(1,1,1,0.95))
	draw_circle(wl, 2.8, Color(1.0,0.22,0.22,0.90)); draw_circle(wr, 2.8, Color(0.22,1.0,0.40,0.90))

# ══════════════════════════════════════════════════════════════════════════════
# HUD
# ══════════════════════════════════════════════════════════════════════════════

func _draw_hud(vp: Vector2, arena: float) -> void:
	var hy   := arena
	var font := ThemeDB.fallback_font
	var pad  := 14.0

	draw_rect(Rect2(0, hy, vp.x, HUD_HEIGHT), Color(0.018, 0.022, 0.070, 0.96))
	draw_line(Vector2(0, hy), Vector2(vp.x, hy), Color(0.20, 0.42, 0.85, 0.55), 2.0)
	draw_line(Vector2(0, hy), Vector2(vp.x, hy), Color(0.30, 0.58, 1.00, 0.10), 9.0)

	var lw := vp.x * 0.38
	var cw := vp.x * 0.62
	for xd: float in [lw, cw]:
		draw_line(Vector2(xd, hy + 5), Vector2(xd, vp.y - 5), Color(0.20, 0.35, 0.60, 0.30), 1.0)

	# LEFT: player
	var ship_name: String = GameManager.current_ship.get("name", "Корабль")
	draw_string(font, Vector2(pad, hy + 17),
		"%s  [%s · %s]" % [ship_name,
			GameManager.current_ship.get("ship_type", ""),
			GameManager.current_ship.get("ship_class", "")],
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.50, 0.88, 1.00, 0.95))

	var hpct: float = clampf(float(player_hull) / float(player_max_hull), 0.0, 1.0)
	var spct: float = clampf(float(player_shields) / float(player_max_shields), 0.0, 1.0) \
					  if player_max_shields > 0 else 0.0
	var hcol := Color(0.15, 0.85, 0.25) if hpct > 0.5 else \
			   (Color(0.90, 0.72, 0.10) if hpct > 0.25 else Color(0.95, 0.15, 0.15))
	_draw_bar(pad, hy + 22, lw - pad * 2, 17, hpct, hcol,
		"КОРПУС  %d / %d" % [player_hull, player_max_hull], font)
	_draw_bar(pad, hy + 44, lw - pad * 2, 13, spct, Color(0.22, 0.55, 1.00),
		"ЩИТ  %d / %d" % [player_shields, player_max_shields], font)

	draw_string(font, Vector2(pad, hy + 68),
		"ВООРУЖЕНИЕ: (клик — выбрать)", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.50, 0.62, 0.72, 0.80))
	var wy := hy + 80.0
	_weapon_rects.resize(player_weapons.size())
	for i in player_weapons.size():
		var w: Dictionary = player_weapons[i]
		var cd: float = weapon_cooldowns.get(w["name"], 0.0)
		var ready     := cd <= 0.05
		var sel       := i == selected_weapon_idx
		var wcol      := Color(0.28, 0.92, 0.42) if ready else Color(0.88, 0.58, 0.20)
		var row_h     := 14.0
		# Highlight selected weapon row
		if sel:
			draw_rect(Rect2(pad - 2, wy - row_h + 2, lw - pad * 2, row_h),
				Color(0.22, 0.55, 0.22, 0.18))
		# Store clickable rect
		_weapon_rects[i] = Rect2(pad - 2, wy - row_h + 2, lw - pad * 2, row_h)
		var ammo_txt: String = ""
		if w.has("ammo_left"):
			ammo_txt = "  [%d🚀]" % w["ammo_left"] if w["ammo_left"] > 0 else "  [ПУСТО]"
		elif w.get("type","") == "railgun":
			ammo_txt = "  [РЕЛЬСА]"
		draw_string(font, Vector2(pad, wy),
			("▶ " if sel else "  ") + w["name"] + ammo_txt + ("  ГОТОВО" if ready else "  %.1fs" % cd),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10, wcol)
		var bx := pad + 155.0; var bww := minf(lw - pad*2 - 158, 82)
		draw_rect(Rect2(bx, wy - 9, bww, 5), Color(0.04, 0.04, 0.12, 0.90))
		if ready: draw_rect(Rect2(bx, wy - 9, bww, 5), wcol)
		else:     draw_rect(Rect2(bx, wy - 9, bww * clampf(1.0 - cd / 2.0, 0, 1), 5), wcol)
		wy += 15.0

	# Retreat — drawn as text in bottom-left corner of HUD
	var ret_col := Color(1.0, 0.55, 0.22, 0.90)
	draw_string(font, Vector2(pad, hy + HUD_HEIGHT - 10),
		"🏳 Отступить [E]", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, ret_col)

	# CENTRE: ability bar + day/credits
	var cx := (lw + cw) * 0.5

	const UPG_ORDER    := ["volley","boost","overload","emergency_shields","shield_injector","repair_drones"]
	const UPG_ICONS    := {"volley":"⚡","boost":"🔥","overload":"💥",
						   "emergency_shields":"🛡","shield_injector":"💉","repair_drones":"🤖"}
	const UPG_LABELS   := {"volley":"Залп","boost":"Форсаж","overload":"Перегр.",
						   "emergency_shields":"Авт.щит","shield_injector":"Инжект.","repair_drones":"Дроны"}
	const UPG_CLICKABLE := ["volley","boost","overload"]

	_upgrade_btn_rects.clear()
	var owned_u  := GameManager.ship_upgrades
	var upg_count := 0
	for u2: String in UPG_ORDER:
		if u2 in owned_u: upg_count += 1

	if upg_count > 0:
		var B_W    := 44.0    # button width
		var B_H    := 44.0    # button height
		var B_GAP  := 4.0
		var total  := upg_count * B_W + (upg_count - 1) * B_GAP
		var bx0    := cx - total * 0.5
		var by0    := hy + (HUD_HEIGHT - B_H) * 0.5 - 10.0   # vertically centred in HUD

		draw_string(font, Vector2(cx - 28, by0 - 8), "СПОСОБНОСТИ",
			HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.40, 0.52, 0.68, 0.65))

		var bi := 0
		for uid: String in UPG_ORDER:
			if uid not in owned_u: continue
			var bx    := bx0 + bi * (B_W + B_GAP)
			var brect := Rect2(bx, by0, B_W, B_H)
			_upgrade_btn_rects[uid] = brect

			var cd: float      = upgrade_cooldowns.get(uid, 0.0)
			var is_click: bool = uid in UPG_CLICKABLE
			var ready: bool    = cd <= 0.05

			# Background
			var bg: Color
			if uid == "repair_drones":
				bg = Color(0.04, 0.18, 0.06, 0.95)
			elif not is_click:
				bg = Color(0.04, 0.10, 0.22, 0.92) if ready else Color(0.04, 0.05, 0.14, 0.88)
			elif not ready:
				bg = Color(0.05, 0.05, 0.10, 0.90)
			elif uid == "overload" and overload_next_shot:
				bg = Color(0.22, 0.03, 0.22, 0.95)
			elif uid == "boost" and boost_timer > 0:
				bg = Color(0.22, 0.09, 0.02, 0.95)
			else:
				bg = Color(0.06, 0.10, 0.24, 0.92)
			draw_rect(brect, bg)

			# Border
			var bord: Color
			if uid == "repair_drones":
				bord = Color(0.28, 0.90, 0.38, 0.88)
			elif not is_click:
				bord = Color(0.28, 0.62, 1.0, 0.80) if ready else Color(0.18, 0.26, 0.52, 0.50)
			elif not ready:
				bord = Color(0.20, 0.22, 0.36, 0.55)
			elif uid == "overload" and overload_next_shot:
				bord = Color(1.0, 0.35, 1.0, 0.95)
			elif uid == "boost" and boost_timer > 0:
				bord = Color(1.0, 0.55, 0.15, 0.95)
			else:
				bord = Color(0.38, 0.60, 1.0, 0.82)
			draw_rect(brect, bord, false, 1.5)

			# Cooldown shade (fills from bottom)
			if cd > 0.05 and is_click:
				var fh := B_H * clampf(cd / UPG_CD.get(uid, 1.0), 0.0, 1.0)
				draw_rect(Rect2(bx, by0 + B_H - fh, B_W, fh), Color(0, 0, 0, 0.58))

			# Icon
			var alpha_i := 0.38 if (not ready and is_click) else 0.95
			draw_string(font, Vector2(bx + B_W * 0.5 - 8, by0 + B_H * 0.50),
				UPG_ICONS.get(uid, "?"), HORIZONTAL_ALIGNMENT_LEFT, -1, 17,
				Color(1, 1, 1, alpha_i))

			# Sub-label
			var sub: String
			if uid == "boost" and boost_timer > 0:        sub = "%.0fs" % boost_timer
			elif uid == "overload" and overload_next_shot: sub = "×3!"
			elif cd > 0.05 and is_click:                  sub = "%.0fs" % cd
			else:                                          sub = UPG_LABELS.get(uid, uid)
			draw_string(font, Vector2(bx + B_W * 0.5 - 16, by0 + B_H - 3),
				sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.80, 0.90, 1.0, 0.82))

			bi += 1

	draw_string(font, Vector2(cx, hy + HUD_HEIGHT - 12),
		"День %d   |   %d кред." % [GameManager.day, GameManager.credits],
		HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(0.72, 0.85, 0.62, 0.88))

	# RIGHT: enemies list
	var rbx := cw + pad
	var rbw := vp.x - rbx - pad * 2
	draw_string(font, Vector2(rbx, hy + 17), "ПРОТИВНИКИ",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.45, 0.52, 0.68, 0.70))

	var ey := hy + 30.0
	for i in enemies.size():
		var e: Dictionary = enemies[i]
		var alive: bool = e["hull"] > 0
		var epct: float = clampf(float(e["hull"]) / float(e["max_hull"]), 0.0, 1.0)
		var ecol := Color(0.15, 0.85, 0.25) if epct > 0.5 else \
				   (Color(0.90, 0.72, 0.10) if epct > 0.25 else Color(0.95, 0.15, 0.15))

		if not alive:
			draw_string(font, Vector2(rbx, ey), "💀  " + e["name"],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.35, 0.35, 0.40, 0.50))
			ey += 14.0
			continue

		var prefix := ("▶ " if i == target_enemy_idx else "  ")
		draw_string(font, Vector2(rbx, ey), prefix + e["name"],
			HORIZONTAL_ALIGNMENT_LEFT, -1, 10,
			Color(1.0, 0.80, 0.30) if i == target_enemy_idx else Color(0.80, 0.55, 0.45))
		ey += 12.0
		_draw_bar(rbx, ey, rbw, 10, epct, ecol,
			"%d / %d" % [e["hull"], e["max_hull"]], font)

		# Attack charge mini-bar
		var acd: float = clampf(1.0 - e["atk_timer"] / e["atk_interval"], 0.0, 1.0)
		draw_rect(Rect2(rbx, ey + 12, rbw, 4), Color(0.03, 0.03, 0.10, 0.90))
		draw_rect(Rect2(rbx, ey + 12, rbw * acd, 4),
			Color(0.85, 0.20 + acd * 0.40, 0.10, 0.70))
		ey += 28.0

func _draw_bar(x: float, y: float, w: float, h: float,
			   pct: float, col: Color, label: String, font: Font) -> void:
	draw_rect(Rect2(x, y, w, h), Color(0.03, 0.03, 0.10, 0.92))
	if pct > 0.0:
		draw_rect(Rect2(x, y, w * pct, h), col)
		draw_rect(Rect2(x + w * pct - 2.0, y, 2.0, h), Color(col.r, col.g, col.b, 0.95))
	draw_rect(Rect2(x, y, w, h), Color(0.20, 0.30, 0.55, 0.40), false, 1.0)
	draw_string(font, Vector2(x + 4, y + h - 2), label,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(1.0, 1.0, 1.0, 0.88))
