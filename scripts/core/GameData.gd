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
	 "price": 67500, "speed": 310, "cargo": 60,  "hull": 280, "shields": 90,  "sensors": 95,
	 "desc": "Элитный исследователь. Лучшие сенсоры класса, дальний прыжок, хорошая автономность."},
	{"name": "Скаут-Б",         "ship_type": "Исследовательский", "ship_class": "B",
	 "price": 33000, "speed": 270, "cargo": 40,  "hull": 200, "shields": 65,  "sensors": 75,
	 "desc": "Надёжный разведчик среднего класса. Хорошая скорость, средние сенсоры."},
	{"name": "Зонд-С",          "ship_type": "Исследовательский", "ship_class": "C",
	 "price": 12000, "speed": 220, "cargo": 20,  "hull": 150, "shields": 40,  "sensors": 55,
	 "desc": "Бюджетный разведчик. Слабое оборудование, но доступная цена."},
	# ── Грузовой ──────────────────────────────────────────────────────
	{"name": "Левиафан-А",      "ship_type": "Грузовой", "ship_class": "A",
	 "price": 87000, "speed": 130, "cargo": 400, "hull": 500, "shields": 70,  "sensors": 45,
	 "desc": "Огромный грузовик класса А. Максимальная вместимость трюма."},
	{"name": "Фрейтер-Б",       "ship_type": "Грузовой", "ship_class": "B",
	 "price": 36000, "speed": 160, "cargo": 220, "hull": 380, "shields": 50,  "sensors": 35,
	 "desc": "Стандартный торговый транспортник. Надёжный и вместительный."},
	{"name": "Баржа-С",         "ship_type": "Грузовой", "ship_class": "C",
	 "price": 13500, "speed": 110, "cargo": 100, "hull": 250, "shields": 30,  "sensors": 25,
	 "desc": "Дешёвый грузовик. Медленный, уязвимый, но много места."},
	# ── Боевой ────────────────────────────────────────────────────────
	{"name": "Дредноут-А",      "ship_type": "Боевой", "ship_class": "A",
	 "price": 127500, "speed": 200, "cargo": 80,  "hull": 900, "shields": 150, "sensors": 70,
	 "desc": "Тяжёлый дредноут. Максимальная броня и огневая мощь класса."},
	{"name": "Корвет-Б",        "ship_type": "Боевой", "ship_class": "B",
	 "price": 57000, "speed": 250, "cargo": 55,  "hull": 500, "shields": 110, "sensors": 60,
	 "desc": "Боевой корвет. Баланс скорости и огневой мощи."},
	{"name": "Перехватчик-С",   "ship_type": "Боевой", "ship_class": "C",
	 "price": 21000, "speed": 300, "cargo": 25,  "hull": 250, "shields": 65,  "sensors": 50,
	 "desc": "Лёгкий истребитель. Быстрый, но хрупкий."},
	# ── Ресурсодобывающий ─────────────────────────────────────────────
	{"name": "Горнодобытчик-А", "ship_type": "Ресурсодобывающий", "ship_class": "A",
	 "price": 78000, "speed": 120, "cargo": 300, "hull": 450, "shields": 60,  "sensors": 80,
	 "desc": "Промышленный шахтёр класса А. Мощные буры, большой трюм для руды."},
	{"name": "Бурильщик-Б",     "ship_type": "Ресурсодобывающий", "ship_class": "B",
	 "price": 39000, "speed": 140, "cargo": 180, "hull": 320, "shields": 45,  "sensors": 60,
	 "desc": "Средний добывающий корабль. Хороший баланс для начала."},
	{"name": "Кирка-С",         "ship_type": "Ресурсодобывающий", "ship_class": "C",
	 "price": 15000, "speed": 100, "cargo": 80,  "hull": 200, "shields": 25,  "sensors": 40,
	 "desc": "Базовый горнодобытчик. Минимальное оснащение."},
	# ── Штурмовой ─────────────────────────────────────────────────────
	{"name": "Рапира-А",        "ship_type": "Штурмовой", "ship_class": "A",
	 "price": 108000, "speed": 340, "cargo": 40,  "hull": 650, "shields": 200, "sensors": 80,
	 "desc": "Элитный штурмовик. Высочайшая скорость боевого класса, прекрасная манёвренность."},
	{"name": "Фалькон-Б",       "ship_type": "Штурмовой", "ship_class": "B",
	 "price": 46500, "speed": 290, "cargo": 30,  "hull": 380, "shields": 130, "sensors": 65,
	 "desc": "Быстрый штурмовик. Отличная манёвренность для боевых операций."},
	{"name": "Стриж-С",         "ship_type": "Штурмовой", "ship_class": "C",
	 "price": 18000, "speed": 260, "cargo": 15,  "hull": 180, "shields": 55,  "sensors": 45,
	 "desc": "Лёгкий штурмовик. Дёшевый, быстрый, уязвимый."},
	# ── Дипломатический ───────────────────────────────────────────────
	{"name": "Посол-А",         "ship_type": "Дипломатический", "ship_class": "A",
	 "price": 142500, "speed": 195, "cargo": 120, "hull": 600, "shields": 250, "sensors": 90,
	 "desc": "Роскошный дипломатический крейсер. Бонус +20 к репутации всех фракций при переговорах."},
	{"name": "Эмиссар-Б",       "ship_type": "Дипломатический", "ship_class": "B",
	 "price": 63000, "speed": 175, "cargo": 80,  "hull": 400, "shields": 160, "sensors": 70,
	 "desc": "Дипломатический транспорт. Внушает доверие и уважение во всех портах."},
	# ── Пиратский ─────────────────────────────────────────────────────
	{"name": "Хищник-А",        "ship_type": "Пиратский", "ship_class": "A",
	 "price": 102000, "speed": 310, "cargo": 110, "hull": 700, "shields": 170, "sensors": 60,
	 "desc": "Тяжёлый рейдер пиратов. Много орудий, вместительный трюм для добычи. Покупка снижает репутацию Федерации."},
	{"name": "Корсар-Б",        "ship_type": "Пиратский", "ship_class": "B",
	 "price": 42000, "speed": 275, "cargo": 75,  "hull": 420, "shields": 100, "sensors": 50,
	 "desc": "Лёгкий корсар. Быстрый налётчик среднего класса."},
	# ── Флагманский (требует лидерство фракцией) ──────────────────────
	{"name": "Колосс-А",        "ship_type": "Флагманский", "ship_class": "A",
	 "price": 750000, "speed": 170, "cargo": 250, "hull": 2000, "shields": 300, "sensors": 100,
	 "desc": "ФЛАГМАН КЛАССА А — Командный корабль фракции. Только для лидера. Управляй флотом с мостика."},
	{"name": "Авангард-Б",      "ship_type": "Флагманский", "ship_class": "B",
	 "price": 330000, "speed": 195, "cargo": 180, "hull": 1200, "shields": 220, "sensors": 85,
	 "desc": "ФЛАГМАН КЛАССА Б — Боевой крейсер командования. Требует лидерства фракцией."},
	{"name": "Командор-С",      "ship_type": "Флагманский", "ship_class": "C",
	 "price": 142500, "speed": 215, "cargo": 120, "hull": 750,  "shields": 150, "sensors": 70,
	 "desc": "ФЛАГМАН КЛАССА С — Тяжёлый фрегат командования. Начальный флагман лидера."},
]

const WEAPONS := [
	# Лёгкое
	{"name": "Импульсное орудие",      "price":  2700, "damage":  25, "type": "pulse",    "ammo": 200,
	 "desc": "Скорострельное лёгкое орудие. Небольшой урон, но высокий темп огня. Батарей: 200."},
	# Среднее
	{"name": "Лазерные пушки",         "price":  6750, "damage":  70, "type": "energy",   "ammo": 100,
	 "desc": "Стандартное энергетическое оружие. Надёжное и точное. Батарей: 100."},
	{"name": "Электропушка",           "price":  9000, "damage": 110, "type": "emp",      "ammo": 80,
	 "desc": "Электромагнитный разряд. Выводит системы врага из строя. Батарей: 80."},
	# Тяжёлое
	{"name": "Турболазерные батареи",  "price": 14250, "damage": 155, "type": "turbolaser","ammo": 60,
	 "desc": "Двойной лазерный залп: выстреливает 2 снаряда одновременно. Батарей: 60."},
	{"name": "Плазменные пушки",       "price": 16500, "damage": 160, "type": "plasma",   "ammo": 50,
	 "desc": "Плазменные сгустки пробивают щиты. Веер из 3 снарядов. Батарей: 50."},
	{"name": "Торпеды Z-120",          "price": 22500, "damage": 200, "type": "torpedo",  "ammo": 5,
	 "desc": "Самонаводящиеся торпеды. Сокрушительный урон. Боезапас: 5 торпед."},
	# Сверхтяжёлое
	{"name": "Рельсовая пушка",        "price": 33000, "damage": 700, "type": "railgun",       "ammo": 15,
	 "desc": "Кинетический снаряд с чудовищным уроном. Зарядов: 15."},
	{"name": "Торпеды Z-240",          "price": 90000, "damage": 600, "type": "torpedo_heavy", "ammo": 4,
	 "desc": "Тяжёлые торпеды Z-240. При пуске весь боезапас уходит залпом — по торпеде на цель. Боезапас: 4."},
]

# ── Weapon categories ────────────────────────────────────────────────────────
const WEAPON_CATEGORY := {
	"Импульсное орудие":     "light",
	"Лазерные пушки":        "medium",
	"Электропушка":          "medium",
	"Турболазерные батареи": "heavy",
	"Плазменные пушки":      "heavy",
	"Торпеды Z-120":         "heavy",
	"Рельсовая пушка":       "superheavy",
	"Торпеды Z-240":         "superheavy",
}

# ship_type → ship_class → {slots, cats}
const SHIP_WEAPON_RULES := {
	"Исследовательский": {
		"C": {"slots": 1, "cats": ["light"]},
		"B": {"slots": 2, "cats": ["light", "medium"]},
		"A": {"slots": 3, "cats": ["light", "medium"]},
	},
	"Грузовой": {
		"C": {"slots": 1, "cats": ["light", "medium"]},
		"B": {"slots": 2, "cats": ["medium"]},
		"A": {"slots": 2, "cats": ["medium"]},
	},
	"Боевой": {
		"C": {"slots": 3, "cats": ["light", "medium", "heavy"]},
		"B": {"slots": 4, "cats": ["light", "medium", "heavy"]},
		"A": {"slots": 5, "cats": ["light", "medium", "heavy", "superheavy"]},
	},
	"Ресурсодобывающий": {
		"C": {"slots": 1, "cats": ["light"]},
		"B": {"slots": 2, "cats": ["light", "medium"]},
		"A": {"slots": 3, "cats": ["light", "medium"]},
	},
	"Штурмовой": {
		"C": {"slots": 3, "cats": ["light", "medium"]},
		"B": {"slots": 4, "cats": ["light", "medium", "heavy"]},
		"A": {"slots": 5, "cats": ["light", "medium", "heavy"]},
	},
	"Дипломатический": {
		"B": {"slots": 2, "cats": ["light", "medium"]},
		"A": {"slots": 3, "cats": ["light", "medium"]},
	},
	"Пиратский": {
		"B": {"slots": 4, "cats": ["light", "medium", "heavy"]},
		"A": {"slots": 5, "cats": ["light", "medium", "heavy", "superheavy"]},
	},
	"Флагманский": {
		"C": {"slots": 4, "cats": ["light", "medium", "heavy"]},
		"B": {"slots": 5, "cats": ["light", "medium", "heavy", "superheavy"]},
		"A": {"slots": 6, "cats": ["light", "medium", "heavy", "superheavy"]},
	},
}

func get_ship_weapon_slots(ship: Dictionary) -> int:
	var stype:  String = ship.get("ship_type",  "Исследовательский")
	var sclass: String = ship.get("ship_class", "C")
	if not SHIP_WEAPON_RULES.has(stype):
		return 2
	var tr: Dictionary = SHIP_WEAPON_RULES[stype]
	if tr.has(sclass):
		return tr[sclass]["slots"]
	# fallback to first class available
	return tr.values()[0]["slots"]

func get_ship_allowed_cats(ship: Dictionary) -> Array:
	var stype:  String = ship.get("ship_type",  "Исследовательский")
	var sclass: String = ship.get("ship_class", "C")
	if not SHIP_WEAPON_RULES.has(stype):
		return ["light", "medium", "heavy"]
	var tr: Dictionary = SHIP_WEAPON_RULES[stype]
	if tr.has(sclass):
		return tr[sclass]["cats"]
	return tr.values()[0]["cats"]

# Returns "" if OK, human-readable error if not
func can_equip_weapon(ship: Dictionary, weapon: Dictionary, equipped: Array) -> String:
	var slots := get_ship_weapon_slots(ship)
	if equipped.size() >= slots:
		return "Слоты заполнены (%d/%d)" % [equipped.size(), slots]
	var allowed: Array = get_ship_allowed_cats(ship)
	var cat: String = WEAPON_CATEGORY.get(weapon["name"], "medium")
	if cat not in allowed:
		var cat_ru := {"light": "лёгкое", "medium": "среднее", "heavy": "тяжёлое", "superheavy": "сверхтяжёлое"}
		return "%s оружие нельзя на %s" % [cat_ru.get(cat, cat), ship.get("ship_type", "?")]
	return ""

const QUEST_TYPES := [
	{
		"id": "cargo_delivery", "title": "Доставка груза",
		"desc": "Перевезите %d единиц %s на %s. Срочный заказ — клиент платит хорошо.",
		"reward_min": 2400,  "reward_max": 6000, "type": "trade",
		"icon": "📦"
	},
	{
		"id": "bounty_hunt", "title": "Охота за головой",
		"desc": "Пират по имени %s угрожает торговым путям. Уничтожьте его корабль. Живым не нужен.",
		"reward_min": 4500, "reward_max": 12000, "type": "combat",
		"icon": "💀"
	},
	{
		"id": "escort", "title": "Эскортирование",
		"desc": "Транспортный корабль следует в %s. Защитите его от пиратов на всём пути.",
		"reward_min": 3600, "reward_max": 9000, "type": "combat",
		"icon": "🛡"
	},
	{
		"id": "rescue", "title": "Спасательная операция",
		"desc": "Экипаж корабля застрял в секторе %s. Найдите их и доставьте в безопасное место.",
		"reward_min": 1800,  "reward_max": 5400, "type": "exploration",
		"icon": "🆘"
	},
	{
		"id": "smuggling", "title": "Контрабанда",
		"desc": "Груз нелегален, но хорошо оплачивается. Доставьте его в %s, минуя патрули.",
		"reward_min": 6000, "reward_max": 15000, "type": "trade",
		"icon": "🕵"
	},
	{
		"id": "patrol", "title": "Патрулирование сектора",
		"desc": "Патрулируйте сектор вокруг %s в течение трёх суток. Доложите об аномалиях.",
		"reward_min": 1500,  "reward_max": 3600, "type": "patrol",
		"icon": "🔭"
	},
	{
		"id": "exploration", "title": "Разведка системы",
		"desc": "Система %s до сих пор не картографирована. Исследуйте все планеты и вернитесь.",
		"reward_min": 2700,  "reward_max": 7500, "type": "exploration",
		"icon": "🗺"
	},
	{
		"id": "mining", "title": "Добыча ресурсов",
		"desc": "Добудьте %d единиц руды в поясе астероидов и доставьте на %s.",
		"reward_min": 2100,  "reward_max": 5400, "type": "trade",
		"icon": "⛏"
	},
	{
		"id": "assassination", "title": "Устранение цели",
		"desc": "Адмирал %s ведёт карательные экспедиции против мирных колоний. Остановите его.",
		"reward_min": 9000, "reward_max": 21000, "type": "combat",
		"icon": "🎯"
	},
	{
		"id": "data_retrieval", "title": "Извлечение данных",
		"desc": "Военный спутник на орбите %s содержит секретные коды. Взломайте и передайте данные.",
		"reward_min": 5400, "reward_max": 13500, "type": "stealth",
		"icon": "💾"
	},
	{
		"id": "diplomacy", "title": "Дипломатическая миссия",
		"desc": "Доставьте посла фракции %s на переговоры. Никаких стычек — репутация на кону.",
		"reward_min": 3000, "reward_max": 8400, "type": "trade",
		"icon": "🤝"
	},
	{
		"id": "defense", "title": "Оборона базы",
		"desc": "Пиратский флот атакует станцию %s. Помогите отразить несколько волн нападения.",
		"reward_min": 6000, "reward_max": 16500, "type": "combat",
		"icon": "🏰"
	},
	{
		"id": "mystery", "title": "Исчезновение корабля",
		"desc": "Транспортник «%s» не выходит на связь уже 5 суток. Выясните что произошло.",
		"reward_min": 3600, "reward_max": 9600, "type": "exploration",
		"icon": "👁"
	},
	{
		"id": "mercenary", "title": "Наёмник фракции",
		"desc": "Фракция %s ведёт войну и срочно нанимает пилотов. Три миссии, хорошая плата.",
		"reward_min": 7500, "reward_max": 18000, "type": "combat",
		"icon": "⚔"
	},
	{
		"id": "trade_run", "title": "Торговый рейс",
		"desc": "Купите товары здесь и продайте их в %s по максимальной цене. Время ограничено.",
		"reward_min": 1200,  "reward_max": 4500, "type": "trade",
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
# patrol и mystery требуют перелёта — вынесены из локальных
const LOCAL_QUEST_IDS := ["bounty_hunt","assassination","mercenary"]

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
			"data_retrieval":
				conditions   = {"type": "travel", "dest_galaxy": dest_galaxy}
			"exploration":
				conditions   = {"type": "travel", "dest_galaxy": dest_galaxy}
			"patrol":
				# Патрулирование: нужно добраться до системы и провести там 3 дня
				conditions   = {"type": "patrol", "days_needed": 3, "dest_galaxy": dest_galaxy}
			"mystery":
				# Расследование: нужно добраться до системы и вступить в бой
				conditions   = {"type": "combat_travel", "wins_needed": 1, "dest_galaxy": dest_galaxy}
			"defense":
				# Оборона базы: добраться и победить врагов в бою
				conditions   = {"type": "combat_travel", "wins_needed": 1, "dest_galaxy": dest_galaxy}
			"bounty_hunt","assassination","mercenary":
				conditions   = {"type": "local"}  # сдаётся в баре, но требует боевых побед

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
				return "Нужно доставить груз в систему «%s»" % dest
		"travel":
			var dest: String = cond.get("dest_galaxy", "")
			if dest != "" and GameManager.current_galaxy != dest:
				return "Нужно прибыть в систему «%s»" % dest
		"patrol":
			# Патрулирование: нужно оказаться в системе И провести там нужное число дней
			var dest: String = cond.get("dest_galaxy", "")
			if dest != "" and GameManager.current_galaxy != dest:
				return "Нужно прибыть в систему «%s» для патрулирования" % dest
			var day_at: int = q.get("day_at_accept", GameManager.day)
			var days_needed: int = cond.get("days_needed", 3)
			var days_spent: int = GameManager.day - day_at
			if days_spent < days_needed:
				return "Патрулируйте ещё %d дн. (прошло %d из %d)" % [days_needed - days_spent, days_spent, days_needed]
		"combat_travel":
			# Нужно прибыть в систему И выиграть бой
			var dest: String = cond.get("dest_galaxy", "")
			if dest != "" and GameManager.current_galaxy != dest:
				return "Нужно прибыть в систему «%s»" % dest
			var wins_at: int = q.get("battles_won_at_accept", GameManager.total_battles_won)
			var wins_needed: int = cond.get("wins_needed", 1)
			var wins_got: int = GameManager.total_battles_won - wins_at
			if wins_got < wins_needed:
				return "Выиграйте %d бой(ев) в этом секторе (выполнено %d/%d)" % [wins_needed - wins_got, wins_got, wins_needed]
		"local":
			# Боевые задания в баре требуют фактической победы в бою
			var qid: String = q.get("id", "")
			var wins_at: int = q.get("battles_won_at_accept", GameManager.total_battles_won)
			match qid:
				"bounty_hunt", "assassination":
					if GameManager.total_battles_won <= wins_at:
						return "Победите хотя бы в одном бою чтобы выполнить задание"
				"mercenary":
					var wins_got: int = GameManager.total_battles_won - wins_at
					if wins_got < 3:
						return "Выиграйте ещё %d боёв (выполнено %d/3)" % [3 - wins_got, wins_got]
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
