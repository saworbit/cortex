#
# Cortex Goal/Intent TODO
#
# Practical, logic-first plan for a Quake 1 DM bot.
#

## 1) Objective and evaluation
- [ ] Define the primary objective as maximize net score over a short horizon (kills - deaths).
- [ ] Implement a "expected net score over next N seconds" utility function.

## 2) Top-level modes (macro loop)
- [ ] Add modes: Fight, Finish, Disengage, Re-arm, Power-up plan, Hunt, Deny control, Stabilize.
- [ ] Choose control style (state machine vs utility scoring) and implement mode selection.

## 3) State tracking (what matters)
Self
- [ ] Track health, armor, and stack (effective survivability).
- [ ] Track weapons, ammo, and best weapon per range.
- [ ] Track powerups and remaining time (quad/pent/ring).
- [ ] Track position, velocity, and quick-cover options.
- [ ] Track recent damage direction (threat vector).

Enemy model
- [ ] Track last known position and timestamp.
- [ ] Add a route likelihood model from last known position.
- [ ] Infer enemy stack (weak/even/strong) from damage taken and behavior.
- [ ] Infer weapon set from projectile patterns and aim behavior.

Map control
- [ ] Track timers for mega, red armor, yellow armor, quad, pent.
- [ ] Flag items as safe/unsafe based on LOS and trap risk.
- [ ] Compute a control score: who likely owns major timers.

Risk context
- [ ] Track match type (duel vs FFA).
- [ ] Track spawn randomness and common spawn clusters.
- [ ] Estimate "punishability of death" (position loss, quad swing, etc.).

## 4) Core decision: fight vs not fight
- [ ] Implement an engagement desirability score.
- [ ] Fight when: stack/powerup advantage, position advantage, range advantage, safe chase, no critical timer loss.
- [ ] Disengage when: weak, out of ammo, bad geometry, item timing conflict, unknown enemy/trap risk.

## 5) Micro loops (moment-to-moment behavior)
Combat loop (1-5 seconds)
- [ ] Choose preferred range by weapon and enforce it.
- [ ] Always keep an exit tile (cover/corner/drop).
- [ ] Use consistent damage policy over perfect aim.
- [ ] Compare TTK; reposition when disadvantaged.
- [ ] Track opponent via audio cues (steps/lifts/pickups).
- [ ] Finish rule: chase only if safe path, predictable exits, no known trap corridor.

Disengage loop (0.5-3 seconds)
- [ ] Break LOS quickly using corners, height, water, lifts.
- [ ] Drop pursuit via sound breaks and route forks.
- [ ] Grab stabilizer items if safe (YA, small health, ammo).
- [ ] Avoid dead ends unless stacked or invulnerable.

Re-arm loop (5-20 seconds)
- [ ] Reach a minimum viable kit (mid-range weapon + ammo + armor/health baseline).
- [ ] Upgrade to control kit (rockets + LG + strong stack).
- [ ] Prefer routes with low exposure and info points (sound/sight checks).

Control loop (20-60 seconds)
- [ ] Maintain timers for mega/RA/quad/pent.
- [ ] Pick control plan: hard control vs soft control/steal.
- [ ] Learn and store control routes per map (rotations, traps, denial positions).

## 6) Priority ladder (gated policy)
- [ ] Immediate survival -> disengage/stabilize.
- [ ] Immediate kill -> finish if safe.
- [ ] Secure spawning major item -> power-up plan/control.
- [ ] Favored fight -> engage.
- [ ] Deny opponent major item -> steal/poke/force.
- [ ] Re-arm to minimum kit.
- [ ] Improve position and info.

## 7) Sub-intents to encode
Information warfare
- [ ] Sound baiting and ambush routes.
- [ ] LOS probing without commitment.
- [ ] Uncertainty handling: act conservatively when blind.
- [ ] Predictive tracking from last known + map graph.

Tempo control
- [ ] When ahead: reduce risk and force bad fights.
- [ ] When behind: take calculated risks and contest powerups.

Resource denial
- [ ] Take items to starve opponent when safe.
- [ ] Leave junk if it exposes you to traps.
- [ ] Prefer denying mega/RA over topping to 200+ when safe.

Spawn logic (FFA)
- [ ] After a kill, expect nearby spawns and reposition.
- [ ] Avoid tunnel vision and third-party risk.
- [ ] Value "not being seen" higher in FFA.

Geometry tactics
- [ ] Use chokes/corners for rockets and traps.
- [ ] Favor open space for hitscan and dodging.
- [ ] Hold height to reduce surprise angles.

Mistake recovery
- [ ] If a major timing is missed, switch to denial mode.
- [ ] If a fight goes bad, disengage early.

## 8) State machine sketch (tick evaluation)
- [ ] Implement a per-tick evaluation ladder:
      - threat_high + escape -> Disengage
      - enemy_low + chase_safe -> Finish
      - major_item_spawning + safe -> Control
      - fight_advantage_high + enemy_known -> Fight
      - need_min_kit -> Re-arm
      - opponent_in_control -> Deny
      - else -> Hunt/Position
- [ ] Each state must output: movement target, weapon choice, posture, disengage thresholds.

## 9) ML reward shaping (future)
- [ ] Define positives: damage dealt, kills, item control, denial.
- [ ] Define negatives: deaths, damage while weak, missed item windows, bad fights.
- [ ] Define dense signals: control routes, cover use, timing accuracy.

## 10) Next build inputs (needed to proceed)
- [ ] Pick target map(s) (eg DM2, DM3, E1M2).
- [ ] Confirm match type (1v1 duel vs FFA).
- [ ] Provide or confirm respawn assumptions for items.
