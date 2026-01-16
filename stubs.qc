/*
==============================================================================

CORTEX BOT - Standalone Test Stubs
Provides minimal definitions for standalone compilation and testing.

To compile: fteqcc progs.src
To test: Copy progs.dat to id1/ folder, run Quake, type "impulse 100"

==============================================================================
*/

// ==========================================================================
// QUAKE ENGINE BUILT-IN FUNCTIONS
// ==========================================================================

void(vector ang) makevectors = #1;
void(entity e, vector o) setorigin = #2;
void(entity e, string m) setmodel = #3;
void(entity e, vector min, vector max) setsize = #4;
void() break_ = #6;
float() random = #7;
void(entity e, float chan, string samp, float vol, float atten) sound = #8;
vector(vector v) normalize = #9;
void(string e) error = #10;
void(string e) objerror = #11;
float(vector v) vlen = #12;
float(vector v) vectoyaw = #13;
entity() spawn = #14;
void(entity e) remove = #15;
void(vector v1, vector v2, float nomonsters, entity forent) traceline = #16;
entity() checkclient = #17;
entity(entity start, .string fld, string match) find = #18;
string(string s) precache_sound = #19;
string(string s) precache_model = #20;
void(entity client, string s) stuffcmd = #21;
entity(vector org, float rad) findradius = #22;
void(string s) bprint = #23;
void(entity client, string s) sprint = #24;
void(string s) dprint = #25;
string(float f) ftos = #26;
string(vector v) vtos = #27;
void() coredump = #28;
void() traceon = #29;
void() traceoff = #30;
void(entity e) eprint = #31;
float(float yaw, float dist) walkmove = #32;
float() droptofloor = #34;
void(float style, string value) lightstyle = #35;
float(float v) rint = #36;
float(float v) floor = #37;
float(float v) ceil = #38;
float(entity e) checkbottom = #40;
float(vector v) pointcontents = #41;
float(float f) fabs = #43;
vector(entity e, float speed) aim = #44;
float(string s) cvar = #45;
void(string s) localcmd = #46;
entity(entity e) nextent = #47;
void(vector o, vector d, float color, float count) particle = #48;
void() ChangeYaw = #49;
vector(vector v) vectoangles = #51;
void(float to, float f) WriteByte = #52;
void(float to, float f) WriteChar = #53;
void(float to, float f) WriteShort = #54;
void(float to, float f) WriteLong = #55;
void(float to, float f) WriteCoord = #56;
void(float to, float f) WriteAngle = #57;
void(float to, string s) WriteString = #58;
void(float to, entity e) WriteEntity = #59;
void(float step) movetogoal = #67;
string(string s) precache_file = #68;
void(entity e) makestatic = #69;
void(string s) changelevel = #70;
void(float to) multicast = #82;

// ==========================================================================
// QUAKE CONSTANTS
// ==========================================================================

// Entity flags
float FL_FLY          = 1;
float FL_SWIM         = 2;
float FL_CLIENT       = 8;
float FL_INWATER      = 16;
float FL_MONSTER      = 32;
float FL_GODMODE      = 64;
float FL_NOTARGET     = 128;
float FL_ITEM         = 256;
float FL_ONGROUND     = 512;
float FL_PARTIALGROUND = 1024;
float FL_WATERJUMP    = 2048;
float FL_JUMPRELEASED = 4096;

// Move types
float MOVETYPE_NONE         = 0;
float MOVETYPE_WALK         = 3;
float MOVETYPE_STEP         = 4;
float MOVETYPE_FLY          = 5;
float MOVETYPE_TOSS         = 6;
float MOVETYPE_PUSH         = 7;
float MOVETYPE_NOCLIP       = 8;
float MOVETYPE_FLYMISSILE   = 9;
float MOVETYPE_BOUNCE       = 10;

// Solid types
float SOLID_NOT       = 0;
float SOLID_TRIGGER   = 1;
float SOLID_BBOX      = 2;
float SOLID_SLIDEBOX  = 3;
float SOLID_BSP       = 4;

// Damage types
float DAMAGE_NO       = 0;
float DAMAGE_YES      = 1;
float DAMAGE_AIM      = 2;

// Dead flags
float DEAD_NO         = 0;
float DEAD_DYING      = 1;
float DEAD_DEAD       = 2;

// Content types
float CONTENT_EMPTY   = -1;
float CONTENT_SOLID   = -2;
float CONTENT_WATER   = -3;
float CONTENT_SLIME   = -4;
float CONTENT_LAVA    = -5;
float CONTENT_SKY     = -6;

// Sound channels
float CHAN_AUTO       = 0;
float CHAN_WEAPON     = 1;
float CHAN_VOICE      = 2;
float CHAN_ITEM       = 3;
float CHAN_BODY       = 4;

// Sound attenuation
float ATTN_NONE       = 0;
float ATTN_NORM       = 1;
float ATTN_IDLE       = 2;
float ATTN_STATIC     = 3;

// Message destinations
float MSG_BROADCAST   = 0;
float MSG_ONE         = 1;
float MSG_ALL         = 2;
float MSG_INIT        = 3;

// Temp entities
float TE_SPIKE        = 0;
float TE_SUPERSPIKE   = 1;
float TE_GUNSHOT      = 2;
float TE_EXPLOSION    = 3;
float TE_TAREXPLOSION = 4;
float TE_LIGHTNING1   = 5;
float TE_LIGHTNING2   = 6;
float TE_WIZSPIKE     = 7;
float TE_KNIGHTSPIKE  = 8;
float TE_LIGHTNING3   = 9;
float TE_LAVASPLASH   = 10;
float TE_TELEPORT     = 11;

// SVC messages
float SVC_TEMPENTITY  = 23;

// Effects
float EF_BRIGHTFIELD  = 1;
float EF_MUZZLEFLASH  = 2;
float EF_BRIGHTLIGHT  = 4;
float EF_DIMLIGHT     = 8;

// ==========================================================================
// GLOBAL VARIABLES
// ==========================================================================

float time;
float frametime;
string mapname;
float deathmatch;
float coop;
float teamplay;
float serverflags;
float total_secrets;
float total_monsters;
float found_secrets;
float killed_monsters;
float force_retouch;
string forcefog;

entity self;
entity other;
entity world;
float trace_allsolid;
float trace_startsolid;
float trace_fraction;
vector trace_endpos;
vector trace_plane_normal;
float trace_plane_dist;
entity trace_ent;
float trace_inopen;
float trace_inwater;
entity msg_entity;
entity newmis;
entity lastspawn;

vector v_forward;
vector v_up;
vector v_right;

// ==========================================================================
// ENTITY FIELDS
// ==========================================================================

.float modelindex;
.vector absmin, absmax;
.float ltime;
.float movetype;
.float solid;
.vector origin;
.vector oldorigin;
.vector velocity;
.vector angles;
.vector avelocity;
.vector punchangle;
.string classname;
.string model;
.float frame;
.float skin;
.float effects;
.vector mins, maxs;
.vector size;
.void() touch;
.void() use;
.void() think;
.void() blocked;
.float nextthink;
.entity groundentity;
.float health;
.float frags;
.float weapon;
.string weaponmodel;
.float weaponframe;
.float currentammo;
.float ammo_shells;
.float ammo_nails;
.float ammo_rockets;
.float ammo_cells;
.float items;
.float takedamage;
.entity chain;
.float deadflag;
.vector view_ofs;
.float button0;
.float button1;
.float button2;
.float impulse;
.float fixangle;
.vector v_angle;
.float idealpitch;
.string netname;
.entity enemy;
.float flags;
.float colormap;
.float team;
.float max_health;
.float teleport_time;
.float armortype;
.float armorvalue;
.float waterlevel;
.float watertype;
.float ideal_yaw;
.float yaw_speed;
.entity aiment;
.entity goalentity;
.float spawnflags;
.string target;
.string targetname;
.float dmg_take;
.float dmg_save;
.entity dmg_inflictor;
.entity owner;
.vector movedir;
.string message;
.float sounds;
.string noise;
.string noise1;
.string noise2;
.string noise3;

// Player extensions
.float attack_finished;
.float pain_finished;
.float invincible_finished;
.float invisible_finished;
.float super_damage_finished;
.float radsuit_finished;

// Monster AI fields
.void() th_stand;
.void() th_walk;
.void() th_run;
.void() th_missile;
.void() th_melee;
.void() th_pain;
.void() th_die;

// ==========================================================================
// STUB IMPLEMENTATIONS - Required External Functions
// ==========================================================================

/*
spawn_tfog - Teleport fog effect
*/
void(vector org) spawn_tfog =
{
    WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte(MSG_BROADCAST, TE_TELEPORT);
    WriteCoord(MSG_BROADCAST, org_x);
    WriteCoord(MSG_BROADCAST, org_y);
    WriteCoord(MSG_BROADCAST, org_z);

    local entity fog;
    fog = spawn();
    fog.origin = org;
    fog.classname = "tfog";
    fog.nextthink = time + 0.5;
    fog.think = SUB_Remove;
};

/*
spawn_tdeath - Telefrag check
*/
void(vector org, entity death_owner) spawn_tdeath =
{
    local entity head;
    head = findradius(org, 64);
    while (head)
    {
        if (head != death_owner && head.takedamage)
        {
            if (head.health > 0)
                T_Damage(head, death_owner, death_owner, 5000);
        }
        head = head.chain;
    }
};

/*
T_Damage - Apply damage to entity
*/
void(entity targ, entity inflictor, entity attacker, float damage) T_Damage =
{
    if (!targ.takedamage) return;
    if (targ.health <= 0) return;

    // Apply armor reduction
    local float save;
    save = ceil(targ.armortype * damage);
    if (save >= targ.armorvalue)
    {
        save = targ.armorvalue;
        targ.armortype = 0;
        targ.items = targ.items - (targ.items & (1 | 2 | 4)); // Remove armor items
    }
    targ.armorvalue = targ.armorvalue - save;
    damage = damage - save;

    targ.health = targ.health - damage;

    if (targ.health <= 0)
    {
        if (targ.th_die)
            targ.th_die();

        // Award frag
        if (attacker.classname == "player" || attacker.classname == "cortexbot")
        {
            if (targ != attacker)
                attacker.frags = attacker.frags + 1;
            else
                attacker.frags = attacker.frags - 1; // Suicide
        }
    }
};

/*
T_MissileTouch - Rocket explosion
*/
void() T_MissileTouch =
{
    local entity head;
    local float damage;

    if (other == self.owner) return;

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    damage = 100 + random() * 20;

    // Direct hit damage
    if (other.health > 0)
        T_Damage(other, self, self.owner, damage);

    // Splash damage
    head = findradius(self.origin, 160);
    while (head)
    {
        if (head.takedamage && head != other)
        {
            local float dist;
            dist = vlen(head.origin - self.origin);
            damage = 120 - dist * 0.75;
            if (damage > 0)
                T_Damage(head, self, self.owner, damage);
        }
        head = head.chain;
    }

    // Explosion effect
    WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte(MSG_BROADCAST, TE_EXPLOSION);
    WriteCoord(MSG_BROADCAST, self.origin_x);
    WriteCoord(MSG_BROADCAST, self.origin_y);
    WriteCoord(MSG_BROADCAST, self.origin_z);

    remove(self);
};

/*
GrenadeTouch - Grenade bounce
*/
void() GrenadeTouch =
{
    if (other == self.owner) return;

    if (other.takedamage)
    {
        GrenadeExplode();
        return;
    }

    sound(self, CHAN_WEAPON, "weapons/bounce.wav", 1, ATTN_NORM);

    if (self.velocity == '0 0 0')
        self.avelocity = '0 0 0';
};

/*
GrenadeExplode - Grenade explosion
*/
void() GrenadeExplode =
{
    local entity head;
    local float damage;

    // Splash damage
    head = findradius(self.origin, 160);
    while (head)
    {
        if (head.takedamage)
        {
            local float dist;
            dist = vlen(head.origin - self.origin);
            damage = 120 - dist * 0.75;
            if (damage > 0)
                T_Damage(head, self, self.owner, damage);
        }
        head = head.chain;
    }

    // Explosion effect
    WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
    WriteByte(MSG_BROADCAST, TE_EXPLOSION);
    WriteCoord(MSG_BROADCAST, self.origin_x);
    WriteCoord(MSG_BROADCAST, self.origin_y);
    WriteCoord(MSG_BROADCAST, self.origin_z);

    remove(self);
};

/*
launch_spike - Nailgun projectile
*/
void(vector org, vector dir) launch_spike =
{
    newmis = spawn();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;
    newmis.classname = "spike";
    newmis.velocity = dir * 1000;
    newmis.angles = vectoangles(newmis.velocity);
    newmis.touch = spike_touch;
    newmis.nextthink = time + 6;
    newmis.think = SUB_Remove;
    setmodel(newmis, "progs/spike.mdl");
    setsize(newmis, '0 0 0', '0 0 0');
    setorigin(newmis, org);
};

void() spike_touch =
{
    if (other == self.owner) return;

    if (pointcontents(self.origin) == CONTENT_SKY)
    {
        remove(self);
        return;
    }

    if (other.takedamage)
    {
        local float damage;
        if (self.classname == "superspike")
            damage = 18;
        else
            damage = 9;
        T_Damage(other, self, self.owner, damage);
    }
    else
    {
        WriteByte(MSG_BROADCAST, SVC_TEMPENTITY);
        WriteByte(MSG_BROADCAST, TE_SPIKE);
        WriteCoord(MSG_BROADCAST, self.origin_x);
        WriteCoord(MSG_BROADCAST, self.origin_y);
        WriteCoord(MSG_BROADCAST, self.origin_z);
    }

    remove(self);
};

/*
FireBullets - Hitscan shotgun
*/
void(float count, vector dir, vector spread) FireBullets =
{
    local vector src, end;
    local float damage;

    makevectors(self.v_angle);
    src = self.origin + '0 0 16';

    while (count > 0)
    {
        end = src + dir * 2048;
        end = end + (crandom() * spread_x * v_right);
        end = end + (crandom() * spread_y * v_up);

        traceline(src, end, FALSE, self);

        if (trace_fraction != 1.0)
        {
            if (trace_ent.takedamage)
            {
                damage = 4;
                T_Damage(trace_ent, self, self, damage);
            }
        }

        count = count - 1;
    }
};

float() crandom =
{
    return 2 * (random() - 0.5);
};

/*
ThrowHead - Gib on death
*/
void(string mdl, float dmg) ThrowHead =
{
    setmodel(self, mdl);
    self.frame = 0;
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_BOUNCE;
    self.takedamage = DAMAGE_NO;
    self.velocity_x = -100 + random() * 200;
    self.velocity_y = -100 + random() * 200;
    self.velocity_z = 200 + random() * 200;
    self.avelocity = '0 600 0';
    self.nextthink = time + 10;
    self.think = SUB_Remove;
};

/*
SUB_Remove - Standard entity removal
*/
void() SUB_Remove =
{
    remove(self);
};

// ==========================================================================
// WORLDSPAWN AND TEST INITIALIZATION
// ==========================================================================

void() worldspawn =
{
    precache_model("progs/player.mdl");
    precache_model("progs/missile.mdl");
    precache_model("progs/grenade.mdl");
    precache_model("progs/spike.mdl");
    precache_model("progs/s_spike.mdl");
    precache_model("progs/h_player.mdl");

    precache_sound("weapons/sgun1.wav");
    precache_sound("weapons/lstart.wav");
    precache_sound("weapons/grenade.wav");
    precache_sound("weapons/bounce.wav");
    precache_sound("weapons/spike2.wav");
    precache_sound("weapons/rocket1i.wav");
    precache_sound("weapons/shotgn2.wav");
    precache_sound("weapons/guncock.wav");
    precache_sound("weapons/pkup.wav");
    precache_sound("weapons/lock4.wav");
    precache_sound("player/death3.wav");
    precache_sound("items/health1.wav");
    precache_sound("items/armor1.wav");
    precache_sound("items/damage.wav");
    precache_sound("items/protect.wav");
    precache_sound("items/inv1.wav");
};

/*
ClientConnect - Player joins server
*/
void() ClientConnect =
{
    bprint(self.netname);
    bprint(" entered the game\n");
    Cortex_ClientInRankings();
};

/*
ClientDisconnect - Player leaves server
*/
void() ClientDisconnect =
{
    bprint(self.netname);
    bprint(" left the game\n");
    Cortex_ClientDisconnected();
};

/*
PlayerPreThink - Called every frame before physics
*/
void() PlayerPreThink =
{
    // Handle impulse commands
    if (self.impulse == 100)
    {
        SpawnCortexBot();
        self.impulse = 0;
    }
};

/*
PlayerPostThink - Called every frame after physics
*/
void() PlayerPostThink =
{
};

/*
PutClientInServer - Spawn player
*/
void() PutClientInServer =
{
    local entity spot;

    self.classname = "player";
    self.health = 100;
    self.takedamage = DAMAGE_AIM;
    self.solid = SOLID_SLIDEBOX;
    self.movetype = MOVETYPE_WALK;
    self.flags = FL_CLIENT;
    self.deadflag = DEAD_NO;

    spot = find(world, classname, "info_player_start");
    if (!spot)
        spot = find(world, classname, "info_player_deathmatch");

    if (spot)
    {
        setorigin(self, spot.origin);
        self.angles = spot.angles;
    }

    setmodel(self, "progs/player.mdl");
    setsize(self, '-16 -16 -24', '16 16 32');

    self.th_die = PlayerDie;
};

void() PlayerDie =
{
    self.deadflag = DEAD_DEAD;
    self.solid = SOLID_NOT;
    self.movetype = MOVETYPE_NONE;
};
