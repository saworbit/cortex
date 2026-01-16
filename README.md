# Cortex Bot

[![CI](https://github.com/github_user/cortexbot/actions/workflows/ci.yml/badge.svg)](https://github.com/github_user/cortexbot/actions/workflows/ci.yml)

A state-of-the-art deathmatch bot for Quake (1996).

## What is Cortex Bot?

Cortex Bot is an advanced AI opponent for the classic first-person shooter, Quake. It's designed to provide a challenging and human-like deathmatch experience. The bot is written in QuakeC and can be integrated into existing mods or used as a standalone `progs.dat`.

## Features

- **Smart Weapon Selection**: Chooses the best weapon for the current range and ammo.
- **Projectile Dodging**: Actively evades incoming rockets and grenades.
- **Threat Assessment**: Knows when to fight and when to retreat.
- **Lead Prediction**: Aims ahead of moving targets to increase accuracy.
- **Advanced Navigation**: Can navigate complex maps, including jumping gaps, using teleporters, and swimming.
- **Resource Management**: Seeks out health, armor, and ammo when low, and tracks major power-up respawn times.
- **Situational Awareness**: Investigates sounds of combat and hunts down enemies.

## Building

To compile the bot, you'll need `fteqcc`. You can download it from [fteqcc.org](https://www.fteqcc.org/) or install it using your system's package manager.

### Windows

Run the build script:
```sh
build.bat
```

### Linux / macOS

Run the build script:
```sh
./build.sh
```

These scripts will generate a `progs.dat` file in the root of the repository. This file contains the compiled QuakeC code.

## Quick Start

1.  Build the `progs.dat` file as described in the **Building** section.
2.  Copy the generated `progs.dat` into your Quake `id1` directory (e.g., `C:\Games\Quake\id1` or `~/.quake/id1`).
3.  Launch Quake and start a deathmatch game (e.g., `quake +deathmatch 1 +map dm4`).
4.  Once in the game, open the console and type `impulse 100` to spawn a bot.

## For Developers

The following sections provide more detailed information for developers who want to integrate Cortex Bot into their own mods or understand its inner workings.

### Integration

To integrate Cortex Bot into your existing QuakeC codebase, please refer to the instructions in the original `README.md` file, which has been preserved as `README-legacy.md`.

### File Structure

```
cortexbot/
├── bot.qc          # Main bot AI (~2100 lines)
├── stubs.qc        # Test stubs for standalone compilation
├── progs.src       # Compilation order
├── README.md       # This file
├── CHANGELOG.md    # Version history
└── STATUS.md       # Feature completion status
```

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

### API

#### Public Functions

```c
void() SpawnCortexBot;           // Spawn a new bot
void() Cortex_ClientInRankings;  // Call when player joins
void() Cortex_ClientDisconnected; // Call when player leaves
```

#### Bot Entity Fields

```c
.float cortex_state;        // Current AI state
.entity cortex_goal_ent;    // Current navigation target
.vector cortex_last_known;  // Last known enemy position
.float cortex_stuck_severity; // Stuck detection counter
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
