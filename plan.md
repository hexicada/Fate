# Plan: Fate Lore Lock And Player Base Body

## Context
- Fresh Godot project, no existing player scripts or scenes yet
- Starting from scratch with lore, class foundation, and player embodiment
- Immediate goal: lock the current lore foundation, then pivot to a gameplay-first player base body design
- Output format: design-first, then implementation planning for Godot

## Locked Lore Foundations
- **Core metaphysics**: Death is governed by a vast, indifferent Consuming Force that absorbs awareness
- **The Grammar of Death**: Mortality has exploitable structure; death is a threshold with seams that can be held open
- **The Gira**: A sustained working cast by the player character that creates an anchor for return from death
- **Death loop**:
  - On death, the body falls or is destroyed
  - The etheric body enters a liminal death space
  - The Gira acts as a marker to find the seam back into reality
  - In unrestricted respawn, the return is close to the body
  - In restricted respawn, the player traverses through the fog for 10 to 20 seconds unless revived by a teammate
  - If no Gira is active, teammates must create a ritual beacon to provide an anchor
  - If everyone dies without an anchor, the encounter wipes
- **The Gira constraint**: It is not permanent; it persists until disrupted, damaged, or otherwise broken

## Locked Class And Element Framework
- **Classes**:
  - Sentinel: tank, group defense buffs
  - Slayer: glass cannon, high DPS, needs protection
  - Seer: healing, support, enemy analysis
- **Elements**:
  - Solar = fire-based, radiant heat, ignition, burning pressure
  - Void = black holes, purple palette, absence, compression, gravitational force
  - Chaos = crimson red, particulate, destructive, unstable violent energy
- **Progression**: gear-based, not XP-gated

## Canonical Subclass Matrix
- **Sentinel**
  - Solar: Dawnshield
  - Void: Voidguard
  - Chaos: Carnage Marine
- **Slayer**
  - Solar: Sunsetter
  - Void: Nullifier
  - Chaos: Maelstrom
- **Seer**
  - Solar: Zenithblade
  - Void: Abyssal Cleric
  - Chaos: Anarchy

Base Body Direction
Entity baseline: playable characters are canonical humans
Character selection: players choose male or female body variant
Current planning slice: shared gameplay contract for both male and female
Camera: first-person
Movement feel: grounded gunplay with bursts of mobility
Core movement verbs: walk, sprint, jump, crouch, slide, mantle
Current scope: gameplay body and movement only, not proportions or armor-fit planning yet
Recommended Shared Movement Contract (Male/Female)
Controller model: first-person CharacterBody3D style controller with a single collision capsule and a separate camera pivot for look control
Design target: responsive shooter movement that preserves aim readability; faster than a tactical shooter, slower and heavier than an arena shooter
Stance states:
Standing = default combat and traversal state
Sprinting = traversal burst that trades some immediate weapon readiness for speed
Crouched = lower profile precision state with slower traversal and improved stability
Sliding = short momentum state entered from sprint into crouch
Airborne = constrained midair control, tuned for readability rather than trick movement
Mantling = brief assisted traversal state that resolves on top of ledges and returns to standing
Recommended transitions:
Standing -> Sprinting when moving forward past a threshold and sprint input is held
Sprinting -> Sliding when crouch is pressed above a minimum speed and grounded
Standing -> Crouched on crouch press when not sprinting or mantling
Crouched -> Standing when crouch is released and there is headroom
Any grounded state -> Airborne on jump or loss of ground contact
Airborne -> Mantling only when the player reaches a valid ledge at allowable height and angle
Mantling -> Standing when the assisted climb finishes
Movement priorities:
Gunplay clarity outranks traversal tech
Sprinting should be useful for repositioning, not the default combat state
Slides should feel deliberate and strong in short bursts, not chainable movement tech
Mantles should preserve flow and reduce frustration, not trivialize level geometry
Recommended Movement Rules By Verb
Walk:
Full weapon readiness
Highest aiming precision baseline
Fast strafe response and fast stop response
Sprint:
Forward-biased speed boost
Reduced strafe influence while active
Cancels on firing, aiming down sights, jump, hard collision, or crouch-to-slide transition
Intended for crossing danger or pushing between cover, not hipfire dominance
Jump:
Single grounded jump only in the base controller
Medium height with a quick takeoff and readable landing window
Air control is limited so accuracy and silhouette remain readable in PvE or PvP
Crouch:
Lowers camera and capsule height with a smooth but short transition
Improves recoil handling and visual stability
Slows traversal enough that standing remains the default combat posture
Slide:
Triggered from sprint plus crouch above a speed floor
Carries momentum briefly, then decays into crouch
Preserves limited hipfire but should restrict precision aiming during the slide itself
Ends on low speed, jump, obstacle interruption, or duration timeout
Mantle:
Valid only on ledges within a tuned height band and frontal angle
Takes control briefly to keep traversal readable and avoid edge snagging
Disabled while in deep fall, heavy knockback, or other invalid states
First-Person Combat Posture Assumptions
Camera behavior:
Camera is anchored to a head or eye pivot, but tuned to reduce excessive bob and motion sickness
Sprint adds mild camera tilt and bob; slide lowers the camera sharply but briefly
Landing applies a short recovery dip, not a large cinematic bounce
Weapon handling:
Standing and crouching support full ready posture
Sprint lowers weapon presentation enough to clearly signal reduced readiness
Slide keeps the weapon visible but de-emphasized to preserve situational awareness
Interaction posture:
Revive, ritual beacon use, and general interactions should work from standing or crouch
Interaction reach should be generous enough for FPS usability and not require exact foot placement
Death and Gira presentation link:
The movement controller should expose a clean handoff from live locomotion to death-state presentation without baking Gira logic into the locomotion core
Godot Implementation Outline
Planned scene root: player should eventually contain a root player scene with child nodes for collision, camera pivot, interaction raycast, weapon pivot, and mantle probes
Planned script split:
Movement controller = velocity, state transitions, gravity, jump, crouch, slide, mantle
Camera controller = look input, pitch clamp, head/eye pivot behavior, camera effects
Interaction component = revive, pickup, beacon interaction checks
Combat bridge = weapon-ready state changes driven by locomotion state
Suggested first prototype order:
Walk/look
Sprint
Jump and landing
Crouch
Slide
Mantle
Interaction hooks
Update the plan steps and decisions to match this:

Plan Steps
Lock lore into a concise design brief
Capture only the current canonical metaphysics, death loop, class matrix, and elemental framework
Exclude deep history, factions, armor aesthetics, and subclass ability trees for now
Define the shared base body gameplay contract for male and female
Specify the first-person controller assumptions: collision capsule, eye height, camera pivot, grounded acceleration/deceleration, air control, crouch transition, slide trigger, and mantle rules
This should answer what the body must do before any art or rig work begins
Define the movement verb behavior
Walk: default traversal and aiming baseline
Sprint: forward-commit burst for repositioning
Jump: readable, grounded arc rather than floaty arena movement
Crouch: low-profile precision state and slide prerequisite
Slide: momentum-preserving repositioning tool, short and intentional rather than spam-heavy
Mantle: environmental recovery and flow preservation over waist-high or chest-high cover as defined later
Define first-person combat posture assumptions
Decide how the base body supports weapon readiness, aiming, recoil response, landing recovery, revive interaction, and interaction reach
This prevents movement design from diverging from gunplay feel
Define implementation-facing scene/script boundaries
Plan the future player scene and movement/controller scripts under player
Separate input handling, locomotion state, camera behavior, and interaction hooks at the planning level before code exists
Return later to armor fit and visual customization passes
Male and female should both implement the same movement and interaction rules from the first playable pass
Class identity should layer through gear, abilities, and effects rather than body movement differences


## Plan Steps
1. **Lock lore into a concise design brief**
   - Capture only the current canonical metaphysics, death loop, and class/element framework
   - Exclude deep history, factions, and subclass ability trees for now

2. **Define the base player body spec**
   - Establish shared gameplay requirements across male and female variants: movement capsule, camera model, jump/sliding/sprinting decisions, aiming posture, revive interaction posture, and weapon carry assumptions
   - This should produce one baseline body contract that Godot implementation can follow

3. **Define male/female embodiment boundaries**
   - Keep collision, movement state logic, and interaction reach equivalent across both body variants
   - Limit differences to presentation-level decisions so gameplay readability and balance stay consistent
   - Use one shared locomotion/gameplay state machine for both body variants
   - Support separate male/female animation profile mappings for each locomotion state (idle, walk, sprint, jump, crouch, slide, mantle)
   - Do not tie gameplay stats or locomotion values to body type

4. **Define required attachment architecture**
   - Identify sockets or anchor points needed for helmets, chest armor, arms, legs, primary weapon, secondary weapon, melee tool, and visible Gira effects
   - This is necessary before rigging or scene hierarchy design

5. **Map the body spec to Godot implementation surfaces**
   - Planned files should likely include a player scene and core movement script under `res/actors/player/`
   - Keep this at the planning level only until the design brief is approved

6. **Return to class identity after the base body is stable**
   - Once movement/body assumptions are fixed, define subclass identities and abilities without changing the shared body movement contract

## Relevant files
- `c:\Users\hexicada\Projects\Fate\res\actors\player\` - empty target area for future player scene/scripts
- `c:\Users\hexicada\Projects\Fate\res\core\` - likely home for future shared player/class constants

## Verification
1. Confirm the lore summary can be read without contradiction between the Consuming Force, the Grammar of Death, and the Gira mechanic
2. Confirm the player body spec answers the practical questions needed for implementation: movement, camera, posture, interaction, and attachment points
3. Confirm male and female variants preserve one coherent gameplay contract for hitbox/collision behavior and movement readability
4. Confirm the plan excludes subclass ability-tree detail until after the player body contract is stable
5. Confirm animation variation is implemented through profile mapping only, without body-type gameplay stat divergence

## Decisions
- Scope is reordered: lore lock first, shared base body second, class kit detail later
- Playable characters are canonical humans
- Class-based body differentiation is out of scope
- Male and female share one movement and interaction contract
- Locomotion/gameplay uses one shared state machine across both body variants
- Male and female can use different animation clips through per-body animation profile mappings
- Body type cannot modify gameplay stats, speed tiers, or movement tuning values
- The first body pass is gameplay-first, not art-first

## Initialization Status (May 29, 2026)
- Completed: first-playable player scene and movement loop (walk, sprint, jump, crouch, slide)
- Completed: test arena scene as startup level for rapid iteration
- Completed: initial script boundaries in player package
  - `player_controller.gd` = locomotion/state owner
  - `player_camera_controller.gd` = look, pitch clamp, eye-height blend, sprint/slide tilt
  - `player_interaction_component.gd` = forward interaction ray + target hint surface
  - `player_combat_bridge.gd` = weapon readiness states derived from locomotion
- Completed: scene hierarchy hooks for next systems pass
  - interaction raycast, weapon pivot, mantle probes, combat bridge node
- Completed: mantle traversal first pass (probe-driven detection with assisted pull-up)
- Pending tune: mantle arc, target placement, and ledge validation strictness
- Deferred: revive/beacon interaction logic beyond target detection
- Deferred: subclass/class ability systems and Gira runtime integration
