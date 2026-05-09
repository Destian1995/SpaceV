extends Resource
class_name StarSystem

enum SystemType { TRADING_HUB, MILITARY, FRONTIER, OUTLAW, DERELICT }

@export var system_name: String = "Unknown"
@export var system_type: SystemType = SystemType.FRONTIER
@export var position: Vector2 = Vector2.ZERO
@export var description: String = ""
@export var faction: String = "Independent"
@export var danger_level: int = 1  # 1-5

# Economy
@export var goods: Dictionary = {}  # item -> price

signal player_arrived()

static func create(p_name: String, p_type: SystemType, p_pos: Vector2, p_faction: String = "Independent", p_danger: int = 1) -> StarSystem:
	var s := StarSystem.new()
	s.system_name = p_name
	s.system_type = p_type
	s.position = p_pos
	s.faction = p_faction
	s.danger_level = p_danger
	s._generate_goods()
	return s

func _generate_goods() -> void:
	var all_goods := ["Fuel", "Food", "Metals", "Electronics", "Medicine", "Weapons", "Luxury"]
	goods.clear()
	for item in all_goods:
		if randf() > 0.4:
			goods[item] = randi_range(50, 800)

func get_travel_danger() -> float:
	return danger_level / 5.0
