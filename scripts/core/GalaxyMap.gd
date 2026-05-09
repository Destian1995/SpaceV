extends Node
class_name GalaxyMap

var systems: Array[StarSystem] = []
var current_system: StarSystem = null

signal travel_started(destination: StarSystem)
signal travel_completed(system: StarSystem)

func _ready() -> void:
	_generate_galaxy()
	current_system = systems[0]
	print("[Galaxy] Starting in: %s" % current_system.system_name)

func _generate_galaxy() -> void:
	var data := [
		["Sol Prime",    StarSystem.SystemType.TRADING_HUB, Vector2(400,300), "Federation",   1],
		["Krath Station",StarSystem.SystemType.MILITARY,    Vector2(700,150), "Federation",   2],
		["Vega Drift",   StarSystem.SystemType.FRONTIER,    Vector2(200,500), "Independent",  3],
		["Scarlet Nebula",StarSystem.SystemType.OUTLAW,     Vector2(900,400), "Raiders",      4],
		["Echo Void",    StarSystem.SystemType.DERELICT,    Vector2(550,600), "None",         5],
		["Auren Gate",   StarSystem.SystemType.TRADING_HUB, Vector2(300,200), "Merchants",   2],
		["Pyrox",        StarSystem.SystemType.MILITARY,    Vector2(800,550), "Empire",       3],
		["Nova Reach",   StarSystem.SystemType.FRONTIER,    Vector2(100,350), "Independent",  2],
	]
	for d in data:
		systems.append(StarSystem.create(d[0], d[1], d[2], d[3], d[4]))
	print("[Galaxy] Generated %d star systems" % systems.size())

func travel_to(destination: StarSystem) -> void:
	if destination == current_system:
		return
	print("[Galaxy] Traveling to %s (danger: %d)" % [destination.system_name, destination.danger_level])
	travel_started.emit(destination)
	# Travel duration simulated — actual timer in scene
	await get_tree().create_timer(2.0).timeout
	current_system = destination
	travel_completed.emit(destination)
	GameManager.advance_day()

func get_reachable_systems(range_ly: float = 999.0) -> Array[StarSystem]:
	var reachable: Array[StarSystem] = []
	for s in systems:
		if s != current_system:
			var dist := current_system.position.distance_to(s.position)
			if dist <= range_ly:
				reachable.append(s)
	return reachable
