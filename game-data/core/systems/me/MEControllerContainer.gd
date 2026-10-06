# res://core/systems/me/MEControllerContainer.gd
## Heart of an ME network. It is a power consumer on the electrical grid; while
## its EU buffer is above zero the network it belongs to is "online".
extends PoweredMachineContainer
class_name MEControllerContainer

## EU drained per second just to keep the network powered.
const IDLE_DRAIN := 12.0
var network_drain := IDLE_DRAIN


func _init() -> void:
	machine_title = "ME CONTROLLER"
	power_capacity = 400.0
	requires_power = true


func tick(delta: float) -> void:
	# Constant idle draw; PowerNetworkManager refills the buffer when wired.
	power_stored = maxf(power_stored - network_drain * delta, 0.0)
	processing_active = power_stored > 0.0


func is_online() -> bool:
	return power_stored > 0.0


func supports_module(module_type: String) -> bool:
	return module_type in ["efficiency", "capacity"]


func process_progress() -> float:
	return power_progress()


func module_summary() -> String:
	return tr("Energy %d%% · Buffer +%d%%") % [roundi(energy_use_multiplier() * 100.0), roundi((capacity_multiplier() - 1.0) * 100.0)]
