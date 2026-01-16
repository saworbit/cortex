# CORTEX BOT v4.2 "Hunter"

A state-of-the-art deathmatch bot for Quake (1996).

## Features

### Combat
- **Smart Weapon Selection** - Chooses best weapon for range and ammo
- **Projectile Dodging** - Evades incoming rockets and grenades
- **Threat Assessment** - Retreats when outmatched
- **Lead Prediction** - Aims ahead of moving targets

### Navigation
- **Whisker Navigation** - 3-ray obstacle detection
- **Platform Riding** - Stays on moving platforms
- **Rocket Jumping** - Escapes stuck situations
- **Teleporter Use** - Uses teleporters when roaming
- **Water Navigation** - Swims to surface automatically
- **Jump Gap Detection** - Jumps across gaps and up ledges

### Resource Management
- **Item Awareness** - Picks up items within touch range
- **Item Timing** - Tracks Quad/Pent/Mega respawn times
- **Supply Seeking** - Finds health, armor, ammo when low

### Sensory
- **Sound Awareness** - Hears combat and investigates
- **HUNT Mode** - Chases enemies to last known position

---

## Quick Start

### Standalone Testing (Recommended for First Test)

1. **Install FTEQCC compiler**
   - Download from: https://www.fteqcc.org/
   - Or use your package manager: `apt install fteqcc`

2. **Compile the bot**
   ```bash
   cd cortexbot
   fteqcc progs.src
   ```
   This creates `progs.dat` using the included test stubs.

3. **Install in Quake**
   ```bash
   # Copy to your Quake directory
   cp progs.dat /path/to/quake/id1/
   ```

4. **Run and test**
   ```
   # Start Quake in deathmatch mode
   quake +deathmatch 1 +map dm4

   # In console, spawn a bot:
   impulse 100
   ```

### Integration with Existing Mod

1. **Add to progs.src** (before world.qc):
   ```
   bot.qc
   ```

2. **Add impulse binding** in `client.qc` (PlayerPreThink):
   ```c
   if (self.impulse == 100)
   {
       SpawnCortexBot();
       self.impulse = 0;
   }
   ```

3. **Add scoreboard hooks** in `client.qc`:
   ```c
   // In ClientConnect()
   Cortex_ClientInRankings();

   // In ClientDisconnect()
   Cortex_ClientDisconnected();
   ```

4. **Compile**:
   ```bash
   fteqcc progs.src
   ```

---

## File Structure

```
cortexbot/
├── bot.qc          # Main bot AI (~2100 lines)
├── stubs.qc        # Test stubs for standalone compilation
├── progs.src       # Compilation order
├── README.md       # This file
├── CHANGELOG.md    # Version history
└── STATUS.md       # Feature completion status
```

---

## Required Dependencies

When integrating into your mod, these functions must exist:

```c
void(vector org) spawn_tfog;                                    // Teleport effect
void(vector org, entity death_owner) spawn_tdeath;              // Telefrag check
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage;
void() T_MissileTouch;                                          // Rocket explosion
void() GrenadeTouch;                                            // Grenade bounce
void() GrenadeExplode;                                          // Grenade explosion
void(vector org, vector dir) launch_spike;                      // Nail projectile
void(float count, vector dir, vector spread) FireBullets;       // Shotgun hitscan
void(string mdl, float dmg) ThrowHead;                          // Gib on death
```

The included `stubs.qc` provides working implementations for testing.

---

## Bot Behavior

### State Machine

| State | Behavior |
|-------|----------|
| ROAM | Patrol between spawn points, seek items |
| HUNT | Chase enemy to last known position or sound |
| COMBAT | Engage with strafing and shooting |
| RETREAT | Flee to find health when low |
| FETCH | Move to specific goal (powerup, teleporter) |
| RIDING | Stay still on moving platform |
| SOLVE | Interact with button |

### Weapon Priority

**Close Range (<120 units):**
LG > SSG > SG > SNG > NG (avoids self-damage)

**Medium Range (120-500 units):**
RL > LG > SNG > GL

**Long Range (500+ units):**
RL > LG > SNG > NG

### Item Priority

1. Health (when < 50hp)
2. Armor (when < 100)
3. Rockets/Cells (when low)
4. Rocket Launcher (if missing)
5. Lightning Gun (if missing)
6. Quad/Pent when available

---

## Configuration

Edit these constants in `bot.qc`:

```c
float CORTEX_CLOSE_RANGE = 200;        // LG preferred range
float CORTEX_MID_RANGE = 500;          // RL sweet spot
float CORTEX_ROCKET_SELF_DAMAGE = 120; // Min safe rocket range
```

---

## Console Commands

```
impulse 100    // Spawn a bot
```

---

## Troubleshooting

**Bot doesn't spawn:**
- Check console for errors
- Verify progs.dat was copied to id1/
- Ensure map has info_player_deathmatch spawns

**Bot doesn't move:**
- Check that spawn points exist
- Verify bot.think is set to Cortex_Think

**Bot doesn't shoot:**
- Ensure weapon functions exist (T_MissileTouch, etc.)
- Check ammo values (bot spawns with 50 rockets, 50 cells)

**Bot gets stuck:**
- Normal on complex geometry
- Will attempt rocket jump after ~1.5 seconds
- Unstuck system has 3 escalation stages
- Will use nearby teleporters to escape

**Compile errors:**
- Check progs.src order
- Add forward declarations for missing functions
- Verify all stubs are provided

---

## Testing Checklist

- [ ] Bot spawns with `impulse 100`
- [ ] Bot moves and patrols spawn points
- [ ] Bot shoots at player
- [ ] Bot picks up items
- [ ] Bot dodges rockets
- [ ] Bot uses teleporters
- [ ] Bot swims out of water
- [ ] Bot appears on scoreboard
- [ ] Bot respawns after death

---

## API Reference

### Public Functions

```c
void() SpawnCortexBot;           // Spawn a new bot
void() Cortex_ClientInRankings;  // Call when player joins
void() Cortex_ClientDisconnected; // Call when player leaves
```

### Bot Entity Fields

```c
.float cortex_state;        // Current AI state
.entity cortex_goal_ent;    // Current navigation target
.vector cortex_last_known;  // Last known enemy position
.float cortex_stuck_severity; // Stuck detection counter
```

---

## Version History

See [CHANGELOG.md](CHANGELOG.md) for full history.

## Project Status

See [STATUS.md](STATUS.md) for feature completion and TODOs.

## License

Released for the Quake modding community. Free to use and modify.
