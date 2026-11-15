# Maintenance notes

Context for anyone — human or model — picking this pack up without the original development conversation. `DEVLOG.md` is the companion: every problem this fork hit, its real cause and its fix, including the dead ends. Everything below was established by reading Iris source, Iris documentation or other shaderpacks, or by a failure observed in game. Treat it as load-bearing: several of these cost multiple debugging rounds.

## Ground rules

- **Validate before shipping.** `python3 check.py` must exit 0. It compiles every program in every dimension across every option combination that changes generated code. A change that only compiles under the default options will break for someone else.
- **Verify, do not assume.** Iris behaviour is frequently undocumented and occasionally counter-intuitive. Read the Iris source or docs, or reproduce in game, before asserting a cause. Several "obvious" diagnoses in this pack's history were wrong, and each one cost a round trip.
- **The user's settings file wins.** Iris writes in-game option values to `<packname>.zip.txt` beside the pack. Changing a default in `shader.h` does nothing for an option the user has already touched. When a shipped default changes, say so explicitly.
- **A full pack reload is required** for any change to take effect — reselecting the pack in the shader menu, not just a resource reload.
- **Every change goes to `matv-studio/miniatureXL`.** Commit and push each modification of the pack to this repository (branch `main`) as soon as it passes `check.py`. Never leave work only in a session's filesystem — it has been lost once (see `DEVLOG.md` §9).

## Iris constraints discovered the hard way

**`workGroups` is parsed textually.** Iris's `ComputeDirectiveParser` reads the characters between the commas of `const ivec3 workGroups = ivec3(...)` *before* preprocessing and calls `Integer.parseInt`. Any arithmetic — `VOXEL_SIZE / 8` — throws `NumberFormatException` and the whole pack silently fails to load with no useful in-game message. This forces the per-size `#if` branches with literal integers in `program/shadowcomp.csh`. `check.py` asserts this.

**A block belongs to exactly one `block.properties` group.** Entries apply top to bottom and a later group overwrites an earlier one as if the first never existed. Copper lanterns were in the copper reflectivity group (`20008`) *and* the colored-light group (`10218`); the reflectivity group won, so placed lanterns reached the voxelizer with an unknown id and emitted the default warm color while the held item — routed through `item.properties`, no conflict — was correctly green. Redstone ore had the same conflict with the glowing-ores group (`10014`), resolved by giving it id `10220` and extending the `isOre` test. `check.py` asserts uniqueness.

**Iris skips a dimension's shadow pass if nothing samples the shadow map there.** The Nether and End cast no shadows, so without a sampler the pass never runs and the voxelizer is starved. The workaround is an invisible tap in `program/textured_lit.fsh` for non-Overworld dimensions:

```glsl
albedo.rgb += texture2D(shadowcolor0, vec2(0.5)).rgb * 1.0e-6;
```

The contribution cannot be optimized away, so the sampler stays live and the pass keeps running.

**Entity lighting requires entities in the shadow pass.** The shadow pass is the only place Iris gives a light source's world position, so `shadowEntities`, `shadowBlockEntities` and `shadowPlayer` must be `true` or no entity can emit light. `shaders.properties` forces them on whenever `CL_ENTITY_LIGHT` or `CL_ITEM_LIGHT` is active, independently of the pack's own *Entity shadows* setting. Note that Minecraft's own **Entity Shadows** video option is unrelated to this directive — it does not control it.

**Entity ids reach the shadow pass.** `entityId`, `blockEntityId` and `currentRenderedItemId` are rewritten by Iris's `EntityPatcher` into components of the `iris_Entity` vertex attribute, which is part of the vertex format used by both the gbuffers and shadow entity programs. They are valid in `shadow.vsh`. `minecraft:entity_flame` is a real hardcoded Iris identifier for the flame overlay on a burning entity, and `MixinFlameFeatureRenderer` sets it in the shadow pass too.

**Entity sources must be voxelized from the vertex stage.** The flame overlay is a billboard oriented toward the *player* camera even while the shadow pass renders from the sun — Iris does not re-orient the dispatcher. From the light's point of view it can be edge-on, back-facing (this pack uses `shadow.culling=reversed`) or fully transparent, so a fragment-stage `imageStore` often never executes. Since 1.1 `program/shadow.vsh` writes the whole voxel map, terrain included, from the vertex stage. Bliss does the same thing for the same reason.

**`shadow.culling=reversed` needs `const float voxelDistance`.** Reversed culling leaves the shadow pass unculled only within `voxelDistance` of the camera and culls the rest with the advanced shadow frustum, which keeps only geometry whose shadow can land in the view. Iris's default is `0.0` (`PackShadowDirectives`), so until 1.2 the whole voxelizer ran under the advanced frustum: chunks behind the player were never drawn in the shadow pass and their lights vanished from the colored light. `shader.h` now declares it from *Lights behind you* (`CL_BEHIND_DISTANCE`, default 32). Keep it modest: everything inside it is drawn in the shadow pass, behind the player too — 64 blocks caused hitches on fast turns. A light carries ~17–25 blocks, so 32 covers every light that can reach what the player sees. Literal `#if` branches only (const directives are read textually).

**Iris sets no render stage for entities in the shadow pass.** `ShadowRenderer` never calls `setPhase`, so `renderStage` cannot single out entities there. `shadow.vsh` identifies them as geometry with no mid-block data outside the terrain stages (entity shadow fade).

**The shadow pass can skip rasterization where no shadow map is read.** In the Nether, the End and the Overworld with shadows off the pass only exists for the vertex-stage voxel writes; `shadow.vsh` then moves every primitive outside the clip volume. The keep-alive tap in `textured_lit.fsh` is gated on `!ENABLE_SHADOWS` (not `!OVERWORLD`), so the Overworld with shadows off keeps its voxelizer too.

**Block-entity text is drawn by `gbuffers_block_translucent`**, which falls back to `gbuffers_block` then `gbuffers_terrain` (`ProgramId`). Sign text therefore reaches `textured_lit` with `GBUFFERS_TERRAIN` defined, no mid-block data and a font page bound (`atlasSize == 0`); glowing text is drawn fullbright. That is how glow ink text is recognized.

**`colortex2.a` and `shadowcolor0.a` carry flags.** `colortex2.a < 0` marks the nether portal for `final.fsh` (translucents write colortex2 with `ONE ZERO`, so the value arrives intact). `shadowcolor0.a` is the occluder's shadow strength (entity shadow fade); nothing else reads either channel.

**`#elif` in `shaders.properties` is unverified.** Nested `#if` / `#else` / `#endif` is known to work and is what the file uses. Parenthesized boolean expressions and `defined X` do work.

## Colored light architecture

Since 1.1 the colored light is a light propagation volume (`common/lpv.glsl` holds the layout and constants):

```
shadow.vsh       voxelize from the vertex stage: voxelData (rgba8, cleared
                 each frame) = palette color x vanilla level (at_midBlock.w),
                 or a tint (stained glass, leaves), or opaque
shadowcomp.csh   one propagation step per frame: average of self and open
                 neighbors (LPV_CENTER, LPV_LOSS), x transmission, + emission;
                 ping-pong by frame parity, re-indexed as the camera moves
getTorchColor    log transfer 1 + ln(amplitude) / (3.5 + CL_FALLOFF): vanilla
                 falloff at the lowest Light reach; hue from the field, strength
                 = max(vanilla, field) with the field capped at vanilla + 0.5
```

The sections below describe the 1.0 engine. The color rules still hold; the voxel encoding and the confidence windows they mention are historical.

- **Two volumes, ping-ponged by frame parity.** The reader samples both and keeps the stronger (`alpha`) sample. A parity read alone desynchronizes from the compute cadence and the light visibly pulses between its color and the warm default.
- **Injection comes *after* the temporal filter**, not before. Filtering the injection caps a source at `CL_TRANSITION` of its strength unless it stays in the same cell for ~`1/CL_TRANSITION` frames, which moving lights (burning mobs, dropped items, held lights) never do — they get drowned out by the static field around them.
- **`rgb/alpha` is distance-invariant**, so the reader recovers the palette color's own magnitude (`max(rgb) / (0.75 * alpha)`, knee at 0.75) and uses it as the light's brightness. That is how the RGB sliders double as a brightness control.
- **Hue and illumination use different confidence windows.** Hue adoption reaches far (a hue is a ratio, valid at tiny luma) so a source's color covers its real lit radius; the illumination floor stays close to the source so added brightness does not creep outward. The adoption curve is `pow(hueConfidence, 0.6)` — a gentler curve leaves a wide partial-mix band that reads as a third color (orange × green = a yellow ring around green sources).
- **The volume wraps toroidally.** Both the voxelizer and the reader need vertical and radial fade windows or sources from far above or below ghost into view as drifting colored patches.
- **NaN defense at both ends**: the volumes are persistent and never cleared by Iris, so they are wiped during the first frames after load (`frameCounter < 2`), clamped every frame in the compute, and rejected on read with comparison-based tests (`isnan` does not exist in GLSL 120).

## Color handling rules

- **Never extrapolate a color past its gamut.** `mix(gray, color, factor)` with `factor > 1` inflates the peak channel and drives the others negative — lava `(1.0, 0.4, 0.1)` at factor 1.5 becomes `(1.23, 0.33, -0.11)`, clamped to pure red with a dead blue channel, flooding whole areas in one blinding hue. Extrapolate if you want the saturation, then **rescale to the original peak** instead of letting it clip.
- **Never multiply two saturated colors to get a hue.** An orange lava texture times a blue biome tint is `(0.2, 0.3, 0.09)` — green, a hue in neither operand. The surface recolor and the light hue must use the *same* rule: chromaticity from the tint, luminance from the texture.
- **A neutral tint is not a tint.** Vanilla lava carries a white vertex color; running it through a hue swap desaturates the texture to gray. Both the surface recolor and the voxel hue gate on `tintChroma > 0.06` and fall back to the texture.
- **Luminance restoration clips.** Dividing by `luma(tintHue)` to preserve luminance exactly means a ×1.7 gain for a saturated orange, which pins the red channel at 1.0 across most of the texture and flattens the pattern. The gain is capped at 1.25.

## Things already tried and rejected

Do not re-propose these; they were implemented, tested in game and rolled back at the user's request.

- **Occlusion-aware light softening** (sampling neighbors to fill closed rooms): produced red light leaking through walls and pitch-black ceilings. Two attempted fixes failed. Rolled back; the "Block light softness" slider — a pure remap of the vanilla lightmap curve, which cannot leak — is what remains.
- **A `depthtex1` rule for Voxy LODs seen through tinted glass**: made things worse. The working fix is the per-buffer blend override `blend.gbuffers_water.colortex2=ONE ZERO ONE ZERO`, which has translucents purge the glow buffer.
- **A "Lava glow" slider**: had no measurable effect because saturated lava luma sits below the glow cutoff, so there was nothing to scale. Removed to avoid settings bloat; the fixed `bloomLevelCap` of 0.4 stays.
- **Legacy inner/middle/outer torch color sliders**: superseded by the per-block palette, removed.

## Known limitations

- Lava buried one block under the ground still tints the surface above it red. The field passes through geometry by design; accepted as a limitation of the method.
- Vertex-stage image writes need a non-zero `GL_MAX_VERTEX_IMAGE_UNIFORMS`. Fine on NVIDIA; untested elsewhere.
- Redstone ore only emits while in its lit state, which is vanilla behaviour, not a bug.

## Block id map

Colored-light groups live in `10201`–`10220` and are declared in `block.properties`, mirrored for held items in `item.properties`, and resolved to colors in `common/lightPalette.glsl`. `shadow.vsh` trusts ids in `(10200, 10221)` without a plausible mid-block offset — **extend that range when adding a new group whose geometry may lack one** (fluids), or the new id is treated as foreign geometry and discarded. Reflectivity groups use `20001`–`20017`; they must not overlap.

Glowing materials and split groups added since: `10221` sculk, `10222` redstone, `10223`/`10224` warped/crimson stems, `10225` creaking heart, `10226`–`10229` plants, `10248` spawner, `10253`–`10258` firefly bush, trial spawners, jack o'lantern, campfire, `10260` soul fire, `10261` amethyst blocks (glow, no light), `10262` enchanting table (light, no glow), `10263` beacon, `10264`–`10266` calibrated sculk sensor by phase (inactive / active / cooldown). Entities: `10304` blaze and magma cube, `10305` glow squid, `10306` allay and vex, `10307` creaking.

## Emissive masks

`common/lightPalette.glsl: getEmissiveParams` picks a model per id, `getEmissiveMask` evaluates it per texel. The mask is both the texel's self-light and its glow level. Models: hue window, lightness window, power, saturation, golden, soul, and since 1.2:

- **lightness rank** (`x = -7 - h`, `-8 - h` = vivid texels only): the lightest texels of the texture (L ≥ y) glow 100%, darker ones `rescale(L, z, y)^GLOW_CONTRAST`. `h` in the fraction gates a hue (0..0.5). y/z come from the vanilla texture's own lightness range — measure it before choosing them (copper bulbs move y/z with the oxidation light level in `textured_lit.vsh`).
- **vein** (`x = -6 - h`): nether stem veins, gated by hue, saturation and a lightness floor (bark), `NETHER_VEIN_BASE` on plain veins, 100% on the animated pulse.

Glow color for these models is taken from the **unlit** texel: the lit albedo carries the self-light, which made the glow go as mask² in the dark.
