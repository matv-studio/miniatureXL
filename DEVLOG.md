# Development log

Every problem this fork hit, what caused it, and what fixed it. Written for whoever (or whatever) picks the pack up next, so the same ground is not re-covered. `CLAUDE.md` holds the resulting rules in condensed form; this file holds the reasoning and the dead ends.

Entries are grouped by subsystem rather than by date. Within each, the format is: **symptom as reported** → what was wrong about the first diagnosis, if anything → the actual cause → the fix.

---

## 0. Working context

- **Environment**: Minecraft 1.21.11, Iris 1.10.7, Voxy 0.2.16-beta, LambDynamicLights, Nature X resource pack (recolors lava through the biome tint), RTX 4090.
- **Base**: Miniature Shader 2.19 by Mateus A. Kreuch, MIT. The fork keeps the licence and lists its modifications in `LICENSE`.
- **Testing loop**: the pack was validated offline with `check.py`, zipped, and tested in game by the user, who reported back with screenshots. Nothing below was confirmed any other way — there is no automated visual test.

Two process lessons, both learned by paying for them:

- **Screenshots settle arguments that words do not.** "The copper lantern's emitted light is still yellow" was read as a colored-light palette problem for two rounds. A screenshot of two floating lanterns showed the yellow was the *bloom halo*, which takes its color from the flame texture and never touches the palette. Different subsystem, different fix.
- **State the mechanism, not the conclusion.** Several diagnoses below were confidently wrong. The ones that held up were the ones where the arithmetic was worked out explicitly (channel values, luma weights, gain factors) before any file was edited.

---

## 1. The colored light engine

### 1.1 Nothing emitted any colored light at all

**Reported**: "Well now i don't see any colored light", then "Toujours pas" with a full `latest.log`.

**First diagnosis — wrong**: suspected `#elif` in `shaders.properties`, which the preprocessor documentation does not clearly guarantee. It was rewritten to nested `#if`/`#else`. No effect.

**Actual cause**, visible in the log: `NumberFormatException` from Iris's `ComputeDirectiveParser`. Iris reads `const ivec3 workGroups = ivec3(...)` **textually, before preprocessing**, and calls `Integer.parseInt` on the characters between the commas. `ivec3(VOXEL_SIZE / 8, ...)` is not a number. The pack failed to load with no usable in-game message.

**Fix**: per-`VOXEL_SIZE` `#if` branches in `program/shadowcomp.csh`, each declaring `workGroups` with bare integer literals. `check.py` now asserts this with a regex so it cannot regress.

### 1.2 The light cycled between the source color and warm white

**Reported**: "i still see it yellowish, it cycles between yellow and white".

**Cause**: the two voxel volumes are ping-ponged by frame parity, and the reader picked its volume by the same parity. When the compute cadence drifts from the render loop (driver or Iris scheduling), a parity read alternates between a fresh and a stale volume, so the light pulses between its real hue and the default warm fallback.

**Fix**: read **both** volumes and keep the sample with the higher alpha. At steady state they hold the same converged field, so this costs one extra sample and is immune to cadence drift.

### 1.3 The Nether had no colored light even though everything compiled

**Cause**: Iris skips rendering a dimension's shadow pass when nothing in that dimension samples the shadow map. The Nether and End cast no shadows, so the pass — which is the pack's voxelizer — never ran.

**Fix**: an invisible tap in `program/textured_lit.fsh` for non-Overworld dimensions:

```glsl
albedo.rgb += texture2D(shadowcolor0, vec2(0.5)).rgb * 1.0e-6;
```

The contribution cannot be folded away by the compiler, so the sampler stays live and Iris keeps the pass. The End got the same treatment afterwards for consistency.

### 1.4 A hard edge where a light's tint stopped

**Reported**: "there is a clean separation line from where the lichen emmits and where it stops".

**Cause**: the brightness scaling from the palette magnitude used a step-like weight, so the transition landed in one block.

**Fix**: a dedicated `dimWeight` using a fourth root of the field reference, which spreads the transition over roughly four blocks — the same pace at which the source's own vanilla light dies out, so no seam is visible.

### 1.5 A yellow ring around green sources

**Reported**: "when i said still a yellowish color it was about the copper lanterns" — after the lanterns were already mapped correctly.

**Cause**: between the warm default gradient and the source hue there is a partial-mix band. Orange × green reads as **yellow** — a third color the eye picks out immediately as a ring.

**Fix**: tighten the hue confidence window (upper bound 0.004 → 0.002) and steepen the adoption curve to `pow(hueConfidence, 0.6)`, squeezing that band thin.

### 1.6 Moving lights were drowned out by the static field

**Reported**: "when lighting a mob on fire it emmits the nearby light color instead of the fire orange color. Same for handheld light".

**Cause**: in `shadowcomp.csh` the direct source injection ran **before** the temporal filter (`CL_TRANSITION`, default 0.1). A cell therefore reached only 10 % of a source's value per frame, and needed ~10 frames in the same cell to converge. A light that moves every frame — a burning mob, a dropped item, the player's own held light — never gets there, so the surrounding static field wins.

**Fix**: move the injection **after** the temporal mix. A cell that contains a source holds its full value on the first frame; the propagated neighbourhood still eases in and out, which is what the setting was for.

### 1.7 Burning mobs still emitted nothing

**Reported**: "strictement rien ne change", with a screenshot showing Minecraft's **Entity Shadows** option enabled.

This one needed an audit of the Iris source before it moved. Two independent causes:

**Cause A — the pack switched entities off itself.** `shaders.properties` only set `shadowEntities=true` when the pack's own *Entity shadows* option (`SHADOW_ENTITY`) was ≥ 1. The NORMAL profile sets it to 0. Minecraft's video option of the same name is unrelated and does not control that directive. With `shadowEntities=false`, Iris renders no entities in the shadow pass — the only pass that gives a light source's world position — so no entity could ever emit. This also explains an earlier unresolved report that dropped items emitted no light.

**Cause B — the write was in the wrong stage.** The fire overlay on a burning entity is a billboard oriented toward the **player** camera; Iris does not re-orient the dispatcher for the shadow view (`FlameFeatureRenderer` runs after `cameraOrientation()` is set). From the sun's point of view the quad can be edge-on, back-facing (this pack uses `shadow.culling=reversed`) or fully transparent, producing no fragments — and the `imageStore` lived in the fragment shader.

**Fix**: force `shadowEntities` / `shadowBlockEntities` / `shadowPlayer` on whenever `CL_ENTITY_LIGHT` or `CL_ITEM_LIGHT` is active, and move the voxel write for entity sources into `shadow.vsh`, which runs regardless of what the rasterizer does. Terrain still writes from the fragment stage because it needs the texture for the lava hue. Confirmed working in game.

**Verified during that audit**, in case it is doubted again: `minecraft:entity_flame` is a genuine hardcoded Iris identifier; `entityId` and `currentRenderedItemId` *are* available in the shadow pass (Iris rewrites them into the `iris_Entity` vertex attribute); and Bliss uses exactly this shadow-pass + vertex-stage pattern for the same purpose, while Photon explicitly excludes entities and Complementary voxelizes terrain only.

### 1.8 Rejected: occlusion-aware softening for closed rooms

**Asked**: sources did not light closed rooms convincingly; could neighbouring lights be sampled and averaged?

**Built, then rolled back.** The experiment produced red light leaking through walls and pitch-black ceilings. Two attempted corrections failed. On the user's instruction the behaviour was reverted while keeping the sliders.

**What remains** is the *Block light softness* slider: an exponent applied to the vanilla lightmap value. It lifts the low end of the curve and smooths the taxicab steps, and because it is a pure remap of vanilla data, light can never appear where Minecraft has none — no leaking is structurally possible.

---

## 2. Color handling

Three separate bugs, one underlying theme: **naive color arithmetic produces hues that exist in none of its inputs.**

### 2.1 Nature X lava rendered white-mint instead of cyan

**Cause**: the base pack remaps lava's **vertex color** toward white as a stylistic choice. Resource packs recolor lava through that exact vertex tint, so the remap crushed the pack's color.

**Fix**: disable the remap when `CL_LAVA_TEXTURE` is on.

### 2.2 Then the lava blew out to a flat sheet

**Reported**: "it worked ! but now i can't really see the texture in the original lava, everything is so orange and uniform".

**Cause**: the recolor restored luminance exactly by dividing by `luma(tintHue)`. For a saturated orange that is 0.577 under Rec.601 weights (0.299 R, 0.587 G, 0.114 B) — a ×1.73 gain. A lava texture with luma up to ~0.65 then lands at 1.13 in the red channel, clipped to 1.0 across most of the surface. Clipping a channel is what flattens the pattern. Cyan tints clipped later (luma ≈ 0.72, gain ×1.39), which is why cyan looked acceptable and orange did not.

**Fix**: cap the gain at ×1.25. No channel saturates, the full texture pattern survives.

### 2.3 Vanilla lava turned gray when Nature X was disabled

**Cause**: vanilla lava carries a **white** vertex color. A white tint through a hue swap is `vec3(1) × luma(texture)` — pure gray.

**Fix**: a chroma gate. The recolor only runs when the tint actually carries chroma (`max − min > 0.06`); otherwise the texture keeps its own colors.

### 2.4 Soul-sand-valley lava was green instead of blue

**Cause**: `shadow.fsh` computed the *light* color as `albedo.rgb * voxelTint` — an orange texture (1.0, 0.5, 0.1) times a blue tint (0.2, 0.6, 0.9) gives (0.20, 0.30, 0.09), which normalizes to **green**. Meanwhile the *surface* had already been switched to the luminance-preserving rule and was going blue. The surface was then multiplied by the green light it supposedly emitted, and the result read green.

**Fix**: apply the same rule in both files — chromaticity from the tint when it has chroma, from the texture when it does not.

### 2.5 Everything flooded in one blinding hue

**Reported**: "la lave reste bcp trop brillante", with a screenshot of terrain washed uniform red.

**Cause**: the saturation step was `mix(vec3(luma), torchColor, 0.5 + 0.5 * COLORED_LIGHT_STRENGTH)`. At the user's strength of 2.0 the factor is **1.5** — extrapolation, not interpolation. Lava (1.0, 0.4, 0.1) becomes (1.227, 0.328, −0.108): red over range, blue clamped to zero. That is the flood.

**First fix — too blunt**: capping the factor at 1.0. It removed the overflow but also removed the saturation the user wanted, and green and cyan sources visibly lost their presence.

**Final fix**: keep the extrapolation, then **rescale the result to the color's original peak** instead of letting it clip. Lava becomes (1.0, 0.27, 0.0): same hue purity, no brightness overflow.

---

## 3. Block and entity identification

### 3.1 Copper lanterns emitted the default warm color when placed, green when held

**First diagnosis — incomplete**: the eight oxidation and waxed variants were missing from `block.properties`. They were added (verified against the wiki). Still wrong.

**Second diagnosis — wrong subsystem**: a screenshot proved the remaining yellow was the *bloom halo*, not the light. The halo takes its color from the flame texture, whose core is near-white. A per-category `bloomTint` was added, multiplying id 10218's halo toward green.

**Actual cause of the placed-vs-held split**: copper lanterns were *also* listed in the copper reflectivity group `block.20008`, inherited from the base pack. **A block may appear in only one `block.properties` group** — entries apply top to bottom and the later one overwrites the earlier as if it never existed. The reflectivity group won, so placed lanterns reached the voxelizer with an unrecognized id. Held items go through `item.properties`, where there was no conflict, which is exactly why in-hand was green and placed was not.

**Fix**: remove the lanterns from the reflectivity group. They lose a specular property invisible at that block size. `check.py` now asserts group uniqueness across the whole file.

### 3.2 Redstone ore emitted no red light

**Cause**: the same conflict in a different costume. `redstone_ore` and `deepslate_redstone_ore` existed only in `block.10014`, the glowing-ores group, which has no palette entry.

**Fix**: a dedicated id `10220` with `CL_REDSTONE`, and `isOre` extended to accept it so the ore glow survives. The trusted id range in `shadow.vsh` was widened to `(10200, 10221)` — **forget that step and a new id is discarded as foreign geometry.**

### 3.3 Emissive white quartz took the hue of nearby lights

**Cause**: resource-pack emissive overlays are self-lit but were being multiplied by the ambient, which carries the local light's hue.

**Fix**: for pixels matching the overlay mask (fullbright lightmap on a non-emitting block), neutralize the ambient's hue at identical peak brightness.

---

## 4. Voxy (LOD terrain) compatibility

### 4.1 LOD terrain glowed when seen through tinted glass

**Reported**: regular glass fine, tinted glass glowing — with sky glow and texture-pack emissives both off.

**Fix that worked**: a per-buffer blend override so translucents purge the glow buffer rather than adding to it:

```
blend.gbuffers_water.colortex2=ONE ZERO ONE ZERO
```

**Then broken by a "refinement"**: a follow-up change using `depthtex1` made it worse. The user's call — "i made a mistake the previous iteration v48 worked" — was correct; it was reverted exactly. Noted here because the refinement looked principled and was not.

### 4.2 A visible brightness seam at the LOD boundary

**Cause**: Voxy renders its LOD terrain with plain vanilla shading, while the pack applies shadows, sun color, sky tints and Nether grading. The step was visible at every time of day.

**Fix**: capture the vanilla reference (`albedo × AO × lightmap`) early in the fragment shader and blend toward it over the last stretch before the render distance, using the same fog-mix mechanism the pack already used for water. All the pack's stylization fades out together, so the handoff carries no step at any hour.

---

## 5. Shadows

**Reported**: "why is there no shadow when sunrise/dusk/noon", then "je veux même garder les ombres à 100% pendant le jour, pendant la nuit je veux une ombre de très faible intensité", then "shadow darkness at .5 is way too dark at daytime".

The base pack faded shadow *strength* with the sun's height. Removing that fade gave full-strength shadows all day but made them far too dark at the user's preferred darkness setting.

**Fix**: separate strength from opacity. `getDiffuse`'s day/night fade is gone; instead a flat varying carries a time-of-day **opacity** (`DAY_SHADOW 0.5`, `NIGHT_SHADOW 0.2`, blended over the sun-height range −3…3) applied to the darkening itself:

```glsl
ambient.rgb *= mix(mix(vec3(1.0), SHADOW_COLOR, shadowOpacity), vec3(1.0), lightStrength);
```

Lit areas keep full brightness; only how dark a shadow gets is scaled. The user's framing — "let's cheat this" — is accurate: it is not physical, it matches a preference.

---

## 6. Bloom

- **Per-category pixel cutoffs** decide which pixels of an emitting block glow. Bright-bodied emitters (lantern cage, campfire logs) need a strict cutoff so only flame pixels pass; dim-textured ones (redstone torch, amethyst, portal) need a lenient one.
- **The glow ceiling must be applied after every glow path** (emitter, overlay, ores), or a `max()` in a later path jumps over it.
- **A "Lava glow" slider was built and removed.** It had no measurable effect because saturated lava luma sits *below* the cutoff — there was no glow to scale. Removed rather than kept as dead UI, per the user's instruction to avoid settings bloat. The fixed cap of 0.4 stays, for retextured lavas that are uniformly bright.
- **Sculk sensors** render their active tendrils fullbright, which the overlay path would glow at full strength (blinding white). They are routed through the luma-shaped overlay instead and capped.

---

## 7. Accepted limitations

- **Lava buried one block below the surface tints the ground above it red.** The flood-filled field passes through geometry by design. The user accepted this ("ok its fine") rather than pay the cost of occlusion.
- **Vertex-stage image writes** need a non-zero `GL_MAX_VERTEX_IMAGE_UNIFORMS`. Fine on NVIDIA, untested elsewhere.
- **Redstone ore only emits while lit** — vanilla behaviour, not a bug.
- **`check.py` uses two shims** that do not reflect the real driver: `flat varying` is downgraded (glslang rejects it in strict GLSL 120, drivers accept it) and `imageStore` is stubbed out (same situation). Both are annotated in the file. It validates syntax and declarations, not linking or runtime behaviour.

---

## 8. Settings persistence — the recurring false alarm

Three separate times, a change "did not work" because **Iris stores the player's in-game option values in `<packname>.zip.txt` next to the pack, and those override the pack's defaults.** A new default in `shader.h` does nothing for an option the user has already touched. Renaming the zip orphans the settings file and resets everything.

Once, a missing menu entry was simply a stale zip still loaded in game.

Before diagnosing "the change had no effect", confirm the pack was fully reloaded (reselected in the shader menu) and that the option in question is not pinned in that file.

---

## 9. Repository setup

The pack was developed in an ephemeral cloud container; after a period of inactivity the container was reclaimed and **every working file was lost**. The only surviving copy was the zip already downloaded by the user. The repository was rebuilt from it.

Pushing from that session was then blocked by a policy, not a credential problem:

```
access denied by the git proxy: matv-studio/miniatureXL is not in this
session's authorized repository set
```

The GitHub API answers `sessions are bound to their configured repositories` — the binding is fixed when a session is created, and a session started against a project rather than a repository cannot acquire one afterwards. The commit was handed over as an archive for the user to push.

**Two conclusions worth keeping**: commit early rather than relying on a session's filesystem, and start sessions that will touch this pack **from the repository**, which avoids the whole problem.

**Resolved later**: a subsequent session attached the repository to itself (`add_repo` with push access) and pushed the archived history unchanged, plus the README screenshots taken from the Modrinth gallery (`docs/images/`, converted from PNG to JPEG to keep the clone small). From then on every change is pushed to `main`.

---

## 10. Where things stood at the last in-game test

Confirmed working by the user: colored light in all three dimensions; entity, item and burning-mob lights; copper torches and lanterns; froglights; sculk sensors; the Voxy tinted-glass fix and seam matching; day/night shadow opacity; lava following Nature X.

Shipped but awaiting a report: the soul-sand-valley lava hue alignment (§2.4) and the saturation rescale (§2.5), both delivered in the final zip.
