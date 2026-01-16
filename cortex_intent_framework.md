#
# Cortex Intent Framework (Universal Layer)
#
# Drop-in, logic-first brain skeleton for Quake 1 DM bots.
#

## 1) Goal hierarchy (non-negotiable)
1. Increase expected net frags over time.
2. Do not die unnecessarily.
3. Secure kills when advantage exists.
4. Control resources that enable future kills.
5. Deny opponent access to those resources.
6. Maintain positional advantage and information.

If an action helps a lower goal but harms a higher one, it is invalid.

## 2) Intent enum (exactly one active)
SURVIVE
FINISH_KILL
ENGAGE
DISENGAGE
REARM
CONTROL_MAJOR
DENY_CONTROL
HUNT
STABILISE

## 3) Persistent world model (updated every tick)
Use the schema in `cortex_intent_schema.json`. At minimum, keep:
- self: health, armor, stack, weapons, ammo, powerups, position, mobility, recent damage
- enemy_belief: last seen, estimated stack/weapons, intent guess, confidence
- map: major item timers, control score, danger zones, safe routes

## 4) Decision loop (always-on)
Pseudocode (run every tick or decision frame):
```pseudo
update_world_model()
update_enemy_beliefs()
update_item_timers()

evaluate_threat()
evaluate_advantage()
evaluate_control()

intent = select_intent()
action = execute_intent_policy(intent)
```

## 5) Intent selection (core logic)
```pseudo
if imminent_death_risk():
    intent = SURVIVE
else if enemy_low_health() and chase_is_safe():
    intent = FINISH_KILL
else if major_item_spawning_now() and can_secure_item():
    intent = CONTROL_MAJOR
else if fight_advantage_high():
    intent = ENGAGE
else if undergeared():
    intent = REARM
else if enemy_in_control():
    intent = DENY_CONTROL
else if enemy_location_uncertain():
    intent = HUNT
else:
    intent = STABILISE
```

## 6) Thresholds (starting defaults)
Adjust per map and skill level:
- LOW_HEALTH = 40
- LOW_STACK = 120
- RECENT_DAMAGE_MS = 600
- ENEMY_LOST_MS = 1200
- CONTROL_MAJOR_WINDOW_MS = 5000
- SAFE_CHASE_DISTANCE = 600
- ADVANTAGE_STACK_DELTA = 40
- UNDERGEARED_AMMO_MIN = 1 fight worth

## 7) Core evaluators (deterministic rules)
```pseudo
imminent_death_risk():
    return (self.health <= LOW_HEALTH) or
           (self.stack <= LOW_STACK) or
           (self.recent_damage.time_ms <= RECENT_DAMAGE_MS and self.recent_damage.amount >= 30)

enemy_low_health():
    return enemy_belief.estimated_stack == "low" and enemy_belief.confidence >= 0.5

chase_is_safe():
    return distance_to(enemy_last_seen) <= SAFE_CHASE_DISTANCE and
           not route_hits_danger_zones() and
           not third_party_risk_high()

major_item_spawning_now():
    return any item.respawns_in_ms <= CONTROL_MAJOR_WINDOW_MS

can_secure_item():
    return time_to_item() <= item.respawns_in_ms and route_safe()

fight_advantage_high():
    return stack_advantage() >= ADVANTAGE_STACK_DELTA or powerup_advantage() or position_advantage()

undergeared():
    return no_reliable_weapon() or ammo_for_one_fight() == false or stack_too_low()

enemy_in_control():
    return map.control_score <= -0.2

enemy_location_uncertain():
    return (now_ms - enemy_last_seen.time_ms) > ENEMY_LOST_MS or enemy_belief.confidence < 0.5
```

## 8) Intent policies (sub-loops)
SURVIVE
- Break LOS immediately
- Move to nearest cover or vertical change
- Avoid unknown space
- Fire only to create space

FINISH_KILL
- Predict exits, cut off routes
- Abort if third-party risk increases or stack advantage drops

ENGAGE
- Force a range you dominate
- Maintain an escape vector
- Re-evaluate every 500 ms

DISENGAGE
- Use geometry, not speed
- Take stabilizers only if safe
- Do not re-engage until stack recovers

REARM
- Minimum kit: reliable weapon + ammo for one fight + armor/health buffer
- Prefer info-rich routes over perfect items

CONTROL_MAJOR
- Be early, not on time
- Force fights on pickup
- If control fails, switch to DENY_CONTROL

DENY_CONTROL
- Steal items or force bad fights
- Damage matters more than kills

HUNT
- Move through sound-rich areas
- Probe without commitment

STABILISE
- Hold strong positions
- Reduce exposure
- Prepare for next control window

## 9) Action output (what each intent returns)
Each intent produces:
- movement_target (node or route)
- weapon_preference
- posture (aggressive, cautious, baiting)
- disengage thresholds (stack low, damage per second high, LOS break)

## 10) Next concrete integration steps
- Wire the schema into your bot debugger/logging.
- Implement the evaluators with simple, deterministic checks.
- Add intent policies as small movement/weapon/posture routines.
