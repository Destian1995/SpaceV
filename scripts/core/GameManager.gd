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
