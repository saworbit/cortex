# CORTEX BOT - Project Status

**Current Version:** v4.2 "Hunter"
**Last Updated:** 2026-01-16
**Status:** Playable Beta

---

## Feature Completion

### Combat Systems
| Feature | Status | Notes |
|---------|--------|-------|
| Weapon Selection | Done | Distance-based, all 7 weapons |
| Ammo Consumption | Done | Correct amounts per weapon |
| Lead Prediction | Done | Velocity-based with variance |
| Self-Damage Avoidance | Done | No rockets < 120 units |
| Projectile Dodging | Done | Rockets and grenades |
| Threat Assessment | Done | Power level comparison |
| Suppressive Fire | Done | At last known position |

### Navigation
| Feature | Status | Notes |
|---------|--------|-------|
| Whisker System | Done | 3-ray obstacle detection |
| Hazard Avoidance | Done | Lava, slime, pits |
| Platform Riding | Done | Plat, train, door |
| Unstuck System | Done | 3-stage escalation |
| Rocket Jumping | Done | When stuck, health-aware |
| Teleporter Use | Done | Uses trigger_teleport when roaming/stuck |
| Swimming | Done | Swims to surface, escapes slime |
| Jump Gaps | Done | Detects gaps, calculates jumps |

### Sensory
| Feature | Status | Notes |
|---------|--------|-------|
| Vision | Done | FOV check + traceline |
| Sound Awareness | Done | Hears rockets, grenades, teleports |

### Resource Management
| Feature | Status | Notes |
|---------|--------|-------|
| Item Pickup | Done | All item types |
| Item Seeking | Done | Prioritized by need |
| Item Timing | Done | Quad/Pent/Mega tracking |
| Weapon Prioritization | Done | Seeks RL/LG first |

### AI Behavior
| Feature | Status | Notes |
|---------|--------|-------|
| ROAM State | Done | Patrol spawn points |
| HUNT State | Done | Chase to last known |
| COMBAT State | Done | Strafe + shoot |
| RETREAT State | Done | Flee when hurt |
| FETCH State | Done | Go to specific item |
| RIDING State | Done | Stay on platform |
| SOLVE State | Done | Button interaction |

---

## TODO - Priority Order

### Medium Priority
1. **Camping/Ambush Behavior**
   - Hold strategic positions
   - Wait at powerup spawns
   - Ambush from cover
   - Estimated complexity: Medium

2. **Team Deathmatch Support**
   - Team identification
   - Don't shoot teammates
   - Coordinate attacks
   - Estimated complexity: Medium

### Low Priority
3. **Difficulty Levels**
   - Adjustable reaction time
   - Aim variance scaling
   - Decision delay
   - Estimated complexity: Low

4. **Personality Variations**
   - Aggressive vs defensive
   - Risk tolerance
   - Weapon preferences
   - Estimated complexity: Low

5. **Voice/Chat**
   - Taunt on kills
   - Call out items
   - Request help
   - Estimated complexity: Low

---

## Known Issues

### Bugs
- [ ] Bot may get stuck on complex geometry
- [ ] Rocket jump sometimes fires wrong direction
- [ ] Item pickup doesn't remove item from world (needs engine touch)

### Limitations
- No pathfinding - uses reactive whisker navigation only
- Cannot navigate complex multi-level areas
- No memory of map layout between lives
- Cannot use doors that require triggers

---

## File Structure

```
cortexbot/
├── bot.qc          # Main bot AI (~2100 lines)
├── stubs.qc        # Test stubs for standalone compilation (~400 lines)
├── progs.src       # Compilation order for FTEQCC
├── README.md       # Usage instructions & compile guide
├── CHANGELOG.md    # Version history
└── STATUS.md       # This file
```

### Compilation

```bash
# Standalone test build
cd cortexbot
fteqcc progs.src

# Copy to Quake
cp progs.dat /path/to/quake/id1/

# Test in game
quake +deathmatch 1 +map dm4
# Then: impulse 100
```

---

## Integration Notes

### Required External Functions
These must be defined in your progs.dat:
- `spawn_tfog(vector org)` - Teleport fog effect
- `spawn_tdeath(vector org, entity death_owner)` - Telefrag check
- `T_Damage(entity targ, entity inflictor, entity attacker, float damage)`
- `T_MissileTouch()` - Rocket explosion
- `GrenadeTouch()` - Grenade bounce
- `GrenadeExplode()` - Grenade explosion
- `launch_spike(vector org, vector dir)` - Nail projectile
- `FireBullets(float count, vector dir, vector spread)` - Hitscan
- `ThrowHead(string mdl, float dmg)` - Gib on death

### Spawning a Bot
```c
// In your code:
SpawnCortexBot();
```

### Scoreboard Integration
Bots automatically register with the scoreboard system. Call these from your client.qc:
- `Cortex_ClientInRankings()` - When player joins
- `Cortex_ClientDisconnected()` - When player leaves

---

## Performance Notes

- Think rate: 20Hz (0.05s intervals)
- Scan rate: 10Hz (objective assessment)
- Dodge check: 6-7Hz
- Typical entity searches per frame: 2-4
- Memory per bot: ~50 entity fields

---

## Credits

CORTEX BOT v4.2 "Hunter"
Developed for Quake (1996) deathmatch
