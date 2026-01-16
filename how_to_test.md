# How to Test the Cortex Bot

This document provides instructions on how to compile and test the Cortex Bot.

## 1. Compilation

The bot's source code is in `bot.qc`. You need to compile it into a `progs.dat` file that the Quake engine can load.

1.  **Compiler:** The recommended compiler is `fteqcc64.exe`, located in the `tools/fteqcc_win64` directory.
2.  **Command:** Open a command prompt in the `cortexbot` directory and run the following command:

    ```sh
tools\\fteqcc_win64\\fteqcc64.exe -srcfile progs.src
    ```

    This will create a `progs.dat` file inside the `quakespasm/cortexbot` directory. This file contains the compiled game + bot logic.

## 2. Running the Bot

Once you have compiled the bot, you can run it in Quake.

1.  **Engine:** Use the `quakespasm.exe` engine located in the `quakespasm` directory.
2.  **Launch Command:** To start a game with the bot, you'll need to use a command line like this. This example starts a listen server (needed for scoreboard slots), a deathmatch game on the map `e1m1`, and adds one bot to the game.

    ```sh
quakespasm\\quakespasm.exe -listen 8 -game cortexbot +map e1m1 +deathmatch 1 +skill 3
    ```
3.  **Adding a bot:** Once in the game, open the console (usually with the `~` key) and type the following command to add a bot:
    ```
impulse 100
    ```
    The `SpawnCortexBot` function in `bot.qc` is hooked to `impulse 100` but this is not standard. A better way would be to add a console command to spawn the bot. For now, you can add a bot with the `impulse` command.

## 3. Testing Scenarios

Here is a checklist of scenarios to test the bot's features:

### Environmental Interaction

*   **Push Buttons:** Find a map with a pushable `func_button`. The bot should walk into it when in `STATE_ROAM` or when it gets stuck.
*   **Shootable Buttons:** Find a map with a shootable `func_button`. The bot should shoot it.
*   **Platforms:** Find a map with a `func_plat` or `func_train`. The bot should stand still on the platform while it's moving (`STATE_RIDING`).

### Unstuck System

*   **Getting Stuck:** Try to trap the bot in a corner or behind an obstacle.
*   **Stage 1 (Wall Slide):** Observe if the bot tries to change its angle to get free.
*   **Stage 2 (Backpedal):** If it's still stuck, it should try to walk backward.
*   **Stage 3 (Panic Rocket):** If it's severely stuck, it should fire a rocket at its feet to dislodge itself.

### Combat

*   **Weapon Selection:**
    *   **Close Range:** When close to an enemy, the bot should use its lightning gun.
    *   **Long Range:** At a distance, it should use the rocket launcher.
*   **Target Leading:** In a large open area, observe if the bot leads its rocket shots against a moving target.
*   **Suppressive Fire:** When an enemy is out of sight, the bot should fire rockets at the enemy's last known position.
*   **Strafing:** During combat, the bot should strafe left and right to avoid incoming fire.
*   **Retreating:** When the bot's health is low (below 40), it should stop fighting and go look for health packs (`STATE_RETREAT`).

### Objectives

*   **Roaming:** When there are no enemies or objectives, the bot should move between `info_player_deathmatch` locations.
*   **Power-up Fetching:** In a map with a Quad Damage or Pentagram of Protection, the bot should actively try to collect them (`STATE_FETCH`).

By going through these scenarios, you can thoroughly test the functionality of the Cortex Bot.
