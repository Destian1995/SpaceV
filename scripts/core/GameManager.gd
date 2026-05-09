extends Node

enum GameState { GALAXY_MAP, STAR_SYSTEM, SPACEPORT, COMBAT }

var current_state: GameState = GameState.GALAXY_MAP
var credits: int = 5000
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

func advance_day() -> void:
	day += 1
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
