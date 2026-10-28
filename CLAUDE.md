# Maintenance notes

Context for anyone — human or model — picking this pack up without the original development conversation. `DEVLOG.md` is the companion: every problem this fork hit, its real cause and its fix, including the dead ends. Everything below was established by reading Iris source, Iris documentation or other shaderpacks, or by a failure observed in game. Treat it as load-bearing: several of these cost multiple debugging rounds.

## Ground rules

- **Validate before shipping.** `python3 check.py` must exit 0. It compiles every program in every dimension across every option combination that changes generated code. A change that only compiles under the default options will break for someone else.
- **Verify, do not assume.** Iris behaviour is frequently undocumented and occasionally counter-intuitive. Read the Iris source or docs, or reproduce in game, before asserting a cause. Several "obvious" diagnoses in this pack's history were wrong, and each one cost a round trip.
- **The user's settings file wins.** Iris writes in-game option values to `<packname>.zip.txt` beside the pack. Changing a default in `shader.h` does nothing for an option the user has already touched. When a shipped default changes, say so explicitly.
- **A full pack reload is required** for any change to take effect — reselecting the pack in the shader menu, not just a resource reload.

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

**Entity sources must be voxelized from the vertex stage.** The flame overlay is a billboard oriented toward the *player* camera even while the shadow pass renders from the sun — Iris does not re-orient the dispatcher. From the light's point of view it can be edge-on, back-facing (this pack uses `shadow.culling=reversed`) or fully transparent, so a fragment-stage `imageStore` often never executes. `program/shadow.vsh` writes entity sources itself; terrain still writes from the fragment stage because it needs the texture for the lava hue. Bliss does the same thing for the same reason.

**`#elif` in `shaders.properties` is unverified.** Nested `#if` / `#else` / `#endif` is known to work and is what the file uses. Parenthesized boolean expressions and `defined X` do work.

## Colored light architecture

```
shadow.vsh/fsh   voxelize: palette color -> imageStore(voxelData)
                 rgb = color * sqrt(level), alpha = sqrt(level) (colorless reference)
shadowcomp.csh   flood fill: 6-neighbor average / (6.0 + 0.2/CL_FALLOFF)
                 temporal easing, THEN direct injection (x256 HDR)
getTorchColor    read both ping-pong volumes, keep the higher-alpha sample,
                 adopt hue by confidence, scale brightness by palette magnitude
```

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

Colored-light groups live in `10201`–`10220` and are declared in `block.properties`, mirrored for held items in `item.properties`, and resolved to colors in `common/lightPalette.glsl`. `shadow.vsh` trusts ids in `(10200, 10221)` without a plausible mid-block offset — **extend that range when adding a new group**, or the new id is treated as foreign geometry and discarded. Reflectivity groups use `20001`–`20017`; they must not overlap.
