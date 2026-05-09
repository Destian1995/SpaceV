extends Node2D

var time_e: float = 0.0

# Layout constants
const SCHEMATIC_CENTER := Vector2(480, 430)
const PANEL_X          := 820.0   # right panel start X

func _process(delta: float) -> void:
	time_e += delta
	queue_redraw()

func _ready() -> void:
	_build_ui()

# ── UI Build ─────────────────────────────────────────────────────────────────

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	# ── Top bar ──────────────────────────────────────────────────────────────
	var topbar := PanelContainer.new()
	topbar.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	topbar.offset_bottom = 48
	ui.add_child(topbar)

	var hb := HBoxContainer.new()
	topbar.add_child(hb)

	_nav_btn(hb, "◀ В систему",    func(): get_tree().change_scene_to_file("res://scenes/star_system/StarSystemView.tscn"))
	_nav_btn(hb, "🌌 Карта",       func(): get_tree().change_scene_to_file("res://scenes/galaxy_map/GalaxyMap.tscn"))

	var title := Label.new()
	title.text = "⚙  МОСТИК —  %s  |  %s  Класс %s" % [
		GameManager.current_ship.get("name","???"),
		GameManager.current_ship.get("ship_type",""),
		GameManager.current_ship.get("ship_class","C"),
	]
	title.add_theme_font_size_override("font_size", 18)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(title)

	var cred_lbl := Label.new()
	cred_lbl.text = "💰 %d" % GameManager.credits
	cred_lbl.add_theme_font_size_override("font_size", 17)
	cred_lbl.custom_minimum_size = Vector2(150, 0)
	cred_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hb.add_child(cred_lbl)
	var _cred_cb := func(v): cred_lbl.text = "💰 %d" % v
	GameManager.credits_changed.connect(_cred_cb)
	tree_exiting.connect(func(): GameManager.credits_changed.disconnect(_cred_cb))

	# ── Right panel ───────────────────────────────────────────────────────────
	var right := PanelContainer.new()
	right.set_anchor(SIDE_LEFT,   1.0)
	right.set_anchor(SIDE_RIGHT,  1.0)
	right.set_anchor(SIDE_TOP,    0.0)
	right.set_anchor(SIDE_BOTTOM, 1.0)
	right.offset_left   = -380
	right.offset_top    = 52
	right.offset_right  = -2
	right.offset_bottom = -2
	ui.add_child(right)

	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(tabs)

	# Stats tab
	var stats_scroll := ScrollContainer.new()
	stats_scroll.name = "📊 Системы"
	stats_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(stats_scroll)
	var sv := VBoxContainer.new()
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_scroll.add_child(sv)
	_populate_stats(sv)

	# Cargo tab
	var cargo_scroll := ScrollContainer.new()
	cargo_scroll.name = "📦 Трюм"
	cargo_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(cargo_scroll)
	var cv := VBoxContainer.new()
	cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cargo_scroll.add_child(cv)
	_populate_cargo(cv)

	# Quests tab
	var quest_scroll := ScrollContainer.new()
	quest_scroll.name = "📋 Задания"
	quest_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(quest_scroll)
	var qv := VBoxContainer.new()
	qv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quest_scroll.add_child(qv)
	_populate_quests(qv)

func _nav_btn(hb: HBoxContainer, text: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 15)
	btn.custom_minimum_size = Vector2(148, 0)
	btn.pressed.connect(cb)
	hb.add_child(btn)

# ── Stats panel ───────────────────────────────────────────────────────────────

func _populate_stats(vb: VBoxContainer) -> void:
	var ship := GameManager.current_ship
	var cls: String = ship.get("ship_class", "C")
	var cls_colors := {"A": Color(1.0,0.82,0.1), "B": Color(0.5,0.78,1.0), "C": Color(0.55,0.55,0.6)}
	var cls_col: Color = cls_colors.get(cls, Color.WHITE)

	vb.add_child(_lbl("ИДЕНТИФИКАЦИЯ", 13, Color(0.4,0.6,0.9)))
	vb.add_child(_lbl(ship.get("name","???"), 22, cls_col))
	vb.add_child(_lbl("%s  •  Класс %s" % [ship.get("ship_type",""), cls], 15, cls_col * 0.85))
	var desc_l := _lbl(ship.get("desc",""), 13, Color(0.6,0.6,0.6))
	desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(desc_l)
	vb.add_child(HSeparator.new())

	vb.add_child(_lbl("ХАРАКТЕРИСТИКИ", 13, Color(0.4,0.6,0.9)))
	var stats := [
		["⚡ Скорость",  ship.get("speed",   0), 400],
		["🛡 Броня",     ship.get("hull",    0), 2000],
		["🔵 Щиты",     ship.get("shields", 0), 300],
		["📡 Сенсоры",  ship.get("sensors", 0), 100],
		["📦 Грузовой трюм", ship.get("cargo", 0), 400],
	]
	for st in stats:
		vb.add_child(_stat_row(st[0], st[1], st[2]))
	vb.add_child(HSeparator.new())

	vb.add_child(_lbl("ЭКИПАЖ", 13, Color(0.4,0.6,0.9)))
	var crew_data := [
		["Зара",    "Пилот",      85, Color(0.4,0.9,0.6)],
		["Косс",    "Канонир",    70, Color(1.0,0.6,0.3)],
		["Мира",    "Инженер",    75, Color(0.5,0.75,1.0)],
	]
	for c in crew_data:
		var row := HBoxContainer.new()
		vb.add_child(row)
		var nl := _lbl("%s  (%s)" % [c[0], c[1]], 14)
		nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(nl)
		var bar := ProgressBar.new()
		bar.max_value = 100
		bar.value     = c[2]
		bar.custom_minimum_size = Vector2(80, 16)
		row.add_child(bar)
		var ml := _lbl("%d%%" % c[2], 13, c[3])
		ml.custom_minimum_size = Vector2(36, 0)
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(ml)
	vb.add_child(HSeparator.new())

	vb.add_child(_lbl("ВООРУЖЕНИЕ", 13, Color(0.4,0.6,0.9)))
	if GameManager.equipped_weapons.is_empty():
		vb.add_child(_lbl("  Оружие не установлено", 13, Color(0.5,0.5,0.5)))
	else:
		for w in GameManager.equipped_weapons:
			vb.add_child(_lbl("  ⚔  " + str(w), 14))

# ── Cargo panel ───────────────────────────────────────────────────────────────

func _populate_cargo(vb: VBoxContainer) -> void:
	var used: int = GameManager.cargo_capacity - GameManager.cargo_free()
	var cap:  int = GameManager.cargo_capacity

	vb.add_child(_lbl("СОСТОЯНИЕ ТРЮМА", 13, Color(0.4,0.6,0.9)))

	# Capacity bar
	var cap_row := HBoxContainer.new()
	vb.add_child(cap_row)
	var cap_bar := ProgressBar.new()
	cap_bar.max_value = cap
	cap_bar.value     = used
	cap_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cap_bar.custom_minimum_size   = Vector2(0, 22)
	cap_row.add_child(cap_bar)
	var cap_lbl := _lbl("  %d / %d" % [used, cap], 14)
	cap_row.add_child(cap_lbl)

	vb.add_child(HSeparator.new())

	if GameManager.cargo.is_empty():
		vb.add_child(_lbl("  Трюм пуст", 14, Color(0.45,0.45,0.5)))
		return

	vb.add_child(_lbl("СОДЕРЖИМОЕ", 13, Color(0.4,0.6,0.9)))

	# Header
	var hdr := HBoxContainer.new()
	vb.add_child(hdr)
	var th1 := _lbl("Товар", 12, Color(0.5,0.7,1.0))
	th1.custom_minimum_size = Vector2(160, 0)
	hdr.add_child(th1)
	var th2 := _lbl("Кол-во", 12, Color(0.5,0.7,1.0))
	th2.custom_minimum_size = Vector2(60, 0)
	th2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hdr.add_child(th2)
	var th3 := _lbl("Объём", 12, Color(0.5,0.7,1.0))
	th3.custom_minimum_size = Vector2(50, 0)
	th3.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hdr.add_child(th3)
	vb.add_child(HSeparator.new())

	for item in GameManager.cargo:
		var qty: int  = GameManager.cargo[item]
		var row := HBoxContainer.new()
		vb.add_child(row)

		var name_l := _lbl("📦 " + item, 15)
		name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_l)

		var qty_l := _lbl("×%d" % qty, 15, Color(1.0, 0.88, 0.3))
		qty_l.custom_minimum_size = Vector2(52, 0)
		qty_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(qty_l)

		var vol := qty
		var vol_l := _lbl("%d т" % vol, 14, Color(0.55,0.55,0.6))
		vol_l.custom_minimum_size = Vector2(48, 0)
		vol_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(vol_l)

	vb.add_child(HSeparator.new())
	# Check active quests requiring cargo
	for q in GameManager.active_quests:
		var cond: Dictionary = q.get("conditions",{})
		if cond.get("type","") == "cargo_and_travel":
			var item: String = cond.get("item","")
			var need: int    = cond.get("amount", 0)
			var have: int    = GameManager.cargo.get(item, 0)
			var ok: bool     = have >= need
			var col: Color   = Color(0.3,1.0,0.45) if ok else Color(1.0,0.5,0.3)
			vb.add_child(_lbl("%s  %s: %d/%d %s" % [
				q.get("icon",""), q.get("title",""),
				have, need, item
			], 13, col))

# ── Quests panel ──────────────────────────────────────────────────────────────

func _populate_quests(vb: VBoxContainer) -> void:
	vb.add_child(_lbl("АКТИВНЫЕ ЗАДАНИЯ", 13, Color(0.4,0.6,0.9)))
	if GameManager.active_quests.is_empty():
		vb.add_child(_lbl("  Нет активных заданий", 14, Color(0.45,0.45,0.5)))
	else:
		for q in GameManager.active_quests:
			vb.add_child(_quest_card(q))

	vb.add_child(HSeparator.new())
	vb.add_child(_lbl("ВЫПОЛНЕНО: %d" % GameManager.completed_quests.size(), 13, Color(0.3,0.85,0.45)))

func _quest_card(q: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)
	var vb := VBoxContainer.new()
	card.add_child(vb)
	vb.add_child(_lbl("%s  %s" % [q.get("icon",""), q["title"]], 16))
	var dl := _lbl(q["desc"], 12, Color(0.6,0.6,0.6))
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vb.add_child(dl)

	var fail: String = GameData.check_quest_conditions(q)
	var status_col: Color = Color(0.3,1.0,0.5) if fail.is_empty() else Color(1.0,0.6,0.3)
	var status_text: String = "✅ Условия выполнены — сдать в баре" if fail.is_empty() else "⏳ " + fail
	vb.add_child(_lbl(status_text, 13, status_col))
	vb.add_child(_lbl("💰 %d кред.  |  Сдать: %s" % [q["reward"], q.get("dest_galaxy","?")], 13, Color(1.0,0.85,0.25)))
	vb.add_child(HSeparator.new())
	return card

# ── Draw ──────────────────────────────────────────────────────────────────────

func _draw() -> void:
	var vp := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, vp), Color(0.008, 0.01, 0.022, 1))
	_draw_grid(vp)
	_draw_ship_blueprint(SCHEMATIC_CENTER)

func _draw_grid(vp: Vector2) -> void:
	var gc := Color(0.07, 0.12, 0.22, 0.45)
	for ix in int(vp.x / 40) + 1:
		draw_line(Vector2(ix * 40, 0), Vector2(ix * 40, vp.y), gc, 1)
	for iy in int(vp.y / 40) + 1:
		draw_line(Vector2(0, iy * 40), Vector2(vp.x, iy * 40), gc, 1)
	# Diagonal accents
	for d in 12:
		var dx: float = d * 120.0
		draw_line(Vector2(dx, 0), Vector2(dx - 200, vp.y), Color(0.06, 0.10, 0.20, 0.2), 1)

func _draw_ship_blueprint(C: Vector2) -> void:
	var ship := GameManager.current_ship
	var ship_type: String = ship.get("ship_type","Исследовательский")
	var ship_class: String = ship.get("ship_class","C")
	var cls_colors := {"A": Color(1.0,0.82,0.1), "B": Color(0.45,0.72,1.0), "C": Color(0.45,0.5,0.6)}
	var accent: Color = cls_colors.get(ship_class, Color(0.45,0.5,0.6))

	# ── Scale factor by ship type ─────────────────────────────────────────────
	var scale_v: float = 1.0
	match ship_type:
		"Грузовой":       scale_v = 1.15
		"Боевой":         scale_v = 1.1
		"Флагманский":    scale_v = 1.3
		"Ресурсодобывающий": scale_v = 1.05

	_draw_hull(C, ship_type, accent, scale_v)
	_draw_systems(C, ship_type, scale_v, accent)
	_draw_blueprint_labels(C, ship_type, scale_v, accent)
	_draw_class_badge(C, ship_class, accent)

func _draw_hull(C: Vector2, ship_type: String, accent: Color, sc: float) -> void:
	# Blueprint style: dark fill + bright lines
	var hull_pts := _get_hull_pts(C, ship_type, sc)
	if hull_pts.is_empty():
		return

	# Shadow fill
	draw_colored_polygon(hull_pts, Color(accent.r*0.06, accent.g*0.06, accent.b*0.12, 0.7))

	# Main hull outline
	draw_polyline(hull_pts, Color(accent.r, accent.g, accent.b, 0.75), 2.0)
	draw_line(hull_pts[hull_pts.size()-1], hull_pts[0], Color(accent.r, accent.g, accent.b, 0.75), 2.0)

	# Center axis line
	draw_dashed_line(C + Vector2(0, -int(220*sc)), C + Vector2(0, int(210*sc)),
		Color(accent.r, accent.g, accent.b, 0.22), 1.0, 10.0)

	# Cross axis
	draw_dashed_line(C + Vector2(-int(220*sc), 0), C + Vector2(int(220*sc), 0),
		Color(accent.r, accent.g, accent.b, 0.15), 1.0, 8.0)

func _get_hull_pts(C: Vector2, ship_type: String, sc: float) -> PackedVector2Array:
	match ship_type:
		"Боевой":
			return PackedVector2Array([
				C+Vector2(0,    -int(215*sc)),
				C+Vector2(30,   -int(160*sc)),
				C+Vector2(100,  -int(110*sc)),
				C+Vector2(210,  -int(40*sc)),
				C+Vector2(195,  int(80*sc)),
				C+Vector2(140,  int(180*sc)),
				C+Vector2(55,   int(215*sc)),
				C+Vector2(-55,  int(215*sc)),
				C+Vector2(-140, int(180*sc)),
				C+Vector2(-195, int(80*sc)),
				C+Vector2(-210, -int(40*sc)),
				C+Vector2(-100, -int(110*sc)),
				C+Vector2(-30,  -int(160*sc)),
			])
		"Грузовой":
			return PackedVector2Array([
				C+Vector2(0,    -int(180*sc)),
				C+Vector2(50,   -int(130*sc)),
				C+Vector2(200,  -int(70*sc)),
				C+Vector2(215,  int(160*sc)),
				C+Vector2(100,  int(210*sc)),
				C+Vector2(-100, int(210*sc)),
				C+Vector2(-215, int(160*sc)),
				C+Vector2(-200, -int(70*sc)),
				C+Vector2(-50,  -int(130*sc)),
			])
		"Ресурсодобывающий":
			return PackedVector2Array([
				C+Vector2(0,    -int(170*sc)),
				C+Vector2(80,   -int(120*sc)),
				C+Vector2(195,  int(10*sc)),
				C+Vector2(205,  int(120*sc)),
				C+Vector2(120,  int(210*sc)),
				C+Vector2(-120, int(210*sc)),
				C+Vector2(-205, int(120*sc)),
				C+Vector2(-195, int(10*sc)),
				C+Vector2(-80,  -int(120*sc)),
			])
		"Флагманский":
			return PackedVector2Array([
				C+Vector2(0,    -int(230*sc)),
				C+Vector2(60,   -int(170*sc)),
				C+Vector2(200,  -int(100*sc)),
				C+Vector2(265,  int(40*sc)),
				C+Vector2(230,  int(160*sc)),
				C+Vector2(150,  int(225*sc)),
				C+Vector2(-150, int(225*sc)),
				C+Vector2(-230, int(160*sc)),
				C+Vector2(-265, int(40*sc)),
				C+Vector2(-200, -int(100*sc)),
				C+Vector2(-60,  -int(170*sc)),
			])
		_: # Исследовательский
			return PackedVector2Array([
				C+Vector2(0,    -int(205*sc)),
				C+Vector2(38,   -int(130*sc)),
				C+Vector2(160,  -int(55*sc)),
				C+Vector2(170,  int(120*sc)),
				C+Vector2(90,   int(200*sc)),
				C+Vector2(-90,  int(200*sc)),
				C+Vector2(-170, int(120*sc)),
				C+Vector2(-160, -int(55*sc)),
				C+Vector2(-38,  -int(130*sc)),
			])

func _draw_systems(C: Vector2, ship_type: String, sc: float, accent: Color) -> void:
	# Shared system positions scaled by ship type
	var s := sc
	var pulse := sin(time_e * 2.2) * 0.25 + 0.5

	# Bridge
	_draw_zone(C + Vector2(0, -int(140*s)), 38*s, 28*s, Color(0.3, 0.7, 1.0), "bridge", pulse)

	# Shield ring
	_draw_ring_zone(C, int(75*s), Color(0.2, 0.5, 0.95), pulse * 0.5)

	# Reactor core
	_draw_zone(C + Vector2(0, -int(30*s)), 32*s, 32*s, Color(1.0, 0.85, 0.1), "reactor", pulse)

	# Engine block
	_draw_zone(C + Vector2(0, int(160*s)), int(70*s), int(30*s), Color(0.35, 0.85, 0.95), "engines", pulse)

	# Life support
	_draw_zone(C + Vector2(0, int(95*s)), int(45*s), int(22*s), Color(0.7, 0.35, 0.95), "life", pulse * 0.8)

	# Weapon hardpoints
	var wx: float = 135.0 * s
	match ship_type:
		"Боевой":
			wx = 165.0 * s
		"Грузовой":
			wx = 175.0 * s
	_draw_weapon_hp(C + Vector2(-wx, -int(20*s)), accent, pulse)
	_draw_weapon_hp(C + Vector2(wx,  -int(20*s)), accent, pulse)

	# Cargo hold
	var ch_h: float = 55.0 * s
	match ship_type:
		"Грузовой": ch_h = 90.0 * s
		"Ресурсодобывающий": ch_h = 75.0 * s
	_draw_cargo_hold(C + Vector2(0, int(40*s)), int(80*s), ch_h, pulse)

func _draw_zone(pos: Vector2, hw: float, hh: float, col: Color, _key: String, pulse: float) -> void:
	var r := Rect2(pos - Vector2(hw, hh), Vector2(hw*2, hh*2))
	draw_rect(r, Color(col.r, col.g, col.b, 0.10 + pulse * 0.04))
	draw_rect(r, Color(col.r, col.g, col.b, 0.55 + pulse * 0.2), false, 1.5)
	# Corner ticks
	var tick := 7.0
	for corner in [r.position, Vector2(r.end.x, r.position.y),
				   Vector2(r.position.x, r.end.y), r.end]:
		var dx: float = sign(corner.x - pos.x) * tick
		var dy: float = sign(corner.y - pos.y) * tick
		draw_line(corner, corner + Vector2(dx, 0), col, 1.5)
		draw_line(corner, corner + Vector2(0, dy), col, 1.5)
	# Pulse dot center
	draw_circle(pos, 3.5 + pulse * 1.5, Color(col.r, col.g, col.b, 0.8 + pulse * 0.2))

func _draw_ring_zone(C: Vector2, r: float, col: Color, pulse: float) -> void:
	draw_arc(C, r, 0, TAU, 64, Color(col.r, col.g, col.b, 0.35 + pulse * 0.15), 2.0)
	draw_arc(C, r + 8, 0, TAU, 64, Color(col.r, col.g, col.b, 0.12), 1.0)
	# Shield arc indicators
	for seg in 6:
		var a0: float = seg / 6.0 * TAU + time_e * 0.4
		var a1: float = a0 + 0.35
		draw_arc(C, r, a0, a1, 8, Color(col.r, col.g, col.b, 0.7 + pulse * 0.3), 3.0)

func _draw_weapon_hp(pos: Vector2, col: Color, pulse: float) -> void:
	var size := 18.0
	draw_rect(Rect2(pos - Vector2(size, size), Vector2(size*2, size*2)),
		Color(col.r, col.g, col.b, 0.12))
	draw_rect(Rect2(pos - Vector2(size, size), Vector2(size*2, size*2)),
		Color(1.0, 0.45, 0.2, 0.6 + pulse * 0.3), false, 2.0)
	# Cross-hair
	draw_line(pos - Vector2(size*0.7, 0), pos + Vector2(size*0.7, 0), Color(1.0, 0.5, 0.2, 0.8), 1.5)
	draw_line(pos - Vector2(0, size*0.7), pos + Vector2(0, size*0.7), Color(1.0, 0.5, 0.2, 0.8), 1.5)
	draw_circle(pos, 5.0, Color(1.0, 0.6, 0.2, 0.7 + pulse * 0.3))

func _draw_cargo_hold(C: Vector2, hw: float, hh: float, pulse: float) -> void:
	var r := Rect2(C - Vector2(hw, hh), Vector2(hw*2, hh*2))
	var used: float = float(GameManager.cargo_capacity - GameManager.cargo_free())
	var cap: float  = float(GameManager.cargo_capacity)
	var fill: float = used / cap if cap > 0 else 0.0
	var fill_col := Color(0.2+fill*0.6, 0.75-fill*0.4, 0.3, 0.25)
	draw_rect(r, fill_col)
	draw_rect(r, Color(0.4, 0.75, 0.35, 0.55 + pulse * 0.15), false, 1.5)
	# Fill bar inside
	var fill_r := Rect2(r.position, Vector2(r.size.x * fill, r.size.y))
	draw_rect(fill_r, Color(0.3, 0.9, 0.35, 0.18))
	# Divider lines (cargo cells)
	var cells := 5
	for ci in range(1, cells):
		var cx: float = r.position.x + r.size.x * ci / cells
		draw_line(Vector2(cx, r.position.y), Vector2(cx, r.end.y),
			Color(0.35, 0.65, 0.3, 0.35), 1.0)

func _draw_blueprint_labels(C: Vector2, ship_type: String, sc: float, accent: Color) -> void:
	var labels := [
		[C + Vector2(0,     -int(155*sc)), "МОСТИК"],
		[C + Vector2(0,     -int(35*sc)),  "РЕАКТОР"],
		[C + Vector2(0,     int(50*sc)),   "ТРЮМ"],
		[C + Vector2(0,     int(100*sc)),  "ЖИЗНЕОБЕСПЕЧЕНИЕ"],
		[C + Vector2(0,     int(170*sc)),  "ДВИГАТЕЛИ"],
	]
	var font := ThemeDB.fallback_font
	for lp in labels:
		draw_string(font, lp[0] + Vector2(-50, 5),
			lp[1], HORIZONTAL_ALIGNMENT_CENTER, 110, 11,
			Color(accent.r*0.6+0.4, accent.g*0.6+0.4, accent.b*0.4+0.5, 0.7))

	# Weapon labels
	var wx: float = 155.0 * sc
	draw_string(font, C + Vector2(-wx-20, -int(35*sc)),
		"ОРУДИЕ Л", HORIZONTAL_ALIGNMENT_CENTER, 90, 11,
		Color(1.0, 0.55, 0.25, 0.7))
	draw_string(font, C + Vector2(wx-20, -int(35*sc)),
		"ОРУДИЕ П", HORIZONTAL_ALIGNMENT_CENTER, 90, 11,
		Color(1.0, 0.55, 0.25, 0.7))

	# Measurement lines
	var hull_pts := _get_hull_pts(C, ship_type, sc)
	if not hull_pts.is_empty():
		var top_y: float = hull_pts[0].y
		var left_x: float = hull_pts[hull_pts.size()/2 + 1].x if hull_pts.size() > 4 else C.x - 180*sc
		draw_line(Vector2(left_x - 18, top_y), Vector2(left_x - 18, C.y + 200*sc),
			Color(accent.r, accent.g, accent.b, 0.18), 1.0)
		draw_line(Vector2(left_x - 24, top_y), Vector2(left_x - 12, top_y),
			Color(accent.r, accent.g, accent.b, 0.25), 1.0)

func _draw_class_badge(C: Vector2, ship_class: String, accent: Color) -> void:
	var badge_pos := C + Vector2(-SCHEMATIC_CENTER.x * 0.5, -240)
	draw_rect(Rect2(badge_pos, Vector2(90, 30)), Color(accent.r, accent.g, accent.b, 0.15))
	draw_rect(Rect2(badge_pos, Vector2(90, 30)), accent, false, 1.5)
	draw_string(ThemeDB.fallback_font, badge_pos + Vector2(6, 20),
		"КЛАСС  %s" % ship_class, HORIZONTAL_ALIGNMENT_LEFT, 82, 15, accent)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _stat_row(label: String, value: int, max_val: int) -> HBoxContainer:
	var row := HBoxContainer.new()
	var lbl := _lbl(label, 14)
	lbl.custom_minimum_size = Vector2(130, 0)
	row.add_child(lbl)
	var bar := ProgressBar.new()
	bar.max_value = max_val
	bar.value     = value
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size   = Vector2(0, 18)
	row.add_child(bar)
	var vl := _lbl(str(value), 13, Color(0.7,0.85,1.0))
	vl.custom_minimum_size = Vector2(45, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(vl)
	return row

func _lbl(text: String, size: int = 14, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l
