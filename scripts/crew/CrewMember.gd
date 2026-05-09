extends Resource
class_name CrewMember

enum Role { NAVIGATOR, GUNNER, ENGINEER, MEDIC, PILOT, TACTICIAN }

@export var crew_name: String = "Unknown"
@export var role: Role = Role.GUNNER
@export var level: int = 1
@export var morale: float = 80.0   # 0-100
@export var salary: int = 100      # credits/day

# Skills 0.0 - 1.0
@export var accuracy: float = 0.5
@export var evasion: float = 0.5
@export var repair_speed: float = 0.5
@export var navigation: float = 0.5

signal morale_changed(value: float)

func get_combat_bonus() -> float:
	# How much this crew member improves their role
	match role:
		Role.GUNNER:
			return accuracy * morale / 100.0
		Role.PILOT:
			return evasion * morale / 100.0
		Role.ENGINEER:
			return repair_speed * morale / 100.0
		Role.NAVIGATOR:
			return navigation * morale / 100.0
		_:
			return 0.5

func change_morale(delta: float) -> void:
	morale = clamp(morale + delta, 0.0, 100.0)
	morale_changed.emit(morale)

func to_dict() -> Dictionary:
	return {
		"name": crew_name,
		"role": Role.keys()[role],
		"level": level,
		"morale": morale,
		"accuracy": accuracy
	}

static func create(p_name: String, p_role: Role, p_level: int = 1) -> CrewMember:
	var m := CrewMember.new()
	m.crew_name = p_name
	m.role = p_role
	m.level = p_level
	var base := 0.3 + p_level * 0.08
	m.accuracy = clamp(base + randf_range(-0.1, 0.1), 0.1, 1.0)
	m.evasion = clamp(base + randf_range(-0.1, 0.1), 0.1, 1.0)
	m.repair_speed = clamp(base + randf_range(-0.1, 0.1), 0.1, 1.0)
	m.navigation = clamp(base + randf_range(-0.1, 0.1), 0.1, 1.0)
	m.salary = 80 + p_level * 20
	return m
