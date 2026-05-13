extends CanvasLayer

signal spaceport_closed()

var current_planet: Dictionary = {}

# Built UI refs
var _title_lbl:    Label
var _credits_lbl:  Label
var _trade_list:   VBoxContainer
var _weapons_list: VBoxContainer
var _ships_list:   VBoxContainer
var _quests_list:  VBoxContainer
var _bar_list:     VBoxContainer
var _bank_list:    VBoxContainer
var _repair_list:    VBoxContainer
var _upgrades_list:  VBoxContainer
var _hq_list:        VBoxContainer

func _ready() -> void:
	layer = 10
	_build_ui()

func _build_ui() -> void:
	# Full-screen dark overlay
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.82)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Centered main panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.offset_left   = 160
	panel.offset_top    = 80
	panel.offset_right  = -160
	panel.offset_bottom = -80
	add_child(panel)

	var root_vbox := VBoxContainer.new()
	panel.add_child(root_vbox)

	# ── Header ──────────────────────────────────────────────
	var header := HBoxContainer.new()
	root_vbox.add_child(header)

	_title_lbl = Label.new()
	_title_lbl.text = "Космопорт"
	_title_lbl.add_theme_font_size_override("font_size", 26)
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title_lbl)

	_credits_lbl = Label.new()
	_credits_lbl.add_theme_font_size_override("font_size", 18)
	_credits_lbl.custom_minimum_size = Vector2(200, 0)
	_credits_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_credits_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕  Покинуть"
	close_btn.add_theme_font_size_override("font_size", 17)
	close_btn.custom_minimum_size = Vector2(150, 0)
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	root_vbox.add_child(HSeparator.new())

	# ── Tabs ────────────────────────────────────────────────
	var tabs := TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(tabs)

	_bar_list      = _make_scroll_tab(tabs, "🍺 Бар")
	_trade_list    = _make_scroll_tab(tabs, "💰 Торговля")
	_weapons_list  = _make_scroll_tab(tabs, "⚔ Оружие")
	_ships_list    = _make_scroll_tab(tabs, "🚀 Корабли")
	_quests_list   = _make_scroll_tab(tabs, "📋 Задания")
	_bank_list     = _make_scroll_tab(tabs, "🏦 Банк")
	_repair_list   = _make_scroll_tab(tabs, "🔧 Ремонт")
	_upgrades_list = _make_scroll_tab(tabs, "🔬 Улучшения")
	_hq_list       = _make_scroll_tab(tabs, "🏛 Штаб")

func _make_scroll_tab(tabs: TabContainer, tab_name: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = tab_name
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tabs.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	return vbox

# ── Public API ───────────────────────────────────────────────────────────────

func open_spaceport(planet: Dictionary) -> void:
	current_planet = planet
	_title_lbl.text = "⚓ Космопорт — " + planet["name"]
	_refresh_credits()
	_populate_bar()
	_populate_trade()
	_populate_weapons()
	_populate_ships()
	_populate_quests()
	_populate_bank()
	_populate_repair()
	_populate_upgrades()
	_populate_hq()
	visible = true

func _on_close() -> void:
	visible = false
	spaceport_closed.emit()

func _refresh_credits() -> void:
	_credits_lbl.text = "💰 %d кред.  |  Груз: %d/%d" % [
		GameManager.credits,
		GameManager.cargo_capacity - GameManager.cargo_free(),
		GameManager.cargo_capacity
	]

# ── Trade ────────────────────────────────────────────────────────────────────

func _populate_trade() -> void:
	_clear(_trade_list)
	var goods: Dictionary = current_planet.get("goods", {})
	if goods.is_empty():
		_trade_list.add_child(_lbl("Товаров нет", 16))
		return

	# Header row
	var hdr := HBoxContainer.new()
	for pair in [["Товар", 200], ["Купить", 140], ["Продать", 140], ["Склад", 80]]:
		var l := _lbl(pair[0], 13)
		l.custom_minimum_size = Vector2(pair[1], 0)
		l.add_theme_color_override("font_color", Color(0.5, 0.8, 1.0))
		hdr.add_child(l)
	_trade_list.add_child(hdr)
	_trade_list.add_child(HSeparator.new())

	for item_name in goods:
		var d = goods[item_name]
		var row := HBoxContainer.new()

		var name_lbl := _lbl(item_name, 16)
		name_lbl.custom_minimum_size = Vector2(200, 0)
		row.add_child(name_lbl)

		var buy_lbl := _lbl("%d к." % d["buy_price"], 15)
		buy_lbl.custom_minimum_size = Vector2(140, 0)
		row.add_child(buy_lbl)

		var sell_lbl := _lbl("%d к." % d["sell_price"], 15)
		sell_lbl.custom_minimum_size = Vector2(140, 0)
		row.add_child(sell_lbl)

		var stock_lbl := _lbl("×%d" % d["stock"], 14)
		stock_lbl.custom_minimum_size = Vector2(80, 0)
		row.add_child(stock_lbl)

		var buy_btn := Button.new()
		buy_btn.text = "Купить"
		buy_btn.disabled = GameManager.credits < d["buy_price"] or d["stock"] <= 0 or GameManager.cargo_free() <= 0
		buy_btn.pressed.connect(_buy_good.bind(item_name, d))
		row.add_child(buy_btn)

		var sell_btn := Button.new()
		sell_btn.text = "Продать"
		sell_btn.disabled = not GameManager.cargo.has(item_name)
		sell_btn.pressed.connect(_sell_good.bind(item_name, d))
		row.add_child(sell_btn)

		_trade_list.add_child(row)

func _buy_good(item_name: String, d: Dictionary) -> void:
	if GameManager.spend_credits(d["buy_price"]) and GameManager.add_cargo(item_name, 1):
		d["stock"] -= 1
		_populate_trade()
		_refresh_credits()

func _sell_good(item_name: String, d: Dictionary) -> void:
	if GameManager.remove_cargo(item_name, 1):
		GameManager.add_credits(d["sell_price"])
		d["stock"] += 1
		_populate_trade()
		_refresh_credits()

# ── Weapons ──────────────────────────────────────────────────────────────────

func _populate_weapons() -> void:
	_clear(_weapons_list)
	var ship    := GameManager.current_ship
	var slots   := GameData.get_ship_weapon_slots(ship)
	var allowed := GameData.get_ship_allowed_cats(ship)
	var used    := GameManager.equipped_weapons.size()

	# ── Slot header ────────────────────────────────────────────────────────
	var slot_hb := HBoxContainer.new()
	_weapons_list.add_child(slot_hb)

	var slot_col := Color(0.3, 1.0, 0.5) if used < slots else Color(1.0, 0.4, 0.3)
	slot_hb.add_child(_lbl("🔫 Слоты: %d / %d" % [used, slots], 17, slot_col))

	var cat_ru := {"light": "лёгкое", "medium": "среднее", "heavy": "тяжёлое", "superheavy": "сверхтяжёлое"}
	var allowed_str := "  |  Разрешено: " + ", ".join(allowed.map(func(c): return cat_ru.get(c, c)))
	slot_hb.add_child(_lbl(allowed_str, 13, Color(0.55, 0.75, 1.0)))

	# ── Installed weapons ───────────────────────────────────────────────────
	if not GameManager.equipped_weapons.is_empty():
		_weapons_list.add_child(_lbl("— Установлено —", 13, Color(0.5, 0.5, 0.5)))
		for wname in GameManager.equipped_weapons.duplicate():
			var row := HBoxContainer.new()
			row.add_child(_lbl("✅ " + wname, 15))
			var rm := Button.new()
			rm.text = "Снять"
			rm.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
			rm.pressed.connect(_remove_weapon.bind(wname))
			row.add_child(rm)
			_weapons_list.add_child(row)
		_weapons_list.add_child(HSeparator.new())

	# ── Shop ───────────────────────────────────────────────────────────────
	var available: Array = current_planet.get("weapons", GameData.WEAPONS)
	if available.is_empty():
		_weapons_list.add_child(_lbl("Оружия нет в продаже", 16))
		return

	_weapons_list.add_child(_lbl("— В продаже —", 13, Color(0.5, 0.5, 0.5)))

	var cat_icon := {"light": "🔹", "medium": "🔶", "heavy": "🔴", "superheavy": "💀"}
	for w in available:
		var owned:    bool   = w["name"] in GameManager.equipped_weapons
		var cat:      String = GameData.WEAPON_CATEGORY.get(w["name"], "medium")
		var err:      String = GameData.can_equip_weapon(ship, w, GameManager.equipped_weapons)
		var cat_label: String = cat_icon.get(cat, "◆") + " " + cat_ru.get(cat, cat)

		var card := _make_item_card(
			w["name"],
			w["desc"] + "   " + cat_label,
			"Урон: %d  |  Тип: %s" % [w["damage"], w["type"]],
			w["price"],
			"✅ Установлено" if owned else ("🔒 " + err if err != "" else "Купить"),
			owned or err != "",
			func(): _buy_weapon(w)
		)
		_weapons_list.add_child(card)

func _buy_weapon(w: Dictionary) -> void:
	var err := GameData.can_equip_weapon(GameManager.current_ship, w, GameManager.equipped_weapons)
	if err != "" or w["name"] in GameManager.equipped_weapons:
		return
	if GameManager.spend_credits(w["price"]):
		GameManager.equipped_weapons.append(w["name"])
		_populate_weapons()
		_refresh_credits()

func _remove_weapon(wname: String) -> void:
	GameManager.equipped_weapons.erase(wname)
	_populate_weapons()
	_refresh_credits()

# ── Ships ────────────────────────────────────────────────────────────────────

func _populate_ships() -> void:
	_clear(_ships_list)
	var available: Array = current_planet.get("ships", GameData.SHIPS)
	if available.is_empty():
		_ships_list.add_child(_lbl("Кораблей нет в продаже", 16))
		return
	for s in available:
		var owned: bool = GameManager.current_ship["name"] == s["name"]
		var card := _make_item_card(
			s["name"],
			s["desc"],
			"Скорость: %d  |  Груз: %d  |  Броня: %d" % [s["speed"], s["cargo"], s["hull"]],
			s["price"],
			"✅ Ваш корабль" if owned else "Купить",
			owned,
			func(): _buy_ship(s)
		)
		_ships_list.add_child(card)

func _buy_ship(s: Dictionary) -> void:
	if GameManager.current_ship["name"] == s["name"]:
		return
	if GameManager.spend_credits(s["price"]):
		GameManager.current_ship = s.duplicate()
		GameManager.cargo_capacity = s["cargo"]
		GameManager.ship_upgrades.clear()   # улучшения привязаны к кораблю
		GameManager.ship_hull_pct = 1.0     # новый корабль — целый корпус
		GameManager.damaged_weapons.clear() # новый корабль — орудия целые
		GameManager.weapon_ammo_state.clear()  # сбрасываем боезапас на дефолт
		_populate_ships()
		_populate_weapons()
		_populate_upgrades()
		_populate_repair()
		_refresh_credits()
		print("[Spaceport] Ship purchased: %s" % s["name"])

# ── Bar ──────────────────────────────────────────────────────────────────────

const BAR_NEWS := [
	"«Пираты снова активизировались в секторе Scarlet Nebula. Торговцам советуют обходить стороной.»",
	"«Федерация объявила награду за головы лидеров группировки 'Железный Кулак'.»",
	"«Говорят, в системе Echo Void видели корабль-призрак. Никто не вернулся чтобы рассказать подробнее.»",
	"«Цены на Электронику резко выросли после инцидента на заводе в Krath Station.»",
	"«Империя вербует наёмников для 'спецоперации'. Подробности засекречены.»",
	"«Торговый союз открыл новый маршрут через Nova Reach. Пошлины снижены на 20%.»",
	"«Сигнал SOS из сектора 7-G. Спасательная служба перегружена — есть возможность заработать.»",
	"«Говорят, капитан по имени Зарра нашла древний артефакт. Цена — астрономическая.»",
	"«Рейдеры угнали три грузовика с медикаментами. Больница на Vega Drift в отчаянии.»",
	"«В системе Pyrox обнаружены новые залежи редкой руды. Горнодобытчики уже летят туда.»",
	"«Молодой пилот поставил рекорд скорости на маршруте Sol Prime — Auren Gate. Невероятно.»",
	"«Фракция Независимых заявила о суверенитете над тремя новыми системами. Федерация не признаёт.»",
]

const BARTENDER_GREETINGS := [
	"Добро пожаловать, капитан. Что будешь?",
	"Давно не видел таких усталых глаз. Садись, расскажу новости.",
	"Хочешь знать что происходит в галактике? Ты пришёл по адресу.",
	"Сегодня народу много. Слухов — ещё больше.",
	"Осторожно с тем что слышишь здесь. Но кое-что — чистая правда.",
]

func _populate_bar() -> void:
	_clear(_bar_list)
	var planet_name: String = current_planet.get("name", "???")
	var galaxy_name: String = GameManager.current_galaxy

	# ── Bartender greeting ───────────────────────────────────────────────
	var header_hb := HBoxContainer.new()
	_bar_list.add_child(header_hb)

	var avatar_lbl := _lbl("🍺", 36)
	avatar_lbl.custom_minimum_size = Vector2(50, 0)
	header_hb.add_child(avatar_lbl)

	var greet_vb := VBoxContainer.new()
	greet_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hb.add_child(greet_vb)

	var bartender_lbl := _lbl("Бармен Гус", 17, Color(0.9, 0.7, 0.3))
	greet_vb.add_child(bartender_lbl)
	var greeting_lbl := _lbl("«%s»" % BAR_GREETINGS_PICK(planet_name), 14, Color(0.75, 0.75, 0.75))
	greeting_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	greet_vb.add_child(greeting_lbl)

	_bar_list.add_child(HSeparator.new())

	# ── Active quests completable HERE ───────────────────────────────────
	var completable: Array = []
	for q in GameManager.active_quests:
		# Travel quests: any spaceport in dest_galaxy
		var matches_galaxy: bool = (q.get("dest_galaxy","") == galaxy_name and not q.get("is_local", false))
		# Local quests: bar at origin planet/galaxy
		var is_local_here: bool = (q.get("is_local", false) and q.get("origin_galaxy","") == galaxy_name)
		if matches_galaxy or is_local_here:
			completable.append(q)

	if not completable.is_empty():
		var complete_hdr := _lbl("✅ ЗАДАНИЯ К ВЫПОЛНЕНИЮ", 16, Color(0.3, 1.0, 0.5))
		_bar_list.add_child(complete_hdr)

		for q in completable:
			var card := _make_complete_card(q)
			_bar_list.add_child(card)

		_bar_list.add_child(HSeparator.new())

	# ── News board ───────────────────────────────────────────────────────
	var news_hdr := _lbl("📰 НОВОСТИ И СЛУХИ", 16, Color(0.6, 0.8, 1.0))
	_bar_list.add_child(news_hdr)

	# Show 3-4 random news for this port (seeded by planet so consistent)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(planet_name + "_bar")
	var news_pool := BAR_NEWS.duplicate()
	var news_count: int = rng.randi_range(3, 4)
	for _i in news_count:
		var idx: int = rng.randi() % news_pool.size()
		var news_text: String = news_pool[idx]
		news_pool.remove_at(idx)

		var news_card := PanelContainer.new()
		news_card.custom_minimum_size = Vector2(0, 48)
		var hb := HBoxContainer.new()
		news_card.add_child(hb)

		var icon_l := _lbl("📡", 20)
		icon_l.custom_minimum_size = Vector2(38, 0)
		hb.add_child(icon_l)

		var news_l := _lbl(news_text, 14, Color(0.72, 0.72, 0.72))
		news_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		news_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(news_l)

		_bar_list.add_child(news_card)

	_populate_factions()

func _populate_factions() -> void:
	# ── Фракционный офицер ───────────────────────────────────────────────────────
	_bar_list.add_child(HSeparator.new())
	var fac_hdr := HBoxContainer.new()
	_bar_list.add_child(fac_hdr)
	var fac_icon := _lbl("⚔", 28)
	fac_icon.custom_minimum_size = Vector2(40, 0)
	fac_hdr.add_child(fac_icon)
	var fac_title_vb := VBoxContainer.new()
	fac_title_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fac_hdr.add_child(fac_title_vb)
	fac_title_vb.add_child(_lbl("ФРАКЦИОННЫЙ ОФИЦЕР", 17, Color(0.9, 0.82, 0.3)))
	fac_title_vb.add_child(_lbl("«Хочешь служить или командовать — у меня есть предложения.»", 12, Color(0.65, 0.65, 0.65)))

	_bar_list.add_child(HSeparator.new())

	# Текущее членство
	if GameManager.player_faction != "":
		var is_leader: bool = GameManager.faction_leader_of == GameManager.player_faction
		var status_txt := "👑 ВЫ — ОСНОВАТЕЛЬ  «%s»" % GameManager.player_faction if is_leader \
			else "✅ Вы состоите во фракции  «%s»" % GameManager.player_faction
		var status_col := Color(1.0, 0.88, 0.2) if is_leader else Color(0.3, 1.0, 0.55)
		_bar_list.add_child(_lbl(status_txt, 16, status_col))

		var leave_row := HBoxContainer.new()
		_bar_list.add_child(leave_row)
		leave_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var leave_btn := Button.new()
		leave_btn.text = "Покинуть фракцию"
		leave_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
		leave_btn.custom_minimum_size = Vector2(200, 40)
		leave_btn.pressed.connect(func():
			GameManager.faction_leave()
			_populate_bar()
			_refresh_credits())
		leave_row.add_child(leave_btn)
		return

	# Список фракций для вступления
	_bar_list.add_child(_lbl("ВСТУПИТЬ В ФРАКЦИЮ", 14, Color(0.55, 0.75, 1.0)))
	_bar_list.add_child(_lbl("  Требуется репутация ≥ 25 (Дружественный). Штаб-квартира указана в скобках.", 12, Color(0.5, 0.5, 0.55)))
	_bar_list.add_child(HSeparator.new())

	const FACTION_HQ := {
		"Федерация":   "Sol Prime",
		"Торговцы":    "Auren Gate",
		"Независимые": "Nova Reach",
		"Пираты":      "Scarlet Nebula",
		"Империя":     "Orion Breach",
	}
	const FACTION_ICONS := {
		"Федерация":   "🔵",
		"Торговцы":    "🟡",
		"Независимые": "⚪",
		"Пираты":      "💀",
		"Империя":     "🔴",
	}
	const FACTION_DESC := {
		"Федерация":   "Порядок, закон, защита. Бонусы в безопасных системах.",
		"Торговцы":    "Торговые маршруты, скидки, информация о рынках.",
		"Независимые": "Свобода, нейтралитет. Доступ в закрытые зоны.",
		"Пираты":      "Высокая прибыль, высокий риск. Все против тебя.",
		"Империя":     "Мощь, ресурсы, жёсткая дисциплина. Экспансия.",
	}

	for faction in FACTION_HQ:
		var rep: int = GameManager.faction_reputation.get(faction, 0)
		var standing: String = GameManager.get_faction_standing(faction)
		var can_join: bool = rep >= GameManager.FACTION_JOIN_REP
		var hq: String = FACTION_HQ[faction]

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 72)
		var hb := HBoxContainer.new()
		card.add_child(hb)

		var ico_l := _lbl(FACTION_ICONS.get(faction, "·"), 26)
		ico_l.custom_minimum_size = Vector2(42, 0)
		ico_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hb.add_child(ico_l)

		var info_vb := VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(info_vb)

		var name_row := HBoxContainer.new()
		info_vb.add_child(name_row)
		name_row.add_child(_lbl(faction, 17))
		var hq_l := _lbl("  HQ: %s" % hq, 12, Color(0.5, 0.7, 0.5))
		name_row.add_child(hq_l)

		var rep_col := Color(0.3, 1.0, 0.45) if rep >= 25 else (Color(1.0, 0.82, 0.2) if rep >= -10 else Color(1.0, 0.4, 0.3))
		info_vb.add_child(_lbl(FACTION_DESC.get(faction, ""), 12, Color(0.65, 0.65, 0.65)))
		info_vb.add_child(_lbl("Репутация: %+d  (%s)" % [rep, standing], 13, rep_col))

		var btn := Button.new()
		btn.custom_minimum_size = Vector2(160, 0)
		if can_join:
			btn.text = "✅ Вступить"
			btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
		else:
			var need := GameManager.FACTION_JOIN_REP - rep
			btn.text = "🔒  нужно +%d реп." % need
			btn.disabled = true
		var f_cap: String = faction
		btn.pressed.connect(func():
			if GameManager.faction_join(f_cap):
				_populate_bar()
				_populate_ships()
				_populate_hq()
				_refresh_credits())
		hb.add_child(btn)

		_bar_list.add_child(card)

	# Создать свою фракцию
	_bar_list.add_child(HSeparator.new())
	_bar_list.add_child(_lbl("СОЗДАТЬ СВОЮ ФРАКЦИЮ", 14, Color(1.0, 0.85, 0.3)))
	_bar_list.add_child(_lbl("  Стоимость: %d кред. Выберите безопасную звёздную систему для штаб-квартиры." % GameManager.FACTION_CREATE_COST,
		12, Color(0.55, 0.55, 0.6)))
	_bar_list.add_child(_lbl("  ⚠ Штаб можно основать только в системе без активных врагов (опасность ≤ 2, мирная фракция).",
		12, Color(0.7, 0.6, 0.3)))

	var create_row := HBoxContainer.new()
	_bar_list.add_child(create_row)
	create_row.add_child(_lbl("Название:", 14))
	var name_input := LineEdit.new()
	name_input.placeholder_text = "введи название..."
	name_input.custom_minimum_size = Vector2(200, 0)
	name_input.max_length = 30
	create_row.add_child(name_input)

	# Выбор звёздной системы для штаба (безопасные системы без врагов)
	create_row.add_child(_lbl("  Штаб:", 14))
	var hq_opt := OptionButton.new()
	hq_opt.custom_minimum_size = Vector2(200, 0)
	hq_opt.add_theme_font_size_override("font_size", 13)
	for sys_info in HQ_ELIGIBLE_SYSTEMS:
		hq_opt.add_item("🌟 %s  [Опасность %d]" % [sys_info["name"], sys_info["danger"]])
	create_row.add_child(hq_opt)

	var create_btn := Button.new()
	create_btn.text = "👑  Основать (%d к.)" % GameManager.FACTION_CREATE_COST
	create_btn.add_theme_color_override("font_color", Color(1.0, 0.88, 0.2))
	create_btn.disabled = GameManager.credits < GameManager.FACTION_CREATE_COST
	create_btn.pressed.connect(func():
		var fname: String = name_input.text.strip_edges()
		if fname.is_empty(): return
		var chosen_sys: String = HQ_ELIGIBLE_SYSTEMS[hq_opt.selected]["name"]
		if GameManager.faction_create(fname, chosen_sys):
			_populate_bar()
			_populate_ships()
			_populate_hq()
			_refresh_credits())
	create_row.add_child(create_btn)

func _make_complete_card(q: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 90)
	var hb := HBoxContainer.new()
	card.add_child(hb)

	var icon_l := _lbl(q.get("icon","📋"), 32)
	icon_l.custom_minimum_size = Vector2(52, 0)
	icon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hb.add_child(icon_l)

	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(info_vb)

	info_vb.add_child(_lbl(q["title"], 19))
	info_vb.add_child(_lbl("Выдано: %s / %s" % [q.get("origin_galaxy","?"), q.get("origin","?")], 12, Color(0.5,0.5,0.5)))
	info_vb.add_child(_lbl("💰 Награда: %d кред." % q["reward"], 16, Color(1.0, 0.88, 0.25)))

	# Check conditions
	var fail_reason: String = GameData.check_quest_conditions(q)
	var can_complete: bool  = fail_reason.is_empty()

	var right_vb := VBoxContainer.new()
	right_vb.custom_minimum_size = Vector2(240, 0)
	hb.add_child(right_vb)

	if not can_complete:
		var reason_l := _lbl("⚠ " + fail_reason, 13, Color(1.0, 0.5, 0.3))
		reason_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		right_vb.add_child(reason_l)

	var btn := Button.new()
	btn.text = "✅ ПОЛУЧИТЬ НАГРАДУ" if can_complete else "🔒 Условия не выполнены"
	btn.add_theme_font_size_override("font_size", 15)
	btn.disabled = not can_complete
	if can_complete:
		btn.add_theme_color_override("font_color", Color(0.2, 1.0, 0.45))
	btn.custom_minimum_size = Vector2(230, 44)
	btn.pressed.connect(_complete_quest_bar.bind(q))
	right_vb.add_child(btn)

	return card

func _complete_quest_bar(q: Dictionary) -> void:
	# Consume cargo if needed
	var cond: Dictionary = q.get("conditions", {})
	if cond.get("type","") == "cargo_and_travel":
		GameManager.remove_cargo(cond.get("item",""), cond.get("amount", 0))
	GameManager.active_quests.erase(q)
	GameManager.completed_quests.append(q)
	GameManager.add_credits(q["reward"])

	# Репутация: +8 к фракции текущей системы, +4 к фракции выдавшей задание (если отличается)
	var dest_faction: String = GameManager.current_faction
	GameManager.change_reputation(dest_faction, 8)
	var origin_faction: String = q.get("origin_faction", "")
	if origin_faction != "" and origin_faction != dest_faction:
		GameManager.change_reputation(origin_faction, 4)

	print("[Bar] Quest completed: %s  +%d кред.  +реп %s" % [q["title"], q["reward"], dest_faction])
	_populate_bar()
	_refresh_credits()

# Helper: pick greeting seeded by planet
func BAR_GREETINGS_PICK(planet_name: String) -> String:
	return BARTENDER_GREETINGS[hash(planet_name) % BARTENDER_GREETINGS.size()]

func BAR_BARTENDER_COUNT() -> int:
	return BARTENDER_GREETINGS.size()

# ── Quests ───────────────────────────────────────────────────────────────────

func _populate_quests() -> void:
	_clear(_quests_list)
	var quests: Array = current_planet.get("quests", [])
	if quests.is_empty():
		_quests_list.add_child(_lbl("Заданий нет", 16))
		return

	# Header
	var hdr := _lbl("Доступные задания в %s" % current_planet.get("name", ""), 14)
	hdr.add_theme_color_override("font_color", Color(0.5, 0.75, 1.0))
	_quests_list.add_child(hdr)
	_quests_list.add_child(HSeparator.new())

	for q in quests:
		var card := _make_quest_card(q)
		_quests_list.add_child(card)

func _make_quest_card(q: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)

	var hb := HBoxContainer.new()
	card.add_child(hb)

	# Icon column
	var icon_lbl := _lbl(q.get("icon", "📋"), 36)
	icon_lbl.custom_minimum_size = Vector2(58, 0)
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hb.add_child(icon_lbl)

	var sep := VSeparator.new()
	hb.add_child(sep)

	# Info column
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(info)

	# Title row
	var title_row := HBoxContainer.new()
	info.add_child(title_row)

	var title_lbl := _lbl(q["title"], 20)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title_lbl)

	# Quest type badge
	var type_map := {"combat": ["⚔ Боевое", Color(1.0,0.4,0.3)],
					 "trade":  ["📦 Торговля", Color(0.4,0.9,0.4)],
					 "exploration": ["🔭 Разведка", Color(0.4,0.7,1.0)],
					 "stealth": ["🕵 Скрытность", Color(0.8,0.6,1.0)],
					 "patrol": ["🛡 Патруль", Color(0.9,0.8,0.3)]}
	var badge_data: Array = type_map.get(q.get("id",""), ["❓ Прочее", Color(0.6,0.6,0.6)])
	# match by type field in quest type definition
	for qt in GameData.QUEST_TYPES:
		if qt["id"] == q.get("id",""):
			badge_data = type_map.get(qt["type"], badge_data)
			break
	var badge := _lbl(badge_data[0], 12)
	badge.add_theme_color_override("font_color", badge_data[1])
	title_row.add_child(badge)

	# Description
	var desc_lbl := _lbl(q["desc"], 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.72, 0.72, 0.72))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(desc_lbl)

	# Reward row
	var reward_row := HBoxContainer.new()
	info.add_child(reward_row)

	var reward_lbl := _lbl("💰 Награда: %d кред." % q["reward"], 16)
	reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3))
	reward_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_row.add_child(reward_lbl)

	# Accept button
	# Destination info line
	var dest_text: String
	if q.get("is_local", false):
		dest_text = "📍 Сдать задание: прямо здесь, в баре"
	else:
		dest_text = "📍 Сдать задание: система «%s» (любой космопорт)" % q.get("dest_galaxy", "?")
	var dest_l := _lbl(dest_text, 13, Color(0.4, 0.85, 0.55))
	info.add_child(dest_l)

	var already := GameManager.active_quests.any(func(aq): return aq["title"] == q["title"] and aq["origin"] == q["origin"])
	var btn := Button.new()
	if already:
		btn.text = "✅ Принято"
		btn.disabled = true
	elif q.get("done", false):
		btn.text = "☑ Выполнено"
		btn.disabled = true
	else:
		btn.text = "Принять задание"
		btn.pressed.connect(_accept_quest.bind(q))
	btn.add_theme_font_size_override("font_size", 15)
	btn.custom_minimum_size = Vector2(170, 0)
	reward_row.add_child(btn)

	return card

func _accept_quest(q: Dictionary) -> void:
	var qd: Dictionary = q.duplicate()
	qd["origin_faction"] = GameManager.current_faction  # фракция системы где взяли задание
	# Сохраняем снимок прогресса для проверки выполнения боевых и временных условий
	qd["battles_won_at_accept"] = GameManager.total_battles_won
	qd["day_at_accept"] = GameManager.day
	GameManager.active_quests.append(qd)
	print("[Spaceport] Quest accepted: %s" % q["title"])
	_populate_quests()
	_refresh_credits()

# ── Bank ─────────────────────────────────────────────────────────────────────

func _populate_bank() -> void:
	_clear(_bank_list)

	# Header
	var hdr := _lbl("🏦  ГАЛАКТИЧЕСКИЙ БАНК", 22, Color(0.9, 0.78, 0.2))
	_bank_list.add_child(hdr)
	_bank_list.add_child(_lbl("Надёжное хранение кредитов и финансовые услуги во всех системах.", 13, Color(0.6, 0.6, 0.6)))
	_bank_list.add_child(HSeparator.new())

	# Balance info
	var info_hb := HBoxContainer.new()
	_bank_list.add_child(info_hb)

	var bal_vb := VBoxContainer.new()
	bal_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_hb.add_child(bal_vb)
	bal_vb.add_child(_lbl("💳 На счёте:", 14, Color(0.5, 0.8, 1.0)))
	bal_vb.add_child(_lbl("%d кред." % GameManager.bank_balance, 24, Color(0.3, 1.0, 0.55)))

	var cred_vb := VBoxContainer.new()
	cred_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_hb.add_child(cred_vb)
	cred_vb.add_child(_lbl("💰 Наличные:", 14, Color(0.5, 0.8, 1.0)))
	cred_vb.add_child(_lbl("%d кред." % GameManager.credits, 24, Color(1.0, 0.88, 0.3)))

	if GameManager.loan_amount > 0:
		var loan_vb := VBoxContainer.new()
		loan_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_hb.add_child(loan_vb)
		loan_vb.add_child(_lbl("📋 Долг:", 14, Color(1.0, 0.4, 0.3)))
		loan_vb.add_child(_lbl("%d кред." % GameManager.loan_amount, 24, Color(1.0, 0.3, 0.2)))

	_bank_list.add_child(HSeparator.new())

	# ── Deposit ──
	var dep_hdr := HBoxContainer.new()
	_bank_list.add_child(dep_hdr)
	dep_hdr.add_child(_lbl("ДЕПОЗИТ", 15, Color(0.4, 0.9, 0.5)))
	# Interest info
	var int_lbl := _lbl(
		"   📈 Вклад от %d к. → +4%% в день" % GameManager.BANK_MIN_FOR_INTEREST,
		13, Color(0.9, 0.82, 0.3))
	dep_hdr.add_child(int_lbl)
	if GameManager.bank_balance >= GameManager.BANK_MIN_FOR_INTEREST:
		var next_int := int(GameManager.bank_balance * GameManager.BANK_DEPOSIT_RATE)
		var gain_lbl := _lbl("  ✅ Следующее начисление: +%d к." % next_int, 13, Color(0.3, 1.0, 0.55))
		dep_hdr.add_child(gain_lbl)
	elif GameManager.bank_balance > 0:
		var need := GameManager.BANK_MIN_FOR_INTEREST - GameManager.bank_balance
		var need_lbl := _lbl("  ⚠ До минимума: %d к." % need, 13, Color(0.9, 0.6, 0.3))
		dep_hdr.add_child(need_lbl)

	# Быстрые кнопки депозита
	var dep_row := HBoxContainer.new()
	_bank_list.add_child(dep_row)
	dep_row.add_child(_lbl("Быстро:", 13, Color(0.6, 0.6, 0.6)))
	for amt in [500, 1000, 5000, 10000, 25000]:
		var b := Button.new()
		b.text = "%d к." % amt
		b.disabled = GameManager.credits < amt
		b.pressed.connect(func(): _bank_do_deposit(amt))
		dep_row.add_child(b)

	# Произвольная сумма + "Положить всё"
	var dep_custom_row := HBoxContainer.new()
	_bank_list.add_child(dep_custom_row)
	dep_custom_row.add_child(_lbl("Сумма:", 14))
	var dep_input := LineEdit.new()
	dep_input.placeholder_text = "введи сумму"
	dep_input.custom_minimum_size = Vector2(140, 0)
	dep_input.max_length = 12
	dep_custom_row.add_child(dep_input)
	var dep_custom_btn := Button.new()
	dep_custom_btn.text = "Положить"
	dep_custom_btn.pressed.connect(func():
		var v: int = int(dep_input.text)
		if v > 0: _bank_do_deposit(v))
	dep_custom_row.add_child(dep_custom_btn)
	var dep_all_btn := Button.new()
	dep_all_btn.text = "Положить всё  (%d к.)" % GameManager.credits
	dep_all_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
	dep_all_btn.disabled = GameManager.credits <= 0
	dep_all_btn.pressed.connect(func(): _bank_do_deposit(GameManager.credits))
	dep_custom_row.add_child(dep_all_btn)

	# ── Withdraw ──
	_bank_list.add_child(HSeparator.new())
	_bank_list.add_child(_lbl("СНЯТИЕ", 15, Color(0.4, 0.9, 0.5)))
	# Быстрые кнопки
	var wdr_row := HBoxContainer.new()
	_bank_list.add_child(wdr_row)
	wdr_row.add_child(_lbl("Быстро:", 13, Color(0.6, 0.6, 0.6)))
	for amt in [500, 1000, 5000, 10000]:
		var b := Button.new()
		b.text = "%d к." % amt
		b.disabled = GameManager.bank_balance < amt
		b.pressed.connect(func(): _bank_do_withdraw(amt))
		wdr_row.add_child(b)

	# Произвольная сумма + "Снять всё"
	var wdr_custom_row := HBoxContainer.new()
	_bank_list.add_child(wdr_custom_row)
	wdr_custom_row.add_child(_lbl("Сумма:", 14))
	var wdr_input := LineEdit.new()
	wdr_input.placeholder_text = "введи сумму"
	wdr_input.custom_minimum_size = Vector2(140, 0)
	wdr_input.max_length = 12
	wdr_custom_row.add_child(wdr_input)
	var wdr_custom_btn := Button.new()
	wdr_custom_btn.text = "Снять"
	wdr_custom_btn.pressed.connect(func():
		var v: int = int(wdr_input.text)
		if v > 0: _bank_do_withdraw(v))
	wdr_custom_row.add_child(wdr_custom_btn)
	var wdr_all_btn := Button.new()
	wdr_all_btn.text = "Снять всё  (%d к.)" % GameManager.bank_balance
	wdr_all_btn.add_theme_color_override("font_color", Color(1.0, 0.82, 0.2))
	wdr_all_btn.disabled = GameManager.bank_balance <= 0
	wdr_all_btn.pressed.connect(func(): _bank_do_withdraw(GameManager.bank_balance))
	wdr_custom_row.add_child(wdr_all_btn)

	# ── Loan ──
	_bank_list.add_child(HSeparator.new())
	_bank_list.add_child(_lbl("КРЕДИТОВАНИЕ  (12% сверху, разовый займ)", 15, Color(1.0, 0.75, 0.2)))

	if GameManager.loan_amount > 0:
		var repay_row := HBoxContainer.new()
		_bank_list.add_child(repay_row)
		repay_row.add_child(_lbl("Погасить долг (%d кред.):" % GameManager.loan_amount, 14))
		for amt in [500, 1000, 5000]:
			if amt > GameManager.loan_amount:
				continue
			var b := Button.new()
			b.text = "%d к." % amt
			b.disabled = GameManager.credits < amt
			b.pressed.connect(func(): _bank_do_repay(amt))
			repay_row.add_child(b)
		var b_full := Button.new()
		b_full.text = "Погасить полностью"
		b_full.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		b_full.disabled = GameManager.credits < GameManager.loan_amount
		b_full.pressed.connect(func(): _bank_do_repay(GameManager.loan_amount))
		repay_row.add_child(b_full)
	else:
		var loan_row := HBoxContainer.new()
		_bank_list.add_child(loan_row)
		loan_row.add_child(_lbl("Взять займ:", 14))
		for amt in [1000, 5000, 10000, 25000]:
			var b := Button.new()
			b.text = "%d к." % amt
			b.pressed.connect(func(): _bank_do_loan(amt))
			loan_row.add_child(b)

	# ── Info ──
	_bank_list.add_child(HSeparator.new())
	_bank_list.add_child(_lbl(
		"ℹ  Счёт доступен в любом космопорту. Депозит от %d к. приносит 4%% в день (начисляется при смене дня/прыжке). Кредит: +12%% разово." % GameManager.BANK_MIN_FOR_INTEREST,
		12, Color(0.45, 0.45, 0.45)))

func _bank_do_deposit(amt: int) -> void:
	if GameManager.bank_deposit(amt):
		_populate_bank()
		_refresh_credits()

func _bank_do_withdraw(amt: int) -> void:
	if GameManager.bank_withdraw(amt):
		_populate_bank()
		_refresh_credits()

func _bank_do_loan(amt: int) -> void:
	if GameManager.bank_take_loan(amt):
		_populate_bank()
		_refresh_credits()

func _bank_do_repay(amt: int) -> void:
	if GameManager.bank_repay_loan(amt):
		_populate_bank()
		_refresh_credits()

# ── Repair ───────────────────────────────────────────────────────────────────

func _populate_repair() -> void:
	_clear(_repair_list)

	var ship      := GameManager.current_ship
	var hull_pct  := clampf(GameManager.ship_hull_pct, 0.0, 1.0)
	var max_hull: int = ship.get("hull", 100)
	var cur_hull: int = maxi(1, int(hull_pct * float(max_hull)))
	var missing   := max_hull - cur_hull
	var ship_price: int = ship.get("price", 10000)

	# Header
	_repair_list.add_child(_lbl("🔧  РЕМОНТНЫЙ ДОК", 22, Color(0.85, 0.68, 0.25)))
	_repair_list.add_child(HSeparator.new())

	# Ship condition block
	var cond_hb := HBoxContainer.new()
	_repair_list.add_child(cond_hb)

	var info_vb := VBoxContainer.new()
	info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cond_hb.add_child(info_vb)

	info_vb.add_child(_lbl("Корабль: %s" % ship.get("name", "?"), 17))
	var hull_col := Color(0.2, 0.85, 0.3) if hull_pct > 0.6 else \
				   (Color(0.9, 0.72, 0.1) if hull_pct > 0.3 else Color(0.95, 0.2, 0.2))
	info_vb.add_child(_lbl("Корпус: %d / %d  (%.0f%%)" % [cur_hull, max_hull, hull_pct * 100],
		18, hull_col))

	# Condition label
	var cond_txt := "🟢 Отличное состояние"
	if hull_pct < 0.3:  cond_txt = "🔴 Критические повреждения — срочный ремонт!"
	elif hull_pct < 0.6: cond_txt = "🟡 Значительные повреждения"
	elif hull_pct < 0.9: cond_txt = "🟠 Незначительные повреждения"
	info_vb.add_child(_lbl(cond_txt, 14))

	_repair_list.add_child(HSeparator.new())

	# Cost formula explanation
	# Full repair = 5% of ship price
	# Cost per 1 HP = ship_price * 0.05 / max_hull
	var cost_per_hp: float = float(ship_price) * 0.05 / float(max_hull)
	_repair_list.add_child(_lbl(
		"💡 Тариф: %.1f кред. за 1 ед. корпуса  (полный ремонт = 5%% стоимости корабля)" % cost_per_hp,
		13, Color(0.5, 0.6, 0.7)))
	_repair_list.add_child(HSeparator.new())

	# ── Полное обслуживание (ремонт + заправка одной кнопкой) ────────────────────
	var missing_fuel_full: float = GameManager.max_fuel - GameManager.fuel
	const FUEL_PPU := 12
	var full_repair_cost: int = maxi(1, int(float(missing) * cost_per_hp))
	var full_fuel_cost:   int = int(missing_fuel_full * FUEL_PPU)
	var has_damage: bool = missing > 0
	var needs_fuel: bool = missing_fuel_full >= 0.5

	if has_damage and needs_fuel:
		var combo_cost: int = full_repair_cost + full_fuel_cost
		_repair_list.add_child(_lbl("ПОЛНОЕ ОБСЛУЖИВАНИЕ", 15, Color(0.95, 0.82, 0.3)))
		var combo_row := HBoxContainer.new()
		_repair_list.add_child(combo_row)
		var combo_desc := _lbl("🔧⛽  Полный ремонт + полная заправка", 15)
		combo_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		combo_row.add_child(combo_desc)
		var combo_cost_lbl := _lbl("%d кред." % combo_cost, 15, Color(1.0, 0.88, 0.3))
		combo_cost_lbl.custom_minimum_size = Vector2(130, 0)
		combo_cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		combo_row.add_child(combo_cost_lbl)
		var combo_btn := Button.new()
		combo_btn.text = "Обслужить всё"
		combo_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
		combo_btn.custom_minimum_size = Vector2(150, 0)
		combo_btn.disabled = GameManager.credits < combo_cost
		combo_btn.pressed.connect(func():
			if GameManager.spend_credits(combo_cost):
				GameManager.ship_hull_pct = 1.0
				GameManager.fuel = GameManager.max_fuel
				_populate_repair()
				_refresh_credits())
		combo_row.add_child(combo_btn)
		_repair_list.add_child(HSeparator.new())

	if missing <= 0:
		_repair_list.add_child(_lbl("✅  Корабль в полном порядке — ремонт не требуется.", 16, Color(0.3, 1.0, 0.5)))
	else:
		_repair_list.add_child(_lbl("ВАРИАНТЫ РЕМОНТА", 15, Color(0.5, 0.8, 1.0)))
		for pct_i in [25, 50, 75, 100]:
			var hp_to_fix: int = maxi(1, int(float(missing) * float(pct_i) / 100.0))
			var rcost:     int = maxi(1, int(float(hp_to_fix) * cost_per_hp))
			var row := HBoxContainer.new()
			_repair_list.add_child(row)
			var desc_lbl := _lbl("%d%%  (+%d HP)" % [pct_i, hp_to_fix], 15)
			desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(desc_lbl)
			var cost_lbl := _lbl("%d кред." % rcost, 15, Color(1.0, 0.88, 0.3))
			cost_lbl.custom_minimum_size = Vector2(120, 0)
			cost_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(cost_lbl)
			var btn := Button.new()
			btn.text = "Починить"
			btn.custom_minimum_size = Vector2(120, 0)
			btn.disabled = GameManager.credits < rcost
			var hp_cap: int   = hp_to_fix
			var cost_cap: int = rcost
			btn.pressed.connect(func(): _do_repair(hp_cap, cost_cap))
			row.add_child(btn)
		_repair_list.add_child(HSeparator.new())
		_repair_list.add_child(_lbl(
			"ℹ  Ремонт производится немедленно. Щиты восстанавливаются автоматически перед следующим боем.",
			12, Color(0.4, 0.4, 0.45)))

	# ── Заправка топливом ──────────────────────────────────────────────────────
	_repair_list.add_child(HSeparator.new())
	_repair_list.add_child(_lbl("⛽  ЗАПРАВОЧНАЯ СТАНЦИЯ", 18, Color(0.95, 0.75, 0.2)))
	var fuel_pct := GameManager.fuel / GameManager.max_fuel
	var fuel_col := Color(0.2, 0.85, 0.3) if fuel_pct > 0.5 else \
				   (Color(0.9, 0.72, 0.1) if fuel_pct > 0.25 else Color(0.95, 0.2, 0.2))
	_repair_list.add_child(_lbl("Топливо: %.1f / %.1f  (%.0f%%)" % [
		GameManager.fuel, GameManager.max_fuel, fuel_pct * 100], 16, fuel_col))

	const FUEL_PRICE_PER_UNIT := 12  # кредитов за единицу топлива
	var missing_fuel := GameManager.max_fuel - GameManager.fuel
	if missing_fuel < 0.5:
		_repair_list.add_child(_lbl("✅  Топливный бак полон.", 14, Color(0.3, 1.0, 0.5)))
	else:
		_repair_list.add_child(_lbl(
			"💡 Тариф: %d кред. за единицу топлива" % FUEL_PRICE_PER_UNIT,
			13, Color(0.5, 0.6, 0.7)))
		for pct_i in [25, 50, 75, 100]:
			var amount := GameManager.max_fuel * float(pct_i) / 100.0
			var to_add  := minf(amount, missing_fuel)
			if to_add < 0.5: continue
			var cost   := int(to_add * FUEL_PRICE_PER_UNIT)
			var row    := HBoxContainer.new()
			_repair_list.add_child(row)
			var dl := _lbl("+%.0f ед. (%d%%)" % [to_add, pct_i], 15)
			dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(dl)
			var cl := _lbl("%d кред." % cost, 15, Color(1.0, 0.88, 0.3))
			cl.custom_minimum_size = Vector2(120, 0)
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			row.add_child(cl)
			var btn := Button.new()
			btn.text = "Заправить"
			btn.custom_minimum_size = Vector2(120, 0)
			btn.disabled = GameManager.credits < cost
			var amt_cap: float = to_add; var cost_cap: int = cost
			btn.pressed.connect(func():
				if GameManager.spend_credits(cost_cap):
					GameManager.refuel(amt_cap)
					_populate_repair()
					_refresh_credits())
			row.add_child(btn)

	# ── Ремонт повреждённых орудийных отсеков ────────────────────────────────────
	_repair_list.add_child(HSeparator.new())
	_repair_list.add_child(_lbl("⚠  РЕМОНТ ОРУДИЙНЫХ ОТСЕКОВ", 18, Color(1.0, 0.55, 0.2)))

	var damaged: Array = GameManager.damaged_weapons
	if damaged.is_empty():
		_repair_list.add_child(_lbl("✅  Все орудийные отсеки в норме.", 14, Color(0.3, 1.0, 0.5)))
	else:
		_repair_list.add_child(_lbl(
			"Повреждённые орудия не стреляют до ремонта. Стоимость: 15%% цены орудия.",
			13, Color(0.5, 0.55, 0.65)))
		for slot_idx in damaged:
			var wname: String = GameManager.equipped_weapons[slot_idx] \
				if slot_idx < GameManager.equipped_weapons.size() else "Орудие %d" % slot_idx
			# Find weapon price in GameData
			var wprice: int = 5000
			for wd in GameData.WEAPONS:
				if wd["name"] == wname:
					wprice = wd["price"]
					break
			var repair_cost: int = maxi(500, int(wprice * 0.15))
			var r := HBoxContainer.new()
			_repair_list.add_child(r)
			var dl := _lbl("⚠  %s" % wname, 15, Color(1.0, 0.45, 0.3))
			dl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			r.add_child(dl)
			var cl := _lbl("%d кред." % repair_cost, 15, Color(1.0, 0.88, 0.3))
			cl.custom_minimum_size = Vector2(120, 0)
			cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			r.add_child(cl)
			var btn := Button.new()
			btn.text = "Починить отсек"
			btn.custom_minimum_size = Vector2(140, 0)
			btn.disabled = GameManager.credits < repair_cost
			var cap_slot: int  = slot_idx
			var cap_cost2: int = repair_cost
			btn.pressed.connect(func(): _do_weapon_repair(cap_slot, cap_cost2))
			r.add_child(btn)

		if damaged.size() > 1:
			var all_cost: int = 0
			for slot_idx2 in damaged:
				var wn2: String = GameManager.equipped_weapons[slot_idx2] \
					if slot_idx2 < GameManager.equipped_weapons.size() else ""
				var wp2: int = 5000
				for wd2 in GameData.WEAPONS:
					if wd2["name"] == wn2: wp2 = wd2["price"]; break
				all_cost += maxi(500, int(wp2 * 0.15))
			var all_row := HBoxContainer.new()
			_repair_list.add_child(all_row)
			var all_desc := _lbl("🔧  Починить все орудия", 15)
			all_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			all_row.add_child(all_desc)
			var all_cl := _lbl("%d кред." % all_cost, 15, Color(1.0, 0.88, 0.3))
			all_cl.custom_minimum_size = Vector2(120, 0)
			all_cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			all_row.add_child(all_cl)
			var all_btn := Button.new()
			all_btn.text = "Починить всё"
			all_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
			all_btn.custom_minimum_size = Vector2(140, 0)
			all_btn.disabled = GameManager.credits < all_cost
			var cap_all_cost: int = all_cost
			all_btn.pressed.connect(func(): _do_all_weapon_repair(cap_all_cost))
			all_row.add_child(all_btn)

	# ── Пополнение боезапаса / батарей ───────────────────────────────────────────
	_repair_list.add_child(HSeparator.new())
	_repair_list.add_child(_lbl("🔋  ПОПОЛНЕНИЕ БОЕЗАПАСА", 18, Color(0.55, 0.85, 1.0)))

	var has_any_ammo := false
	for slot_i in GameManager.equipped_weapons.size():
		var wname2: String = GameManager.equipped_weapons[slot_i]
		var max_ammo: int  = 0
		var wprice2:  int  = 1800
		var wtype2:   String = "energy"
		for wd3 in GameData.WEAPONS:
			if wd3["name"] == wname2:
				max_ammo = wd3.get("ammo", 0)
				wprice2  = wd3["price"]
				wtype2   = wd3.get("type", "energy")
				break
		if max_ammo <= 0: continue
		has_any_ammo = true
		var cur_ammo: int = int(GameManager.weapon_ammo_state.get(wname2, max_ammo))
		if cur_ammo >= max_ammo:
			var full_row := HBoxContainer.new()
			_repair_list.add_child(full_row)
			var icon: String = "🚀" if wtype2 == "torpedo" or wtype2 == "missile" else "🔋"
			var fl := _lbl("%s  %s — %d/%d %s" % [
				"✅", wname2, cur_ammo, max_ammo, icon], 14, Color(0.3, 1.0, 0.5))
			fl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			full_row.add_child(fl)
			continue
		# Need restock
		var missing_ammo: int = max_ammo - cur_ammo
		var cost_per_unit: int = maxi(50, int(float(wprice2) / float(max_ammo) * 2.0))
		var restock_cost:  int = missing_ammo * cost_per_unit
		var icon2: String = "🚀" if wtype2 == "torpedo" or wtype2 == "missile" else "🔋"
		var ar := HBoxContainer.new()
		_repair_list.add_child(ar)
		var ad := _lbl("%s  %s — %d/%d %s" % [
			"⚠", wname2, cur_ammo, max_ammo, icon2], 15, Color(0.9, 0.65, 0.2))
		ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ar.add_child(ad)
		var acl := _lbl("%d кред." % restock_cost, 15, Color(1.0, 0.88, 0.3))
		acl.custom_minimum_size = Vector2(120, 0)
		acl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		ar.add_child(acl)
		var abtn := Button.new()
		abtn.text = "Пополнить"
		abtn.custom_minimum_size = Vector2(120, 0)
		abtn.disabled = GameManager.credits < restock_cost
		var cap_wname: String = wname2
		var cap_max:   int    = max_ammo
		var cap_rcost: int    = restock_cost
		abtn.pressed.connect(func(): _do_restock_ammo(cap_wname, cap_max, cap_rcost))
		ar.add_child(abtn)

	if not has_any_ammo:
		_repair_list.add_child(_lbl("На вашем корабле нет орудий с боезапасом.", 14, Color(0.5, 0.5, 0.55)))

func _do_weapon_repair(slot_idx: int, cost: int) -> void:
	if not GameManager.spend_credits(cost): return
	GameManager.damaged_weapons.erase(slot_idx)
	_populate_repair()
	_refresh_credits()

func _do_all_weapon_repair(total_cost: int) -> void:
	if not GameManager.spend_credits(total_cost): return
	GameManager.damaged_weapons.clear()
	_populate_repair()
	_refresh_credits()

func _do_restock_ammo(wname: String, max_ammo: int, cost: int) -> void:
	if not GameManager.spend_credits(cost): return
	GameManager.weapon_ammo_state[wname] = max_ammo
	_populate_repair()
	_refresh_credits()

func _do_repair(hp_amount: int, cost: int) -> void:
	if not GameManager.spend_credits(cost):
		return
	var max_hull: int = GameManager.current_ship.get("hull", 100)
	var cur_hull: int = maxi(1, int(clampf(GameManager.ship_hull_pct, 0.0, 1.0) * float(max_hull)))
	var new_hull: int = mini(cur_hull + hp_amount, max_hull)
	GameManager.ship_hull_pct = float(new_hull) / float(max_hull)
	_populate_repair()
	_refresh_credits()

# ── Upgrades ─────────────────────────────────────────────────────────────────

const UPGRADES_DATA := [
	{
		"id": "volley", "name": "Синхронный залп", "icon": "⚡",
		"desc": "Все орудия стреляют одновременно по одной цели за счёт энергии щита.",
		"detail": "Клавиша: Q  |  Расход: 30 щита  |  Перезарядка: 8 сек",
		"price": 8000,
	},
	{
		"id": "emergency_shields", "name": "Аварийные щиты", "icon": "🛡",
		"desc": "Генератор конвертирует 10% текущего корпуса в щитовую энергию.",
		"detail": "Клавиша: W  |  Расход: 10% корпуса  |  Перезарядка: 12 сек",
		"price": 6500,
	},
	{
		"id": "boost", "name": "Форсаж двигателя", "icon": "🔥",
		"desc": "Кратковременный форсаж: скорость ×2.5 на 5 секунд.",
		"detail": "Клавиша: R  |  Расход: 25 щита  |  Перезарядка: 15 сек",
		"price": 7500,
	},
	{
		"id": "overload", "name": "Перегрузка орудий", "icon": "💥",
		"desc": "Следующий выстрел наносит утроенный урон, перегревая орудия.",
		"detail": "Клавиша: F  |  Расход: 25 щита  |  Перезарядка: 10 сек",
		"price": 9000,
	},
	{
		"id": "repair_drones", "name": "Ремонтные дроны", "icon": "🤖",
		"desc": "Нанодроны непрерывно восстанавливают корпус во время боя (+2 HP/сек).",
		"detail": "Пассивное улучшение  |  Эффект всегда активен в бою",
		"price": 12000,
	},
	{
		"id": "shield_injector", "name": "Щитовой инжектор", "icon": "💉",
		"desc": "Экстренный впрыск плазмы: мгновенно восстанавливает щиты до 50% ценой корпуса.",
		"detail": "Клавиша: X  |  Расход: 10% корпуса  |  Перезарядка: 18 сек",
		"price": 10000,
	},
]

func _populate_upgrades() -> void:
	_clear(_upgrades_list)
	_upgrades_list.add_child(_lbl("🔬  УЛУЧШЕНИЯ КОРАБЛЯ", 22, Color(0.55, 0.85, 1.0)))
	_upgrades_list.add_child(_lbl(
		"Активные улучшения запускаются кнопкой в бою. Защитные — автоматически. Привязаны к кораблю.",
		13, Color(0.5, 0.55, 0.65)))
	_upgrades_list.add_child(HSeparator.new())

	for upg in UPGRADES_DATA:
		var owned: bool = upg["id"] in GameManager.ship_upgrades

		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 88)
		var hb := HBoxContainer.new()
		card.add_child(hb)

		# Icon
		var icon_l := _lbl(upg["icon"], 34)
		icon_l.custom_minimum_size = Vector2(56, 0)
		icon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hb.add_child(icon_l)

		# Info
		var info_vb := VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(info_vb)

		var name_row := HBoxContainer.new()
		info_vb.add_child(name_row)
		name_row.add_child(_lbl(upg["name"], 18))
		if owned:
			name_row.add_child(_lbl("  ✅ Установлено", 13, Color(0.3, 1.0, 0.5)))

		var desc_l := _lbl(upg["desc"], 13, Color(0.68, 0.68, 0.68))
		desc_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vb.add_child(desc_l)

		info_vb.add_child(_lbl(upg["detail"], 12, Color(0.45, 0.75, 1.0)))

		# Buy column
		var buy_vb := VBoxContainer.new()
		buy_vb.custom_minimum_size = Vector2(160, 0)
		hb.add_child(buy_vb)

		var price_l := _lbl("%d кред." % upg["price"], 16, Color(1.0, 0.88, 0.3))
		price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		buy_vb.add_child(price_l)

		var btn := Button.new()
		if owned:
			btn.text = "✅ Установлено"
			btn.disabled = true
		elif GameManager.credits < upg["price"]:
			btn.text = "Недостаточно кредитов"
			btn.disabled = true
		else:
			btn.text = "Установить"
			btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var uid: String = upg["id"]
		var uprice: int = upg["price"]
		btn.pressed.connect(func(): _buy_upgrade(uid, uprice))
		buy_vb.add_child(btn)

		_upgrades_list.add_child(card)

func _buy_upgrade(uid: String, price: int) -> void:
	if uid in GameManager.ship_upgrades:
		return
	if GameManager.spend_credits(price):
		GameManager.ship_upgrades.append(uid)
		_populate_upgrades()
		_refresh_credits()

# ── Faction HQ ───────────────────────────────────────────────────────────────

# Безопасные системы для штаба фракции: опасность ≤ 2, мирная фракция (не Пираты, не Пустота)
const HQ_ELIGIBLE_SYSTEMS := [
	{"name": "Sol Prime",       "danger": 1, "faction": "Федерация"},
	{"name": "Krath Station",   "danger": 2, "faction": "Федерация"},
	{"name": "Auren Gate",      "danger": 2, "faction": "Торговцы"},
	{"name": "Nova Reach",      "danger": 2, "faction": "Независимые"},
	{"name": "Helion Crossing", "danger": 2, "faction": "Торговцы"},
	{"name": "Pax Harbor",      "danger": 1, "faction": "Федерация"},
	{"name": "Silk Route",      "danger": 2, "faction": "Торговцы"},
	{"name": "Drift Market",    "danger": 2, "faction": "Торговцы"},
	{"name": "Echo Station",    "danger": 2, "faction": "Независимые"},
	{"name": "Relay Point",     "danger": 2, "faction": "Независимые"},
	{"name": "Hyperion Falls",  "danger": 2, "faction": "Независимые"},
]

const HQ_ALLY_SHIPS := [
	{"name": "Перехватчик", "icon": "✈", "cost": 8000,  "income": 120,
	 "desc": "Лёгкий истребитель. Быстрый, небольшой доход."},
	{"name": "Корвет",      "icon": "🚀", "cost": 18000, "income": 300,
	 "desc": "Боевой корвет. Надёжный доход и хорошая боеспособность."},
	{"name": "Крейсер",     "icon": "⚓", "cost": 40000, "income": 750,
	 "desc": "Тяжёлый крейсер. Высокий доход, значительная боевая мощь."},
	{"name": "Дредноут",    "icon": "💀", "cost": 90000, "income": 1800,
	 "desc": "Линкор флота. Максимальный доход. Только для крупных фракций."},
]

const HQ_ALLY_NAMES := [
	"Адмирал Кортос", "Капитан Зерра", "Лейтенант Вар", "Командор Нексус",
	"Пилот Орион", "Майор Стрела", "Полковник Фокс", "Капитан Риф",
	"Боец Астра", "Сержант Волк", "Агент Тень", "Пилот Зар",
]

func _count_hq_allies() -> int:
	var n: int = 0
	for a in GameManager.faction_allies:
		if a.get("location", "hq") == "hq":
			n += 1
	return n

func _populate_hq() -> void:
	_clear(_hq_list)

	if GameManager.faction_leader_of.is_empty():
		_hq_list.add_child(_lbl("🏛  ШТАБ ФРАКЦИИ", 22, Color(0.7, 0.7, 0.7)))
		_hq_list.add_child(HSeparator.new())
		_hq_list.add_child(_lbl(
			"Эта вкладка доступна только лидеру фракции.\nСоздайте свою фракцию в Баре, чтобы открыть Штаб.",
			16, Color(0.55, 0.55, 0.6)))
		return

	var fname:  String = GameManager.faction_leader_of
	var hq_sys: String = GameManager.faction_hq_system
	var at_hq:  bool   = (hq_sys != "" and GameManager.current_galaxy == hq_sys)

	_hq_list.add_child(_lbl("🏛  ШТАБ ФРАКЦИИ «%s»" % fname.to_upper(), 22, Color(0.95, 0.82, 0.2)))

	# Штаб-квартира
	if hq_sys != "":
		var hq_col := Color(0.3, 1.0, 0.55) if at_hq else Color(0.6, 0.7, 0.9)
		_hq_list.add_child(_lbl(
			"📍 Штаб-квартира: %s%s" % [hq_sys, "  ← ВЫ ЗДЕСЬ" if at_hq else ""],
			14, hq_col))

	# ── Лог атак на штаб ────────────────────────────────────────────────────────
	if not GameManager.hq_attack_log.is_empty():
		_hq_list.add_child(HSeparator.new())
		_hq_list.add_child(_lbl("📋  ЖУРНАЛ СОБЫТИЙ ФЛОТА", 15, Color(1.0, 0.75, 0.2)))
		for entry in GameManager.hq_attack_log:
			var is_victory: bool = entry.begins_with("✅")
			var is_dead:    bool = entry.begins_with("💀")
			var entry_col := Color(0.35, 0.95, 0.45) if is_victory else \
				(Color(1.0, 0.2, 0.2) if is_dead else Color(0.9, 0.5, 0.35))
			var el := _lbl(entry, 13, entry_col)
			el.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_hq_list.add_child(el)

	_hq_list.add_child(HSeparator.new())

	# ── Обзор фракции ───────────────────────────────────────────────────────────
	var allies: Array = GameManager.faction_allies
	var total_income: int = 0
	for a in allies: total_income += int(a.get("income", 0))
	var at_hq_count: int = _count_hq_allies()

	var ov_hb := HBoxContainer.new()
	_hq_list.add_child(ov_hb)

	var ov_a := VBoxContainer.new()
	ov_a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ov_hb.add_child(ov_a)
	ov_a.add_child(_lbl("👥 Союзников:", 14, Color(0.5, 0.8, 1.0)))
	ov_a.add_child(_lbl("%d человек" % allies.size(), 22, Color(0.3, 1.0, 0.55)))

	var ov_i := VBoxContainer.new()
	ov_i.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ov_hb.add_child(ov_i)
	ov_i.add_child(_lbl("💰 Доход/день:", 14, Color(0.5, 0.8, 1.0)))
	ov_i.add_child(_lbl("+%d кред." % total_income, 22, Color(0.95, 0.82, 0.2)))

	var ov_r := VBoxContainer.new()
	ov_r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ov_hb.add_child(ov_r)
	ov_r.add_child(_lbl("⭐ Репутация:", 14, Color(0.5, 0.8, 1.0)))
	var rep_val: int = GameManager.faction_reputation.get(fname, 0)
	ov_r.add_child(_lbl("%d / 100" % rep_val, 22, Color(1.0, 0.6, 0.2)))

	# Статус патруля в штабе
	var patrol_col := Color(0.3, 1.0, 0.55) if at_hq_count >= 3 else Color(1.0, 0.4, 0.3)
	var patrol_txt := "🛡 В штабе патрулируют: %d кораблей%s" % [
		at_hq_count,
		"" if at_hq_count >= 3 else "  ⚠ КРИТИЧЕСКИ МАЛО (минимум 3)!"]
	_hq_list.add_child(_lbl(patrol_txt, 14, patrol_col))

	# Предупреждение о враждебных фракциях
	var hostile_count: int = 0
	for f in GameManager.faction_reputation:
		if GameManager.faction_reputation.get(f, 0) < -30 and f != fname and f != "Нет":
			hostile_count += 1
	if hostile_count > 0:
		_hq_list.add_child(_lbl(
			"⚔ %d враждебных фракций могут атаковать штаб!" % hostile_count,
			13, Color(1.0, 0.55, 0.2)))

	_hq_list.add_child(HSeparator.new())

	# Управление флотом — только в штабе
	if not at_hq:
		_hq_list.add_child(_lbl("⚠  УПРАВЛЕНИЕ ФЛОТОМ", 16, Color(0.9, 0.6, 0.2)))
		_hq_list.add_child(_lbl(
			"Командовать флотом можно только находясь в штабе (%s).\nПрибудьте в штаб чтобы давать указания кораблям." % hq_sys,
			13, Color(0.6, 0.6, 0.65)))
		_hq_list.add_child(HSeparator.new())

	# ── Протектораты ─────────────────────────────────────────────────────────────
	_hq_list.add_child(_lbl("🏴  ПРОТЕКТОРАТЫ", 18, Color(1.0, 0.72, 0.1)))
	if GameManager.protectorates.is_empty():
		_hq_list.add_child(_lbl(
			"Нет завоёванных систем.\nОбъявите войну фракции и введите флот (≥7 кораблей, ≥3 дредноута).",
			13, Color(0.55, 0.55, 0.62)))
	else:
		# Расчёт сил для предупреждения о бунте
		var fleet_str: int = GameManager.get_fleet_strength()
		var total_prot_str: int = 0
		for p in GameManager.protectorates:
			total_prot_str += int(p.get("garrison_strength", GameManager.PROTECTORATE_GARRISON_STRENGTH))
		var rebellion_risk: bool = fleet_str <= int(total_prot_str * (1.0 + GameManager.REBELLION_SURPLUS_PCT))
		if rebellion_risk:
			var rb := _lbl(
				"⚡ ВНИМАНИЕ: Флот (%d ед.) недостаточно превосходит гарнизоны протекторатов (%d ед.)!\n  Возможен бунт! Наймите больше кораблей." % [fleet_str, total_prot_str],
				13, Color(1.0, 0.3, 0.2))
			rb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			_hq_list.add_child(rb)
		var total_prot_income: int = 0
		for prot in GameManager.protectorates:
			total_prot_income += int(prot.get("income", 0))
			var pc := PanelContainer.new()
			pc.custom_minimum_size = Vector2(0, 52)
			var phb := HBoxContainer.new()
			pc.add_child(phb)
			var pico := _lbl("🏴", 24)
			pico.custom_minimum_size = Vector2(36, 0)
			phb.add_child(pico)
			var pvb := VBoxContainer.new()
			pvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			phb.add_child(pvb)
			pvb.add_child(_lbl(prot["name"], 16))
			pvb.add_child(_lbl("Бывш. фракция: %s  |  Гарнизон: %d ед." % [prot.get("faction","?"), prot.get("garrison_strength", 0)], 12, Color(0.6,0.6,0.7)))
			var inc_lbl := _lbl("+%d кред./день" % prot.get("income", 0), 14, Color(0.3, 1.0, 0.55))
			inc_lbl.custom_minimum_size = Vector2(140, 0)
			inc_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			phb.add_child(inc_lbl)
			_hq_list.add_child(pc)
		_hq_list.add_child(_lbl("Итого доход протекторатов: +%d кред./день" % total_prot_income, 14, Color(0.95, 0.82, 0.2)))

	_hq_list.add_child(HSeparator.new())

	# ── Объявление войны ──────────────────────────────────────────────────────────
	_hq_list.add_child(_lbl("⚔  ВОЙНА", 18, Color(1.0, 0.35, 0.25)))
	_hq_list.add_child(_lbl(
		"Объявление войны даёт право завоевать системы врага (-40 репутации у цели).\n" +
		"Для завоевания нужно: ввести в систему ≥7 союзников и ≥3 дредноута, затем уничтожить врагов.",
		12, Color(0.6, 0.55, 0.55)))
	_hq_list.add_child(HSeparator.new())

	const WAR_FACTION_ICONS := {
		"Федерация":   "🔵",
		"Торговцы":    "🟡",
		"Независимые": "⚪",
		"Пираты":      "💀",
		"Империя":     "🔴",
	}
	var base_factions := ["Федерация", "Торговцы", "Независимые", "Пираты", "Империя"]
	for wf in base_factions:
		if wf == fname: continue   # не воевать с собой
		var at_war: bool = wf in GameManager.war_targets
		var rep: int = GameManager.faction_reputation.get(wf, 0)
		var wcard := PanelContainer.new()
		wcard.custom_minimum_size = Vector2(0, 52)
		var whb := HBoxContainer.new()
		wcard.add_child(whb)
		var wico := _lbl(WAR_FACTION_ICONS.get(wf, "·"), 24)
		wico.custom_minimum_size = Vector2(36, 0)
		whb.add_child(wico)
		var wvb := VBoxContainer.new()
		wvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		whb.add_child(wvb)
		wvb.add_child(_lbl(wf, 16))
		var rep_col := Color(1.0, 0.35, 0.25) if at_war else (Color(0.35, 0.95, 0.45) if rep >= 0 else Color(1.0, 0.6, 0.2))
		wvb.add_child(_lbl(
			("⚔ В СОСТОЯНИИ ВОЙНЫ" if at_war else "Репутация: %+d" % rep), 12, rep_col))
		var wbtn := Button.new()
		wbtn.custom_minimum_size = Vector2(160, 0)
		var captured_wf: String = wf
		if at_war:
			wbtn.text = "🕊 Заключить мир"
			wbtn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
			wbtn.pressed.connect(func():
				GameManager.end_war(captured_wf)
				_populate_hq())
		else:
			wbtn.text = "⚔ Объявить войну"
			wbtn.add_theme_color_override("font_color", Color(1.0, 0.35, 0.25))
			wbtn.pressed.connect(func():
				GameManager.declare_war(captured_wf)
				_populate_hq())
		whb.add_child(wbtn)
		_hq_list.add_child(wcard)

	_hq_list.add_child(HSeparator.new())

	# ── Набор союзников ─────────────────────────────────────────────────────────
	_hq_list.add_child(_lbl("⚔  НАБОР СОЮЗНИКОВ", 18, Color(0.55, 0.85, 1.0)))
	_hq_list.add_child(_lbl(
		"Каждый союзник несёт службу в штабе и приносит ежедневный доход.",
		13, Color(0.5, 0.55, 0.65)))
	_hq_list.add_child(HSeparator.new())

	for ship_data in HQ_ALLY_SHIPS:
		var cost: int = ship_data["cost"]
		var income: int = ship_data["income"]
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(0, 80)
		var hb := HBoxContainer.new()
		card.add_child(hb)
		var icon_l := _lbl(ship_data["icon"], 32)
		icon_l.custom_minimum_size = Vector2(50, 0)
		icon_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hb.add_child(icon_l)
		var info_vb := VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hb.add_child(info_vb)
		info_vb.add_child(_lbl(ship_data["name"], 17))
		info_vb.add_child(_lbl(ship_data["desc"], 13, Color(0.65, 0.65, 0.65)))
		info_vb.add_child(_lbl("💰 Доход: +%d кред./день" % income, 13, Color(0.3, 1.0, 0.55)))
		var buy_vb := VBoxContainer.new()
		buy_vb.custom_minimum_size = Vector2(160, 0)
		hb.add_child(buy_vb)
		var price_l := _lbl("%d кред." % cost, 16, Color(1.0, 0.88, 0.3))
		price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		buy_vb.add_child(price_l)
		var recruit_btn := Button.new()
		recruit_btn.text = "Завербовать"
		recruit_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.55))
		recruit_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recruit_btn.disabled = GameManager.credits < cost
		var cap_cost: int    = cost
		var cap_inc:  int    = income
		var cap_ship: String = ship_data["name"]
		recruit_btn.pressed.connect(func(): _hq_recruit(cap_cost, cap_inc, cap_ship))
		buy_vb.add_child(recruit_btn)
		_hq_list.add_child(card)

	# ── Текущий состав ──────────────────────────────────────────────────────────
	if allies.size() > 0:
		_hq_list.add_child(HSeparator.new())
		_hq_list.add_child(_lbl("👥  ТЕКУЩИЙ СОСТАВ ФЛОТА", 18, Color(0.85, 0.65, 1.0)))
		if at_hq:
			_hq_list.add_child(_lbl(
				"📡 Вы в штабе — можно командовать флотом. Минимум 3 корабля должны оставаться в штабе.",
				12, Color(0.5, 0.75, 0.55)))

		# Список посещённых систем для дислокации
		var dest_options: Array = []
		dest_options.append("📍 Штаб (%s)" % hq_sys)
		for sname in GameManager.visited_galaxy_names:
			if sname != hq_sys:
				dest_options.append("🌐 " + sname)

		for ally in allies:
			var ally_loc: String = ally.get("location", "hq")
			var is_in_hq: bool  = (ally_loc == "hq")
			var loc_display: String = ("📍 Штаб" if is_in_hq else "🌐 " + ally_loc)

			var card2 := PanelContainer.new()
			card2.custom_minimum_size = Vector2(0, 56)
			var r := VBoxContainer.new()
			card2.add_child(r)

			# Строка 1: инфо об союзнике
			var row1 := HBoxContainer.new()
			r.add_child(row1)
			var icon_col := Color(0.3, 1.0, 0.55) if is_in_hq else Color(0.6, 0.75, 1.0)
			row1.add_child(_lbl(ally.get("icon", "✈"), 20))
			var al := _lbl("  %s  —  %s" % [ally.get("name", "?"), ally.get("ship", "?")], 15)
			al.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row1.add_child(al)
			row1.add_child(_lbl(loc_display, 13, icon_col))
			row1.add_child(_lbl("  +%d к./д" % int(ally.get("income", 0)), 13, Color(0.3, 1.0, 0.55)))

			var dismiss_btn := Button.new()
			dismiss_btn.text = "Уволить"
			dismiss_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.3))
			dismiss_btn.custom_minimum_size = Vector2(85, 0)
			var cap_ally: Dictionary = ally
			dismiss_btn.pressed.connect(func(): _hq_dismiss(cap_ally))
			row1.add_child(dismiss_btn)

			# Строка 2: дислокация (только в штабе)
			if at_hq:
				var row2 := HBoxContainer.new()
				r.add_child(row2)
				row2.add_child(_lbl("  ⇒ Передислоцировать:", 13, Color(0.6, 0.7, 0.85)))

				var dest_opt := OptionButton.new()
				dest_opt.add_theme_font_size_override("font_size", 13)
				dest_opt.custom_minimum_size = Vector2(220, 0)
				for opt_txt in dest_options:
					dest_opt.add_item(opt_txt)
				# Установить текущую локацию как выбранную
				var cur_sel: int = 0
				if not is_in_hq:
					for di in dest_options.size():
						if dest_options[di].ends_with(ally_loc):
							cur_sel = di
							break
				dest_opt.selected = cur_sel
				row2.add_child(dest_opt)

				var apply_btn := Button.new()
				apply_btn.text = "Применить"
				apply_btn.add_theme_font_size_override("font_size", 13)
				apply_btn.custom_minimum_size = Vector2(120, 0)
				apply_btn.add_theme_color_override("font_color", Color(0.3, 0.9, 0.6))

				var cap_ally2: Dictionary = ally
				var cap_opt: OptionButton = dest_opt
				var cap_hq_count: int = at_hq_count
				apply_btn.pressed.connect(func():
					var sel_idx: int = cap_opt.selected
					var new_loc: String
					if sel_idx == 0:
						new_loc = "hq"
					else:
						# Извлекаем имя системы (убираем иконку)
						new_loc = dest_options[sel_idx].trim_prefix("🌐 ")
					var cur_loc: String = cap_ally2.get("location", "hq")
					# Проверка минимума 3 в штабе при уводе из штаба
					if cur_loc == "hq" and new_loc != "hq" and cap_hq_count <= 3:
						return  # нельзя убрать — осталось бы меньше 3
					cap_ally2["location"] = new_loc
					_populate_hq()
					_refresh_credits())
				# Если пытаемся убрать из штаба и осталось бы < 3 — заблокировать кнопку визуально
				# (пересчитываем при рендере)
				if is_in_hq and at_hq_count <= 3:
					apply_btn.disabled = true
					apply_btn.tooltip_text = "Нельзя: в штабе должно быть не менее 3 кораблей"
				row2.add_child(apply_btn)

			_hq_list.add_child(card2)

func _hq_recruit(cost: int, income: int, ship_name: String) -> void:
	if not GameManager.spend_credits(cost):
		return
	var idx: int = GameManager.faction_allies.size() % HQ_ALLY_NAMES.size()
	var ally_name: String = HQ_ALLY_NAMES[idx]
	var icon := "✈"
	for sd in HQ_ALLY_SHIPS:
		if sd["name"] == ship_name:
			icon = sd["icon"]
			break
	# location: "hq" — новый союзник базируется в штабе
	GameManager.faction_allies.append({
		"name": ally_name, "ship": ship_name, "income": income, "icon": icon, "location": "hq"
	})
	_populate_hq()
	_refresh_credits()

func _hq_dismiss(ally: Dictionary) -> void:
	GameManager.faction_allies.erase(ally)
	_populate_hq()

# ── Helpers ───────────────────────────────────────────────────────────────────

func _make_item_card(title: String, desc: String, stats: String,
		price: int, btn_text: String, btn_disabled: bool, cb: Callable) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 80)
	var hb := HBoxContainer.new()
	card.add_child(hb)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(info)

	var name_l := _lbl(title, 19)
	info.add_child(name_l)
	var desc_l := _lbl(desc, 13)
	desc_l.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	info.add_child(desc_l)
	info.add_child(_lbl(stats, 14))

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(160, 0)
	hb.add_child(right)

	var price_l := _lbl("%d кред." % price, 16)
	price_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	right.add_child(price_l)

	var btn := Button.new()
	btn.text = btn_text
	btn.disabled = btn_disabled or (not btn_disabled and GameManager.credits < price)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(cb)
	right.add_child(btn)

	return card

func _lbl(text: String, size: int = 15, col: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	return l

func _clear(container: VBoxContainer) -> void:
	for c in container.get_children():
		c.queue_free()
