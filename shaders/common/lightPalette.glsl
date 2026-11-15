#ifndef LIGHT_PALETTE_INCLUDED
#define LIGHT_PALETTE_INCLUDED

// shared block/item id -> colored light palette (ids from block.properties /
// item.properties; colors configurable in the Light colors settings screen)
vec3 getLightPaletteColor(int id) {
   if (id == 10201 || id == 10072 || id == 10209 || id == 10210 || id == 10212 || id == 10257 || id == 10258) return CL_FLAME;
   if (id == 10211) return CL_PORTAL;
   if (id == 10202) return CL_SOUL;
   if (id == 10068 || id == 10208) return CL_LAVA;
   if (id == 10203 || id == 10220) return CL_REDSTONE; // torch/lamp, lit ore
   if (id == 10204) return CL_AMETHYST;
   if (id == 10205) return CL_SEA;
   if (id == 10206) return CL_PORTAL;
   if (id == 10207) return CL_GLOW;
   if (id == 10213) return CL_ROD;  // end rod (white by default)
   if (id == 10214) return CL_LICHEN; // glow lichen (own setting, blue-cyan default)

   // fixed colors matching the vanilla textures (no settings, by design)
   if (id == 10215) return vec3(1.0, 0.85, 0.4);   // ochre froglight: yellow
   if (id == 10216) return vec3(0.55, 1.0, 0.5);   // verdant froglight: green
   if (id == 10217) return vec3(1.0, 0.7, 0.95);   // pearlescent froglight: purple-pink
   if (id == 10218) return vec3(0.4, 1.0, 0.55);   // copper torch & lantern: green flame
   if (id == 10219 || id == 10221) return vec3(0.25, 0.95, 1.0); // sculk: cyan
   if (id == 10222) return CL_REDSTONE;              // redstone block, powered components
   if (id == 10223) return vec3(0.3, 0.95, 0.85);   // warped stems: teal veins
   if (id == 10224) return vec3(1.0, 0.35, 0.15);   // crimson stems: red-orange veins
   if (id == 10225 || id == 10226) return vec3(1.0, 0.6, 0.25); // creaking heart, eyeblossom
   if (id == 10227) return vec3(1.0, 0.7, 0.35);    // glow berries
   if (id == 10228) return vec3(1.0, 0.55, 0.3);    // nether fungi, torchflower
   if (id == 10248) return vec3(0.9, 0.35, 0.8);    // spawner: pink glow
   if (id == 10253) return vec3(1.0, 0.95, 0.6);    // firefly bush: pale yellow
   if (id == 10254) return CL_FLAME;                 // trial spawner, vault
   if (id == 10255) return CL_SOUL;                  // ominous trial spawner, vault

   return CL_DEFAULT;
}

// nominal emission level (vanilla light level / 15) per palette id - used
// where the vertex attribute is unavailable or unreliable: block entities
// (animating chest lid), dropped items, item frames, held-by-entity items.
// ids that only sometimes emit (candles 10209, furnaces 10210, redstone
// torch 10203 when placed) return values used ONLY on carried/entity paths,
// never to force placed-but-unlit blocks on
float getLightPaletteLevel(int id) {
   if (id == 10068) return 1.0;   // lava bucket
   if (id == 10201) return 0.93;  // torch group (14)
   if (id == 10257) return 1.0;   // jack o'lantern (15)
   if (id == 10258) return 1.0;   // campfire (15)
   if (id == 10202) return 0.67;  // soul group (10)
   if (id == 10203) return 0.5;   // redstone torch (7)
   if (id == 10204) return 0.35;  // amethyst (5)
   if (id == 10205) return 1.0;   // sea lantern (15)
   if (id == 10206) return 0.67;  // crying obsidian (10)
   if (id == 10207) return 1.0;   // glowstone group (15)
   if (id == 10208) return 0.6;   // magma
   if (id == 10211) return 0.47;  // ender chest (7)
   if (id == 10212) return 0.3;   // brewing stand (1, raised above the junk threshold)
   if (id == 10213) return 0.93;  // end rod (14)
   if (id == 10214) return 0.47;  // glow lichen (7)
   if (id == 10215 || id == 10216 || id == 10217) return 1.0; // froglights (15)
   if (id == 10218) return 0.93;  // copper torch / lantern (14)

   return 0.0;
}

// light transmission of tinted blocks for the propagation volume: stained
// glass (10231 white ... 10246 black, dye colors) and leaves (10247, dimmed)
vec3 getLightTint(int id) {
   if (id == 10231) return vec3(0.95, 0.95, 0.95); // white
   if (id == 10232) return vec3(1.0, 0.55, 0.15);  // orange
   if (id == 10233) return vec3(0.85, 0.3, 0.85);  // magenta
   if (id == 10234) return vec3(0.45, 0.7, 1.0);   // light blue
   if (id == 10235) return vec3(1.0, 0.95, 0.25);  // yellow
   if (id == 10236) return vec3(0.55, 0.95, 0.2);  // lime
   if (id == 10237) return vec3(1.0, 0.6, 0.75);   // pink
   if (id == 10238) return vec3(0.4, 0.4, 0.4);    // gray
   if (id == 10239) return vec3(0.7, 0.7, 0.7);    // light gray
   if (id == 10240) return vec3(0.2, 0.7, 0.75);   // cyan
   if (id == 10241) return vec3(0.55, 0.25, 0.85); // purple
   if (id == 10242) return vec3(0.25, 0.3, 0.9);   // blue
   if (id == 10243) return vec3(0.55, 0.35, 0.2);  // brown
   if (id == 10244) return vec3(0.35, 0.55, 0.15); // green
   if (id == 10245) return vec3(0.85, 0.2, 0.2);   // red
   if (id == 10246) return vec3(0.12, 0.12, 0.12); // black
   return vec3(0.75);                              // leaves
}

// minimum light level (/15) a block feeds the colored light volume with, on
// top of its vanilla emission: materials that glow without (or with almost
// no) vanilla light. relative strengths follow Photon's light table
float getLightEmitFloor(int id) {
   if (id == 10204) return 0.33;                  // amethyst buds & clusters
   if (id == 10212) return 0.27;                  // brewing stand (vanilla 1)
   if (id == 10211) return 0.2;                   // end portal frame (vanilla 1)
   if (id == 10219 || id == 10221) return 0.2;    // sculk
   if (id == 10222) return 0.2;                   // redstone components
   if (id == 10223 || id == 10224) return 0.13;   // nether stems
   if (id == 10225) return 0.33;                  // awake creaking heart
   if (id == 10226) return 0.2;                   // open eyeblossom
   if (id == 10228) return 0.27;                  // nether fungi, torchflower
   if (id == 10248) return 0.17;                  // spawner
   return 0.0;
}

// emissive texels: which texels of a light source's texture shine on their
// own (self-lit, full brightness in the dark) and glow - one model per light
// category, after Photon's hardcoded emission (same texel selections; our
// strengths are higher because Miniature has no HDR: 0.2 in Photon still
// reads bright there). L = HSL lightness of the texel.
//   x >= 0   hue mode: x = hue (0..1), y = hue half-width, z = minimum L
//   x = -1   window:   ramp of L from z to y (flame and filament texels)
//   x = -2   power:    L^y (whole texture, brightest most; no floor, so the
//                      dark texels of a light do not glow)
//   x = -3   saturation: ramp of HSL saturation from z to y (any hue)
//   x = -4   golden: ramp of 0.2 S + 0.55 L from z to y (Photon)
//   x = -5   soul: ramp of (cyan hue match + L) from z to y (Photon)
//   w        strength (0 = not emissive)
vec4 getEmissiveParams(int id) {
   if (id == 10218) return vec4(-1.0, 0.82, 0.62, 0.95);   // copper torch, lantern: flame core
   if (id == 10201) return vec4(-1.0, 0.82, 0.62, 0.95);   // torch, lantern: flame core
   // campfire: its orange flame too (L ~0.55 -> glow 0.5), never the logs
   // (log ends reach L ~0.5: below 0.52 nothing glows)
   if (id == 10258) return vec4(-1.0, 0.565, 0.52, 0.95);
   if (id == 10257) return vec4(-1.0, 0.85, 0.65, 0.95);   // jack o'lantern: the lit carved face, not the orange skin
   if (id == 10202) return vec4(-5.0, 0.95, 0.7, 0.85);    // soul lights: cyan flame and its white core
   if (id == 10203 || id == 10220) return vec4(0.0, 0.05, 0.35, 0.7); // redstone torch, lit ore
   if (id == 10204) return vec4(-1.0, 0.9, 0.7, 0.55);     // amethyst: the light facets only
   if (id == 10205) return vec4(-2.0, 3.0, 0.0, 1.0);      // sea lantern, sea pickle, conduit
   if (id == 10206) return vec4(0.83, 0.14, 0.2, 0.85);    // crying obsidian, portal: purple-pink
   if (id == 10207) return vec4(-1.0, 0.8, 0.6, 0.9);      // glowstone, lamp, shroomlight, beacon: bright filament
   if (id == 10208) return vec4(-2.0, 3.0, 0.0, 0.75);     // magma
   if (id == 10072) return vec4(-1.0, 0.45, 0.2, 0.9);     // fire: every flame texel (Photon: whole texture)
   if (id == 10068) return vec4(-2.0, 2.0, 0.0, 0.9);      // lava: by lightness, so recolored lava (Nature X) glows too
   if (id == 10210) return vec4(-1.0, 0.82, 0.62, 0.9);    // lit furnaces: fire opening
   if (id == 10211) return vec4(0.4, 0.14, 0.2, 0.6);      // end portal frame: green eye
   if (id == 10212) return vec4(0.11, 0.07, 0.45, 0.9);    // brewing stand: blaze rod (yellow-orange)
   if (id == 10213) return vec4(-1.0, 0.9, 0.75, 0.85);    // end rod
   if (id == 10214) return vec4(-1.0, 0.8, 0.55, 0.55);    // glow lichen: its light specks
   if (id >= 10215 && id <= 10217) return vec4(-2.0, 3.0, 0.0, 0.7); // froglights
   if (id == 10219 || id == 10221) return vec4(0.55, 0.11, 0.5, 0.7);  // sculk: cyan specks
   if (id == 10222) return vec4(0.0, 0.05, 0.35, 0.6);     // redstone: lit red
   if (id == 10223) return vec4(0.555, 0.17, 0.05, 0.75);  // warped stems: blue-teal veins, dark ones too
   if (id == 10224) return vec4(-1.0, 0.5, 0.33, 0.75);    // crimson stems: the lighter veins
   if (id == 10229) return vec4(-2.0, 4.0, 0.0, 0.45);     // chorus plant & flower: brightest texels
   if (id == 10253) return vec4(-1.0, 0.92, 0.8, 0.9);     // firefly bush: the fireflies only
   if (id == 10254 || id == 10255) return vec4(-1.0, 0.85, 0.62, 0.85); // trial spawner, vault: flame and keyhole
   if (id == 10304) return vec4(-1.0, 0.8, 0.55, 0.85);    // blaze, magma cube (entity): hot parts
   if (id == 10305) return vec4(-1.0, 0.75, 0.45, 0.85);   // glow squid (entity): glowing spots
   if (id == 10225) return vec4(-4.0, 0.55, 0.35, 0.85);   // creaking heart: its orange veins (Photon golden mask, lowered 0.05)
   if (id == 10226) return vec4(-3.0, 0.6, 0.4, 0.9);      // open eyeblossom: every vivid texel (Photon)
   if (id == 10227) return vec4(0.09, 0.06, 0.45, 0.8);    // glow berries
   if (id == 10228) return vec4(-1.0, 0.7, 0.6, 0.8);      // nether fungi, torchflower
   if (id == 10248) return vec4(0.86, 0.14, 0.25, 0.75);   // spawner: pink glow
   if (id == 10306) return vec4(-1.0, 0.7, 0.3, 0.9);      // allay (entity): its light body
   // copper bulbs share the copper block groups (reflections, waxed
   // highlight); the emission gate in textured_lit.vsh keeps unlit bulbs
   // and every copper block at 0 - only a lit bulb's bright core glows
   if (id == 20007 || id == 20008) return vec4(-1.0, 0.88, 0.68, 0.9);
   return vec4(0.0);
}

// how far past 1.0 an emissive texel's self-light goes (HDR): 1.0 for the
// colored body of a glowing texture, up to EMISSIVE_BOOST for its hottest
// texels (HSL lightness 0.7 -> 0.95)
float emissiveHeat(vec3 texel) {
   float lightness = 0.5 * (max(texel.r, max(texel.g, texel.b)) + min(texel.r, min(texel.g, texel.b)));
   return 1.0 + (EMISSIVE_BOOST - 1.0) * smoothe(rescale(lightness, 0.7, 0.95));
}

// halo amount by category (0..1): how much glow a material spreads AROUND
// itself. its own glowing texels always glow fully; large emissive surfaces
// spread less, their halo sums over a whole face
float getEmissiveGlow(int id) {
   if (id == 10207 || id == 10205 || id == 10208 || id == 10225) return 0.8; // glowstone, lamp, sea lantern, magma
   if (id >= 10215 && id <= 10217) return 0.8;   // froglights
   if (id == 20007 || id == 20008) return 0.8;   // lit copper bulbs
   if (id == 10254 || id == 10255) return 0.8;   // trial spawner, vault
   if (id == 10223 || id == 10224) return 1.0;   // nether stems (glow x2, user tuning)
   if (id == 10221 || id == 10229) return 0.8;   // sculk, chorus
   return 1.0;
}

// per-category glow strength sliders (Glow > Glow per block). id: block or
// entity group; emitting: the block is a light source without a category
float getGlowScale(int id, bool emitting) {
   if (id == 10201 || id == 10218 || id == 10209 || id == 10210 || id == 10257 || id == 10258) return GLOW_FLAMES;
   if (id == 10202) return GLOW_SOUL;
   if (id == 10068 || id == 10208 || id == 10072) return GLOW_LAVA;
   if (id == 10203 || id == 10220 || id == 10222) return GLOW_REDSTONE;
   if (id == 10207) return GLOW_LAMPS;
   if (id == 10205) return GLOW_SEA;
   if (id >= 10215 && id <= 10217) return GLOW_FROGLIGHTS;
   if (id == 10204) return GLOW_AMETHYST;
   if (id == 10213) return GLOW_END_ROD;
   if (id == 10206 || id == 10211) return GLOW_PORTALS;
   if (id == 10219 || id == 10221) return GLOW_SCULK;
   if (id == 10223 || id == 10224) return GLOW_STEMS;
   if (id == 10214 || (id >= 10226 && id <= 10229) || id == 10253) return GLOW_PLANTS;
   if (id == 10212) return GLOW_BREWING;
   if (id == 10225 || id == 10248 || id == 10254 || id == 10255) return GLOW_MISC;
   if (id >= 10301 && id <= 10399) return GLOW_MOBS;
   return emitting ? GLOW_OTHER : 1.0;
}

// emissive mask of one texel (0..1, already scaled by strength)
float getEmissiveMask(vec3 texel, vec4 params) {
   if (params.w <= 0.0) return 0.0;

   float peak = max(texel.r, max(texel.g, texel.b));
   float low = min(texel.r, min(texel.g, texel.b));
   float lightness = 0.5 * (peak + low);

   if (params.x < -4.5) {
      // soul mode (Photon's soul lights): cyan hue OR sheer lightness - the
      // flame is cyan at its rim and near-white in its core; the hue mode
      // alone required saturation and left the white core dark
      float chroma5 = peak - low;
      float hue5 = 0.0;
      if (chroma5 > 1.0e-2) {
         if (peak == texel.r)      hue5 = mod((texel.g - texel.b) / chroma5, 6.0) / 6.0;
         else if (peak == texel.g) hue5 = ((texel.b - texel.r) / chroma5 + 2.0) / 6.0;
         else                      hue5 = ((texel.r - texel.g) / chroma5 + 4.0) / 6.0;
      }
      float cyan = chroma5 > 1.0e-2 ? 1.0 - clamp(abs(fract(hue5 - 0.556 + 0.5) - 0.5) / 0.0833, 0.0, 1.0) : 0.0;
      return params.w * smoothe(rescale(cyan + lightness, params.z, params.y));
   }

   if (params.x < -3.5) {
      // golden mode (Photon's "strong golden light": creaking heart):
      // a blend of saturation and lightness, so saturated orange veins of
      // medium lightness qualify, dull bark of the same lightness not
      float hslSat = (peak - low) / max(1.0 - abs(2.0 * lightness - 1.0), 1.0e-4);
      return params.w * smoothe(rescale(0.2 * hslSat + 0.55 * lightness, params.z, params.y));
   }

   if (params.x < -2.5) {
      // saturation mode (Photon's open eyeblossom): every vivid texel, any
      // hue - the petals and the glowing center, not the gray-green leaves
      float hslSaturation = (peak - low) / max(1.0 - abs(2.0 * lightness - 1.0), 1.0e-4);
      return params.w * smoothe(rescale(hslSaturation, params.z, params.y));
   }

   if (params.x < -1.5) {
      return params.w * pow(lightness, params.y);
   }

   if (params.x < 0.0) {
      return params.w * smoothe(rescale(lightness, params.z, params.y));
   }

   float chroma = peak - low;
   float saturation = chroma / max(peak, 1.0e-4);

   // hue in 0..1 (hexagonal approximation)
   float hue = 0.0;
   if (chroma > 1.0e-4) {
      if (peak == texel.r)      hue = mod((texel.g - texel.b) / chroma, 6.0) / 6.0;
      else if (peak == texel.g) hue = ((texel.b - texel.r) / chroma + 2.0) / 6.0;
      else                      hue = ((texel.r - texel.g) / chroma + 4.0) / 6.0;
   }

   float hueDistance = abs(fract(hue - params.x + 0.5) - 0.5);

   return params.w
        * (1.0 - rescale(hueDistance, 0.5 * params.y, params.y))
        * rescale(saturation, 0.2, 0.45)
        * rescale(lightness, params.z, params.z + 0.15);
}

#endif
