# CORTEX BOT - Testing Guide

## Quick Start

### Windows
```batch
cd cortexbot
build.bat
```

### Linux/macOS
```bash
cd cortexbot
chmod +x build.sh
./build.sh
```

---

## Manual Compilation

### Step 1: Install FTEQCC

**Windows:**
- Download from https://www.fteqcc.org/
- Extract to a folder
- Add folder to PATH

**Linux:**
```bash
# Ubuntu/Debian
sudo apt install fteqcc

# Arch
yay -S fteqcc

# From source
git clone https://github.com/nicolarctic/fteqcc
cd fteqcc && make
```

**macOS:**
```bash
brew install fteqcc
```

### Step 2: Compile

```bash
cd cortexbot
fteqcc progs.src
```

Expected output:
```
FTEQCC v1.xx
2 file(s) compiled
progs.dat (xxxxx bytes)
```

### Step 3: Install

Copy `progs.dat` to your Quake installation:

```bash
# Windows
copy progs.dat "C:\Games\Quake\id1\"

# Linux
cp progs.dat ~/.quake/id1/

# macOS
cp progs.dat ~/Library/Application\ Support/Quake/id1/
```

---

## Running the Test

### Launch Quake in Deathmatch Mode

**Using Quakespasm (recommended):**
```bash
quakespasm -listen 8 +set developer 1 +set condebug 1 +game cortexbot +deathmatch 1 +map dm4
```

**Using original Quake:**
```bash
quake -game id1 +deathmatch 1 +map dm4
```

**Using vkQuake:**
```bash
vkquake +deathmatch 1 +map dm4
```

### Spawn a Bot

Open the console (~ key) and type:
```
impulse 100
```

You should see:
```
Cortex: Solver Logic Loaded.
```

### Spawn Multiple Bots

```
impulse 100
impulse 100
impulse 100
```

Each bot gets a unique scoreboard slot.

---

## Test Procedures

### Test 1: Basic Movement
1. Spawn bot with `impulse 100`
2. Observe bot patrolling spawn points
3. **PASS:** Bot moves around the map
4. **FAIL:** Bot stands still or spins in place

### Test 2: Combat Engagement
1. Spawn bot
2. Walk into bot's line of sight
3. **PASS:** Bot turns and shoots at you
4. **FAIL:** Bot ignores you

### Test 3: Weapon Selection
1. Spawn bot, get close (< 100 units)
2. **PASS:** Bot uses Lightning Gun or Shotgun
3. Move far away (> 500 units)
4. **PASS:** Bot switches to Rocket Launcher

### Test 4: Item Pickup
1. Spawn bot
2. Drop health/armor nearby (or lead bot to items)
3. **PASS:** Bot walks over items (plays pickup sound)
4. **FAIL:** Bot ignores items

### Test 5: Projectile Dodging
1. Spawn bot
2. Shoot rockets at bot
3. **PASS:** Bot strafes/jumps to avoid rockets
4. **FAIL:** Bot stands still and takes hits

### Test 6: Threat Assessment
1. Spawn bot, damage it to low health
2. Attack bot with Quad damage
3. **PASS:** Bot retreats to find health
4. **FAIL:** Bot keeps fighting despite low health

### Test 7: Sound Awareness
1. Spawn bot on one side of map
2. Fire rockets on other side (out of sight)
3. **PASS:** Bot moves toward sound
4. **FAIL:** Bot continues patrol

### Test 8: Water Navigation
1. Lead bot into water (dm3 has water)
2. **PASS:** Bot swims to surface and exits
3. **FAIL:** Bot drowns or swims in circles

### Test 9: Teleporter Use
1. Find map with teleporters (dm4)
2. Observe bot near teleporter
3. **PASS:** Bot occasionally uses teleporter
4. **FAIL:** Bot avoids teleporters

### Test 10: Jump Gaps
1. Find map with jumpable gaps
2. Observe bot approaching gap
3. **PASS:** Bot jumps across gap
4. **FAIL:** Bot falls or turns around

### Test 11: Platform Riding
1. Find map with lifts (dm2, dm6)
2. Observe bot on lift
3. **PASS:** Bot stays on lift while moving
4. **FAIL:** Bot walks off moving lift

### Test 12: Scoreboard
1. Spawn bot
2. Press TAB to see scoreboard
3. **PASS:** Bot appears with name "cortexbot"
4. **FAIL:** Bot not visible on scoreboard

---

## Recommended Test Maps

| Map | Tests | Features |
|-----|-------|----------|
| dm1 | Combat, items | Simple layout |
| dm2 | Lifts, combat | Platform riding |
| dm3 | Water, teleporters | Water navigation |
| dm4 | Teleporters, gaps | Teleporter use |
| dm5 | Water, buttons | Swimming |
| dm6 | Lifts, multi-level | Complex navigation |

---

## Console Commands for Testing

```
god              # God mode (can't die)
noclip           # Fly through walls
give h 999       # Give health
give c 999       # Give cells
give r 999       # Give rockets
impulse 100      # Spawn bot
impulse 255      # Quad damage
notarget         # Enemies ignore you
```

---

## Debugging

### Enable Bot Logging

The bot prints messages with `Cortex_Log()`. Check console for:
- "Solver Logic Loaded." - Bot spawned
- "Terminated." - Bot died
- "Button pressed." - Bot interacted with button

### Common Issues

**Bot doesn't spawn:**
- Check progs.dat is in id1/ folder
- Verify map has info_player_deathmatch entities
- Check console for error messages

**Bot doesn't move:**
- Ensure spawn points exist on map
- Check if bot is stuck (rocket jump should trigger)

**Bot doesn't shoot:**
- Bot spawns with 50 rockets and 50 cells
- Check if weapon functions are working

**Compile errors:**
- Verify stubs.qc is included in progs.src
- Check for missing semicolons
- Ensure forward declarations exist

---

## Performance Monitoring

Watch for:
- FPS drops with multiple bots
- Network traffic in multiplayer
- Entity count limits

Target: 4+ bots without significant FPS drop

---

## Bug Reporting

When reporting bugs, include:
1. Map name
2. Steps to reproduce
3. Expected vs actual behavior
4. Console output
5. Quake engine used

---

*Last Updated: 2026-01-16*
