# CORTEX BOT - TODO List

## Current Status: v4.2 "Hunter" - COMPILED & READY TO TEST

**progs.dat:** 364 KB compiled (2026-01-16)
**Compiler:** FTEQCC git-30-c781d13
**Warnings:** 71 (all safe to ignore - mostly unused vars)

---

## Completed Features

### Combat Systems
- [x] Distance-based weapon selection (all 7 weapons)
- [x] Ammo consumption tracking
- [x] Lead prediction for projectile weapons
- [x] Self-damage avoidance (no rockets < 120 units)
- [x] Projectile dodging (rockets, grenades)
- [x] Threat assessment (power level comparison)
- [x] Suppressive fire at last known position
- [x] Tactical retreat when outgunned

### Navigation
- [x] Whisker system (3-ray obstacle detection)
- [x] Hazard avoidance (lava, slime, pits)
- [x] Platform riding (plat, train, door)
- [x] Unstuck system (3-stage escalation)
- [x] Rocket jumping (when stuck, health-aware)
- [x] Teleporter navigation
- [x] Water/swimming support
- [x] Jump gap detection

### Sensory
- [x] Vision (FOV check + traceline)
- [x] Sound awareness (rockets, grenades, teleports)

### Resource Management
- [x] Item pickup (all types)
- [x] Item seeking (prioritized by need)
- [x] Item timing (Quad/Pent/Mega tracking)
- [x] Weapon prioritization (seeks RL/LG first)

### AI States
- [x] ROAM - Patrol spawn points
- [x] HUNT - Chase to last known position/sound
- [x] COMBAT - Strafe + shoot
- [x] RETREAT - Flee when hurt
- [x] FETCH - Go to specific item/teleporter
- [x] RIDING - Stay on platform
- [x] SOLVE - Button interaction

### Documentation
- [x] README.md with compile/test instructions
- [x] CHANGELOG.md with version history
- [x] STATUS.md with feature matrix
- [x] TODO.md (this file)
- [x] stubs.qc for standalone testing
- [x] progs.src for compilation

---

## In Progress

- [ ] Testing on various DM maps (dm1-dm6)
- [ ] Performance optimization

---

## TODO - Future Features

### High Priority
- [ ] **Lift/Elevator Calling** - Press buttons to call lifts
- [ ] **Door Opening** - Shoot/touch doors that need triggers
- [ ] **Better Pathfinding** - Remember good routes

### Medium Priority
- [ ] **Camping/Ambush Behavior**
  - Hold strategic positions
  - Wait at powerup spawns
  - Ambush from cover

- [ ] **Team Deathmatch Support**
  - Team identification
  - Don't shoot teammates
  - Coordinate attacks

- [ ] **Map Learning**
  - Remember item locations
  - Learn good camping spots
  - Track enemy patterns

### Low Priority
- [ ] **Difficulty Levels**
  - Adjustable reaction time
  - Aim variance scaling
  - Decision delay

- [ ] **Personality Variations**
  - Aggressive vs defensive
  - Risk tolerance
  - Weapon preferences

- [ ] **Voice/Chat**
  - Taunt on kills
  - Call out items
  - Request help (TDM)

- [ ] **Strafe Jumping**
  - Bunny hopping
  - Circle jumping
  - Speed preservation

---

## Known Bugs

- [ ] Bot may get stuck on complex geometry
- [ ] Rocket jump sometimes fires wrong direction
- [ ] Item pickup doesn't remove item from world (needs engine touch)
- [ ] Bot doesn't use doors that require triggers

---

## Testing Checklist

### Basic Functionality
- [ ] Bot spawns with `impulse 100`
- [ ] Bot moves and patrols spawn points
- [ ] Bot shoots at player
- [ ] Bot picks up items
- [ ] Bot appears on scoreboard
- [ ] Bot respawns after death

### Combat
- [ ] Bot switches weapons based on range
- [ ] Bot dodges incoming rockets
- [ ] Bot retreats when low health
- [ ] Bot chases to last known position
- [ ] Bot investigates sounds

### Navigation
- [ ] Bot uses teleporters
- [ ] Bot swims out of water
- [ ] Bot jumps gaps
- [ ] Bot rides platforms
- [ ] Bot escapes stuck situations

### Maps to Test
- [ ] dm1 - Place of Two Deaths
- [ ] dm2 - Claustrophobopolis
- [ ] dm3 - The Abandoned Base
- [ ] dm4 - The Bad Place
- [ ] dm5 - The Cistern
- [ ] dm6 - The Dark Zone

---

## Performance Targets

| Metric | Target | Current |
|--------|--------|---------|
| Think rate | 20 Hz | 20 Hz |
| Scan rate | 10 Hz | 10 Hz |
| Dodge check | 6-7 Hz | 6-7 Hz |
| Entity searches/frame | < 5 | 2-4 |
| Memory per bot | < 100 fields | ~50 fields |

---

## Version Roadmap

### v4.2 "Hunter" (Current)
- Sound awareness
- Teleporter navigation
- Water swimming
- Jump gap detection

### v4.3 "Tactician" (Planned)
- Camping behavior
- Better unstuck logic
- Lift calling

### v5.0 "Commander" (Future)
- Team DM support
- Difficulty levels
- Personality system

---

## Contributing

To add a feature:
1. Create branch from main
2. Implement feature in bot.qc
3. Update documentation
4. Test on multiple maps
5. Update CHANGELOG.md
6. Submit PR

---

*Last Updated: 2026-01-16*
