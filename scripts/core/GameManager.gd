extends Node

enum GameState { GALAXY_MAP, STAR_SYSTEM, SPACEPORT, COMBAT }

var current_state: GameState = GameState.GALAXY_MAP
var credits: int = 500000
var day: int = 1

# Navigation
var current_galaxy: String = "Sol Prime"
var current_galaxy_idx: int = 0
var current_danger: int = 1

# Ship
var current_ship: Dictionary = {
	"name": "Зонд-С", "ship_type": "Исследовательский", "ship_class": "C",
	"speed": 220, "cargo": 20, "hull": 150, "shields": 40, "sensors": 55,
	"desc": "Бюджетный разведчик. Слабое оборудование, но доступная цена."
}
var faction_leader_of: String = ""  # название фракции если игрок лидер
var player_faction:    String = ""  # фракция к которой принадлежит игрок ("" = без фракции)
# Союзники фракции: массив словарей {name, ship, income, level}
var faction_allies: Array = []
var equipped_weapons: Array = []

# Cargo hold
var cargo: Dictionary = {}  # item_name -> quantity
var cargo_capacity: int = 50

# Quests
var active_quests: Array = []
var completed_quests: Array = []

# Bank
var bank_balance: int = 0
var loan_amount: int = 0
var loan_interest: float = 0.12  # 12% per day

# Combat — враг который напал в StarSystem
var pending_enemy_variant: int = 1
var pending_enemy_hull: int = 80
var pending_enemy_id: int = -1       # id конкретного врага которого нужно удалить после победы
var combat_result: String = ""       # "won" | "lost" | "retreat" | ""

# Ship damage persistence
var ship_hull_pct: float = 1.0       # текущий корпус как доля от максимума (0.0–1.0)

# Ship upgrades (array of upgrade IDs, e.g. ["volley", "boost"])
var ship_upgrades: Array = []

# Weapon damage / ammo persistence between combats
var damaged_weapons:    Array      = []   # slot indices that are damaged
var weapon_ammo_state:  Dictionary = {}   # weapon_name -> ammo_remaining

# Враги уничтоженные в текущей системе (сбрасывается при смене системы)
var current_system_dead_enemies: Array = []   # list of enemy IDs killed this visit

# ── Боевая статистика (накопительно, личное дело) ─────────────────────────────
var total_damage_dealt:    int = 0
var total_damage_absorbed: int = 0
var total_ships_destroyed: int = 0
var total_battles_won:     int = 0

# ── Репутация у фракций (-100 … +100) ─────────────────────────────────────────
var faction_reputation: Dictionary = {
	"Федерация":   0,
	"Торговцы":    0,
	"Независимые": 0,
	"Пираты":    -50,
	"Империя":     0,
	"Нет":         0,
}

# ── Туман войны — посещённые системы (индексы) ────────────────────────────────
var visited_systems: Array = [0]    # Sol Prime открыта с самого начала

# ── Текущая фракция системы ────────────────────────────────────────────────────
var current_faction: String = "Федерация"

# ── Топливо ───────────────────────────────────────────────────────────────────
var fuel:     float = 100.0
var max_fuel: float = 100.0

# ── Гиперпространственная встреча (ловушка во время прыжка) ───────────────────
var pending_hyperspace_encounter: bool = false

signal state_changed(new_state: GameState)
signal credits_changed(amount: int)

func _ready() -> void:
	print("[GameManager] Initialized — Day %d, Credits: %d" % [day, credits])

func change_state(new_state: GameState) -> void:
	current_state = new_state
	state_changed.emit(new_state)

func add_credits(amount: int) -> void:
	credits += amount
	credits_changed.emit(credits)

func spend_credits(amount: int) -> bool:
	if credits < amount:
		return false
	credits -= amount
	credits_changed.emit(credits)
	return true

const BANK_DEPOSIT_RATE    := 0.04   # 4% в день при депозите ≥ 20 000
const BANK_MIN_FOR_INTEREST := 20000

func advance_day() -> void:
	day += 1
	# Начисление процентов по вкладу
	if bank_balance >= BANK_MIN_FOR_INTEREST:
		var interest := int(bank_balance * BANK_DEPOSIT_RATE)
		bank_balance += interest
		print("[Bank] Начислено %d кред. (4%% за день %d)" % [interest, day])
	# Доход от союзников фракции
	if faction_allies.size() > 0:
		var ally_income := 0
		for ally in faction_allies:
			ally_income += int(ally.get("income", 0))
		if ally_income > 0:
			credits += ally_income
			credits_changed.emit(credits)
			print("[Faction] Союзники принесли %d кред. за день %d" % [ally_income, day])
	print("[GameManager] Day %d" % day)

func add_cargo(item: String, qty: int) -> bool:
	var used := _cargo_used()
	if used + qty > cargo_capacity:
		return false
	cargo[item] = cargo.get(item, 0) + qty
	return true

func remove_cargo(item: String, qty: int) -> bool:
	if not cargo.has(item) or cargo[item] < qty:
		return false
	cargo[item] -= qty
	if cargo[item] <= 0:
		cargo.erase(item)
	return true

func _cargo_used() -> int:
	var total := 0
	for item in cargo:
		total += cargo[item]
	return total

func cargo_free() -> int:
	return cargo_capacity - _cargo_used()

# ── Bank ──────────────────────────────────────────────────────────────────────

func bank_deposit(amount: int) -> bool:
	if amount <= 0 or credits < amount:
		return false
	credits -= amount
	bank_balance += amount
	credits_changed.emit(credits)
	return true

func bank_withdraw(amount: int) -> bool:
	if amount <= 0 or bank_balance < amount:
		return false
	bank_balance -= amount
	credits += amount
	credits_changed.emit(credits)
	return true

func bank_take_loan(amount: int) -> bool:
	if amount <= 0 or loan_amount > 0:
		return false
	loan_amount = int(amount * (1.0 + loan_interest))
	credits += amount
	credits_changed.emit(credits)
	return true

func bank_repay_loan(amount: int) -> bool:
	if amount <= 0 or loan_amount <= 0 or credits < amount:
		return false
	var paid := mini(amount, loan_amount)
	if not spend_credits(paid):
		return false
	loan_amount -= paid
	return true

# ── Запись результатов боя в личное дело ──────────────────────────────────────

func record_combat_result(damage_dealt: int, damage_absorbed: int, ships_destroyed: int, victory: bool) -> void:
	total_damage_dealt    += damage_dealt
	total_damage_absorbed += damage_absorbed
	total_ships_destroyed += ships_destroyed
	if victory:
		total_battles_won += 1
	print("[Combat] Итоги: нанесено=%d, поглощено=%d, уничтожено=%d, победа=%s" % [
		damage_dealt, damage_absorbed, ships_destroyed, str(victory)])

# ── Фракции игрока ────────────────────────────────────────────────────────────

const FACTION_JOIN_REP    := 25     # минимальная репутация для вступления
const FACTION_CREATE_COST := 50000  # стоимость создания своей фракции

func faction_join(faction: String) -> bool:
	if player_faction != "": return false
	var rep: int = faction_reputation.get(faction, -999)
	if rep < FACTION_JOIN_REP: return false
	player_faction = faction
	change_reputation(faction, 10)  # бонус при вступлении
	return true

func faction_leave() -> void:
	if faction_leader_of != "" and faction_leader_of == player_faction:
		faction_leader_of = ""
	player_faction = ""

func faction_create(fname: String) -> bool:
	if player_faction != "": return false
	if fname.strip_edges().is_empty(): return false
	if not spend_credits(FACTION_CREATE_COST): return false
	faction_leader_of = fname
	player_faction = fname
	faction_reputation[fname] = 50
	return true

# ── Репутация ─────────────────────────────────────────────────────────────────

func change_reputation(faction: String, amount: int) -> void:
	if faction.is_empty() or faction == "Нет": return
	var cur: int = faction_reputation.get(faction, 0)
	faction_reputation[faction] = clampi(cur + amount, -100, 100)

func get_faction_standing(faction: String) -> String:
	var rep: int = faction_reputation.get(faction, 0)
	if rep >= 60:   return "Союзник"
	if rep >= 25:   return "Дружественный"
	if rep >= -10:  return "Нейтральный"
	if rep >= -40:  return "Недружественный"
	return "Враждебный"

# ── Топливо ───────────────────────────────────────────────────────────────────

func spend_fuel(amount: float) -> bool:
	if fuel < amount: return false
	fuel -= amount
	return true

func refuel(amount: float) -> void:
	fuel = minf(fuel + amount, max_fuel)

# ── Очки (для личного дела) ───────────────────────────────────────────────────

func get_score() -> int:
	return int(credits * 0.05) + total_damage_dealt / 10 + \
		   total_ships_destroyed * 500 + total_battles_won * 2000 + day * 50

# ── Сохранение / Загрузка ─────────────────────────────────────────────────────

const SAVE_PATH := "user://spacev_save.json"

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data := {
		"credits": credits, "day": day,
		"current_galaxy": current_galaxy,
		"current_galaxy_idx": current_galaxy_idx,
		"current_danger": current_danger,
		"current_faction": current_faction,
		"current_ship": current_ship,
		"equipped_weapons": equipped_weapons,
		"cargo": cargo,
		"cargo_capacity": cargo_capacity,
		"bank_balance": bank_balance, "loan_amount": loan_amount,
		"ship_hull_pct": ship_hull_pct,
		"ship_upgrades": ship_upgrades,
		"damaged_weapons": damaged_weapons,
		"weapon_ammo_state": weapon_ammo_state,
		"faction_reputation": faction_reputation,
		"visited_systems": visited_systems,
		"player_faction": player_faction,
		"faction_leader_of": faction_leader_of,
		"faction_allies": faction_allies,
		"fuel": fuel, "max_fuel": max_fuel,
		"total_damage_dealt":    total_damage_dealt,
		"total_damage_absorbed": total_damage_absorbed,
		"total_ships_destroyed": total_ships_destroyed,
		"total_battles_won":     total_battles_won,
		"completed_quests_count": completed_quests.size(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()
		print("[Save] Сохранено: день %d, %d кред." % [day, credits])

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH): return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return false
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data == null or not data is Dictionary: return false
	credits              = int(data.get("credits",           500000))
	day                  = int(data.get("day",               1))
	current_galaxy       = str(data.get("current_galaxy",    "Sol Prime"))
	current_galaxy_idx   = int(data.get("current_galaxy_idx", 0))
	current_danger       = int(data.get("current_danger",    1))
	current_faction      = str(data.get("current_faction",   "Федерация"))
	current_ship         = data.get("current_ship",          current_ship)
	equipped_weapons     = data.get("equipped_weapons",      [])
	cargo                = data.get("cargo",                 {})
	cargo_capacity       = int(data.get("cargo_capacity",    50))
	bank_balance         = int(data.get("bank_balance",      0))
	loan_amount          = int(data.get("loan_amount",       0))
	ship_hull_pct        = float(data.get("ship_hull_pct",   1.0))
	ship_upgrades        = data.get("ship_upgrades",         [])
	damaged_weapons      = data.get("damaged_weapons",       [])
	weapon_ammo_state    = data.get("weapon_ammo_state",     {})
	faction_reputation   = data.get("faction_reputation",    faction_reputation)
	visited_systems      = data.get("visited_systems",       [0])
	player_faction       = str(data.get("player_faction",    ""))
	faction_leader_of    = str(data.get("faction_leader_of", ""))
	faction_allies       = data.get("faction_allies",        [])
	fuel                 = float(data.get("fuel",            100.0))
	max_fuel             = float(data.get("max_fuel",        100.0))
	total_damage_dealt   = int(data.get("total_damage_dealt",    0))
	total_damage_absorbed= int(data.get("total_damage_absorbed", 0))
	total_ships_destroyed= int(data.get("total_ships_destroyed", 0))
	total_battles_won    = int(data.get("total_battles_won",     0))
	credits_changed.emit(credits)
	print("[Save] Загружено: день %d, %d кред." % [day, credits])
	return true
