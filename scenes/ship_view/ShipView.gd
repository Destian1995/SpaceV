extends Node2D

var time_e: float = 0.0

# Layout constants
const SCHEMATIC_CENTER := Vector2(480, 430)
const PANEL_X          := 820.0   # right panel start X

# Hardpoint local positions (mirror of CombatScene) — x=right, y=fwd (fraction of hp_sz)
const HARDPOINT_LOCAL: Array = [
	Vector2( 0.0,   0.82),   # 0: нос
	Vector2(-0.95,  0.05),   # 1: левое крыло
	Vector2( 0.95,  0.05),   # 2: правое крыло
	Vector2( 0.0,  -0.60),   # 3: корма
	Vector2(-0.55,  0.55),   # 4: левый передний
	Vector2( 0.55,  0.55),   # 5: правый передний
]

# Weapon type colors (mirror of CombatScene)
const WEAPON_TYPE_COLOR: Dictionary = {
	"energy":       Color(0.22, 0.88, 0.55, 0.90),
	"plasma":       Color(1.0,  0.55, 0.15, 0.90),
	"emp":          Color(0.25, 0.95, 0.85, 0.90),
	"kinetic":      Color(0.85, 0.85, 0.85, 0.90),
	"railgun":      Color(0.85, 0.85, 0.85, 0.90),
	"missile":      Color(1.0,  0.85, 0.10, 0.90),
	"torpedo":      Color(1.0,  0.85, 0.10, 0.90),
	"torpedo_heavy":Color(1.0,  0.42, 0.08, 0.95),
	"turbolaser":   Color(0.45, 0.75, 1.0,  0.90),
	"pulse":        Color(0.55, 1.0,  0.55, 0.90),
}

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

	# Status tab (current ship health)
	var status_scroll := ScrollContainer.new()
	status_scroll.name = "🔴 Системы"
	status_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(status_scroll)
	var stv := VBoxContainer.new()
	stv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_scroll.add_child(stv)
	_populate_status(stv)

	# Stats tab (base characteristics)
	var stats_scroll := ScrollContainer.new()
	stats_scroll.name = "📊 Характеристики"
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

	# Personal file tab
	var dossier_scroll := ScrollContainer.new()
	dossier_scroll.name = "🎖 Личное дело"
	dossier_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(dossier_scroll)
	var dv := VBoxContainer.new()
	dv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dossier_scroll.add_child(dv)
	_populate_dossier(dv)

func _nav_btn(hb: HBoxContainer, text: String, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 15)
	btn.custom_minimum_size = Vector2(148, 0)
	btn.pressed.connect(cb)
	hb.add_child(btn)

# ── Status panel (current damage) ────────────────────────────────────────────

func _populate_status(vb: VBoxContainer) -> void:
	var ship     := GameManager.current_ship
	var hull_pct := clampf(GameManager.ship_hull_pct, 0.0, 1.0)

	vb.add_child(_lbl("ИДЕНТИФИКАЦИЯ", 13, Color(0.4, 0.6, 0.9)))
	vb.add_child(_lbl(ship.get("name", "???"), 22, Color(0.85, 0.90, 1.0)))
	vb.add_child(_lbl("%s  •  Класс %s" % [ship.get("ship_type",""), ship.get("ship_class","C")],
		15, Color(0.55, 0.65, 0.75)))
	vb.add_child(HSeparator.new())

	# Overall condition summary
	var overall_txt: String
	var overall_col: Color
	if hull_pct >= 0.90:
		overall_txt = "✅  Отличное — все системы в норме"
		overall_col = Color(0.3, 1.0, 0.45)
	elif hull_pct >= 0.65:
		overall_txt = "🟡  Лёгкие повреждения — рекомендован осмотр"
		overall_col = Color(0.95, 0.82, 0.20)
	elif hull_pct >= 0.35:
		overall_txt = "🟠  Значительные повреждения — требуется ремонт"
		overall_col = Color(1.0, 0.55, 0.12)
	else:
		overall_txt = "🔴  Критическое состояние — срочный ремонт!"
		overall_col = Color(1.0, 0.18, 0.18)
	vb.add_child(_lbl(overall_txt, 15, overall_col))
	vb.add_child(HSeparator.new())

	# Each system has its own degradation curve based on hull_pct
	# Systems degrade at different thresholds to simulate real damage spread
	vb.add_child(_lbl("СОСТОЯНИЕ СИСТЕМ", 13, Color(0.4, 0.6, 0.9)))

	var max_hull: int  = ship.get("hull", 100)
	var cur_hull: int  = maxi(1, int(hull_pct * float(max_hull)))
	_status_row(vb, "⚙  Корпус",
		cur_hull, max_hull, hull_pct)

	# Shields degrade slowly at first, then faster below 50%
	var sh_pct := clampf(0.15 + hull_pct * 0.85, 0.0, 1.0) if hull_pct < 0.5 \
		else clampf(0.5 + (hull_pct - 0.5) * 1.0, 0.0, 1.0)
	var max_sh: int = ship.get("shields", 50)
	_status_row(vb, "🔵  Щиты",
		int(sh_pct * max_sh), max_sh, sh_pct)

	# Engines: start degrading below 70%
	var eng_pct := 1.0 if hull_pct >= 0.70 \
		else clampf(0.30 + (hull_pct / 0.70) * 0.70, 0.0, 1.0)
	var max_spd: int = ship.get("speed", 200)
	_status_row(vb, "⚡  Двигатели",
		int(eng_pct * max_spd), max_spd, eng_pct)

	# Weapons: start degrading below 60%
	var wpn_pct := 1.0 if hull_pct >= 0.60 \
		else clampf(0.20 + (hull_pct / 0.60) * 0.80, 0.0, 1.0)
	_status_row(vb, "🔫  Вооружение",
		int(wpn_pct * 100), 100, wpn_pct)

	# Sensors: degrade below 80%
	var sen_pct := 1.0 if hull_pct >= 0.80 \
		else clampf(0.40 + (hull_pct / 0.80) * 0.60, 0.0, 1.0)
	var max_sen: int = ship.get("sensors", 50)
	_status_row(vb, "📡  Сенсоры",
		int(sen_pct * max_sen), max_sen, sen_pct)

	# Life support: only affected at critical hull
	var ls_pct := 1.0 if hull_pct >= 0.30 \
		else clampf(hull_pct / 0.30, 0.0, 1.0)
	_status_row(vb, "💨  Жизнеобеспечение",
		int(ls_pct * 100), 100, ls_pct)

	vb.add_child(HSeparator.new())

	# Repair cost info
	var ship_price: int = ship.get("price", 10000)
	var missing_pct := 1.0 - hull_pct
	var repair_cost := int(float(ship_price) * 0.05 * missing_pct)
	if missing_pct > 0.01:
		vb.add_child(_lbl("🔧  Стоимость полного ремонта: %d кред." % repair_cost,
			14, Color(1.0, 0.75, 0.25)))
		vb.add_child(_lbl("   (ремонт доступен в любом космопорту)", 12, Color(0.45, 0.45, 0.5)))
	else:
		vb.add_child(_lbl("🔧  Ремонт не требуется", 14, Color(0.3, 1.0, 0.45)))

	vb.add_child(HSeparator.new())
	vb.add_child(_lbl("УСТАНОВЛЕННЫЕ УЛУЧШЕНИЯ", 13, Color(0.4, 0.6, 0.9)))

	const UPG_META := {
		"volley":            ["⚡", "Синхронный залп",    "Все орудия одновременно  |  Актив: кнопка в бою",   Color(1.0, 0.85, 0.2)],
		"emergency_shields": ["🛡", "Аварийные щиты",    "−10% корпус → +щиты  |  Авто: при потере щита",    Color(0.3, 0.7,  1.0)],
		"boost":             ["🔥", "Форсаж двигателя",  "Скорость ×2.5 на 5 сек  |  Актив: кнопка в бою",   Color(1.0, 0.5,  0.1)],
		"overload":          ["💥", "Перегрузка орудий", "Следующий выстрел ×3  |  Актив: кнопка в бою",      Color(1.0, 0.3,  0.9)],
		"repair_drones":     ["🤖", "Ремонтные дроны",   "+2 HP/сек в бою  |  Пассивное — всегда активно",   Color(0.4, 1.0,  0.5)],
		"shield_injector":   ["💉", "Щитовой инжектор",  "Щиты до 50%  |  Авто: при щитах < 20%",            Color(0.2, 1.0,  0.8)],
	}

	if GameManager.ship_upgrades.is_empty():
		vb.add_child(_lbl("  Улучшений нет. Установите в космопорту (вкладка Улучшения).",
			13, Color(0.45, 0.45, 0.5)))
	else:
		for uid: String in GameManager.ship_upgrades:
			if not UPG_META.has(uid): continue
			var meta: Array = UPG_META[uid]
			var row := HBoxContainer.new()
			vb.add_child(row)
			var icon_l := _lbl(meta[0], 18)
			icon_l.custom_minimum_size = Vector2(28, 0)
			row.add_child(icon_l)
			var info_vb := VBoxContainer.new()
			info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info_vb)
			info_vb.add_child(_lbl(meta[1], 14, meta[3]))
			var detail_l := _lbl(meta[2], 11, Color(0.5, 0.6, 0.7))
			detail_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info_vb.add_child(detail_l)

func _status_row(vb: VBoxContainer, label: String, cur: int, max_v: int, pct: float) -> void:
	var row := HBoxContainer.new()
	vb.add_child(row)

	var lbl := _lbl(label, 14)
	lbl.custom_minimum_size = Vector2(175, 0)
	row.add_child(lbl)

	# Colored progress bar
	var bar := ProgressBar.new()
	bar.max_value = 100
	bar.value     = int(clampf(pct, 0.0, 1.0) * 100)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.custom_minimum_size   = Vector2(0, 20)
	# Color modulation via StyleBox
	if pct >= 0.75:
		bar.modulate = Color(0.3, 1.0, 0.45)
	elif pct >= 0.45:
		bar.modulate = Color(1.0, 0.82, 0.2)
	elif pct >= 0.20:
		bar.modulate = Color(1.0, 0.45, 0.12)
	else:
		bar.modulate = Color(1.0, 0.15, 0.15)
	row.add_child(bar)

	var pct_col := Color(0.3, 1.0, 0.45) if pct >= 0.75 else \
				  (Color(0.95, 0.82, 0.20) if pct >= 0.45 else \
				  (Color(1.0, 0.50, 0.12) if pct >= 0.20 else Color(1.0, 0.2, 0.2)))
	var val_lbl := _lbl("%d%%" % int(pct * 100), 14, pct_col)
	val_lbl.custom_minimum_size = Vector2(42, 0)
	val_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val_lbl)

	var num_lbl := _lbl("%d/%d" % [cur, max_v], 12, Color(0.45, 0.50, 0.58))
	num_lbl.custom_minimum_size = Vector2(72, 0)
	num_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(num_lbl)

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

# ── Personal file / dossier ──────────────────────────────────────────────────

func _populate_dossier(vb: VBoxContainer) -> void:
	vb.add_child(_lbl("ЛИЧНОЕ ДЕЛО КАПИТАНА", 15, Color(0.4, 0.6, 0.9)))
	vb.add_child(_lbl("Текущий корабль: %s  [%s · %s]" % [
		GameManager.current_ship.get("name","???"),
		GameManager.current_ship.get("ship_type",""),
		GameManager.current_ship.get("ship_class","C"),
	], 13, Color(0.6, 0.7, 0.8)))
	vb.add_child(_lbl("День в рейсе: %d  |  Кредитов: %d" % [
		GameManager.day, GameManager.credits], 13, Color(0.55, 0.75, 0.55)))
	vb.add_child(HSeparator.new())

	# ── Score ────────────────────────────────────────────────────────────────────
	var score: int = GameManager.get_score()
	var score_row := HBoxContainer.new()
	vb.add_child(score_row)
	var score_icon := _lbl("🏅", 20)
	score_icon.custom_minimum_size = Vector2(30, 0)
	score_row.add_child(score_icon)
	var score_name := _lbl("РЕЙТИНГ КАПИТАНА", 13, Color(0.4, 0.6, 0.9))
	score_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_row.add_child(score_name)
	var score_val := _lbl(str(score), 20, Color(1.0, 0.88, 0.2))
	score_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	score_row.add_child(score_val)
	vb.add_child(HSeparator.new())

	# ── Fuel ─────────────────────────────────────────────────────────────────────
	vb.add_child(_lbl("ТОПЛИВО", 13, Color(0.4, 0.6, 0.9)))
	var fuel_pct := GameManager.fuel / GameManager.max_fuel
	var fuel_row := HBoxContainer.new()
	vb.add_child(fuel_row)
	var fuel_lbl := _lbl("⛽  Топливо:", 14)
	fuel_lbl.custom_minimum_size = Vector2(120, 0)
	fuel_row.add_child(fuel_lbl)
	var fuel_bar := ProgressBar.new()
	fuel_bar.max_value = 100
	fuel_bar.value = int(fuel_pct * 100)
	fuel_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fuel_bar.custom_minimum_size = Vector2(0, 20)
	if fuel_pct >= 0.6:
		fuel_bar.modulate = Color(0.3, 1.0, 0.45)
	elif fuel_pct >= 0.3:
		fuel_bar.modulate = Color(1.0, 0.82, 0.2)
	else:
		fuel_bar.modulate = Color(1.0, 0.3, 0.2)
	fuel_row.add_child(fuel_bar)
	var fuel_col := Color(0.3, 1.0, 0.45) if fuel_pct >= 0.6 else \
		(Color(1.0, 0.82, 0.2) if fuel_pct >= 0.3 else Color(1.0, 0.3, 0.2))
	var fuel_num := _lbl("%.0f/%.0f" % [GameManager.fuel, GameManager.max_fuel], 13, fuel_col)
	fuel_num.custom_minimum_size = Vector2(72, 0)
	fuel_num.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fuel_row.add_child(fuel_num)
	vb.add_child(HSeparator.new())

	# ── Combat stats ─────────────────────────────────────────────────────────────
	vb.add_child(_lbl("БОЕВЫЕ ПОКАЗАТЕЛИ", 13, Color(0.4, 0.6, 0.9)))
	var stats := [
		["⚔  Нанесено урона:",     GameManager.total_damage_dealt,    Color(1.0, 0.55, 0.25)],
		["🛡  Поглощено урона:",    GameManager.total_damage_absorbed, Color(0.35, 0.65, 1.0)],
		["💀  Уничтожено кораблей:", GameManager.total_ships_destroyed, Color(0.85, 0.25, 0.25)],
		["🏆  Победных боёв:",       GameManager.total_battles_won,     Color(0.25, 0.95, 0.45)],
	]
	for st in stats:
		var row := HBoxContainer.new()
		vb.add_child(row)
		var lbl_name := _lbl(st[0], 14)
		lbl_name.custom_minimum_size = Vector2(200, 0)
		row.add_child(lbl_name)
		var lbl_val := _lbl(str(st[1]), 16, st[2])
		lbl_val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl_val)
	vb.add_child(HSeparator.new())

	# ── Faction reputation ───────────────────────────────────────────────────────
	vb.add_child(_lbl("РЕПУТАЦИЯ ФРАКЦИЙ", 13, Color(0.4, 0.6, 0.9)))
	var faction_icons := {
		"Федерация":    "🔵",
		"Торговцы":     "🟡",
		"Независимые":  "⚪",
		"Пираты":       "💀",
		"Империя":      "🔴",
		"Нет":          "—",
	}
	for faction in GameManager.faction_reputation:
		var rep: int = GameManager.faction_reputation[faction]
		var standing: String = GameManager.get_faction_standing(faction)
		var rep_pct := clampf((float(rep) + 100.0) / 200.0, 0.0, 1.0)
		var rep_col: Color
		if rep >= 50:
			rep_col = Color(0.2, 1.0, 0.45)
		elif rep >= 10:
			rep_col = Color(0.55, 0.85, 0.55)
		elif rep >= -10:
			rep_col = Color(0.65, 0.65, 0.65)
		elif rep >= -50:
			rep_col = Color(1.0, 0.55, 0.2)
		else:
			rep_col = Color(1.0, 0.2, 0.2)

		var f_row := HBoxContainer.new()
		vb.add_child(f_row)

		var icon_l := _lbl(faction_icons.get(faction, "·"), 14)
		icon_l.custom_minimum_size = Vector2(24, 0)
		f_row.add_child(icon_l)

		var name_l := _lbl(faction, 13)
		name_l.custom_minimum_size = Vector2(105, 0)
		f_row.add_child(name_l)

		var f_bar := ProgressBar.new()
		f_bar.max_value = 100
		f_bar.value = int(rep_pct * 100)
		f_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f_bar.custom_minimum_size = Vector2(0, 16)
		f_bar.modulate = rep_col
		f_row.add_child(f_bar)

		var rep_lbl := _lbl("%+d  %s" % [rep, standing], 12, rep_col)
		rep_lbl.custom_minimum_size = Vector2(108, 0)
		rep_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		f_row.add_child(rep_lbl)
	vb.add_child(HSeparator.new())

	# ── Equipment ────────────────────────────────────────────────────────────────
	vb.add_child(_lbl("СНАРЯЖЕНИЕ", 13, Color(0.4, 0.6, 0.9)))
	if GameManager.equipped_weapons.is_empty():
		vb.add_child(_lbl("  Оружие не установлено", 13, Color(0.45, 0.45, 0.5)))
	else:
		for w in GameManager.equipped_weapons:
			vb.add_child(_lbl("  ⚔  " + str(w), 14))
	vb.add_child(HSeparator.new())
	vb.add_child(_lbl("ЗАВЕРШЁННЫЕ ЗАДАНИЯ: %d" % GameManager.completed_quests.size(),
		14, Color(0.3, 0.85, 0.45)))
	if GameManager.completed_quests.is_empty():
		vb.add_child(_lbl("  Нет выполненных заданий", 13, Color(0.45, 0.45, 0.5)))
	else:
		for q in GameManager.completed_quests:
			vb.add_child(_lbl("  ✅ %s" % q.get("title","???"), 13, Color(0.55, 0.85, 0.55)))

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
	for d in 12:
		var dx: float = d * 120.0
		draw_line(Vector2(dx, 0), Vector2(dx - 200, vp.y), Color(0.06, 0.10, 0.20, 0.2), 1)

# Returns health percentages for each ship system
func _get_system_pcts() -> Dictionary:
	var h := clampf(GameManager.ship_hull_pct, 0.0, 1.0)
	var sh := clampf(0.15 + h * 0.85, 0.0, 1.0) if h < 0.5 else clampf(0.5 + (h - 0.5), 0.0, 1.0)
	var eng := 1.0 if h >= 0.70 else clampf(0.30 + (h / 0.70) * 0.70, 0.0, 1.0)
	var wpn := 1.0 if h >= 0.60 else clampf(0.20 + (h / 0.60) * 0.80, 0.0, 1.0)
	var sen := 1.0 if h >= 0.80 else clampf(0.40 + (h / 0.80) * 0.60, 0.0, 1.0)
	var ls  := 1.0 if h >= 0.30 else clampf(h / 0.30, 0.0, 1.0)
	return {"hull": h, "shields": sh, "engines": eng, "weapons": wpn, "sensors": sen, "life": ls}

# Single indicator LED — green/blue when healthy, red when damaged
func _indicator(pos: Vector2, pct: float, phase: float) -> void:
	var col: Color
	var glow_r: float
	if pct >= 0.75:
		# Healthy — slow blue/green pulse
		var t := 0.55 + sin(time_e * 0.85 + phase) * 0.38
		col = Color(0.12 + t * 0.12, 0.52 + t * 0.38, 1.0, 0.92)
		glow_r = 3.0 + t * 2.5
	elif pct >= 0.45:
		# Minor — soft yellow
		var t := 0.5 + sin(time_e * 2.0 + phase) * 0.42
		col = Color(1.0, 0.68 + t * 0.22, 0.05, 0.90)
		glow_r = 2.8 + t * 2.0
	elif pct >= 0.2:
		# Significant — orange blink
		var t := maxf(0.0, sin(time_e * 4.8 + phase))
		col = Color(1.0, 0.28 + t * 0.18, 0.02, 0.92)
		glow_r = 2.5 + t * 3.0
	else:
		# Critical — fast red flash
		var t := maxf(0.0, sin(time_e * 10.5 + phase))
		col = Color(1.0, 0.04, 0.04, 0.95)
		glow_r = 5.5 * t
	draw_circle(pos, glow_r + 4.0, Color(col.r, col.g, col.b, 0.07))
	draw_circle(pos, glow_r,       Color(col.r, col.g, col.b, 0.28))
	draw_circle(pos, 2.3,          col)
	draw_circle(pos, 1.0,          Color(1.0, 1.0, 1.0, col.a * 0.75))

func _draw_ship_blueprint(C: Vector2) -> void:
	var ship       := GameManager.current_ship
	var ship_type  : String = ship.get("ship_type", "Исследовательский")
	var ship_class : String = ship.get("ship_class", "C")
	var cls_colors := {"A": Color(1.0, 0.82, 0.1), "B": Color(0.45, 0.72, 1.0), "C": Color(0.45, 0.5, 0.6)}
	var accent     : Color  = cls_colors.get(ship_class, Color(0.45, 0.5, 0.6))
	var sc         : float  = 1.0
	match ship_type:
		"Грузовой":          sc = 1.15
		"Боевой":            sc = 1.10
		"Флагманский":       sc = 1.30
		"Ресурсодобывающий": sc = 1.05

	var pcts := _get_system_pcts()
	_draw_hull(C, ship_type, accent, sc, pcts)
	_draw_systems(C, ship_type, sc, accent, pcts)
	_draw_blueprint_labels(C, ship_type, sc, accent)
	_draw_class_badge(C, ship_class, accent)

func _draw_hull(C: Vector2, ship_type: String, accent: Color, sc: float, pcts: Dictionary) -> void:
	var hull_pts := _get_hull_pts(C, ship_type, sc)
	if hull_pts.is_empty():
		return
	var hp: float = pcts["hull"]

	# Base fill
	draw_colored_polygon(hull_pts, Color(accent.r*0.06, accent.g*0.06, accent.b*0.12, 0.78))

	# Red damage tint
	if hp < 0.65:
		draw_colored_polygon(hull_pts, Color(0.9, 0.08, 0.05, (0.65 - hp) * 0.30))

	# Outer hull glow (inner thick pass)
	var glow_pulse := 0.5 + sin(time_e * 0.6) * 0.12
	draw_polyline(hull_pts, Color(accent.r, accent.g, accent.b, 0.10 * glow_pulse), 6.0)
	draw_line(hull_pts[hull_pts.size()-1], hull_pts[0],
		Color(accent.r, accent.g, accent.b, 0.10 * glow_pulse), 6.0)

	# Main hull outline — shifts red when damaged
	var line_col := accent.lerp(Color(1.0, 0.18, 0.08), clampf((0.8 - hp) * 1.6, 0.0, 1.0))
	draw_polyline(hull_pts, Color(line_col.r, line_col.g, line_col.b, 0.82), 2.0)
	draw_line(hull_pts[hull_pts.size()-1], hull_pts[0],
		Color(line_col.r, line_col.g, line_col.b, 0.82), 2.0)

	# Damage cracks below 40%
	if hp < 0.40:
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = 7314
		for ci in 6:
			var cs := C + Vector2(rng2.randf_range(-110, 110) * sc, rng2.randf_range(-90, 90) * sc)
			var ce := cs + Vector2(rng2.randf_range(-38, 38) * sc, rng2.randf_range(-28, 28) * sc)
			var flk := maxf(0.0, sin(time_e * 7.5 + ci * 2.1)) * ((0.40 - hp) / 0.40)
			draw_line(cs, ce, Color(1.0, 0.22, 0.08, flk * 0.70), 1.5)

	# Center axis lines
	draw_dashed_line(C + Vector2(0, -int(220*sc)), C + Vector2(0, int(215*sc)),
		Color(accent.r, accent.g, accent.b, 0.20), 1.0, 10.0)
	draw_dashed_line(C + Vector2(-int(220*sc), 0), C + Vector2(int(220*sc), 0),
		Color(accent.r, accent.g, accent.b, 0.12), 1.0, 8.0)

	# Hull integrity indicators (4 corners of the schematic)
	var hi := [
		C + Vector2(-int(115*sc), -int(75*sc)),
		C + Vector2( int(115*sc), -int(75*sc)),
		C + Vector2(-int(100*sc),  int(105*sc)),
		C + Vector2( int(100*sc),  int(105*sc)),
	]
	for i in hi.size():
		_indicator(hi[i], hp, float(i) * 1.15)

func _get_hull_pts(C: Vector2, ship_type: String, sc: float) -> PackedVector2Array:
	match ship_type:
		"Боевой":
			return PackedVector2Array([
				C+Vector2(0,    -int(215*sc)), C+Vector2(30,   -int(160*sc)),
				C+Vector2(100,  -int(110*sc)), C+Vector2(210,  -int(40*sc)),
				C+Vector2(195,   int(80*sc)),  C+Vector2(140,   int(180*sc)),
				C+Vector2(55,    int(215*sc)), C+Vector2(-55,   int(215*sc)),
				C+Vector2(-140,  int(180*sc)), C+Vector2(-195,  int(80*sc)),
				C+Vector2(-210, -int(40*sc)),  C+Vector2(-100, -int(110*sc)),
				C+Vector2(-30,  -int(160*sc)),
			])
		"Грузовой":
			return PackedVector2Array([
				C+Vector2(0,    -int(180*sc)), C+Vector2(50,   -int(130*sc)),
				C+Vector2(200,  -int(70*sc)),  C+Vector2(215,   int(160*sc)),
				C+Vector2(100,   int(210*sc)), C+Vector2(-100,  int(210*sc)),
				C+Vector2(-215,  int(160*sc)), C+Vector2(-200, -int(70*sc)),
				C+Vector2(-50,  -int(130*sc)),
			])
		"Ресурсодобывающий":
			return PackedVector2Array([
				C+Vector2(0,    -int(170*sc)), C+Vector2(80,   -int(120*sc)),
				C+Vector2(195,   int(10*sc)),  C+Vector2(205,   int(120*sc)),
				C+Vector2(120,   int(210*sc)), C+Vector2(-120,  int(210*sc)),
				C+Vector2(-205,  int(120*sc)), C+Vector2(-195,  int(10*sc)),
				C+Vector2(-80,  -int(120*sc)),
			])
		"Флагманский":
			return PackedVector2Array([
				C+Vector2(0,    -int(230*sc)), C+Vector2(60,   -int(170*sc)),
				C+Vector2(200,  -int(100*sc)), C+Vector2(265,   int(40*sc)),
				C+Vector2(230,   int(160*sc)), C+Vector2(150,   int(225*sc)),
				C+Vector2(-150,  int(225*sc)), C+Vector2(-230,  int(160*sc)),
				C+Vector2(-265,  int(40*sc)),  C+Vector2(-200, -int(100*sc)),
				C+Vector2(-60,  -int(170*sc)),
			])
		_: # Исследовательский
			return PackedVector2Array([
				C+Vector2(0,    -int(205*sc)), C+Vector2(38,   -int(130*sc)),
				C+Vector2(160,  -int(55*sc)),  C+Vector2(170,   int(120*sc)),
				C+Vector2(90,    int(200*sc)), C+Vector2(-90,   int(200*sc)),
				C+Vector2(-170,  int(120*sc)), C+Vector2(-160, -int(55*sc)),
				C+Vector2(-38,  -int(130*sc)),
			])

func _draw_systems(C: Vector2, ship_type: String, sc: float, accent: Color, pcts: Dictionary) -> void:
	var s := sc

	# ── Bridge / Sensors ──────────────────────────────────────────────────────
	_draw_zone(C + Vector2(0, -int(140*s)), 38*s, 28*s, Color(0.3, 0.7, 1.0), pcts["sensors"])
	for i in 3:
		_indicator(C + Vector2((-1 + i) * int(22*s), -int(153*s)), pcts["sensors"], float(i) * 0.95)

	# ── Shield ring ───────────────────────────────────────────────────────────
	_draw_ring_zone(C, int(75*s), Color(0.2, 0.5, 0.95), pcts["shields"])

	# ── Reactor core ──────────────────────────────────────────────────────────
	_draw_zone(C + Vector2(0, -int(30*s)), 32*s, 32*s, Color(1.0, 0.85, 0.1), pcts["hull"])
	var rc := C + Vector2(0, -int(30*s))
	var r_col := Color(1.0, 0.85, 0.1) if pcts["hull"] >= 0.5 else Color(1.0, 0.32, 0.08)
	var r_spd := 1.2 if pcts["hull"] >= 0.5 else 3.5
	for ri in 3:
		var ra := time_e * r_spd + ri * TAU / 3.0
		draw_arc(rc, int(20*s), ra, ra + TAU * 0.32, 14,
			Color(r_col.r, r_col.g, r_col.b, 0.55 + sin(time_e * 3.0 + ri) * 0.28), 2.0)
	_indicator(rc, pcts["hull"], 0.0)

	# ── Engine block ──────────────────────────────────────────────────────────
	_draw_zone(C + Vector2(0, int(160*s)), int(70*s), int(30*s), Color(0.35, 0.85, 0.95), pcts["engines"])
	_draw_engine_glow(C + Vector2(0, int(190*s)), s, pcts["engines"])
	for i in 3:
		_indicator(C + Vector2((-1 + i) * int(30*s), int(158*s)), pcts["engines"], float(i) * 1.25)

	# ── Life support ──────────────────────────────────────────────────────────
	_draw_zone(C + Vector2(0, int(95*s)), int(45*s), int(22*s), Color(0.7, 0.35, 0.95), pcts["life"])
	_indicator(C + Vector2(-int(34*s), int(95*s)), pcts["life"], 0.4)
	_indicator(C + Vector2( int(34*s), int(95*s)), pcts["life"], 1.7)

	# ── Weapon hardpoints (positioned as in combat) ──────────────────────────
	_draw_weapon_hardpoints_blueprint(C, ship_type, s, pcts["weapons"])

	# ── Cargo hold ────────────────────────────────────────────────────────────
	var ch_h: float = 55.0 * s
	match ship_type:
		"Грузовой":          ch_h = 90.0 * s
		"Ресурсодобывающий": ch_h = 75.0 * s
	_draw_cargo_hold(C + Vector2(0, int(40*s)), int(80*s), ch_h)

func _draw_zone(pos: Vector2, hw: float, hh: float, col: Color, pct: float) -> void:
	var r := Rect2(pos - Vector2(hw, hh), Vector2(hw*2, hh*2))
	# Fill shifts red when damaged
	var fc := col.lerp(Color(0.8, 0.1, 0.1), clampf((0.8 - pct) * 1.4, 0.0, 0.7))
	draw_rect(r, Color(fc.r, fc.g, fc.b, 0.11))
	# Animated border
	var bp := 0.45 + sin(time_e * 1.8) * 0.22 if pct >= 0.5 \
		else (0.35 + maxf(0.0, sin(time_e * 5.5)) * 0.55)
	draw_rect(r, Color(fc.r, fc.g, fc.b, bp * 0.80), false, 1.5)
	# Corner ticks
	for corner in [r.position, Vector2(r.end.x, r.position.y),
				   Vector2(r.position.x, r.end.y), r.end]:
		var dx: float = sign(corner.x - pos.x) * 7.0
		var dy: float = sign(corner.y - pos.y) * 7.0
		draw_line(corner, corner + Vector2(dx, 0), col, 1.5)
		draw_line(corner, corner + Vector2(0, dy), col, 1.5)

func _draw_ring_zone(C: Vector2, r: float, col: Color, pct: float) -> void:
	var rc := col.lerp(Color(1.0, 0.18, 0.08), clampf((0.8 - pct) * 1.4, 0.0, 0.85))
	draw_arc(C, r,     0, TAU, 64, Color(rc.r, rc.g, rc.b, 0.28 + sin(time_e * 1.4) * 0.10), 2.0)
	draw_arc(C, r + 8, 0, TAU, 64, Color(rc.r, rc.g, rc.b, 0.10), 1.0)
	# Animated shield arc segments
	var spd := 0.38 if pct >= 0.5 else 1.8
	for seg in 6:
		var a0 := seg / 6.0 * TAU + time_e * spd
		var a1 := a0 + 0.32
		var sa  := 0.65 + sin(time_e * 2.2 + seg * 1.0) * 0.25
		draw_arc(C, r, a0, a1, 8, Color(rc.r, rc.g, rc.b, sa * (0.45 + pct * 0.55)), 3.0)
	# 6 indicator lights around the ring
	for i in 6:
		var a := float(i) / 6.0 * TAU + time_e * 0.18
		_indicator(C + Vector2(cos(a) * r, sin(a) * r), pct, float(i) * 0.85)

func _draw_engine_glow(pos: Vector2, sc: float, eng_pct: float) -> void:
	var fc := Color(0.35, 0.85, 0.95) if eng_pct >= 0.5 else Color(1.0, 0.45, 0.12)
	# Exhaust flame particles
	for fi in 6:
		var ft := fmod(time_e * 1.9 + fi * 0.21, 1.0)
		var fy := pos.y + ft * int(55 * sc)
		var fr := int(18 * sc) * (1.0 - ft) * (0.75 + sin(time_e * 9.0 + fi) * 0.22)
		var fa := (1.0 - ft) * 0.48 * eng_pct
		draw_circle(Vector2(pos.x, fy), fr, Color(fc.r, fc.g, fc.b, fa))
	# Nozzle core glow
	var np := 0.5 + sin(time_e * 4.8) * 0.42
	draw_circle(pos, int(20 * sc), Color(fc.r, fc.g, fc.b, np * 0.28))
	draw_circle(pos, int(11 * sc), Color(fc.r, fc.g, fc.b, np * 0.60))
	draw_circle(pos, int(5  * sc), Color(1.0,  1.0,  1.0,  np * 0.50))

func _draw_weapon_hardpoints_blueprint(C: Vector2, ship_type: String, sc: float, wpn_pct: float) -> void:
	# Scale that maps HARDPOINT_LOCAL fractions to blueprint pixels
	var hp_sz: float = 165.0 * sc
	match ship_type:
		"Боевой":            hp_sz = 195.0 * sc
		"Грузовой":          hp_sz = 200.0 * sc
		"Флагманский":       hp_sz = 230.0 * sc
		"Ресурсодобывающий": hp_sz = 178.0 * sc

	var weapons: Array = GameManager.equipped_weapons
	var font := ThemeDB.fallback_font

	# If no weapons — show all 6 slots as empty/dimmed
	var n: int = maxi(weapons.size(), 0)

	for si in HARDPOINT_LOCAL.size():
		var loc: Vector2 = HARDPOINT_LOCAL[si]
		# In blueprint: forward = up (-y), right = right (+x)
		var hp_pos: Vector2 = C + Vector2(loc.x * hp_sz, -loc.y * hp_sz)

		if si < n:
			# Slot is armed — draw with weapon color + name
			var wname: String = str(weapons[si])
			var is_dmg: bool  = si in GameManager.damaged_weapons
			var wtype: String = _get_weapon_type(wname)
			var wc: Color     = WEAPON_TYPE_COLOR.get(wtype, Color(0.22, 0.88, 0.55, 0.90))
			_draw_weapon_hp(hp_pos, wc if not is_dmg else Color(1.0, 0.18, 0.12), wpn_pct if not is_dmg else 0.1)

			# Weapon name label
			var label_offset := Vector2(-55, 14) if loc.y < 0 else Vector2(-55, -22)
			draw_string(font, hp_pos + label_offset,
				wname, HORIZONTAL_ALIGNMENT_CENTER, 115, 10,
				Color(wc.r * 0.7 + 0.3, wc.g * 0.7 + 0.3, wc.b * 0.5 + 0.3, 0.82))
			# Slot number
			draw_string(font, hp_pos + Vector2(-8, -18),
				"#%d" % (si + 1), HORIZONTAL_ALIGNMENT_LEFT, 30, 9,
				Color(wc.r, wc.g, wc.b, 0.55))
		else:
			# Empty slot — dimmed grey box
			var sp := 12.0
			draw_rect(Rect2(hp_pos - Vector2(sp, sp), Vector2(sp*2, sp*2)),
				Color(0.2, 0.2, 0.25, 0.15))
			draw_rect(Rect2(hp_pos - Vector2(sp, sp), Vector2(sp*2, sp*2)),
				Color(0.3, 0.3, 0.38, 0.30), false, 1.0)
			draw_line(hp_pos - Vector2(sp*0.6, 0), hp_pos + Vector2(sp*0.6, 0),
				Color(0.3, 0.3, 0.4, 0.35), 1.0)
			draw_line(hp_pos - Vector2(0, sp*0.6), hp_pos + Vector2(0, sp*0.6),
				Color(0.3, 0.3, 0.4, 0.35), 1.0)
			draw_string(font, hp_pos + Vector2(-28, 20),
				"ПУСТО", HORIZONTAL_ALIGNMENT_CENTER, 58, 9,
				Color(0.35, 0.35, 0.42, 0.55))

func _get_weapon_type(wname: String) -> String:
	for w in GameData.WEAPONS:
		if w.get("name", "") == wname:
			return w.get("type", "energy")
	return "energy"

func _draw_weapon_hp(pos: Vector2, col: Color, wpn_pct: float) -> void:
	var size := 18.0
	var wc := col.lerp(Color(1.0, 0.1, 0.1), clampf((0.8 - wpn_pct) * 1.5, 0.0, 0.85))
	var pulse := 0.52 + sin(time_e * 2.6) * 0.30 if wpn_pct >= 0.5 \
		else (0.35 + maxf(0.0, sin(time_e * 7.5)) * 0.55)
	draw_rect(Rect2(pos - Vector2(size, size), Vector2(size*2, size*2)),
		Color(wc.r, wc.g, wc.b, 0.13))
	draw_rect(Rect2(pos - Vector2(size, size), Vector2(size*2, size*2)),
		Color(wc.r, wc.g, wc.b, 0.55 + pulse * 0.28), false, 2.0)
	# Crosshair
	draw_line(pos - Vector2(size*0.72, 0), pos + Vector2(size*0.72, 0),
		Color(wc.r, wc.g, wc.b, 0.85), 1.5)
	draw_line(pos - Vector2(0, size*0.72), pos + Vector2(0, size*0.72),
		Color(wc.r, wc.g, wc.b, 0.85), 1.5)
	# Rotating targeting arcs
	var rot := time_e * (0.75 if wpn_pct >= 0.5 else 3.2)
	for ri in 4:
		var ra := rot + ri * TAU * 0.25
		draw_line(pos + Vector2(cos(ra), sin(ra)) * size * 0.50,
				  pos + Vector2(cos(ra), sin(ra)) * size * 0.88,
				  Color(wc.r, wc.g, wc.b, pulse * 0.92), 1.5)
	_indicator(pos, wpn_pct, 2.2)

func _draw_cargo_hold(C: Vector2, hw: float, hh: float) -> void:
	var r := Rect2(C - Vector2(hw, hh), Vector2(hw*2, hh*2))
	var used : float = float(GameManager.cargo_capacity - GameManager.cargo_free())
	var cap  : float = float(GameManager.cargo_capacity)
	var fill : float = used / cap if cap > 0 else 0.0
	draw_rect(r, Color(0.2 + fill * 0.6, 0.75 - fill * 0.4, 0.3, 0.25))
	var cp := 0.45 + sin(time_e * 0.95) * 0.12
	draw_rect(r, Color(0.4, 0.75, 0.35, 0.52 + cp * 0.12), false, 1.5)
	draw_rect(Rect2(r.position, Vector2(r.size.x * fill, r.size.y)), Color(0.3, 0.9, 0.35, 0.18))
	for ci in range(1, 5):
		var cx: float = r.position.x + r.size.x * ci / 5
		draw_line(Vector2(cx, r.position.y), Vector2(cx, r.end.y), Color(0.35, 0.65, 0.3, 0.35), 1.0)

func _draw_blueprint_labels(C: Vector2, ship_type: String, sc: float, accent: Color) -> void:
	var labels := [
		[C + Vector2(0, -int(155*sc)), "МОСТИК"],
		[C + Vector2(0, -int(35*sc)),  "РЕАКТОР"],
		[C + Vector2(0,  int(50*sc)),  "ТРЮМ"],
		[C + Vector2(0,  int(100*sc)), "ЖИЗНЕОБЕСПЕЧЕНИЕ"],
		[C + Vector2(0,  int(170*sc)), "ДВИГАТЕЛИ"],
	]
	var font := ThemeDB.fallback_font
	for lp in labels:
		draw_string(font, lp[0] + Vector2(-50, 5),
			lp[1], HORIZONTAL_ALIGNMENT_CENTER, 110, 11,
			Color(accent.r*0.6+0.4, accent.g*0.6+0.4, accent.b*0.4+0.5, 0.72))
	# Weapon labels shown dynamically by _draw_weapon_hardpoints_blueprint
	var hull_pts := _get_hull_pts(C, ship_type, sc)
	if not hull_pts.is_empty():
		var top_y : float = hull_pts[0].y
		var left_x: float = hull_pts[hull_pts.size()/2 + 1].x if hull_pts.size() > 4 else C.x - 180*sc
		draw_line(Vector2(left_x - 18, top_y), Vector2(left_x - 18, C.y + 200*sc),
			Color(accent.r, accent.g, accent.b, 0.18), 1.0)
		draw_line(Vector2(left_x - 24, top_y), Vector2(left_x - 12, top_y),
			Color(accent.r, accent.g, accent.b, 0.26), 1.0)

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
