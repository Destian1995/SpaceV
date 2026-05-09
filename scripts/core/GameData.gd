extends Node
# Autoload: GameData — каталоги товаров, кораблей, оружия

const GOODS := {
	"Топливо":         {"base_price": 50,  "weight": 10},
	"Еда":             {"base_price": 30,  "weight": 5},
	"Металлы":         {"base_price": 120, "weight": 20},
	"Электроника":     {"base_price": 350, "weight": 8},
	"Медикаменты":     {"base_price": 200, "weight": 6},
	"Руда":            {"base_price": 80,  "weight": 25},
	"Предметы роскоши":{"base_price": 700, "weight": 3},
	"Оружие (груз)":   {"base_price": 500, "weight": 15},
}

# ship_type: Исследовательский | Грузовой | Боевой | Ресурсодобывающий | Флагманский
# ship_class: A (лучший) | B (средний) | C (базовый)
const SHIPS := [
	# ── Исследовательский ─────────────────────────────────────────────
	{"name": "Пионер-А",        "ship_type": "Исследовательский", "ship_class": "A",
	 "price": 45000, "speed": 310, "cargo": 60,  "hull": 280, "shields": 90,  "sensors": 95,
	 "desc": "Элитный исследователь. Лучшие сенсоры класса, дальний прыжок, хорошая автономность."},
	{"name": "Скаут-Б",         "ship_type": "Исследовательский", "ship_class": "B",
	 "price": 22000, "speed": 270, "cargo": 40,  "hull": 200, "shields": 65,  "sensors": 75,
	 "desc": "Надёжный разведчик среднего класса. Хорошая скорость, средние сенсоры."},
	{"name": "Зонд-С",          "ship_type": "Исследовательский", "ship_class": "C",
	 "price":  8000, "speed": 220, "cargo": 20,  "hull": 150, "shields": 40,  "sensors": 55,
	 "desc": "Бюджетный разведчик. Слабое оборудование, но доступная цена."},
	# ── Грузовой ──────────────────────────────────────────────────────
	{"name": "Левиафан-А",      "ship_type": "Грузовой", "ship_class": "A",
	 "price": 58000, "speed": 130, "cargo": 400, "hull": 500, "shields": 70,  "sensors": 45,
	 "desc": "Огромный грузовик класса А. Максимальная вместимость трюма."},
	{"name": "Фрейтер-Б",       "ship_type": "Грузовой", "ship_class": "B",
	 "price": 24000, "speed": 160, "cargo": 220, "hull": 380, "shields": 50,  "sensors": 35,
	 "desc": "Стандартный торговый транспортник. Надёжный и вместительный."},
	{"name": "Баржа-С",         "ship_type": "Грузовой", "ship_class": "C",
	 "price":  9000, "speed": 110, "cargo": 100, "hull": 250, "shields": 30,  "sensors": 25,
	 "desc": "Дешёвый грузовик. Медленный, уязвимый, но много места."},
	# ── Боевой ────────────────────────────────────────────────────────
	{"name": "Дредноут-А",      "ship_type": "Боевой", "ship_class": "A",
	 "price": 85000, "speed": 200, "cargo": 80,  "hull": 900, "shields": 150, "sensors": 70,
	 "desc": "Тяжёлый дредноут. Максимальная броня и огневая мощь класса."},
	{"name": "Корвет-Б",        "ship_type": "Боевой", "ship_class": "B",
	 "price": 38000, "speed": 250, "cargo": 55,  "hull": 500, "shields": 110, "sensors": 60,
	 "desc": "Боевой корвет. Баланс скорости и огневой мощи."},
	{"name": "Перехватчик-С",   "ship_type": "Боевой", "ship_class": "C",
	 "price": 14000, "speed": 300, "cargo": 25,  "hull": 250, "shields": 65,  "sensors": 50,
	 "desc": "Лёгкий истребитель. Быстрый, но хрупкий."},
	# ── Ресурсодобывающий ─────────────────────────────────────────────
	{"name": "Горнодобытчик-А", "ship_type": "Ресурсодобывающий", "ship_class": "A",
	 "price": 52000, "speed": 120, "cargo": 300, "hull": 450, "shields": 60,  "sensors": 80,
	 "desc": "Промышленный шахтёр класса А. Мощные буры, большой трюм для руды."},
	{"name": "Бурильщик-Б",     "ship_type": "Ресурсодобывающий", "ship_class": "B",
	 "price": 26000, "speed": 140, "cargo": 180, "hull": 320, "shields": 45,  "sensors": 60,
	 "desc": "Средний добывающий корабль. Хороший баланс для начала."},
	{"name": "Кирка-С",         "ship_type": "Ресурсодобывающий", "ship_class": "C",
	 "price": 10000, "speed": 100, "cargo": 80,  "hull": 200, "shields": 25,  "sensors": 40,
	 "desc": "Базовый горнодобытчик. Минимальное оснащение."},
	# ── Флагманский (требует лидерство фракцией) ──────────────────────
	{"name": "Колосс-А",        "ship_type": "Флагманский", "ship_class": "A",
	 "price": 500000, "speed": 170, "cargo": 250, "hull": 2000, "shields": 300, "sensors": 100,
	 "desc": "ФЛАГМАН КЛАССА А — Командный корабль фракции. Только для лидера. Управляй флотом с мостика."},
]

const WEAPONS := [
	{"name": "Лазерная пушка",    "price": 2000, "damage": 25,  "type": "energy",
	 "desc": "Стандартное энергетическое оружие. Надёжное и точное."},
	{"name": "Ракетный launcher", "price": 3500, "damage": 60,  "type": "missile",
	 "desc": "Высокий урон, ограниченный боезапас."},
	{"name": "Плазменная турель", "price": 5500, "damage": 80,  "type": "plasma",
	 "desc": "Мощное оружие, пробивает щиты врага."},
	{"name": "ЭМИ дизраптор",    "price": 4000, "damage": 15,  "type": "emp",
	 "desc": "Отключает системы врага. Ломает оборудование."},
	{"name": "Рельсотрон",        "price": 7000, "damage": 120, "type": "kinetic",
	 "desc": "Кинетическое орудие. Огромный урон, медленная перезарядка."},
	{"name": "Импульсный бластер","price": 1200, "damage": 18,  "type": "energy",
	 "desc": "Дешёвое и быстрострельное оружие начального уровня."},
]

const QUEST_TYPES := [
	{
		"id": "cargo_delivery", "title": "Доставка груза",
		"desc": "Перевезите %d единиц %s на %s. Срочный заказ — клиент платит хорошо.",
		"reward_min": 800,  "reward_max": 2000, "type": "trade",
		"icon": "📦"
	},
	{
		"id": "bounty_hunt", "title": "Охота за головой",
		"desc": "Пират по имени %s угрожает торговым путям. Уничтожьте его корабль. Живым не нужен.",
		"reward_min": 1500, "reward_max": 4000, "type": "combat",
		"icon": "💀"
	},
	{
		"id": "escort", "title": "Эскортирование",
		"desc": "Транспортный корабль следует в %s. Защитите его от пиратов на всём пути.",
		"reward_min": 1200, "reward_max": 3000, "type": "combat",
		"icon": "🛡"
	},
	{
		"id": "rescue", "title": "Спасательная операция",
		"desc": "Экипаж корабля застрял в секторе %s. Найдите их и доставьте в безопасное место.",
		"reward_min": 600,  "reward_max": 1800, "type": "exploration",
		"icon": "🆘"
	},
	{
		"id": "smuggling", "title": "Контрабанда",
		"desc": "Груз нелегален, но хорошо оплачивается. Доставьте его в %s, минуя патрули.",
		"reward_min": 2000, "reward_max": 5000, "type": "trade",
		"icon": "🕵"
	},
	{
		"id": "patrol", "title": "Патрулирование сектора",
		"desc": "Патрулируйте сектор вокруг %s в течение трёх суток. Доложите об аномалиях.",
		"reward_min": 500,  "reward_max": 1200, "type": "patrol",
		"icon": "🔭"
	},
	{
		"id": "exploration", "title": "Разведка системы",
		"desc": "Система %s до сих пор не картографирована. Исследуйте все планеты и вернитесь.",
		"reward_min": 900,  "reward_max": 2500, "type": "exploration",
		"icon": "🗺"
	},
	{
		"id": "mining", "title": "Добыча ресурсов",
		"desc": "Добудьте %d единиц руды в поясе астероидов и доставьте на %s.",
		"reward_min": 700,  "reward_max": 1800, "type": "trade",
		"icon": "⛏"
	},
	{
		"id": "assassination", "title": "Устранение цели",
		"desc": "Адмирал %s ведёт карательные экспедиции против мирных колоний. Остановите его.",
		"reward_min": 3000, "reward_max": 7000, "type": "combat",
		"icon": "🎯"
	},
	{
		"id": "data_retrieval", "title": "Извлечение данных",
		"desc": "Военный спутник на орбите %s содержит секретные коды. Взломайте и передайте данные.",
		"reward_min": 1800, "reward_max": 4500, "type": "stealth",
		"icon": "💾"
	},
	{
		"id": "diplomacy", "title": "Дипломатическая миссия",
		"desc": "Доставьте посла фракции %s на переговоры. Никаких стычек — репутация на кону.",
		"reward_min": 1000, "reward_max": 2800, "type": "trade",
		"icon": "🤝"
	},
	{
		"id": "defense", "title": "Оборона базы",
		"desc": "Пиратский флот атакует станцию %s. Помогите отразить несколько волн нападения.",
		"reward_min": 2000, "reward_max": 5500, "type": "combat",
		"icon": "🏰"
	},
	{
		"id": "mystery", "title": "Исчезновение корабля",
		"desc": "Транспортник «%s» не выходит на связь уже 5 суток. Выясните что произошло.",
		"reward_min": 1200, "reward_max": 3200, "type": "exploration",
		"icon": "👁"
	},
	{
		"id": "mercenary", "title": "Наёмник фракции",
		"desc": "Фракция %s ведёт войну и срочно нанимает пилотов. Три миссии, хорошая плата.",
		"reward_min": 2500, "reward_max": 6000, "type": "combat",
		"icon": "⚔"
	},
	{
		"id": "trade_run", "title": "Торговый рейс",
		"desc": "Купите товары здесь и продайте их в %s по максимальной цене. Время ограничено.",
		"reward_min": 400,  "reward_max": 1500, "type": "trade",
		"icon": "💰"
	},
]

const PIRATE_NAMES := ["Красный Кракен","Змей Дракаров","Безликий","Тень Коса","Ваар Жестокий"]
const ADMIRAL_NAMES := ["Адм. Серров","Адм. Лейкс","Ком. Брута","Ком. Хейд"]
const SHIP_NAMES := ["Торнадо","Эхо-5","Нептун II","Марево","Быстрый"]
const GOODS_NAMES := ["Металлы","Электроника","Медикаменты","Руда","Топливо"]
const FACTION_NAMES := ["Федерация","Торговцы","Империя","Независимые"]
const SYSTEM_NAMES := ["Vega Drift","Krath Station","Pyrox","Nova Reach","Auren Gate"]

# Квесты, сдаваемые прямо в баре (без перелёта)
const LOCAL_QUEST_IDS := ["bounty_hunt","assassination","mystery","mercenary","patrol"]

# Квесты с условием наличия груза
const CARGO_QUEST_IDS := ["cargo_delivery","smuggling","mining"]

func generate_quests(rng: RandomNumberGenerator, planet_name: String, galaxy_name: String) -> Array:
	var result := []
	var shuffled := QUEST_TYPES.duplicate()
	for i in range(shuffled.size() - 1, 0, -1):
		var j: int = rng.randi() % (i + 1)
		var tmp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = tmp
	var count: int = rng.randi_range(1, 3)
	for k in count:
		var qt: Dictionary = shuffled[k].duplicate()
		var reward: int = rng.randi_range(qt["reward_min"], qt["reward_max"])
		var is_local: bool = qt["id"] in LOCAL_QUEST_IDS

		# Destination = only a galaxy (any spaceport there is valid)
		var dest_galaxy: String = galaxy_name
		if not is_local:
			var dest_sys: String = SYSTEM_NAMES[rng.randi() % SYSTEM_NAMES.size()]
			var attempts := 0
			while dest_sys == galaxy_name and attempts < 5:
				dest_sys = SYSTEM_NAMES[rng.randi() % SYSTEM_NAMES.size()]
				attempts += 1
			dest_galaxy = dest_sys

		# Human-readable destination in description
		var dest_label: String = "систему %s (любой космопорт)" % dest_galaxy if not is_local else "бар здесь"

		# Build conditions
		var conditions := {}
		var cargo_item := ""
		var cargo_amount := 0
		match qt["id"]:
			"cargo_delivery":
				cargo_item   = GOODS_NAMES[rng.randi() % GOODS_NAMES.size()]
				cargo_amount = rng.randi_range(5, 20)
				conditions   = {"type": "cargo_and_travel", "item": cargo_item, "amount": cargo_amount, "dest_galaxy": dest_galaxy}
			"smuggling":
				cargo_item   = GOODS_NAMES[rng.randi() % GOODS_NAMES.size()]
				cargo_amount = rng.randi_range(3, 12)
				conditions   = {"type": "cargo_and_travel", "item": cargo_item, "amount": cargo_amount, "dest_galaxy": dest_galaxy}
			"mining":
				cargo_item   = "Руда"
				cargo_amount = rng.randi_range(10, 40)
				conditions   = {"type": "cargo_and_travel", "item": cargo_item, "amount": cargo_amount, "dest_galaxy": dest_galaxy}
			"trade_run":
				conditions   = {"type": "travel", "dest_galaxy": dest_galaxy}
			"escort","rescue","diplomacy":
				conditions   = {"type": "travel", "dest_galaxy": dest_galaxy}
			"exploration","patrol","data_retrieval":
				conditions   = {"type": "travel", "dest_galaxy": dest_galaxy}
			"defense":
				conditions   = {"type": "travel", "dest_galaxy": dest_galaxy}
			"bounty_hunt","assassination","mercenary","mystery":
				conditions   = {"type": "local"}  # solvable in bar at origin

		# Format description
		var desc: String = qt["desc"]
		match qt["id"]:
			"cargo_delivery":
				desc = desc % [cargo_amount, cargo_item, dest_label]
			"bounty_hunt":
				desc = desc % [PIRATE_NAMES[rng.randi() % PIRATE_NAMES.size()]]
			"escort","patrol","exploration","data_retrieval","defense","rescue":
				desc = desc % [dest_label]
			"smuggling":
				desc = desc % [dest_label]
			"mining":
				desc = desc % [cargo_amount, dest_label]
			"assassination":
				desc = desc % [ADMIRAL_NAMES[rng.randi() % ADMIRAL_NAMES.size()]]
			"diplomacy":
				desc = desc % [FACTION_NAMES[rng.randi() % FACTION_NAMES.size()]]
			"mystery":
				desc = desc % [SHIP_NAMES[rng.randi() % SHIP_NAMES.size()]]
			"mercenary":
				desc = desc % [FACTION_NAMES[rng.randi() % FACTION_NAMES.size()]]
			"trade_run":
				desc = desc % [dest_label]

		result.append({
			"id":             qt["id"],
			"icon":           qt["icon"],
			"title":          qt["title"],
			"desc":           desc,
			"reward":         reward,
			"done":           false,
			"origin":         planet_name,
			"origin_galaxy":  galaxy_name,
			"dest_galaxy":    dest_galaxy,
			"is_local":       is_local,
			"conditions":     conditions,
		})
	return result

# Returns "" if conditions met, else human-readable reason why not
func check_quest_conditions(q: Dictionary) -> String:
	var cond: Dictionary = q.get("conditions", {})
	var ctype: String = cond.get("type", "local")
	match ctype:
		"cargo_and_travel":
			var item: String  = cond.get("item", "")
			var need: int     = cond.get("amount", 0)
			var have: int     = GameManager.cargo.get(item, 0)
			var dest: String  = cond.get("dest_galaxy", "")
			if have < need:
				return "Недостаточно груза: нужно %d × %s, есть %d" % [need, item, have]
			if dest != "" and GameManager.current_galaxy != dest:
				return "Нужно быть в системе «%s»" % dest
		"travel":
			var dest: String = cond.get("dest_galaxy", "")
			if dest != "" and GameManager.current_galaxy != dest:
				return "Нужно быть в системе «%s»" % dest
		"local":
			pass  # always completable in bar
	return ""

func generate_planet_goods(rng: RandomNumberGenerator) -> Dictionary:
	var result := {}
	for item in GOODS:
		if rng.randf() > 0.35:
			var base: int = GOODS[item]["base_price"]
			var variance := rng.randf_range(0.6, 1.6)
			result[item] = {
				"buy_price":  int(base * variance * 1.15),
				"sell_price": int(base * variance * 0.85),
				"stock":      rng.randi_range(5, 50),
			}
	return result

func get_random_weapons(rng: RandomNumberGenerator) -> Array:
	var available := []
	for w in WEAPONS:
		if rng.randf() > 0.35:
			available.append(w)
	if available.is_empty():
		available.append(WEAPONS[0])
	return available

func get_random_ships(rng: RandomNumberGenerator) -> Array:
	var available := []
	for s in SHIPS:
		if rng.randf() > 0.4:
			available.append(s)
	if available.is_empty():
		available.append(SHIPS[0])
	return available
