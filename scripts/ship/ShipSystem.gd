extends Node
class_name ShipSystem

# Base class for all ship systems (shields, engines, weapons, life support)
enum SystemState { ONLINE, DAMAGED, OFFLINE }

@export var system_name: String = "System"
@export var max_power: float = 100.0
@export var current_power: float = 100.0
@export var integrity: float = 100.0  # Hull integrity 0-100

var state: SystemState = SystemState.ONLINE

signal power_changed(value: float)
signal integrity_changed(value: float)
signal state_changed(new_state: SystemState)

func allocate_power(amount: float) -> void:
	current_power = clamp(amount, 0.0, max_power)
	power_changed.emit(current_power)
	_update_state()

func take_damage(amount: float) -> void:
	integrity = max(0.0, integrity - amount)
	integrity_changed.emit(integrity)
	_update_state()
	print("[%s] Damage! Integrity: %.1f%%" % [system_name, integrity])

func repair(amount: float) -> void:
	integrity = min(100.0, integrity + amount)
	integrity_changed.emit(integrity)
	_update_state()

func _update_state() -> void:
	var new_state: SystemState
	if integrity <= 0.0:
		new_state = SystemState.OFFLINE
	elif integrity < 30.0:
		new_state = SystemState.DAMAGED
	else:
		new_state = SystemState.ONLINE

	if new_state != state:
		state = new_state
		state_changed.emit(state)

func get_efficiency() -> float:
	# Damaged systems work at reduced capacity
	if state == SystemState.OFFLINE:
		return 0.0
	elif state == SystemState.DAMAGED:
		return integrity / 100.0
	return current_power / max_power
