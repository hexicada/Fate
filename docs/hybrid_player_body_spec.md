# Hybrid Player Body v0 — Architecture, State Flow & Art Requirements

**Project**: Fate (Godot 4.6)  
**Date**: 2026-06-16  
**Status**: Movement foundation complete (including very forgiving mantle). Shifting focus to visual player body layers.  
**Owner**: Gameplay + Art collaboration

## 1. Locked Decisions (from plan.md)

- **Approach**: Hybrid First-Person (locked).
  - Single gameplay authority: `player_controller.gd` + collision capsule (CharacterBody3D).
  - Visuals are purely presentational. Body assets **cannot** change movement values, hit logic, or interaction reach.
- **Two Visual Layers**:
  - **FP layer** (local-only, camera-relative): Player's personal view. Currently prioritizing arms + weapon. Will later include legs.
  - **World layer**: Full character mesh for third-person visibility (other players, shadows, reflections, multiplayer).
- **Shared Contract**:
  - Male/female (and future customized bodies from character creator) use the **exact same gameplay and locomotion rules**.
  - Visual/animation differences only.
- **Required Locomotion States** (both FP and World layers must support these):
  - STANDING
  - SPRINTING
  - CROUCHED
  - SLIDING
  - AIRBORNE
  - MANTLING
- **Character Creator Integration**:
  - Outputs body mesh + materials + optional per-body animation profile mapping.
  - Runtime body swapping must not require changes to locomotion code.
  - Gear and class fantasy (Solar / Void / Chaos) layer primarily through attachments, FX, and abilities.
- **Attachment Points** (sockets/anchors needed):
  - Helmet / head
  - Chest armor
  - Arms / upper body
  - Legs / lower body
  - Primary weapon
  - Secondary weapon
  - Melee tool
  - Visible Gira effects (and other gameplay FX)

## 2. Current Implementation Status

- Core movement + camera + interaction + state machine complete and playable.
- `player_combat_bridge.gd` exists (maps locomotion state → WeaponReadiness: READY / LOWERED / SLIDE) but is not yet wired into the scene or controller.
- `WeaponAnchor.gd` and `WeaponViewModel.gd` exist with hip/ADS pose support and animation hooks.
- `ViewModelRoot` node exists under `HeadPivot/Camera3D` (correct location for FP).
- `BodyMesh` (capsule placeholder) acts as initial world layer.
- Mantle is deliberately very forgiving ("reach up and grab" even on ledges slightly above head height).

**Important New Constraint (2026-06-16)**:  
FP legs will be added later to support platforming. The player must be able to look down and see their feet for safe landing judgment. **FP arms/weapon work must not block or complicate the addition of FP legs.**

## 3. Target Node Hierarchy (Future-Proof for FP Legs)

```text
Player (CharacterBody3D)
├── CollisionShape3D
├── WorldBodyRoot                  ← Placeholder for full world rig (male/female bodies, shadows, multiplayer)
│   └── [Full Character Rig / Mesh]
│       └── BoneAttachment3D sockets (helmet, chest, legs, Gira, etc.)
├── HeadPivot (camera look + eye height)
│   ├── Camera3D
│   │   └── ViewModelRoot          ← FP presentation root (local only, camera relative)
│   │       ├── UpperFP            ← CURRENT PRIORITY: Arms + Weapon
│   │       │   ├── ArmsRig        (future real arm meshes/rig)
│   │       │   └── WeaponAnchor
│   │       │       └── WeaponViewModel / actual weapon scene
│   │       └── LowerFP            ← FUTURE: FP legs for platforming visibility
│   │           └── LegsRig        (visible when camera pitches down)
│   └── InteractionRayCast3D
├── MantleProbeLower / MantleProbeUpper   (keep for editor visualization)
├── CombatBridge                   ← Logic mediator (no visuals)
└── UI (debug labels)
```

**Rules for this hierarchy**:
- All current and near-term FP arm/weapon work goes **exclusively under `UpperFP`**.
- `LowerFP` is reserved. Do not place arm, weapon, or upper-body nodes inside it.
- `WorldBodyRoot` is the counterpart to the FP layer for third-person needs.
- `CombatBridge` owns weapon readiness state derived from locomotion. It is the recommended place for visuals (both upper and future lower) to query current readiness or full locomotion state.
- The capsule and probes remain the source of truth. Visual nodes are children for organization and easy enabling/disabling.

## 4. State & Readiness Flow (Minimal Coupling)

- `player_controller.gd` owns the authoritative `_state` (`PlayerLocomotionState.Value`).
- Every frame (or on change), the controller calls `combat_bridge.update_from_locomotion_state(current_state)`.
- `WeaponViewModel` / future arm and leg rigs query:
  - The bridge for `WeaponReadiness` (drives hip/ADS, lowered on sprint, special pose on slide).
  - The locomotion state (or a helper) for full stance (crouch height, mantle reach pose, etc.).
- Visual layers should be **driven**, never drive gameplay.
- Later: Both `UpperFP` and `LowerFP` can listen to the same state source.

## 5. FP Layer Specific Rules (Protecting Future Legs)

- The FP layer is **local player only** (no shadows, no multiplayer replication of the view models themselves).
- When the player looks down (camera pitch), FP legs must become visible and feel accurately placed relative to the capsule.
- Weapon/arm positioning (especially during crouch, slide, mantle, and sprint) must not assume the bottom of the screen is empty or cause visual conflicts with future visible feet.
- Upper body (arms) and lower body (legs) should be separable so they can have independent rigs/animations while still being driven by the shared locomotion states.
- Mantle "reach up" feel should eventually be supportable on both arms and legs.

## 6. Art Team Requirements

### Rigging & Skeleton
- Consistent bone naming and hierarchy across male/female variants.
- Support for the 6 locomotion states listed above.
- Clear separation or easy culling between upper body (arms/hands/torso for FP) and lower body (legs/feet for FP legs).

### Animation Requirements (v0 minimum)
- Standing (idle + breathing)
- Sprinting
- Crouched (idle + traversal)
- Sliding (short, momentum-based)
- Airborne (jump, fall, land)
- Mantling (reach/grab + pull-up) — important for "reach up" readability
- Weapon actions: idle, fire, reload, ADS in/out, equip (these can live on the weapon rig or be driven through the arms)
- FP legs will need matching lower-body versions of the above states (especially accurate foot placement for platforming trust)

### FP vs World Layer
- **FP Arms/Upper (priority now)**: Close-up quality. Arms, hands, and weapon presentation. Minimal or no legs needed in this pass.
- **FP Legs (future)**: Visible on downward camera pitch. Must convey safe landing spots. Should match world body proportions and timing.
- **World Body**: Full mesh (head, arms, torso, legs). Used for shadows and other players. Can be higher detail or different LOD strategy.

### Attachment / Socket Points (BoneAttachment3D or equivalent)
- Head/helmet
- Chest / torso
- Upper arms / weapon hold points
- Hips / holsters
- Hands (primary/secondary weapon, melee)
- Ankles / feet (for future FP legs + possible attachments)
- Back / chest for Gira and class-specific FX

### Character Creator / Variant Support
- Male and female bodies must plug into the same state machine.
- Provide per-body animation profile mapping if timing or proportions differ.
- Gear (class fantasy) should be attachable rather than baked into the base body.

### Technical / Export
- GLTF export preferred for Godot 4.6.
- Clean material slots.
- Consistent scale (match current capsule: standing height ~1.8, radius 0.35).
- Placeholder assets needed soon: simple blocky arms + basic weapon + rough full body for stance verification. Basic keyframed or mocap animations for the 6 states are extremely valuable for iteration.

**Immediate Art Ask (for this phase)**:
- Placeholder FP arm + hand meshes that can be parented under `UpperFP`.
- A simple weapon model that works with the existing `weapon_placeholder.tscn` pattern or the `WeaponViewModel`/`WeaponAnchor` system.
- Rough world body placeholder (can be the same as current capsule or a simple mannequin).
- Early thinking on how FP legs will be delivered later (separate lower rig? visibility on full rig?).

## 7. Implementation Phases

1. **Scaffolding (current first step)**  
   - Add placeholder node groups (`UpperFP`, `LowerFP`, `WorldBodyRoot`).  
   - Instantiate `CombatBridge` in the scene.  
   - Produce this spec document for the art team.

2. **State Wiring**  
   - Feed locomotion state + weapon readiness from `player_controller` to the bridge.  
   - Basic hooks so `WeaponViewModel` can react (sprint lowered, slide pose, etc.).

3. **Placeholder Visuals**  
   - Drop simple arm/weapon art under `UpperFP` / `WeaponAnchor`.  
   - Verify all 6 stances look reasonable.

4. **Attachments & Polish**  
   - Add sockets.  
   - Drive camera effects + posture changes.  
   - Prepare for real rigs.

5. **FP Legs Addition (when ready)**  
   - Populate `LowerFP`.  
   - Ensure sync with world body and capsule ground contact.

## 8. Open Questions / Risks

- Animation system choice when real art arrives (simple AnimationPlayer state drive vs AnimationTree)?
- Will FP arms be a completely separate rig or a culling/visibility subset of a unified rig?
- How much camera-relative weapon sway, bob, and "mantle reach" posing do we want in the first arms pass?
- Any specific platforming moves (beyond looking down at feet) that affect leg visibility timing?

---

**Next Action After This Document**: Wire basic state flow and prepare `UpperFP` + `WeaponAnchor` for the first art drop.

This spec should be treated as the single source of truth for the hybrid body contract and art handoff. Update it as decisions are made.
