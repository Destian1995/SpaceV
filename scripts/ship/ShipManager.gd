extends Node
class_name ShipManager

# All ship stats
@export var ship_name: String = "ISS Vagrant"
@export var max_hull: float = 500.0
var hull: float = 500.0

# Power budget
@export var total_power: float = 100.0
var power_allocated: float = 0.0

# Child systems (assigned in scene)
@onready var shields: ShipSystem = $Systems/Shields
@onready var engines: ShipSystem = $Systems/Engines
@onready var weapons: ShipSystem = $Systems/Weapons
@onready var life_support: ShipSystem = $Systems/LifeSupport

signal hull_changed(value: float)
signal ship_destroyed()

func _ready() -> void:
	print("[ShipManager] %s online. Hull: %.0f/%.0f" % [ship_name, hull, max_hull])

func take_hull_damage(amount: float) -> void:
	hull = max(0.0, hull - amount)
	hull_changed.emit(hull)
	if hull <= 0.0:
		ship_destroyed.emit()
		print("[ShipManager] SHIP DESTROYED!")

func repair_hull(amount: float) -> void:
	hull = min(max_hull, hull + amount)
	hull_changed.emit(hull)

func reallocate_power(shield_pct: float, engine_pct: float, weapon_pct: float, life_pct: float) -> bool:
	var total = shield_pct + engine_pct + weapon_pct + life_pct
	if total > 100.0:
		push_warning("[ShipManager] Power exceeds 100%%: %.1f" % total)
		return false
	shields.allocate_power(shield_pct)
	engines.allocate_power(engine_pct)
	weapons.allocate_power(weapon_pct)
	life_support.allocate_power(life_pct)
	power_allocated = total
	print("[ShipManager] Power: shields=%.0f engines=%.0f weapons=%.0f life=%.0f" % [shield_pct, engine_pct, weapon_pct, life_pct])
	return true

func get_hull_percent() -> float:
	return hull / max_hull * 100.0
