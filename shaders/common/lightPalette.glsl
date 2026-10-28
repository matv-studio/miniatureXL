// shared block/item id -> colored light palette (ids from block.properties /
// item.properties; colors configurable in the Light colors settings screen)
vec3 getLightPaletteColor(int id) {
   if (id == 10201 || id == 10072 || id == 10209 || id == 10210 || id == 10212) return CL_FLAME;
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
   if (id == 10219) return vec3(0.25, 0.95, 1.0);  // sculk sensors: cyan tendrils

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
