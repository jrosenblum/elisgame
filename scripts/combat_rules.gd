class_name CombatRules
extends RefCounted
## Approved temporary formulas. Does not manage turns, UI, or unit removal.

static func forecast(attacker: Dictionary, defender: Dictionary) -> Dictionary:
	return {
		"damage": maxi(0, int(attacker.attack) - int(defender.defense)),
		"hit": clampi(85 + 2 * int(attacker.agility) - 2 * int(defender.speed), 10, 100),
		"crit": clampi(floori(float(attacker.agility) / 2.0), 0, 20)
	}

static func strike(attacker: Dictionary, defender: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var result := forecast(attacker, defender)
	result["landed"] = rng.randi_range(1, 100) <= int(result.hit)
	result["critical"] = false
	result["dealt"] = 0
	if result.landed:
		result.critical = rng.randi_range(1, 100) <= int(result.crit)
		result.dealt = int(result.damage) * (2 if result.critical else 1)
	return result
