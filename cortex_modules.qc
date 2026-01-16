/*
==============================================================================
 MODULE 5: GAP-FINDING NAVIGATION (State-of-the-Art Steering)
 Replaces standard "Whiskers".

 Instead of checking Left/Right, this scans a 90-degree sector to find
 the "deepest" open space (the Gap) and steers smoothly towards it.
 This allows the bot to slalom through pillars and doorways fluidly.
==============================================================================
*/

void(float ideal_yaw) Cortex_GapFinder_Move =
{
    local float best_dist, current_dist;
    local float best_yaw, check_yaw;
    local vector source, dir;
    local float i;

    // Default to the ideal direction (where we want to go)
    best_yaw = ideal_yaw;
    best_dist = 0;
    source = self.origin + '0 0 24';

    // Scan 5 rays: -60, -30, 0, +30, +60
    for (i = -2; i <= 2; i = i + 1)
    {
        check_yaw = ideal_yaw + (i * 30);

        self.angles_y = check_yaw;
        makevectors(self.angles);

        // Cast far (200 units)
        traceline(source, source + (v_forward * 200), TRUE, self);

        // Check safety (don't steer into lava)
        if (Cortex_CheckSafety(trace_endpos))
        {
            // Calculate actual distance hit
            current_dist = vlen(trace_endpos - source);

            // Bias slightly towards center (0 index) to prevent wobbling
            if (i == 0) current_dist = current_dist + 20;

            if (current_dist > best_dist)
            {
                best_dist = current_dist;
                best_yaw = check_yaw;
            }
        }
    }

    // Apply the best angle
    self.angles_y = best_yaw;

    // Physics Move
    if (!walkmove(self.angles_y, 20)) // High speed
    {
        // Wall-slide fallback if completely blocked
        if (random() < 0.1) self.velocity_z = 270; // Jump
        else self.angles_y = self.angles_y + 180; // Turn around
    }
};


/*
==============================================================================
 MODULE 6: THE "NEO" MATRIX DODGE (Combat Defense)
 Scans for incoming projectiles (Rockets/Grenades) within a danger radius.
 If detected, it calculates a perpendicular dodge vector to sidestep impact.
==============================================================================
*/

void() Cortex_ProjectileDodge =
{
    local entity threat;
    local vector dir_to_threat, dodge_dir;

    // Scan small radius for missiles
    threat = findradius(self.origin, 300);

    while (threat)
    {
        if (threat.classname == "rocket" || threat.classname == "grenade")
        {
            // Is it moving towards us?
            // Dot product of missile velocity and direction to bot
            // (Simplified: Just check if it's close and we aren't the owner)
            if (threat.owner != self)
            {
                // Calculate Dodge Vector (Perpendicular to threat)
                dir_to_threat = normalize(threat.origin - self.origin);

                // Cross product for perpendicular vector
                dodge_dir_x = dir_to_threat_y * -1;
                dodge_dir_y = dir_to_threat_x;
                dodge_dir_z = 0;

                // Boost Velocity in that direction
                self.velocity = self.velocity + (dodge_dir * 350);

                // Play sound or log
                if (random() < 0.2) sound(self, CHAN_VOICE, "player/land.wav", 1, ATTN_NORM);
                return; // Only dodge one at a time
            }
        }
        threat = threat.chain;
    }
};


/*
==============================================================================
 MODULE 7: POWERUP TIMING CONTROLLER (Map Awareness)
 Tracks the death time of the Quad/Pentagram and forces the bot to
 camp the spawn point 5 seconds before it reappears.
==============================================================================
*/

// Field to store when we expect the item to return
.float cortex_next_quad_spawn;

void() Cortex_CheckPowerupTimers =
{
    // 1. Observe the Quad
    if (self.cortex_cache_quad)
    {
        // If the Quad entity is hidden (solid_not), it has been picked up
        if (self.cortex_cache_quad.solid == SOLID_NOT)
        {
            // If we haven't set a timer yet, set it now
            // Standard Quad respawn is 60 seconds.
            // Note: This requires the bot to 'see' it picked up or check periodically.
            // A simple heuristic: If we see it's gone, assume it comes back in 60s from *now*.
            if (self.cortex_next_quad_spawn < time)
            {
                self.cortex_next_quad_spawn = time + 60;
            }
        }
        else
        {
            // It is present! Reset timer
            self.cortex_next_quad_spawn = 0;
        }
    }

    // 2. Decide to Camp
    // If Quad spawns in < 5 seconds, drop everything and run there
    if (self.cortex_next_quad_spawn > time &&
        self.cortex_next_quad_spawn < (time + 5))
    {
        self.cortex_goal_ent = self.cortex_cache_quad;
        self.cortex_state = STATE_FETCH; // Override current state
        Cortex_Log("Timing Quad Damage...");
    }
};


/*
==============================================================================
 MODULE 8: AERIAL COMBO SYSTEM (Advanced Combat)
 Logic to perform "Pop-up" combos.
 1. If enemy is on ground -> Shoot Rocket at feet (Pop up).
 2. If enemy is in air -> Switch to Lightning Gun/Shotgun (Tracking).
==============================================================================
*/

void() Cortex_ComboCombat =
{
    local float enemy_grounded;

    // Check if enemy is on ground (flag check or trace)
    enemy_grounded = (self.enemy.flags & FL_ONGROUND);

    if (enemy_grounded)
    {
        // GROUNDED: Use Explosives to launch them or do splash damage
        if (Cortex_CheckAmmo(IT_ROCKET_LAUNCHER) > 0)
        {
            self.weapon = IT_ROCKET_LAUNCHER;
            // Aim at feet is handled by BallisticAim usually,
            // but we ensure it here logic-wise.
        }
        else
        {
            Cortex_SelectBestWeapon(); // Fallback
        }
    }
    else
    {
        // AIRBORNE: Use Hitscan (LG/Shotgun) for guaranteed hits
        // Tracking rockets in air is hard; LG is 100% accuracy if aiming right.
        if (Cortex_CheckAmmo(IT_LIGHTNING) > 0 && vlen(self.enemy.origin - self.origin) < 500)
        {
            self.weapon = IT_LIGHTNING;
        }
        else if (Cortex_CheckAmmo(IT_SUPER_SHOTGUN) > 0)
        {
            self.weapon = IT_SUPER_SHOTGUN;
        }
        else
        {
            Cortex_SelectBestWeapon();
        }
    }

    Cortex_FireWeapon();
};
