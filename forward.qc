/*
==============================================================================
FORWARD DECLARATIONS
Fixes for decompiled QuakeC code ordering issues
==============================================================================
*/

// From player.qc - needed by monster death functions
void(string gibname, float dm) ThrowGib;
void(string gibname, float dm) ThrowHead;

// From misc.qc - needed before definition
void() bubble_bob;

// From weapons.qc - needed by various files
void() W_FireAxe;
void() W_FireShotgun;
void() W_FireSuperShotgun;
void() W_FireRocket;
void() W_FireLightning;
void() W_FireGrenade;
void(float ox) W_FireSpikes;
void() W_FireSuperSpikes;

// From client.qc - needed by world.qc
void() respawn;
void() PutClientInServer;

// Entity for missiles
entity newmis;

// Standard entity used in spawning
entity lastspawn;

// From client.qc - needed by player.qc and oldone.qc
float modelindex_player;
float intermission_exittime;
float intermission_running;
