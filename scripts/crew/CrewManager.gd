extends Node
class_name CrewManager

var crew: Array[CrewMember] = []
var max_crew: int = 10

signal crew_hired(member: CrewMember)
signal crew_fired(member: CrewMember)
signal morale_updated()

func _ready() -> void:
	_add_starter_crew()

func _add_starter_crew() -> void:
	hire(CrewMember.create("Zara",  CrewMember.Role.PILOT,     2))
	hire(CrewMember.create("Koss",  CrewMember.Role.GUNNER,    1))
	hire(CrewMember.create("Mira",  CrewMember.Role.ENGINEER,  1))

func hire(member: CrewMember) -> bool:
	if crew.size() >= max_crew:
		return false
	crew.append(member)
	crew_hired.emit(member)
	print("[Crew] Hired %s (%s)" % [member.crew_name, CrewMember.Role.keys()[member.role]])
	return true

func fire(member: CrewMember) -> void:
	crew.erase(member)
	crew_fired.emit(member)

func get_daily_wage() -> int:
	var total := 0
	for m in crew:
		total += m.salary
	return total

func get_best_for_role(role: CrewMember.Role) -> CrewMember:
	var best: CrewMember = null
	for m in crew:
		if m.role == role:
			if best == null or m.get_combat_bonus() > best.get_combat_bonus():
				best = m
	return best

func get_accuracy_bonus() -> float:
	var gunner := get_best_for_role(CrewMember.Role.GUNNER)
	return gunner.get_combat_bonus() if gunner else 0.3

func get_evasion_bonus() -> float:
	var pilot := get_best_for_role(CrewMember.Role.PILOT)
	return pilot.get_combat_bonus() if pilot else 0.3

func pay_wages() -> int:
	var wage := get_daily_wage()
	if GameManager.spend_credits(wage):
		print("[Crew] Wages paid: %d credits" % wage)
		return wage
	else:
		# Low morale when unpaid
		for m in crew:
			m.change_morale(-15.0)
		morale_updated.emit()
		print("[Crew] Cannot pay wages! Morale dropping.")
		return 0
