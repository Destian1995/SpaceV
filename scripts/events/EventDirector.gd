extends Node
class_name EventDirector

# Random event system — fires unpredictable events while traveling or docked

signal event_triggered(event: Dictionary)

const EVENTS: Array = [
	{
		"id": "pirate_ambush",
		"title": "Пираты на перехвате!",
		"desc": "Неизвестный корабль выходит из тени астероида прямо по курсу.",
		"weight": 15,
		"type": "combat",
		"choices": ["Вступить в бой", "Попытаться уйти", "Переговоры"]
	},
	{
		"id": "distress_signal",
		"title": "Сигнал бедствия",
		"desc": "На частоте SOS принят сигнал. Источник — ближайшая луна.",
		"weight": 12,
		"type": "choice",
		"choices": ["Исследовать", "Игнорировать"]
	},
	{
		"id": "engine_fault",
		"title": "Неисправность двигателя",
		"desc": "Инженер докладывает — топливный инжектор даёт сбой.",
		"weight": 10,
		"type": "ship",
		"choices": ["Экстренный ремонт (500 кред.)", "Лететь дальше с риском"]
	},
	{
		"id": "trader_encounter",
		"title": "Странствующий торговец",
		"desc": "Небольшой транспортник предлагает редкие товары по сниженной цене.",
		"weight": 14,
		"type": "trade",
		"choices": ["Торговать", "Пройти мимо"]
	},
	{
		"id": "crew_conflict",
		"title": "Конфликт на борту",
		"desc": "Два члена экипажа не поделили жилой отсек. Нужно решение.",
		"weight": 8,
		"type": "crew",
		"choices": ["Встать на сторону одного", "Примирить", "Строгий выговор"]
	},
	{
		"id": "asteroid_field",
		"title": "Незарегистрированный астероидный пояс",
		"desc": "Навигатор не предупредил об этом поле. Манёвр на пределе.",
		"weight": 11,
		"type": "navigation",
		"choices": ["Проложить путь через поле (быстро)", "Обойти (долго)"]
	},
	{
		"id": "ancient_wreck",
		"title": "Древний обломок",
		"desc": "Сканер фиксирует корабль неизвестной постройки — эпоха неизвестна.",
		"weight": 6,
		"type": "exploration",
		"choices": ["Отправить команду на борт", "Просканировать издали", "Игнорировать"]
	},
	{
		"id": "epidemic",
		"title": "Вспышка болезни",
		"desc": "Несколько членов экипажа слегли с лихорадкой. Медик нужен срочно.",
		"weight": 7,
		"type": "crew",
		"choices": ["Лечить (200 кред.)", "Карантин", "Игнорировать"]
	},
]

var _elapsed_time: float = 0.0
var _next_event_time: float = 0.0
var _active: bool = false

func _ready() -> void:
	_schedule_next()

func set_active(value: bool) -> void:
	_active = value

func _process(delta: float) -> void:
	if not _active:
		return
	_elapsed_time += delta
	if _elapsed_time >= _next_event_time:
		_elapsed_time = 0.0
		_schedule_next()
		_fire_random_event()

func _schedule_next() -> void:
	# Event every 45–120 seconds of play
	_next_event_time = randf_range(45.0, 120.0)

func _fire_random_event() -> void:
	var event := _weighted_pick()
	print("[EventDirector] Event: %s" % event["title"])
	event_triggered.emit(event)

func _weighted_pick() -> Dictionary:
	var total_weight := 0
	for e in EVENTS:
		total_weight += e["weight"]
	var roll := randi() % total_weight
	var cumulative := 0
	for e in EVENTS:
		cumulative += e["weight"]
		if roll < cumulative:
			return e
	return EVENTS[0]
