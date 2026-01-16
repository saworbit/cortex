/*
==============================================================================

CORTEX BOT v4.2 "Hunter"

A state-of-the-art deathmatch bot for Quake.

COMBAT SYSTEMS:
    Weapon Selection - Distance-based weapon choice (LG close, RL mid/long)
                     - Self-damage avoidance (no rockets < 120 units)
                     - Ammo consumption tracking
                     - All weapons supported: SG, SSG, NG, SNG, GL, RL, LG

    Aim Prediction   - Lead calculation for projectile weapons
                     - Velocity-based target prediction
                     - Suppressive fire at last known position

    Threat Response  - Projectile dodging (detects incoming rockets/grenades)
                     - Threat assessment based on enemy health/weapons
                     - Tactical retreat when outgunned or low health

NAVIGATION:
    Whisker System   - 3-ray obstacle detection
                     - Hazard avoidance (lava, slime, pits)
                     - Velocity stacking for momentum

    Platform Riding  - Detects func_plat, func_train, func_door
                     - Freezes movement while platform moving

    Unstuck System   - Stage 1: Random angle adjustment
                     - Stage 2: Tactical backpedal + hop
                     - Stage 3: Panic rocket jump

    Rocket Jumping   - Vertical mobility when stuck
                     - Health-aware (won't RJ below 50hp)

    Teleporters      - Detects trigger_teleport entities
                     - Uses teleporters when roaming or stuck

    Water Navigation - Detects water/slime volumes
                     - Swims toward surface automatically
                     - Emergency escape from slime

    Jump Gaps        - Detects gaps and ledges ahead
                     - Calculates jumpable distances
                     - Executes timed jumps with momentum

RESOURCE MANAGEMENT:
    Item Pickup      - Automatic collection within touch range
                     - Health, armor, weapons, ammo, powerups

    Item Seeking     - Prioritizes needed resources
                     - Finds nearest useful item within 2000 units

    Item Timing      - Tracks powerup respawn times
                     - Anticipates quad/pent/mega spawns

SENSORY:
    Sound Awareness  - Hears rockets, grenades, nailgun fire
                     - Detects teleport fog (player arrivals)
                     - Investigates sounds when no enemy visible

STATE MACHINE:
    ROAM    - Patrol between spawn points, seek items
    HUNT    - Chase enemy to last known position / sound
    COMBAT  - Engage visible enemy with strafing
    RETREAT - Flee to health when low
    FETCH   - Move to specific goal (powerup, item, teleporter)
    RIDING  - Stationary on moving platform
    SOLVE   - Interacting with button

ENVIRONMENTAL:
    Button Interaction - Detects func_button
                       - Shoots shootable buttons
                       - Walks into push buttons

==============================================================================
*/

// --- State Constants ---
float STATE_ROAM      = 0;
float STATE_HUNT      = 1;
float STATE_COMBAT    = 2;
float STATE_RETREAT   = 3;
float STATE_FETCH     = 4; 
float STATE_RIDING    = 5; // On a platform
float STATE_SOLVE     = 6; // Pressing a button

// --- Globals/Fields ---
.float  cortex_state;
.float  cortex_next_scan;
.entity cortex_goal_ent;     
.vector cortex_last_known;   
.float  cortex_strafe_dir;   
.float  cortex_rocket_jump_time; 
.float  cortex_velocity_stack; 

// Unstuck & Solver Fields
.vector cortex_history_pos;  // Position 0.2s ago
.float  cortex_stuck_severity;
.float  cortex_stuck_check_time;

// Map Knowledge & Item Timing
.entity cortex_cache_quad;
.entity cortex_cache_pent;
.entity cortex_cache_mega;
.float  cortex_quad_time;    // When quad will respawn
.float  cortex_pent_time;    // When pent will respawn
.float  cortex_mega_time;    // When mega will respawn

// Dodge System
.float  cortex_dodge_time;   // Cooldown for dodge checks
.vector cortex_dodge_dir;    // Direction to dodge
.float  cortex_clientno;
.float  cortex_shirt;
.float  cortex_pants;
.float  cortex_frags;

// Sound Awareness
.vector cortex_sound_origin; // Where we heard a sound
.float  cortex_sound_time;   // When we last heard something
.float  cortex_listen_time;  // Cooldown for sound checks

// Water Navigation
.float  cortex_in_water;     // Currently in water?
.float  cortex_water_time;   // Time we entered water

// Jump Gap Detection
.float  cortex_jump_time;    // Cooldown for jump attempts
.vector cortex_jump_target;  // Where we want to jump to

// Cover & Strafe Timing
.vector cortex_cover_pos;    // Tactical cover location
.float  cortex_cover_active; // Is cover movement active?
.float  cortex_strafe_time;  // Strafe direction change timer

// Weapon constants - use existing defs from defs.qc
// IT_SHOTGUN, IT_SUPER_SHOTGUN, IT_NAILGUN, IT_SUPER_NAILGUN,
// IT_GRENADE_LAUNCHER, IT_ROCKET_LAUNCHER, IT_LIGHTNING,
// IT_QUAD, IT_INVULNERABILITY, IT_INVISIBILITY already defined

// Weapon selection priorities (higher = better)
// Context-dependent: close range favors hitscan, long range favors projectiles
float CORTEX_CLOSE_RANGE  = 200;   // Use shaft/SSG
float CORTEX_MID_RANGE    = 500;   // RL sweet spot
float CORTEX_LONG_RANGE   = 1000;  // RL/LG
float CORTEX_ROCKET_SELF_DAMAGE = 120; // Don't rocket closer than this

float CORTEX_SVC_UPDATENAME = 13;
float CORTEX_SVC_UPDATEFRAGS = 14;
float CORTEX_SVC_UPDATECOLORS = 17;
float CORTEX_MAX_CLIENTS = 16;
float cortex_active_clients;
float cortex_max_clients;

// Forward Declarations
void() Cortex_Think;
void() Cortex_Die;
void() Cortex_Respawn;
void() Cortex_FireWeapon;
void(vector org) spawn_tfog;
void(vector org, entity death_owner) spawn_tdeath;
void() Cortex_ScoreboardInit;
float(float clientno) Cortex_ClientBitFlag;
float() Cortex_ClientNextAvailable;
void(entity who) Cortex_UpdateClient;
void() Cortex_ClientInRankings;
void() Cortex_ClientDisconnected;
void(entity bot) Cortex_ScoreboardAdd;
void(entity bot) Cortex_ScoreboardRemove;
void() Cortex_ScoreboardRefresh;
void(float clientno) Cortex_BotInvalidClientNo;

// Weapon & Item System
float(float dist) Cortex_SelectWeapon;
void() Cortex_ConsumeAmmo;
void() Cortex_CheckForItems;
float() Cortex_NeedsSupplies;
entity() Cortex_FindNearestItem;
float() Cortex_TryRocketJump;

// Dodging & Threat Assessment
void() Cortex_CheckIncomingProjectiles;
float() Cortex_AssessThreat;
void() Cortex_UpdateItemTimers;

// Sound, Teleporter, Water, Jump Systems
void() Cortex_ListenForSounds;
void() Cortex_CheckTeleporters;
void() Cortex_HandleWater;
float() Cortex_TryJumpGap;
vector(entity targ, float speed, float is_gravity_affected) Cortex_BallisticAim;
vector() Cortex_FindCover;
float(float w_id) Cortex_CheckAmmo;
void() Cortex_SelectBestWeapon;
float(float current_yaw) Cortex_PhantomStep;

// External functions from Quake progs - already defined in weapons.qc/combat.qc
// void(vector org, vector dir) launch_spike;
// void(float count, vector dir, vector spread) FireBullets;
// void() GrenadeTouch;
// void() GrenadeExplode;
// void() T_MissileTouch;
// void(entity targ, entity inflictor, entity attacker, float damage) T_Damage;

// ===========================================================================
// UTILITIES
// ===========================================================================

void(string msg) Cortex_Log =
{
    bprint("Cortex: ");
    bprint(msg);
    bprint("\n");
};

entity() Cortex_PickSpawn =
{
    local entity spot;
    local entity thing;
    local float pcount;

    spot = find(world, classname, "testplayerstart");
    if (spot)
    {
        return spot;
    }

    if (coop)
    {
        lastspawn = find(lastspawn, classname, "info_player_coop");
        if (lastspawn == world)
        {
            lastspawn = find(lastspawn, classname, "info_player_start");
        }
        if (lastspawn != world)
        {
            return lastspawn;
        }
    }
    else if (deathmatch)
    {
        spot = lastspawn;
        while (TRUE)
        {
            spot = find(spot, classname, "info_player_deathmatch");
            if (spot != world)
            {
                if (spot == lastspawn)
                {
                    return lastspawn;
                }
                pcount = 0;
                thing = findradius(spot.origin, 64);
                while (thing)
                {
                    if (thing.classname == "player" || thing.classname == "cortexbot")
                    {
                        pcount = pcount + 1;
                    }
                    thing = thing.chain;
                }
                if (pcount == 0)
                {
                    lastspawn = spot;
                    return spot;
                }
            }
        }
    }

    if (serverflags)
    {
        spot = find(world, classname, "info_player_start2");
        if (spot)
        {
            return spot;
        }
    }
    spot = find(world, classname, "info_player_start");
    if (!spot)
    {
        error("Cortex_PickSpawn: no info_player_start on level");
    }
    return spot;
};

void() Cortex_ScoreboardInit =
{
    local entity ent;
    cortex_active_clients = 0;
    cortex_max_clients = 0;
    ent = nextent(world);
    while (ent && ent.classname != "worldspawn")
    {
        cortex_max_clients = cortex_max_clients + 1;
        ent = nextent(ent);
    }
    if (cortex_max_clients < 1)
        cortex_max_clients = cvar("maxclients");
    if (cortex_max_clients < 1)
        cortex_max_clients = cvar("sv_maxclients");
    if (cortex_max_clients < 1)
        cortex_max_clients = 1;
    if (cortex_max_clients > CORTEX_MAX_CLIENTS)
        cortex_max_clients = CORTEX_MAX_CLIENTS;
};

float(float clientno) Cortex_ClientBitFlag =
{
    if (clientno == 0) return 1;
    else if (clientno == 1) return 2;
    else if (clientno == 2) return 4;
    else if (clientno == 3) return 8;
    else if (clientno == 4) return 16;
    else if (clientno == 5) return 32;
    else if (clientno == 6) return 64;
    else if (clientno == 7) return 128;
    else if (clientno == 8) return 256;
    else if (clientno == 9) return 512;
    else if (clientno == 10) return 1024;
    else if (clientno == 11) return 2048;
    else if (clientno == 12) return 4096;
    else if (clientno == 13) return 8192;
    else if (clientno == 14) return 16384;
    else if (clientno == 15) return 32768;
    return 0;
};

float() Cortex_ClientNextAvailable =
{
    local float clientno;
    clientno = 0;
    while (clientno < cortex_max_clients)
    {
        if (!(cortex_active_clients & Cortex_ClientBitFlag(clientno)))
            return clientno;
        clientno = clientno + 1;
    }
    return -1;
};

void(entity who) Cortex_UpdateClient =
{
    if (cortex_max_clients <= 0)
        Cortex_ScoreboardInit();
    if (who.cortex_clientno < 0)
        return;
    if (who.cortex_clientno >= cortex_max_clients)
        return;
    WriteByte(MSG_ALL, CORTEX_SVC_UPDATENAME);
    WriteByte(MSG_ALL, who.cortex_clientno);
    WriteString(MSG_ALL, who.netname);
    WriteByte(MSG_ALL, CORTEX_SVC_UPDATECOLORS);
    WriteByte(MSG_ALL, who.cortex_clientno);
    WriteByte(MSG_ALL, who.cortex_shirt * 16 + who.cortex_pants);
    WriteByte(MSG_ALL, CORTEX_SVC_UPDATEFRAGS);
    WriteByte(MSG_ALL, who.cortex_clientno);
    WriteShort(MSG_ALL, who.frags);
};

void() Cortex_ClientInRankings =
{
    local float cno;
    if (cortex_max_clients <= 0)
        Cortex_ScoreboardInit();
    cno = self.colormap - 1;
    if (cno < 0) cno = 0;
    Cortex_BotInvalidClientNo(cno);
    cortex_active_clients = cortex_active_clients | Cortex_ClientBitFlag(cno);
    Cortex_ScoreboardRefresh();
};

void() Cortex_ClientDisconnected =
{
    local float cno;
    cno = self.colormap - 1;
    if (cno < 0) cno = 0;
    cortex_active_clients = cortex_active_clients - (cortex_active_clients & Cortex_ClientBitFlag(cno));
};

void() Cortex_ScoreboardRefresh =
{
    local entity bot;
    bot = find(world, classname, "cortexbot");
    while (bot)
    {
        Cortex_UpdateClient(bot);
        bot = find(bot, classname, "cortexbot");
    }
};

void(entity bot) Cortex_ScoreboardRemove =
{
    if (bot.cortex_clientno < 0)
        return;
    WriteByte(MSG_ALL, CORTEX_SVC_UPDATENAME);
    WriteByte(MSG_ALL, bot.cortex_clientno);
    WriteString(MSG_ALL, "");
    WriteByte(MSG_ALL, CORTEX_SVC_UPDATECOLORS);
    WriteByte(MSG_ALL, bot.cortex_clientno);
    WriteByte(MSG_ALL, 0);
    WriteByte(MSG_ALL, CORTEX_SVC_UPDATEFRAGS);
    WriteByte(MSG_ALL, bot.cortex_clientno);
    WriteShort(MSG_ALL, 0);
    cortex_active_clients = cortex_active_clients -
        (cortex_active_clients & Cortex_ClientBitFlag(bot.cortex_clientno));
    bot.cortex_clientno = -1;
};

void(float clientno) Cortex_BotInvalidClientNo =
{
    local entity bot;
    local float newno;
    bot = find(world, classname, "cortexbot");
    while (bot)
    {
        if (bot.cortex_clientno == clientno)
        {
            newno = Cortex_ClientNextAvailable();
            if (newno < 0)
            {
                Cortex_ScoreboardRemove(bot);
                return;
            }
            WriteByte(MSG_ALL, CORTEX_SVC_UPDATENAME);
            WriteByte(MSG_ALL, bot.cortex_clientno);
            WriteString(MSG_ALL, "");
            WriteByte(MSG_ALL, CORTEX_SVC_UPDATECOLORS);
            WriteByte(MSG_ALL, bot.cortex_clientno);
            WriteByte(MSG_ALL, 0);
            WriteByte(MSG_ALL, CORTEX_SVC_UPDATEFRAGS);
            WriteByte(MSG_ALL, bot.cortex_clientno);
            WriteShort(MSG_ALL, 0);
            cortex_active_clients = cortex_active_clients -
                (cortex_active_clients & Cortex_ClientBitFlag(bot.cortex_clientno));
            bot.cortex_clientno = newno;
            cortex_active_clients = cortex_active_clients | Cortex_ClientBitFlag(newno);
            bot.colormap = newno + 1;
            Cortex_UpdateClient(bot);
            return;
        }
        bot = find(bot, classname, "cortexbot");
    }
};

void(entity bot) Cortex_ScoreboardAdd =
{
    local float cno;
    if (cortex_max_clients <= 0)
        Cortex_ScoreboardInit();
    cno = Cortex_ClientNextAvailable();
    if (cno < 0)
    {
        bot.cortex_clientno = -1;
        return;
    }
    bot.cortex_clientno = cno;
    cortex_active_clients = cortex_active_clients | Cortex_ClientBitFlag(cno);
    bot.cortex_shirt = 13;
    bot.cortex_pants = 4;
    bot.cortex_frags = bot.frags;
    bot.netname = "cortexbot";
    bot.colormap = cno + 1;
    Cortex_UpdateClient(bot);
};

void() Cortex_MapAnalysis =
{
    local entity e;
    e = find(world, classname, "item_artifact_super_damage");
    if (e) self.cortex_cache_quad = e;
    e = find(world, classname, "item_artifact_invulnerability");
    if (e) self.cortex_cache_pent = e;
    e = find(world, classname, "item_health");
    while (e)
    {
        if (e.spawnflags & 2 || e.classname == "item_health_mega")
        {
            self.cortex_cache_mega = e; 
            e = world; 
        }
        else e = find(e, classname, "item_health");
    }
};

float(vector point) Cortex_CheckSafety =
{
    local float c;
    local vector below;
    below = point - '0 0 400';
    c = pointcontents(point);
    if (c == CONTENT_LAVA || c == CONTENT_SLIME || c == CONTENT_SKY) return FALSE;
    traceline(point, below, TRUE, self);
    if (trace_fraction == 1.0) return FALSE; 
    c = pointcontents(trace_endpos + '0 0 1');
    if (c == CONTENT_LAVA || c == CONTENT_SLIME) return FALSE;
    return TRUE;
};

float(entity targ) Cortex_CanSee =
{
    local vector vec_to_targ;
    local float dot;
    if (vlen(targ.origin - self.origin) > 2500) return FALSE;
    makevectors(self.angles);
    vec_to_targ = normalize(targ.origin - self.origin);
    dot = vec_to_targ * v_forward;
    if (dot < 0.4) return FALSE;
    traceline(self.origin + '0 0 20', targ.origin + '0 0 20', TRUE, self);
    if (trace_fraction == 1.0) return TRUE;
    return FALSE;
};

/*
Cortex_FindCover
Finds a nearby spot that breaks line of sight to the enemy.
*/
vector() Cortex_FindCover =
{
    local float i;
    local vector test_dir, test_pos;
    local vector best_pos;

    if (!self.enemy || self.enemy == world)
        return self.origin;

    best_pos = self.origin; // Default: stay put if no cover found

    // Cast 8 rays in a circle around the bot
    for (i = 0; i < 360; i = i + 45)
    {
        // Create a vector for this angle
        test_dir_x = cos(i * 0.01745); // Deg to Rad approx
        test_dir_y = sin(i * 0.01745);
        test_dir_z = 0;

        // Check a spot 150 units away
        test_pos = self.origin + (test_dir * 150);

        // 1. Is the spot walkable?
        traceline(self.origin, test_pos, TRUE, self);
        if (trace_fraction == 1.0)
        {
            // 2. Does this spot hide us from the enemy?
            traceline(test_pos, self.enemy.origin, TRUE, self);

            // If trace hit a wall (fraction < 1.0), it's good cover
            if (trace_fraction < 1.0)
            {
                return test_pos;
            }
        }
    }

    return best_pos;
};

// ===========================================================================
// ADVANCED MOVEMENT & SOLVER ENGINE
// ===========================================================================

/*
Cortex_SolveButtons
Scans for nearby buttons. Prioritizes them if stuck or roaming.
*/
void() Cortex_SolveButtons =
{
    local entity head;
    head = findradius(self.origin, 400); // Look around
    
    while (head)
    {
        if (head.classname == "func_button" && Cortex_CanSee(head))
        {
            // Found a button. Is it a SHOOT button?
            if (head.health > 0)
            {
                // Aim and fire!
                self.enemy = head;
                Cortex_FireWeapon();
                return;
            }
            // Is it a PUSH button?
            else
            {
                // Set as goal to walk into
                self.cortex_goal_ent = head;
                self.cortex_state = STATE_SOLVE;
                return;
            }
        }
        head = head.chain;
    }
};

/*
Cortex_HandlePlatform
Detects if we are on a moving floor and stabilizes.
*/
void() Cortex_HandlePlatform =
{
    if (self.flags & FL_ONGROUND)
    {
        // Check if ground is a moving entity
        if (self.groundentity.classname == "func_plat" || 
            self.groundentity.classname == "func_train" || 
            self.groundentity.classname == "func_door")
        {
            // If it's moving, RIDE IT.
            if (vlen(self.groundentity.velocity) > 0)
            {
                self.cortex_state = STATE_RIDING;
                self.velocity = '0 0 0'; // Stop fighting the platform
                return;
            }
        }
    }
    
    // If we were riding but it stopped, resume
    if (self.cortex_state == STATE_RIDING)
    {
        if (vlen(self.groundentity.velocity) == 0)
            self.cortex_state = STATE_ROAM;
    }
};

/*
Cortex_GhostUnstuck
Complex logic to free the bot from geometry traps.
*/
void() Cortex_GhostUnstuck =
{
    // Check progress every 0.3 seconds
    if (time > self.cortex_stuck_check_time)
    {
        self.cortex_stuck_check_time = time + 0.3;
        
        // Have we moved less than 10 units?
        if (vlen(self.origin - self.cortex_history_pos) < 10)
        {
            self.cortex_stuck_severity = self.cortex_stuck_severity + 1;
        }
        else
        {
            // We are free, reset
            self.cortex_stuck_severity = 0;
        }
        self.cortex_history_pos = self.origin;
    }

    // Apply countermeasures based on severity
    if (self.cortex_stuck_severity >= 1)
    {
        // Stage 1: Wall Slide / Jitter
        // Try to find a new angle randomly
        self.angles_y = self.angles_y + (random() * 90) - 45;
    }
    
    if (self.cortex_stuck_severity >= 2)
    {
        // Stage 2: Backpedal
        // Invert velocity intention by walking backwards
        makevectors(self.angles);
        walkmove(self.angles_y + 180, 32);
        if (random() < 0.3) self.velocity_z = 250; // Hop
    }
    
    if (self.cortex_stuck_severity >= 4)
    {
        // Stage 3: Panic Rocket (Explosive Dislodge)
        // Fire at own feet to knock self away from corner
        local float old_pitch;
        old_pitch = self.angles_x;
        self.angles_x = 80;
        Cortex_FireWeapon();
        self.angles_x = old_pitch;
        self.cortex_stuck_severity = 0; // Reset after drastic measure
    }
};

/*
Cortex_PhantomStep
Adds erratic jukes based on pain and a simple weave oscillator.
*/
float(float current_yaw) Cortex_PhantomStep =
{
    local float dodge_yaw;
    dodge_yaw = current_yaw;

    // Pain reaction: juke hard when recently hit
    if (time < self.pain_finished + 0.2)
    {
        if (random() < 0.5)
            dodge_yaw = dodge_yaw + 90;
        else
            dodge_yaw = dodge_yaw - 90;

        // 50% chance to jump when hit
        if (random() < 0.5 && (self.flags & FL_ONGROUND))
            self.velocity_z = 240;
    }

    // Oscillator weave
    if ( (time * 10) & 1 )
        dodge_yaw = dodge_yaw + 15;
    else
        dodge_yaw = dodge_yaw - 15;

    return dodge_yaw;
};

void(float ideal_yaw) Cortex_Move =
{
    local vector source;
    local float left_c, right_c, center_c;
    local vector v_left;
    
    // 0. Platform Check
    Cortex_HandlePlatform();
    if (self.cortex_state == STATE_RIDING) return;

    // 1. Unstuck Monitor
    Cortex_GhostUnstuck();
    if (self.cortex_stuck_severity > 1) return; // Let unstuck logic take control

    // 2. Whisker Navigation (Standard)
    self.angles_x = 0;
    self.angles_z = 0;
    self.angles_y = ideal_yaw;
    makevectors(self.angles);
    source = self.origin + '0 0 24';

    traceline(source, source + (v_forward * 120), TRUE, self);
    center_c = trace_fraction;
    if (!Cortex_CheckSafety(trace_endpos)) center_c = 0;

    v_left = v_forward * 0.819 - v_right * 0.573;
    traceline(source, source + (v_left * 90), TRUE, self);
    left_c = trace_fraction;
    if (!Cortex_CheckSafety(trace_endpos)) left_c = 0;

    v_left = v_forward * 0.819 + v_right * 0.573; 
    traceline(source, source + (v_left * 90), TRUE, self);
    right_c = trace_fraction;
    if (!Cortex_CheckSafety(trace_endpos)) right_c = 0;

    if (center_c < 1.0)
    {
        self.cortex_velocity_stack = 0; 
        if (left_c > right_c) self.angles_y = self.angles_y + 55;
        else self.angles_y = self.angles_y - 55;
    }
    else
    {
        if (left_c < 0.8) self.angles_y = self.angles_y - 15;
        if (right_c < 0.8) self.angles_y = self.angles_y + 15;
    }

    // 3. Velocity Stacking
    float move_speed;
    move_speed = 18; 
    if (center_c == 1.0)
    {
        self.cortex_velocity_stack = self.cortex_velocity_stack + 1;
        if (self.cortex_velocity_stack > 20) move_speed = 26; 
        else if (self.cortex_velocity_stack > 10) move_speed = 22;
    }
    else self.cortex_velocity_stack = 0;

    if (!walkmove(self.angles_y, move_speed))
    {
        self.cortex_velocity_stack = 0;
        // Minor hop, major stuck handled by GhostUnstuck
        if (random() < 0.1 && (self.flags & FL_ONGROUND)) self.velocity_z = 270; 
    }
};

// ===========================================================================
// WEAPON SELECTION SYSTEM
// ===========================================================================

/*
Cortex_CheckAmmo
Return ammo count for a weapon id.
*/
float(float w_id) Cortex_CheckAmmo =
{
    if (w_id == IT_ROCKET_LAUNCHER) return self.ammo_rockets;
    if (w_id == IT_LIGHTNING) return self.ammo_cells;
    if (w_id == IT_SUPER_NAILGUN) return self.ammo_nails;
    if (w_id == IT_SUPER_SHOTGUN) return self.ammo_shells;
    if (w_id == IT_NAILGUN) return self.ammo_nails;
    if (w_id == IT_SHOTGUN) return self.ammo_shells;
    if (w_id == IT_GRENADE_LAUNCHER) return self.ammo_rockets;
    return 0;
};

/*
Cortex_SelectBestWeapon
Dynamic weapon weighting based on distance and situation.
*/
void() Cortex_SelectBestWeapon =
{
    local float score_rl, score_lg, score_sng, score_ssg;
    local float dist;
    local float best_score;
    local float best_weapon;

    if (self.enemy) dist = vlen(self.enemy.origin - self.origin);
    else dist = 500;

    best_score = -99999;
    best_weapon = 0;

    // Rocket Launcher
    score_rl = -99999;
    if ((self.items & IT_ROCKET_LAUNCHER) && Cortex_CheckAmmo(IT_ROCKET_LAUNCHER) > 0)
    {
        score_rl = 50;
        if (dist > 300) score_rl = score_rl + 40; // Great at range
        if (dist < 100) score_rl = score_rl - 100; // Danger close!
        if (self.enemy && self.enemy.origin_z < self.origin_z)
            score_rl = score_rl + 30; // High ground bonus
    }
    if (score_rl > best_score)
    {
        best_score = score_rl;
        best_weapon = IT_ROCKET_LAUNCHER;
    }

    // Lightning Gun
    score_lg = -99999;
    if ((self.items & IT_LIGHTNING) && Cortex_CheckAmmo(IT_LIGHTNING) > 0)
    {
        score_lg = 60;
        if (dist < 400) score_lg = score_lg + 50; // Melting range
        if (inwater(self)) score_lg = -99999; // Don't use in water
    }
    if (score_lg > best_score)
    {
        best_score = score_lg;
        best_weapon = IT_LIGHTNING;
    }

    // Super Nailgun
    score_sng = -99999;
    if ((self.items & IT_SUPER_NAILGUN) && Cortex_CheckAmmo(IT_SUPER_NAILGUN) > 0)
    {
        score_sng = 40;
        if (dist < 600) score_sng = score_sng + 20;
        if (dist < 200) score_sng = score_sng + 10;
    }
    if (score_sng > best_score)
    {
        best_score = score_sng;
        best_weapon = IT_SUPER_NAILGUN;
    }

    // Super Shotgun
    score_ssg = -99999;
    if ((self.items & IT_SUPER_SHOTGUN) && Cortex_CheckAmmo(IT_SUPER_SHOTGUN) > 0)
    {
        score_ssg = 30;
        if (dist < 150) score_ssg = score_ssg + 40; // Point blank
        if (self.enemy && self.enemy.health < 30) score_ssg = score_ssg + 50; // Finish him
    }
    if (score_ssg > best_score)
    {
        best_score = score_ssg;
        best_weapon = IT_SUPER_SHOTGUN;
    }

    self.weapon = best_weapon;
};

/*
Cortex_SelectWeaponLegacy
Distance-based selection used as a fallback.
*/
float(float dist) Cortex_SelectWeaponLegacy =
{
    local float dominated; // Is enemy weaker?

    dominated = FALSE;
    if (self.enemy)
    {
        if (self.enemy.health < 50) dominated = TRUE;
    }

    // Close range - avoid self damage!
    if (dist < CORTEX_ROCKET_SELF_DAMAGE)
    {
        // Lightning gun is king at close range
        if ((self.items & IT_LIGHTNING) && self.ammo_cells >= 1 && !inwater(self))
            return IT_LIGHTNING;
        // Super shotgun next
        if ((self.items & IT_SUPER_SHOTGUN) && self.ammo_shells >= 2)
            return IT_SUPER_SHOTGUN;
        // Regular shotgun as fallback
        if ((self.items & IT_SHOTGUN) && self.ammo_shells >= 1)
            return IT_SHOTGUN;
        // Super nailgun
        if ((self.items & IT_SUPER_NAILGUN) && self.ammo_nails >= 2)
            return IT_SUPER_NAILGUN;
        // Nailgun
        if ((self.items & IT_NAILGUN) && self.ammo_nails >= 1)
            return IT_NAILGUN;
        // Desperate: rocket anyway if nothing else
        if ((self.items & IT_ROCKET_LAUNCHER) && self.ammo_rockets >= 1)
            return IT_ROCKET_LAUNCHER;
    }
    // Medium close range - shaft territory
    else if (dist < CORTEX_CLOSE_RANGE)
    {
        if ((self.items & IT_LIGHTNING) && self.ammo_cells >= 1 && !inwater(self))
            return IT_LIGHTNING;
        if ((self.items & IT_ROCKET_LAUNCHER) && self.ammo_rockets >= 1)
            return IT_ROCKET_LAUNCHER;
        if ((self.items & IT_SUPER_NAILGUN) && self.ammo_nails >= 2)
            return IT_SUPER_NAILGUN;
        if ((self.items & IT_SUPER_SHOTGUN) && self.ammo_shells >= 2)
            return IT_SUPER_SHOTGUN;
    }
    // Mid range - rockets shine here
    else if (dist < CORTEX_MID_RANGE)
    {
        if ((self.items & IT_ROCKET_LAUNCHER) && self.ammo_rockets >= 1)
            return IT_ROCKET_LAUNCHER;
        if ((self.items & IT_LIGHTNING) && self.ammo_cells >= 1 && !inwater(self))
            return IT_LIGHTNING;
        if ((self.items & IT_SUPER_NAILGUN) && self.ammo_nails >= 2)
            return IT_SUPER_NAILGUN;
        if ((self.items & IT_GRENADE_LAUNCHER) && self.ammo_rockets >= 1)
            return IT_GRENADE_LAUNCHER;
    }
    // Long range
    else
    {
        if ((self.items & IT_ROCKET_LAUNCHER) && self.ammo_rockets >= 1)
            return IT_ROCKET_LAUNCHER;
        if ((self.items & IT_LIGHTNING) && self.ammo_cells >= 1 && !inwater(self))
            return IT_LIGHTNING;
        if ((self.items & IT_SUPER_NAILGUN) && self.ammo_nails >= 2)
            return IT_SUPER_NAILGUN;
        if ((self.items & IT_NAILGUN) && self.ammo_nails >= 1)
            return IT_NAILGUN;
    }

    // Fallback: use whatever we have
    if ((self.items & IT_ROCKET_LAUNCHER) && self.ammo_rockets >= 1)
        return IT_ROCKET_LAUNCHER;
    if ((self.items & IT_LIGHTNING) && self.ammo_cells >= 1 && !inwater(self))
        return IT_LIGHTNING;
    if ((self.items & IT_SUPER_NAILGUN) && self.ammo_nails >= 2)
        return IT_SUPER_NAILGUN;
    if ((self.items & IT_NAILGUN) && self.ammo_nails >= 1)
        return IT_NAILGUN;
    if ((self.items & IT_SUPER_SHOTGUN) && self.ammo_shells >= 2)
        return IT_SUPER_SHOTGUN;
    if ((self.items & IT_SHOTGUN) && self.ammo_shells >= 1)
        return IT_SHOTGUN;
    if ((self.items & IT_GRENADE_LAUNCHER) && self.ammo_rockets >= 1)
        return IT_GRENADE_LAUNCHER;

    return 0; // No weapon available!
};

/*
Cortex_SelectWeapon
Chooses the best weapon for the current situation.
Returns the weapon IT_ constant to use.
*/
float(float dist) Cortex_SelectWeapon =
{
    Cortex_SelectBestWeapon();
    if (self.weapon && (self.items & self.weapon) && Cortex_CheckAmmo(self.weapon) > 0)
        return self.weapon;

    return Cortex_SelectWeaponLegacy(dist);
};

/*
Cortex_HasAmmoForWeapon
Check if we have ammo for the selected weapon.
*/
float(float weap) Cortex_HasAmmoForWeapon =
{
    if (weap == IT_SHOTGUN) return (self.ammo_shells >= 1);
    if (weap == IT_SUPER_SHOTGUN) return (self.ammo_shells >= 2);
    if (weap == IT_NAILGUN) return (self.ammo_nails >= 1);
    if (weap == IT_SUPER_NAILGUN) return (self.ammo_nails >= 2);
    if (weap == IT_GRENADE_LAUNCHER) return (self.ammo_rockets >= 1);
    if (weap == IT_ROCKET_LAUNCHER) return (self.ammo_rockets >= 1);
    if (weap == IT_LIGHTNING) return (self.ammo_cells >= 1);
    return FALSE;
};

/*
Cortex_ConsumeAmmo
Deduct ammo for the current weapon.
*/
void() Cortex_ConsumeAmmo =
{
    if (self.weapon == IT_SHOTGUN)
        self.ammo_shells = self.ammo_shells - 1;
    else if (self.weapon == IT_SUPER_SHOTGUN)
        self.ammo_shells = self.ammo_shells - 2;
    else if (self.weapon == IT_NAILGUN)
        self.ammo_nails = self.ammo_nails - 1;
    else if (self.weapon == IT_SUPER_NAILGUN)
        self.ammo_nails = self.ammo_nails - 2;
    else if (self.weapon == IT_GRENADE_LAUNCHER)
        self.ammo_rockets = self.ammo_rockets - 1;
    else if (self.weapon == IT_ROCKET_LAUNCHER)
        self.ammo_rockets = self.ammo_rockets - 1;
    else if (self.weapon == IT_LIGHTNING)
        self.ammo_cells = self.ammo_cells - 1;

    // Update currentammo display
    if (self.weapon == IT_SHOTGUN || self.weapon == IT_SUPER_SHOTGUN)
        self.currentammo = self.ammo_shells;
    else if (self.weapon == IT_NAILGUN || self.weapon == IT_SUPER_NAILGUN)
        self.currentammo = self.ammo_nails;
    else if (self.weapon == IT_GRENADE_LAUNCHER || self.weapon == IT_ROCKET_LAUNCHER)
        self.currentammo = self.ammo_rockets;
    else if (self.weapon == IT_LIGHTNING)
        self.currentammo = self.ammo_cells;
};

// ===========================================================================
// ITEM PICKUP SYSTEM
// ===========================================================================

/*
Cortex_TouchItem
Called when bot touches an item. Handles pickup logic.
*/
void() Cortex_TouchItem =
{
    local entity item;
    item = other;

    // Health
    if (item.classname == "item_health")
    {
        if (self.health >= 100 && !(item.spawnflags & 2))
            return; // Don't need small health
        if (item.spawnflags & 2) // Megahealth
        {
            self.health = self.health + 100;
            if (self.health > 250) self.health = 250;
        }
        else if (item.spawnflags & 1) // Rotten (15hp)
            self.health = self.health + 15;
        else // Normal (25hp)
            self.health = self.health + 25;
        if (self.health > 100 && !(item.spawnflags & 2))
            self.health = 100;
        sound(self, CHAN_ITEM, "items/health1.wav", 1, ATTN_NORM);
    }
    // Armor
    else if (item.classname == "item_armor1") // Green
    {
        if (self.armorvalue >= 100) return;
        self.armortype = 0.3;
        self.armorvalue = 100;
        sound(self, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "item_armor2") // Yellow
    {
        if (self.armorvalue >= 150 && self.armortype >= 0.6) return;
        self.armortype = 0.6;
        self.armorvalue = 150;
        sound(self, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "item_armorInv") // Red
    {
        if (self.armorvalue >= 200 && self.armortype >= 0.8) return;
        self.armortype = 0.8;
        self.armorvalue = 200;
        sound(self, CHAN_ITEM, "items/armor1.wav", 1, ATTN_NORM);
    }
    // Weapons
    else if (item.classname == "weapon_supershotgun")
    {
        self.items = self.items | IT_SUPER_SHOTGUN;
        self.ammo_shells = self.ammo_shells + 5;
        sound(self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "weapon_nailgun")
    {
        self.items = self.items | IT_NAILGUN;
        self.ammo_nails = self.ammo_nails + 30;
        sound(self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "weapon_supernailgun")
    {
        self.items = self.items | IT_SUPER_NAILGUN;
        self.ammo_nails = self.ammo_nails + 30;
        sound(self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "weapon_grenadelauncher")
    {
        self.items = self.items | IT_GRENADE_LAUNCHER;
        self.ammo_rockets = self.ammo_rockets + 5;
        sound(self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "weapon_rocketlauncher")
    {
        self.items = self.items | IT_ROCKET_LAUNCHER;
        self.ammo_rockets = self.ammo_rockets + 5;
        sound(self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "weapon_lightning")
    {
        self.items = self.items | IT_LIGHTNING;
        self.ammo_cells = self.ammo_cells + 15;
        sound(self, CHAN_ITEM, "weapons/pkup.wav", 1, ATTN_NORM);
    }
    // Ammo
    else if (item.classname == "item_shells")
    {
        if (item.spawnflags & 1) self.ammo_shells = self.ammo_shells + 40;
        else self.ammo_shells = self.ammo_shells + 20;
        sound(self, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "item_spikes")
    {
        if (item.spawnflags & 1) self.ammo_nails = self.ammo_nails + 50;
        else self.ammo_nails = self.ammo_nails + 25;
        sound(self, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "item_rockets")
    {
        if (item.spawnflags & 1) self.ammo_rockets = self.ammo_rockets + 10;
        else self.ammo_rockets = self.ammo_rockets + 5;
        sound(self, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "item_cells")
    {
        if (item.spawnflags & 1) self.ammo_cells = self.ammo_cells + 12;
        else self.ammo_cells = self.ammo_cells + 6;
        sound(self, CHAN_ITEM, "weapons/lock4.wav", 1, ATTN_NORM);
    }
    // Powerups
    else if (item.classname == "item_artifact_super_damage") // Quad
    {
        self.super_damage_finished = time + 30;
        self.items = self.items | IT_QUAD;
        sound(self, CHAN_ITEM, "items/damage.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "item_artifact_invulnerability") // Pent
    {
        self.invincible_finished = time + 30;
        self.items = self.items | IT_INVULNERABILITY;
        sound(self, CHAN_ITEM, "items/protect.wav", 1, ATTN_NORM);
    }
    else if (item.classname == "item_artifact_invisibility") // Ring
    {
        self.invisible_finished = time + 30;
        self.items = self.items | IT_INVISIBILITY;
        sound(self, CHAN_ITEM, "items/inv1.wav", 1, ATTN_NORM);
    }

    // Cap ammo
    if (self.ammo_shells > 100) self.ammo_shells = 100;
    if (self.ammo_nails > 200) self.ammo_nails = 200;
    if (self.ammo_rockets > 100) self.ammo_rockets = 100;
    if (self.ammo_cells > 100) self.ammo_cells = 100;
};

/*
Cortex_CheckForItems
Scan for nearby items and pick them up.
*/
void() Cortex_CheckForItems =
{
    local entity head;
    local float dominated;

    head = findradius(self.origin, 64); // Touch range
    while (head)
    {
        // Check if it's a pickup and available
        if (head.solid == SOLID_TRIGGER)
        {
            if (head.classname == "item_health" ||
                head.classname == "item_armor1" ||
                head.classname == "item_armor2" ||
                head.classname == "item_armorInv" ||
                head.classname == "item_shells" ||
                head.classname == "item_spikes" ||
                head.classname == "item_rockets" ||
                head.classname == "item_cells" ||
                head.classname == "weapon_supershotgun" ||
                head.classname == "weapon_nailgun" ||
                head.classname == "weapon_supernailgun" ||
                head.classname == "weapon_grenadelauncher" ||
                head.classname == "weapon_rocketlauncher" ||
                head.classname == "weapon_lightning" ||
                head.classname == "item_artifact_super_damage" ||
                head.classname == "item_artifact_invulnerability" ||
                head.classname == "item_artifact_invisibility")
            {
                other = head;
                Cortex_TouchItem();
            }
        }
        head = head.chain;
    }
};

/*
Cortex_NeedsSupplies
Returns TRUE if bot should seek items.
*/
float() Cortex_NeedsSupplies =
{
    if (self.health < 50) return TRUE;
    if (self.armorvalue < 50) return TRUE;
    if (self.ammo_rockets < 5 && self.ammo_cells < 10) return TRUE;
    return FALSE;
};

/*
Cortex_FindNearestItem
Find the nearest useful item.
*/
entity() Cortex_FindNearestItem =
{
    local entity head, best;
    local float dist, bestdist;

    best = world;
    bestdist = 2000;

    head = findradius(self.origin, 2000);
    while (head)
    {
        if (head.solid == SOLID_TRIGGER)
        {
            dist = vlen(head.origin - self.origin);

            // Prioritize what we need
            if (self.health < 50 && head.classname == "item_health")
            {
                if (dist < bestdist) { best = head; bestdist = dist; }
            }
            else if (self.armorvalue < 100 &&
                     (head.classname == "item_armor1" ||
                      head.classname == "item_armor2" ||
                      head.classname == "item_armorInv"))
            {
                if (dist < bestdist) { best = head; bestdist = dist; }
            }
            else if (self.ammo_rockets < 10 &&
                     (head.classname == "item_rockets" ||
                      head.classname == "weapon_rocketlauncher"))
            {
                if (dist < bestdist) { best = head; bestdist = dist; }
            }
            else if (!(self.items & IT_ROCKET_LAUNCHER) &&
                     head.classname == "weapon_rocketlauncher")
            {
                if (dist < bestdist) { best = head; bestdist = dist; }
            }
            else if (!(self.items & IT_LIGHTNING) &&
                     head.classname == "weapon_lightning")
            {
                if (dist < bestdist) { best = head; bestdist = dist; }
            }
        }
        head = head.chain;
    }
    return best;
};

// ===========================================================================
// ROCKET JUMPING
// ===========================================================================

/*
Cortex_TryRocketJump
Attempt a rocket jump to reach higher ground.
Returns TRUE if performed.
*/
float() Cortex_TryRocketJump =
{
    local vector above;

    // Need rockets and health to survive
    if (self.ammo_rockets < 1) return FALSE;
    if (!(self.items & IT_ROCKET_LAUNCHER)) return FALSE;
    if (self.health < 50) return FALSE; // Too risky
    if (time < self.cortex_rocket_jump_time) return FALSE; // Cooldown

    // Check if there's something above us worth jumping to
    above = self.origin + '0 0 200';
    traceline(self.origin, above, TRUE, self);
    if (trace_fraction < 0.5) return FALSE; // Ceiling too low

    // Check if we're stuck or need vertical mobility
    if (self.cortex_stuck_severity < 3) return FALSE;

    // Do the rocket jump!
    self.cortex_rocket_jump_time = time + 5; // Cooldown

    // Jump first
    if (self.flags & FL_ONGROUND)
        self.velocity_z = 270;

    // Fire rocket at feet
    makevectors(self.angles);
    sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
    newmis = spawn();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "rocket";
    newmis.velocity = '0 0 -1000'; // Straight down
    newmis.angles = '90 0 0';
    newmis.touch = T_MissileTouch;
    setmodel(newmis, "progs/missile.mdl");
    setsize(newmis, '0 0 0', '0 0 0');
    setorigin(newmis, self.origin + '0 0 -20');

    self.weapon = IT_ROCKET_LAUNCHER;
    Cortex_ConsumeAmmo();
    self.effects = self.effects | EF_MUZZLEFLASH;

    return TRUE;
};

// ===========================================================================
// DODGING & THREAT ASSESSMENT
// ===========================================================================

/*
Cortex_CheckIncomingProjectiles
Scans for incoming rockets/grenades and sets dodge direction.
*/
void() Cortex_CheckIncomingProjectiles =
{
    local entity proj;
    local vector to_me, proj_dir;
    local float dot, dist;

    if (time < self.cortex_dodge_time) return;
    self.cortex_dodge_time = time + 0.15; // Check 6-7 times per second

    self.cortex_dodge_dir = '0 0 0';

    proj = find(world, classname, "rocket");
    while (proj)
    {
        // Skip our own rockets
        if (proj.owner != self)
        {
            dist = vlen(proj.origin - self.origin);
            if (dist < 500) // Danger zone
            {
                // Is it heading toward us?
                to_me = normalize(self.origin - proj.origin);
                proj_dir = normalize(proj.velocity);
                dot = to_me * proj_dir;

                if (dot > 0.7) // Coming at us!
                {
                    // Dodge perpendicular to projectile path
                    makevectors(vectoangles(proj.velocity));
                    if (random() < 0.5)
                        self.cortex_dodge_dir = v_right * 200;
                    else
                        self.cortex_dodge_dir = v_right * -200;

                    // Also try to jump if close
                    if (dist < 200 && (self.flags & FL_ONGROUND))
                        self.velocity_z = 270;

                    return; // One dodge at a time
                }
            }
        }
        proj = find(proj, classname, "rocket");
    }

    // Also check grenades
    proj = find(world, classname, "grenade");
    while (proj)
    {
        if (proj.owner != self)
        {
            dist = vlen(proj.origin - self.origin);
            if (dist < 200) // Grenades are short range threat
            {
                // Run away from grenade
                self.cortex_dodge_dir = normalize(self.origin - proj.origin) * 200;
                return;
            }
        }
        proj = find(proj, classname, "grenade");
    }
};

/*
Cortex_AssessThreat
Evaluates how dangerous the current enemy is.
Returns: 0 = weak, 1 = equal, 2 = dangerous
*/
float() Cortex_AssessThreat =
{
    local float my_power, enemy_power;

    if (!self.enemy) return 0;

    // Calculate our power level
    my_power = self.health + (self.armorvalue * self.armortype);
    if (self.items & IT_QUAD) my_power = my_power * 2;
    if (self.items & IT_INVULNERABILITY) my_power = my_power + 500;

    // Estimate enemy power (we can see their health)
    enemy_power = self.enemy.health;
    // Assume some armor if they look healthy
    if (self.enemy.health > 80) enemy_power = enemy_power + 50;
    // Check for powerup glows
    if (self.enemy.effects & EF_DIMLIGHT) enemy_power = enemy_power * 2; // Quad glow
    if (self.enemy.effects & EF_BRIGHTLIGHT) enemy_power = enemy_power + 300; // Pent glow

    if (my_power > enemy_power * 1.5)
        return 0; // We dominate
    else if (my_power < enemy_power * 0.6)
        return 2; // They dominate
    else
        return 1; // Even fight
};

/*
Cortex_UpdateItemTimers
Tracks when powerups were taken and when they'll respawn.
Called periodically to maintain item knowledge.
*/
void() Cortex_UpdateItemTimers =
{
    // Check if quad was just taken (solid changed)
    if (self.cortex_cache_quad != world)
    {
        if (self.cortex_cache_quad.solid == SOLID_NOT && self.cortex_quad_time == 0)
        {
            self.cortex_quad_time = time + 60; // Respawns in 60 sec
        }
        else if (self.cortex_cache_quad.solid != SOLID_NOT)
        {
            self.cortex_quad_time = 0; // It's available
        }
    }

    // Check pent
    if (self.cortex_cache_pent != world)
    {
        if (self.cortex_cache_pent.solid == SOLID_NOT && self.cortex_pent_time == 0)
        {
            self.cortex_pent_time = time + 60;
        }
        else if (self.cortex_cache_pent.solid != SOLID_NOT)
        {
            self.cortex_pent_time = 0;
        }
    }

    // Check mega
    if (self.cortex_cache_mega != world)
    {
        if (self.cortex_cache_mega.solid == SOLID_NOT && self.cortex_mega_time == 0)
        {
            self.cortex_mega_time = time + 20; // Mega respawns faster
        }
        else if (self.cortex_cache_mega.solid != SOLID_NOT)
        {
            self.cortex_mega_time = 0;
        }
    }
};

// ===========================================================================
// SOUND AWARENESS SYSTEM
// ===========================================================================

/*
Cortex_ListenForSounds
Detects nearby combat sounds by finding active projectiles and explosions.
Sets cortex_sound_origin if something interesting is heard.
*/
void() Cortex_ListenForSounds =
{
    local entity snd;
    local float dist, best_dist;
    local vector best_origin;

    if (time < self.cortex_listen_time) return;
    self.cortex_listen_time = time + 0.2; // Check 5 times per second

    // Don't override recent sounds
    if (time < self.cortex_sound_time + 1) return;

    best_dist = 1500; // Max hearing range
    best_origin = '0 0 0';

    // Listen for rockets (indicates combat)
    snd = find(world, classname, "rocket");
    while (snd)
    {
        if (snd.owner != self)
        {
            dist = vlen(snd.origin - self.origin);
            if (dist < best_dist && dist > 200) // Not too close (we'd see it)
            {
                // Check if we can't see the owner (sound reveals hidden enemy)
                if (snd.owner && !Cortex_CanSee(snd.owner))
                {
                    best_dist = dist;
                    best_origin = snd.origin;
                }
            }
        }
        snd = find(snd, classname, "rocket");
    }

    // Listen for grenades
    snd = find(world, classname, "grenade");
    while (snd)
    {
        if (snd.owner != self)
        {
            dist = vlen(snd.origin - self.origin);
            if (dist < best_dist && dist > 150)
            {
                if (snd.owner && !Cortex_CanSee(snd.owner))
                {
                    best_dist = dist;
                    best_origin = snd.origin;
                }
            }
        }
        snd = find(snd, classname, "grenade");
    }

    // Listen for spikes (nailgun fire)
    snd = find(world, classname, "spike");
    while (snd)
    {
        if (snd.owner != self)
        {
            dist = vlen(snd.origin - self.origin);
            if (dist < best_dist && dist > 100)
            {
                if (snd.owner && !Cortex_CanSee(snd.owner))
                {
                    best_dist = dist;
                    best_origin = snd.origin;
                }
            }
        }
        snd = find(snd, classname, "spike");
    }

    // Also listen for teleport fog (player teleported nearby)
    snd = find(world, classname, "tfog");
    while (snd)
    {
        dist = vlen(snd.origin - self.origin);
        if (dist < 800 && dist > 100)
        {
            best_dist = dist;
            best_origin = snd.origin;
        }
        snd = find(snd, classname, "tfog");
    }

    // If we heard something, record it
    if (best_origin != '0 0 0')
    {
        self.cortex_sound_origin = best_origin;
        self.cortex_sound_time = time;
    }
};

// ===========================================================================
// TELEPORTER NAVIGATION
// ===========================================================================

/*
Cortex_CheckTeleporters
Finds and uses nearby teleporters when roaming or stuck.
*/
void() Cortex_CheckTeleporters =
{
    local entity tele;
    local float dist;

    // Only use teleporters when roaming/stuck, not in combat
    if (self.cortex_state == STATE_COMBAT) return;
    if (self.cortex_state == STATE_RETREAT) return;

    // Look for nearby teleporter triggers
    tele = find(world, classname, "trigger_teleport");
    while (tele)
    {
        // Get center of teleporter brush
        local vector tele_center;
        tele_center = (tele.absmin + tele.absmax) * 0.5;
        dist = vlen(tele_center - self.origin);

        // If we're stuck and there's a teleporter nearby, head for it
        if (self.cortex_stuck_severity >= 2 && dist < 500)
        {
            self.cortex_goal_ent = tele;
            self.cortex_state = STATE_FETCH;
            return;
        }

        // Random chance to use teleporter when roaming
        if (self.cortex_state == STATE_ROAM && dist < 300 && random() < 0.3)
        {
            self.cortex_goal_ent = tele;
            self.cortex_state = STATE_FETCH;
            return;
        }

        tele = find(tele, classname, "trigger_teleport");
    }
};

// ===========================================================================
// WATER NAVIGATION
// ===========================================================================

/*
Cortex_HandleWater
Detects water and swims toward the surface or nearest exit.
*/
void() Cortex_HandleWater =
{
    local float contents;
    local vector surface, lateral;
    local float water_level;

    contents = pointcontents(self.origin);

    // Check if we're in water
    if (contents == CONTENT_WATER || contents == CONTENT_SLIME)
    {
        if (!self.cortex_in_water)
        {
            self.cortex_in_water = TRUE;
            self.cortex_water_time = time;
        }

        // Find the water surface (trace up until we hit air)
        surface = self.origin;
        water_level = 0;
        while (water_level < 500)
        {
            surface_z = surface_z + 50;
            if (pointcontents(surface) == CONTENT_EMPTY)
                break;
            water_level = water_level + 50;
        }

        // Swim toward surface
        if (water_level < 500)
        {
            // Swim upward
            self.velocity_z = 200;

            // Also move forward to get out
            makevectors(self.angles);
            lateral = v_forward * 100;
            self.velocity_x = self.velocity_x + lateral_x;
            self.velocity_y = self.velocity_y + lateral_y;
        }

        // If we've been in water too long, try to find land
        if (time > self.cortex_water_time + 3)
        {
            // Look for any solid ground nearby
            local entity ground;
            ground = find(world, classname, "info_player_deathmatch");
            if (ground)
            {
                // Head toward spawn point as likely land
                self.cortex_goal_ent = ground;
            }
        }

        // Slime is dangerous - get out faster!
        if (contents == CONTENT_SLIME)
        {
            self.velocity_z = 300; // Swim up faster
        }
    }
    else
    {
        self.cortex_in_water = FALSE;
    }
};

// ===========================================================================
// JUMP GAP DETECTION
// ===========================================================================

/*
Cortex_TryJumpGap
Attempts to jump across gaps when moving toward a goal.
Returns TRUE if a jump was initiated.
*/
float() Cortex_TryJumpGap =
{
    local vector ahead, below, landing;
    local float gap_found;

    if (time < self.cortex_jump_time) return FALSE;
    if (!(self.flags & FL_ONGROUND)) return FALSE; // Already airborne

    // Only try gaps if we have somewhere to go
    if (!self.cortex_goal_ent) return FALSE;

    makevectors(self.angles);

    // Check if there's a gap ahead
    ahead = self.origin + v_forward * 80;
    below = ahead - '0 0 100';

    traceline(ahead, below, TRUE, self);

    // If nothing below ahead position, there might be a gap
    if (trace_fraction == 1.0)
    {
        // Look for landing spot further ahead
        landing = self.origin + v_forward * 200;
        landing_z = landing_z - 50; // Slightly below our level

        // Check if there's ground at the landing spot
        traceline(landing, landing - '0 0 200', TRUE, self);

        if (trace_fraction < 1.0)
        {
            // Found a landing spot - can we make the jump?
            local float gap_distance;
            gap_distance = vlen(landing - self.origin);

            // Standard Quake jump covers about 200-250 units
            if (gap_distance < 250 && gap_distance > 64)
            {
                // Check the landing is safe (not lava/slime)
                if (Cortex_CheckSafety(trace_endpos + '0 0 32'))
                {
                    // Execute jump!
                    self.cortex_jump_time = time + 1.0;
                    self.velocity_z = 270; // Jump

                    // Add forward momentum for distance
                    self.velocity = self.velocity + v_forward * 300;

                    return TRUE;
                }
            }
        }
    }

    // Check for ledges we need to jump up to
    ahead = self.origin + v_forward * 40 + '0 0 48'; // Check at jump height
    traceline(self.origin + '0 0 48', ahead, TRUE, self);

    if (trace_fraction == 1.0) // Clear at jump height
    {
        // But blocked at ground level?
        traceline(self.origin + '0 0 16', self.origin + v_forward * 40 + '0 0 16', TRUE, self);

        if (trace_fraction < 1.0) // Blocked at ground level
        {
            // It's a step/ledge - jump up!
            self.cortex_jump_time = time + 0.5;
            self.velocity_z = 270;
            return TRUE;
        }
    }

    return FALSE;
};

// ===========================================================================
// COMBAT SYSTEMS
// ===========================================================================

/*
Cortex_BallisticAim
Advanced arc aiming for grenades and rockets.
*/
vector(entity targ, float speed, float is_gravity_affected) Cortex_BallisticAim =
{
    local vector dest, dir;
    local float dist, time_to_hit, gravity_drop;

    // 1. Initial linear prediction
    dist = vlen(targ.origin - self.origin);
    time_to_hit = dist / speed;

    // Predict where enemy will be
    dest = targ.origin + (targ.velocity * time_to_hit);

    // Iterative refine for rockets
    if (!is_gravity_affected)
    {
        time_to_hit = vlen(dest - self.origin) / speed;
        dest = targ.origin + (targ.velocity * time_to_hit);
    }

    // 2. Gravity compensation (grenades)
    if (is_gravity_affected)
    {
        // d = 0.5 * g * t^2
        // sv_gravity is usually 800
        gravity_drop = 0.5 * 800 * (time_to_hit * time_to_hit);

        // Aim up to compensate for the drop
        dest_z = dest_z + gravity_drop;

        // If target is above us, aim higher to clear ledges
        if (targ.origin_z > self.origin_z)
            dest_z = dest_z + 32;
    }
    else
    {
        // For rockets: aim at feet for splash damage
        dest_z = dest_z - 24;
    }

    dir = normalize(dest - (self.origin + '0 0 16'));
    return dir;
};

vector(entity targ, float speed) Cortex_GetLeadVector =
{
    local float dist, time_to_hit;
    local vector pred;
    local float skill_variance;

    if (self.weapon == IT_GRENADE_LAUNCHER)
        return Cortex_BallisticAim(targ, speed, TRUE);
    if (self.weapon == IT_ROCKET_LAUNCHER)
        return Cortex_BallisticAim(targ, speed, FALSE);

    dist = vlen(targ.origin - self.origin);
    time_to_hit = dist / speed;
    pred = targ.origin + (targ.velocity * time_to_hit);

    // Add slight aim variance to make bot less perfect
    // Variance decreases at closer range (easier to hit)
    skill_variance = dist / 2000; // 0 to ~0.5
    if (skill_variance > 0.4) skill_variance = 0.4;

    pred_x = pred_x + (random() - 0.5) * skill_variance * 50;
    pred_y = pred_y + (random() - 0.5) * skill_variance * 50;
    pred_z = pred_z - 20; // Aim at feet for splash

    // Aim lower for rockets (splash damage)
    if (self.weapon == IT_ROCKET_LAUNCHER || self.weapon == IT_GRENADE_LAUNCHER)
        pred_z = pred_z - 15;

    return normalize(pred - (self.origin + '0 0 16'));
};

void() Cortex_FireWeapon =
{
    local vector aim;
    local float dist;
    local float chosen_weapon;

    if (self.enemy) dist = vlen(self.enemy.origin - self.origin);
    else dist = 500; // Default for buttons

    // Select best weapon for this situation
    chosen_weapon = Cortex_SelectWeapon(dist);
    if (chosen_weapon == 0) return; // No weapon/ammo!

    self.weapon = chosen_weapon;
    self.effects = self.effects | EF_MUZZLEFLASH;
    self.frame = 104;

    makevectors(self.angles);

    // LIGHTNING GUN
    if (self.weapon == IT_LIGHTNING)
    {
        sound(self, CHAN_WEAPON, "weapons/lstart.wav", 1, ATTN_NORM);
        traceline(self.origin + '0 0 16', self.origin + (v_forward * 600), FALSE, self);
        if (trace_ent.takedamage) T_Damage(trace_ent, self, self, 30);

        WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte(MSG_BROADCAST, TE_LIGHTNING2);
        WriteEntity(MSG_BROADCAST, self);
        WriteCoord(MSG_BROADCAST, self.origin_x);
        WriteCoord(MSG_BROADCAST, self.origin_y);
        WriteCoord(MSG_BROADCAST, self.origin_z + 16);
        WriteCoord(MSG_BROADCAST, trace_endpos_x);
        WriteCoord(MSG_BROADCAST, trace_endpos_y);
        WriteCoord(MSG_BROADCAST, trace_endpos_z);

        self.attack_finished = time + 0.1;
        Cortex_ConsumeAmmo();
    }
    // ROCKET LAUNCHER
    else if (self.weapon == IT_ROCKET_LAUNCHER)
    {
        if (self.enemy) aim = Cortex_GetLeadVector(self.enemy, 1000);
        else aim = v_forward;

        sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
        newmis = spawn();
        newmis.owner = self;
        newmis.movetype = MOVETYPE_FLYMISSILE;
        newmis.solid = SOLID_BBOX;
        newmis.classname = "rocket";
        newmis.velocity = aim * 1000;
        newmis.angles = vectoangles(newmis.velocity);
        newmis.touch = T_MissileTouch;
        setmodel(newmis, "progs/missile.mdl");
        setsize(newmis, '0 0 0', '0 0 0');
        setorigin(newmis, self.origin + v_forward * 8 + '0 0 16');

        self.attack_finished = time + 0.8;
        Cortex_ConsumeAmmo();
    }
    // GRENADE LAUNCHER
    else if (self.weapon == IT_GRENADE_LAUNCHER)
    {
        if (self.enemy) aim = Cortex_GetLeadVector(self.enemy, 600);
        else aim = v_forward;
        // Lob grenades upward a bit
        aim_z = aim_z + 0.2;
        aim = normalize(aim);

        sound(self, CHAN_WEAPON, "weapons/grenade.wav", 1, ATTN_NORM);
        newmis = spawn();
        newmis.owner = self;
        newmis.movetype = MOVETYPE_BOUNCE;
        newmis.solid = SOLID_BBOX;
        newmis.classname = "grenade";
        newmis.velocity = aim * 600;
        newmis.velocity_z = newmis.velocity_z + 200;
        newmis.avelocity = '300 300 300';
        newmis.angles = vectoangles(newmis.velocity);
        newmis.touch = GrenadeTouch;
        newmis.nextthink = time + 2.5;
        newmis.think = GrenadeExplode;
        setmodel(newmis, "progs/grenade.mdl");
        setsize(newmis, '0 0 0', '0 0 0');
        setorigin(newmis, self.origin + v_forward * 8 + '0 0 16');

        self.attack_finished = time + 0.6;
        Cortex_ConsumeAmmo();
    }
    // SUPER NAILGUN
    else if (self.weapon == IT_SUPER_NAILGUN)
    {
        if (self.enemy) aim = Cortex_GetLeadVector(self.enemy, 1000);
        else aim = v_forward;

        sound(self, CHAN_WEAPON, "weapons/spike2.wav", 1, ATTN_NORM);
        launch_spike(self.origin + '0 0 16', aim);
        newmis.classname = "superspike";
        setmodel(newmis, "progs/s_spike.mdl");

        self.attack_finished = time + 0.1;
        Cortex_ConsumeAmmo();
    }
    // NAILGUN
    else if (self.weapon == IT_NAILGUN)
    {
        if (self.enemy) aim = Cortex_GetLeadVector(self.enemy, 1000);
        else aim = v_forward;

        sound(self, CHAN_WEAPON, "weapons/rocket1i.wav", 1, ATTN_NORM);
        launch_spike(self.origin + '0 0 16', aim);

        self.attack_finished = time + 0.1;
        Cortex_ConsumeAmmo();
    }
    // SUPER SHOTGUN
    else if (self.weapon == IT_SUPER_SHOTGUN)
    {
        sound(self, CHAN_WEAPON, "weapons/shotgn2.wav", 1, ATTN_NORM);
        aim = v_forward;
        FireBullets(14, aim, '0.14 0.08 0');

        self.attack_finished = time + 0.7;
        Cortex_ConsumeAmmo();
    }
    // SHOTGUN
    else if (self.weapon == IT_SHOTGUN)
    {
        sound(self, CHAN_WEAPON, "weapons/guncock.wav", 1, ATTN_NORM);
        aim = v_forward;
        FireBullets(6, aim, '0.04 0.04 0');

        self.attack_finished = time + 0.5;
        Cortex_ConsumeAmmo();
    }
};

void() Cortex_SuppressiveFire =
{
    local vector aim;
    local float dist;

    // Check if we have rockets
    if (!((self.items & IT_ROCKET_LAUNCHER) && self.ammo_rockets >= 1))
        return;

    dist = vlen(self.cortex_last_known - self.origin);

    // Don't suppressive fire if target was too close (self damage)
    if (dist < CORTEX_ROCKET_SELF_DAMAGE)
        return;

    aim = normalize(self.cortex_last_known - self.origin);
    makevectors(self.angles);

    sound(self, CHAN_WEAPON, "weapons/sgun1.wav", 1, ATTN_NORM);
    newmis = spawn();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "rocket";
    newmis.velocity = aim * 1000;
    newmis.angles = vectoangles(newmis.velocity);
    newmis.touch = T_MissileTouch;
    setmodel(newmis, "progs/missile.mdl");
    setsize(newmis, '0 0 0', '0 0 0');
    setorigin(newmis, self.origin + v_forward * 8 + '0 0 16');

    self.weapon = IT_ROCKET_LAUNCHER;
    Cortex_ConsumeAmmo();
    self.effects = self.effects | EF_MUZZLEFLASH;
};

// ===========================================================================
// MAIN BRAIN
// ===========================================================================

void() Cortex_AssessObjectives =
{
    if (self.health < 40)
    {
        self.cortex_state = STATE_RETREAT;
        self.cortex_goal_ent = find(world, classname, "item_health");
        return;
    }
    
    // Environment Check (Buttons) - If bored
    if (random() < 0.1) Cortex_SolveButtons();
    if (self.cortex_state == STATE_SOLVE) return; // Busy solving

    if (self.cortex_cache_quad.solid != SOLID_NOT && self.cortex_cache_quad != world)
    {
        self.cortex_state = STATE_FETCH;
        self.cortex_goal_ent = self.cortex_cache_quad;
        return;
    }
    if (self.cortex_cache_pent.solid != SOLID_NOT && self.cortex_cache_pent != world)
    {
        self.cortex_state = STATE_FETCH;
        self.cortex_goal_ent = self.cortex_cache_pent;
        return;
    }

    // Find players to fight
    local entity head;
    head = find(world, classname, "player");
    while (head)
    {
        if (head != self && head.health > 0 && Cortex_CanSee(head))
        {
            self.enemy = head;
            self.cortex_state = STATE_COMBAT;
            self.cortex_last_known = head.origin;
            return;
        }
        head = find(head, classname, "player");
    }

    // Also fight other bots
    head = find(world, classname, "cortexbot");
    while (head)
    {
        if (head != self && head.health > 0 && Cortex_CanSee(head))
        {
            self.enemy = head;
            self.cortex_state = STATE_COMBAT;
            self.cortex_last_known = head.origin;
            return;
        }
        head = find(head, classname, "cortexbot");
    }

    // No visible enemy - check if we heard something recently
    if (time < self.cortex_sound_time + 3)
    {
        // Investigate the sound
        self.cortex_last_known = self.cortex_sound_origin;
        self.cortex_state = STATE_HUNT;
        return;
    }

    self.cortex_state = STATE_ROAM;
};

void() Cortex_Think =
{
    local vector dir;
    local float dist;
    local entity item;
    local float threat;
    local vector dodge_yaw;
    local vector cover_pos;

    // --- ALWAYS ACTIVE SYSTEMS ---
    Cortex_CheckForItems();           // Pick up items we touch
    Cortex_CheckIncomingProjectiles(); // Scan for rockets/grenades
    Cortex_UpdateItemTimers();        // Track powerup respawns
    Cortex_ListenForSounds();         // Hear nearby combat
    Cortex_HandleWater();             // Swim if in water
    Cortex_CheckTeleporters();        // Use nearby teleporters

    // --- SENSORY ---
    if (time > self.cortex_next_scan)
    {
        self.cortex_next_scan = time + 0.1;
        Cortex_AssessObjectives();
    }

    // --- EXECUTION ---

    // RIDING / PLATFORMS
    if (self.cortex_state == STATE_RIDING)
    {
        Cortex_HandlePlatform(); // Just check if we can get off
        // Do not move.
    }

    // HUNT - Chase enemy to last known position
    else if (self.cortex_state == STATE_HUNT)
    {
        // Can we see the enemy again?
        if (self.enemy && self.enemy.health > 0 && Cortex_CanSee(self.enemy))
        {
            self.cortex_state = STATE_COMBAT;
            self.cortex_last_known = self.enemy.origin;
        }
        else
        {
            // Move to last known position
            dir = vectoangles(self.cortex_last_known - self.origin);
            Cortex_Move(dir_y);

            // Reached last known position?
            if (vlen(self.cortex_last_known - self.origin) < 100)
            {
                // Lost them, go back to roaming
                self.enemy = world;
                self.cortex_state = STATE_ROAM;
            }
        }
    }

    // MOVING TO GOAL (Items, Patrol, Buttons)
    else if (self.cortex_state == STATE_FETCH || self.cortex_state == STATE_ROAM ||
             self.cortex_state == STATE_RETREAT || self.cortex_state == STATE_SOLVE)
    {
        if (self.cortex_state == STATE_RETREAT && self.cortex_cover_active)
        {
            dir = vectoangles(self.cortex_cover_pos - self.origin);
            Cortex_Move(dir_y);
            Cortex_TryJumpGap();

            if (vlen(self.cortex_cover_pos - self.origin) < 80)
                self.cortex_cover_active = FALSE;
        }
        else
        {
            // Check if powerup is about to spawn - prioritize it!
            if (self.cortex_quad_time > 0 && self.cortex_quad_time < time + 5)
            {
                self.cortex_goal_ent = self.cortex_cache_quad;
                self.cortex_state = STATE_FETCH;
            }
            else if (self.cortex_pent_time > 0 && self.cortex_pent_time < time + 5)
            {
                self.cortex_goal_ent = self.cortex_cache_pent;
                self.cortex_state = STATE_FETCH;
            }
            // If we need supplies, find items
            else if (self.cortex_state == STATE_RETREAT || Cortex_NeedsSupplies())
            {
                item = Cortex_FindNearestItem();
                if (item)
                    self.cortex_goal_ent = item;
            }

            if (!self.cortex_goal_ent)
            {
                self.cortex_goal_ent = find(world, classname, "info_player_deathmatch");
                if (random() < 0.5) self.cortex_goal_ent = find(self.cortex_goal_ent, classname, "info_player_deathmatch");
            }

            dir = vectoangles(self.cortex_goal_ent.origin - self.origin);
            Cortex_Move(dir_y);

            // Try jumping gaps if we're moving toward a goal
            Cortex_TryJumpGap();

            if (vlen(self.cortex_goal_ent.origin - self.origin) < 80)
            {
                // Reached goal
                if (self.cortex_state == STATE_SOLVE) Cortex_Log("Button pressed.");
                self.cortex_goal_ent = world;
                self.cortex_state = STATE_ROAM;
            }

            // Try rocket jump if stuck
            if (self.cortex_stuck_severity >= 3)
                Cortex_TryRocketJump();
        }
    }

    // COMBAT
    else if (self.cortex_state == STATE_COMBAT)
    {
        if (!self.enemy || self.enemy.health <= 0)
        {
            self.cortex_state = STATE_ROAM;
            self.enemy = world;
            return;
        }

        if (self.health >= 50)
            self.cortex_cover_active = FALSE;

        if (self.health < 50)
        {
            self.cortex_cover_active = FALSE;
            cover_pos = Cortex_FindCover();
            if (vlen(cover_pos - self.origin) > 1)
            {
                self.cortex_cover_pos = cover_pos;
                self.cortex_cover_active = TRUE;
                self.cortex_state = STATE_RETREAT;
                self.cortex_goal_ent = world;
                return;
            }
        }

        // Threat assessment - retreat if outmatched
        threat = Cortex_AssessThreat();
        if (threat == 2 && self.health < 60)
        {
            // We're outgunned and hurt, retreat!
            self.cortex_state = STATE_RETREAT;
            self.cortex_goal_ent = Cortex_FindNearestItem();
            return;
        }

        dist = vlen(self.enemy.origin - self.origin);
        dir = vectoangles(self.enemy.origin - self.origin);

        if (!Cortex_CanSee(self.enemy))
        {
            // Lost sight - fire suppressive shot and go HUNT
            if (time > self.attack_finished)
            {
                Cortex_SuppressiveFire();
                self.attack_finished = time + 1.5;
            }
            self.cortex_state = STATE_HUNT; // Chase to last known!
        }
        else
        {
            self.cortex_last_known = self.enemy.origin;

            if (time > self.cortex_strafe_time)
            {
                self.cortex_strafe_dir = self.cortex_strafe_dir * -1;
                self.cortex_strafe_time = time + 0.4 + (random() * 0.4);
            }

            float yaw = dir_y;

            // Apply dodge direction if we're evading projectiles
            if (vlen(self.cortex_dodge_dir) > 0)
            {
                dodge_yaw = vectoangles(self.cortex_dodge_dir);
                yaw = dodge_yaw_y;
            }
            else if (dist < 150)
            {
                yaw = yaw + 180; // Back away from close enemy
                yaw = Cortex_PhantomStep(yaw);
            }
            else
            {
                yaw = yaw + (80 * self.cortex_strafe_dir);
                yaw = Cortex_PhantomStep(yaw);
            }

            Cortex_Move(yaw);

            if (time > self.attack_finished) Cortex_FireWeapon();
        }
    }

    if (self.cortex_clientno >= 0 && self.cortex_frags != self.frags)
    {
        self.cortex_frags = self.frags;
        Cortex_UpdateClient(self);
    }

    self.frame = self.frame + 1;
    if (self.frame > 11) self.frame = 6;
    self.nextthink = time + 0.05;
};

void() Cortex_Die =
{
    Cortex_Log("Terminated.");
    sound (self, CHAN_VOICE, "player/death3.wav", 1, ATTN_NORM);
    ThrowHead ("progs/h_player.mdl", self.health);
    self.solid = SOLID_NOT;
    self.takedamage = DAMAGE_NO;
    self.think = Cortex_Respawn;
    self.nextthink = time + 2;
};

void() Cortex_Respawn =
{
    local entity spot;

    if (self.cortex_clientno < 0)
        Cortex_ScoreboardAdd(self);

    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_STEP;
    self.takedamage = DAMAGE_AIM;
    self.deadflag = DEAD_NO;
    self.health = 100;
    self.armorvalue = 100;
    self.velocity = '0 0 0';
    self.items = self.items | IT_ROCKET_LAUNCHER | IT_LIGHTNING;
    self.weapon = IT_ROCKET_LAUNCHER;
    self.ammo_rockets = 50;
    self.ammo_cells = 50;
    self.currentammo = self.ammo_rockets;

    setmodel(self, "progs/player.mdl");
    setsize(self, '-16 -16 -24', '16 16 32');

    spot = Cortex_PickSpawn();
    if (spot)
    {
        setorigin(self, spot.origin);
        self.angles = spot.angles;
    }
    else
    {
        setorigin(self, '0 0 200');
    }
    self.angles_x = 0;
    self.angles_z = 0;
    self.v_angle = self.angles;
    self.ideal_yaw = self.angles_y;
    self.view_ofs = '0 0 22';
    self.flags = self.flags | FL_ONGROUND;
    if (deathmatch || coop)
    {
        makevectors(self.angles);
        spawn_tfog(self.origin + (v_forward * 20));
    }
    spawn_tdeath(self.origin, self);

    self.cortex_state = STATE_ROAM;
    self.cortex_strafe_dir = 1;
    self.cortex_goal_ent = world;
    self.enemy = world;
    self.cortex_cover_pos = '0 0 0';
    self.cortex_cover_active = FALSE;
    self.cortex_strafe_time = time + 0.2;

    self.cortex_history_pos = self.origin;
    self.cortex_stuck_check_time = time + 1;

    Cortex_MapAnalysis();

    self.think = Cortex_Think;
    self.nextthink = time + 0.1;
};

void() SpawnCortexBot =
{
    local entity bot;
    local entity oldself;
    oldself = self;
    bot = spawn();

    bot.classname = "cortexbot";
    bot.solid = SOLID_SLIDEBOX;
    bot.movetype = MOVETYPE_STEP;
    bot.takedamage = DAMAGE_AIM;

    setmodel(bot, "progs/player.mdl");
    setsize(bot, '-16 -16 -24', '16 16 32');
    bot.health = 100;
    bot.armorvalue = 100;
    bot.cortex_clientno = -1;
    bot.items = bot.items | IT_ROCKET_LAUNCHER | IT_LIGHTNING;
    bot.weapon = IT_ROCKET_LAUNCHER;
    bot.ammo_rockets = 50;
    bot.ammo_cells = 50;
    bot.currentammo = bot.ammo_rockets;

    local entity spot;
    spot = Cortex_PickSpawn();
    if (spot)
    {
        setorigin(bot, spot.origin);
        bot.angles = spot.angles;
    }
    else
    {
        setorigin(bot, '0 0 200');
    }
    bot.angles_x = 0;
    bot.angles_z = 0;
    bot.v_angle = bot.angles;
    bot.ideal_yaw = bot.angles_y;
    bot.view_ofs = '0 0 22';
    bot.flags = bot.flags | FL_ONGROUND;
    if (deathmatch || coop)
    {
        makevectors(bot.angles);
        spawn_tfog(bot.origin + (v_forward * 20));
    }
    spawn_tdeath(bot.origin, bot);

    Cortex_ScoreboardAdd(bot);

    bot.th_stand = Cortex_Think;
    bot.th_walk = Cortex_Think;
    bot.th_run = Cortex_Think;
    bot.th_die = Cortex_Die;
    bot.th_missile = Cortex_Think;

    bot.cortex_state = STATE_ROAM;
    bot.cortex_strafe_dir = 1;
    bot.cortex_cover_pos = '0 0 0';
    bot.cortex_cover_active = FALSE;
    bot.cortex_strafe_time = time + 0.2;

    // Init Unstuck
    bot.cortex_history_pos = bot.origin;
    bot.cortex_stuck_check_time = time + 1;

    // Run map analysis with bot context, then start thinking
    self = bot;
    Cortex_MapAnalysis();
    self.think = Cortex_Think;
    self.nextthink = time + 0.1;

    Cortex_Log("Solver Logic Loaded.");
    self = oldself;
};
