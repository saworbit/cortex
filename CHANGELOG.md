# CORTEX BOT Changelog

## [Unreleased]

### Changed
- Introduced `Cortex_CoverDirection` and `inwater` helpers so `Cortex_FindCover` and the weapon selection logic no longer rely on missing `cos`, `sin`, or implicit water checks; this keeps the QuakeC purely on the canonical cover directions and `self.waterlevel`, allowing builds to finish with only the existing warnings noted by FTEQCC.

## [v4.2] "Hunter" - 2026-01-16

### Added
- **Sound Awareness System**
  - Detects nearby rockets, grenades, and nailgun spikes
  - Hears teleport fog when players teleport nearby
  - Investigates sound origins when no enemy is visible
  - Hearing range: 1500 units for combat, 800 units for teleports

- **Teleporter Navigation**
  - Detects trigger_teleport entities in the map
  - Uses teleporters when stuck (severity >= 2)
  - Random chance to use teleporters when roaming
  - Helps navigate complex maps with teleporter shortcuts

- **Water Navigation**
  - Detects CONTENT_WATER and CONTENT_SLIME
  - Automatically swims toward surface
  - Adds forward momentum to escape water
  - Faster swim speed in slime (dangerous!)
  - Seeks spawn points as exit targets after 3 seconds

- **Jump Gap Detection**
  - Detects gaps ahead using ground trace
  - Calculates if gap is jumpable (64-250 units)
  - Verifies landing spot is safe (not lava/slime)
  - Detects step-up ledges and jumps over them
  - Adds forward momentum for distance jumps

### Changed
- HUNT state now also investigates sound origins
- FETCH state can target teleporters
- Movement loop includes gap jump attempts
- Header documentation updated with new systems

### Added Files
- `stubs.qc` - Standalone test stubs for compilation without full Quake progs
- `progs.src` - Compilation order file for FTEQCC

---

## [v4.1] "Predator" - 2026-01-16

### Added
- **Projectile Dodging System**
  - Detects incoming rockets within 500 units
  - Detects grenades within 200 units
  - Calculates if projectile is heading toward bot (dot product analysis)
  - Dodges perpendicular to projectile flight path
  - Emergency jump when rockets are very close

- **Threat Assessment System**
  - Evaluates relative power levels (health + armor + powerups)
  - Detects enemy Quad/Pent via glow effects
  - Returns threat level: 0=dominating, 1=even, 2=outmatched
  - Triggers tactical retreat when outgunned AND hurt

- **Item Respawn Timing**
  - Tracks when Quad/Pent/Mega are taken
  - Remembers respawn times (Quad/Pent: 60s, Mega: 20s)
  - Moves to powerup spawn 5 seconds before respawn

- **Improved Aim Prediction**
  - Distance-based accuracy variance (more accurate close up)
  - Aims lower for rockets/grenades (splash damage)
  - Slight randomization to feel less robotic

### Changed
- Combat loop now integrates dodge direction
- Retreat triggers automatically based on threat assessment
- All three new systems run every think cycle

---

## [v4.0] "Arsenal" - 2026-01-16

### Added
- **Weapon Selection System**
  - Distance-based weapon choice
  - Close range (<120): LG > SSG > SG > SNG > NG
  - Medium range (120-200): LG > RL > SNG > SSG
  - Mid range (200-500): RL > LG > SNG > GL
  - Long range (500+): RL > LG > SNG > NG
  - Self-damage avoidance (won't rocket < 120 units)

- **Ammo Consumption**
  - All weapons now consume correct ammo amounts
  - Tracks currentammo for HUD display

- **Full Weapon Support**
  - Shotgun (SG)
  - Super Shotgun (SSG)
  - Nailgun (NG)
  - Super Nailgun (SNG)
  - Grenade Launcher (GL)
  - Rocket Launcher (RL)
  - Lightning Gun (LG)

- **Item Pickup System**
  - Automatic pickup within 64 unit touch range
  - Health (normal, rotten, mega)
  - Armor (green, yellow, red)
  - All weapons with ammo bonus
  - All ammo types (shells, nails, rockets, cells)
  - Powerups (Quad, Pent, Ring)
  - Ammo caps enforced

- **Item Seeking**
  - `Cortex_NeedsSupplies()` checks health/armor/ammo
  - `Cortex_FindNearestItem()` prioritizes by need
  - Searches within 2000 units

- **Rocket Jumping**
  - Triggers when severely stuck (severity >= 3)
  - Health-aware (won't RJ below 50hp)
  - 5 second cooldown between attempts
  - Checks for ceiling clearance

- **HUNT State**
  - Chases enemy to last known position
  - Re-engages if enemy spotted during pursuit
  - Returns to ROAM if target not found

### Changed
- `Cortex_FireWeapon()` completely rewritten for all weapons
- `Cortex_SuppressiveFire()` now checks ammo and self-damage
- Combat state transitions to HUNT instead of FETCH on lost sight

### Fixed
- Bot now actually uses ammo (was infinite before)
- Self-damage from close-range rockets

---

## [v3.0] "Solver" - Initial Version

### Features
- **State Machine**: ROAM, COMBAT, RETREAT, FETCH, RIDING, SOLVE
- **Whisker Navigation**: 3-ray obstacle detection
- **Platform Riding**: Detects func_plat/train/door
- **Unstuck System**: Wall slide, backpedal, panic rocket
- **Button Interaction**: Push and shoot buttons
- **Basic Combat**: RL and LG only, lead prediction
- **Map Analysis**: Caches Quad/Pent/Mega locations

### Known Issues (Fixed in v4.0)
- No ammo consumption
- Only 2 weapons (RL/LG)
- No item pickup
- HUNT state defined but unused
- Self-damage from rockets at close range
