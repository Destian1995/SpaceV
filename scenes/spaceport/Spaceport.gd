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

	_bar_list     = _make_scroll_tab(tabs, "🍺 Бар")
	_trade_list   = _make_scroll_tab(tabs, "💰 Торговля")
	_weapons_list = _make_scroll_tab(tabs, "⚔ Оружие")
	_ships_list   = _make_scroll_tab(tabs, "🚀 Корабли")
	_quests_list  = _make_scroll_tab(tabs, "📋 Задания")

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
	var available: Array = current_planet.get("weapons", GameData.WEAPONS)
	if available.is_empty():
		_weapons_list.add_child(_lbl("Оружия нет в продаже", 16))
		return
	for w in available:
		var owned: bool = w["name"] in GameManager.equipped_weapons
		var card := _make_item_card(
			w["name"],
			w["desc"],
			"Урон: %d  |  Тип: %s" % [w["damage"], w["type"]],
			w["price"],
			"✅ Установлено" if owned else "Купить",
			owned,
			func(): _buy_weapon(w)
		)
		_weapons_list.add_child(card)

func _buy_weapon(w: Dictionary) -> void:
	if w["name"] in GameManager.equipped_weapons:
		return
	if GameManager.spend_credits(w["price"]):
		GameManager.equipped_weapons.append(w["name"])
		_populate_weapons()
		_refresh_credits()
		print("[Spaceport] Weapon purchased: %s" % w["name"])

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
		_populate_ships()
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
	print("[Bar] Quest completed: %s  +%d кред." % [q["title"], q["reward"]])
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
		dest_text = "📍 Сдать задание: %s / %s" % [q.get("dest_galaxy","?"), q.get("dest_planet","?")]
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
	GameManager.active_quests.append(q.duplicate())
	print("[Spaceport] Quest accepted: %s" % q["title"])
	_populate_quests()
	_refresh_credits()

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
