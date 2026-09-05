class_name ToolTierSystem

## Mining and block breaking use one damage tick per second. Tool power is literal
## damage per tick: a 5 HP tree takes 5 s at power 1, 3 s at power 2, and 2 s at
## power 3. Combat keeps its faster animation-specific swing rhythm below.
const MINING_DAMAGE_INTERVAL := 1.0

## Combat swing cadence. Mining deliberately does not use this table.
const SWING_INTERVALS: Array[float] = [0.52, 0.46, 0.40, 0.34, 0.30]
## Fallback combat rhythm.
const SWING_INTERVAL := 0.55

## Seconds between swings for this tool power (clamped to the authored tiers).
static func swing_interval(tool_power: int) -> float:
	var index: int = clampi(tool_power, 1, SWING_INTERVALS.size()) - 1
	return SWING_INTERVALS[index]


## Damage dealt to a resource or placed block on each one-second mining tick.
## Objects that need no tool always take one damage, so holding a steel pickaxe
## cannot make hand-gathered flax, sticks, or berries instant.
static func mining_damage(tool_power: int, held_tool: String, effective_tool: String) -> int:
	if effective_tool.is_empty() or effective_tool == "none":
		return 1
	if held_tool == effective_tool:
		return maxi(tool_power, 1)
	return 1


static func mining_seconds_to_break(health: int, damage: int) -> float:
	return float(ceili(float(maxi(health, 1)) / float(maxi(damage, 1)))) * MINING_DAMAGE_INTERVAL


static func can_mine_deposit(tool_power: int, deposit: DepositData) -> bool:
	return tool_power >= deposit.mining_level_required
