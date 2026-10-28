#include "/shader.h"

attribute vec4 mc_Entity;

#ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
   attribute vec4 at_midBlock;
#endif

uniform float rainStrength;
uniform float screenBrightness;
uniform int isEyeInWater;
uniform int worldTime;
uniform vec3 sunPosition;

#ifdef HIGHLIGHT_WAXED
   uniform int heldItemId;
   uniform int heldItemId2;
#endif

flat varying float lightSourceLevel;
varying float fogMix;
varying float sunHeight;
varying vec2 lightUV;
varying vec2 texUV;
varying vec3 feetPos;
varying vec3 gradientFogColor;

#ifdef GBUFFERS_TERRAIN
   varying vec4 color;
#else
   flat varying vec4 color;
#endif

#ifdef THE_END
   varying vec3 endTint;
#endif

#if BLOCK_REFLECTIONS > 0
   flat varying vec3 blockReflectivity;
   varying vec3 normal;

   #include "/common/blockReflectivity.glsl"
#endif

#ifdef GLOWING_ORES
   flat varying float isOre;
#endif

#ifdef BLOOM
   #define BLOOM_PASS
#endif

#ifdef BLOOM_PASS
   varying float bloomDistFade;
   flat varying float bloomOverlayOk;
   flat varying float bloomCutoff;
   flat varying float bloomLevelCap;
   flat varying vec3 bloomTint;
#endif

#ifdef CL_LAVA_TEXTURE
   flat varying float lavaRecolor;
#endif

#ifdef VOXY
   varying float vanillaMix;
#endif

#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getFogMix.vsh"
#include "/common/getFogColor.vsh"
#include "/common/getViewPosition.vsh"

#ifdef ENABLE_SHADOWS
   uniform vec3 shadowLightPosition;

   varying vec3 lightColor;
   varying float diffuse;
   flat varying float shadowOpacity;

   #include "/common/getDiffuse.vsh"
   #include "/common/getLightColor.vsh"
#endif

void main() {
   gl_Position = ftransform();

   sunHeight = view2feet(sunPosition).y;
   color     = gl_Color;
   texUV     = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   lightUV   = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;

   #ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
      lightSourceLevel = at_midBlock.w < 16.0 ? at_midBlock.w / 15.0 : 0.0;
   #else
      lightSourceLevel = float(mc_Entity.x == 10068.0 || mc_Entity.x == 10072.0);
   #endif

   #ifdef THE_END
      endTint = END_AMBIENT + 0.02*(gl_NormalMatrix * gl_Normal).xyz;
   #endif

   #if BLOCK_REFLECTIONS > 0
      normal = ndc2screen(gl_Normal);
      blockReflectivity = BLOCK_REFLECTIVITY[int(max(0.0, mc_Entity.x - 20000.0))];
   #endif

   #ifndef CL_LAVA_TEXTURE
      // stylized vanilla lava: remap the vertex color toward white. MUST stay
      // disabled when following the texture/tint: resource packs (Nature X)
      // recolor lava through this very vertex tint, and the remap would crush
      // their color to near-white
      if (mc_Entity.x == 10068.0) { // lava
         color.rgb = mix(vec3(0.8, 0.5, 0.3), vec3(1.0), rescale(color.rgb, vec3(0.54), vec3(0.9)));
      }
   #endif

   #ifdef GLOWING_ORES
      // redstone ore lives in its own colored-light id (10220) but must keep
      // the ore glow: a block can only belong to ONE block.properties group
      isOre = float(mc_Entity.x == 10014.0 || mc_Entity.x == 10220.0);
   #endif

   #ifdef CL_LAVA_TEXTURE
      lavaRecolor = float(mc_Entity.x == 10068.0);
   #endif

   #ifdef HIGHLIGHT_WAXED
      color.rgb *= (heldItemId == 20007 || heldItemId2 == 20007) && mc_Entity.x == 20007.0 ? 0.4 : 1.0;
   #endif

   bool isThin = mc_Entity.x == 10031.0 || mc_Entity.x == 10059.0
              || mc_Entity.x == 10175.0 || mc_Entity.x == 10176.0
              || mc_Entity.x == 10214.0 // glow lichen (moved out of 10059 for colored light)
              || (abs(gl_Normal.y) < 0.01 && abs(abs(gl_Normal.x) - abs(gl_Normal.z)) < 0.01);

   #ifndef FLAT_LIGHTING
      vec3 lightNormal = gl_NormalMatrix * gl_Normal;

      lightNormal = isThin ? vec3(0.0, 1.0, 0.0) : view2feet(lightNormal);

      color.rgb *= clamp(lightNormal.x * lightNormal.x * 0.6
                       + lightNormal.y * lightNormal.y * 0.25 * (3.0 + lightNormal.y)
                       + lightNormal.z * lightNormal.z * 0.8, lightSourceLevel, 1.0);
   #endif

   feetPos = view2feet(getViewPosition());

   #ifdef BLOOM_PASS
      // absolute distance cap on the CLIP-SPACE depth (gl_Position.w = true
      // perspective distance): unlike attributes, matrices or uniforms, this
      // cannot be faked by any renderer - geometry drawn at the horizon must
      // have a large w or it would not rasterize at the right size. reliably
      // excludes LOD terrain (Voxy etc.); glow is subpixel out there anyway
      bloomDistFade = 1.0 - rescale(max(gl_Position.w, length(feetPos)), 96.0, 144.0);

      // fullbright-overlay glow policy:
      //   terrain  -> full strength (1.0), the overlay is an exact mask - but only
      //               for geometry with plausible mid-block data; Voxy LOD terrain
      //               fails that test and additionally gets its emission zeroed
      //   entities -> shaped by pixel brightness (0.5 marker), so emissive
      //               eyes glow but a mob standing in fullbright does not
      //   hand     -> never (0.0): dynamic hand light makes the arm fullbright
      #ifdef GBUFFERS_TERRAIN
         #ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
            if (dot(at_midBlock.xyz, at_midBlock.xyz) > 1.0
             && all(lessThan(abs(at_midBlock.xyz), vec3(40.0)))) {
               bloomOverlayOk = 1.0;
            } else {
               bloomOverlayOk = 0.0;
               lightSourceLevel = 0.0;
            }
         #elif defined VOXY
            bloomOverlayOk = 0.0;
         #else
            bloomOverlayOk = 1.0;
         #endif
      #elif defined GBUFFERS_HAND
         bloomOverlayOk = 0.0;
      #else
         bloomOverlayOk = 0.5;
      #endif

      // per-category glow pixel cutoff (Complementary-style masks): blocks whose
      // body texture is bright (lantern cage, campfire logs) need a strict cutoff
      // so only their flame pixels glow; dim-textured emitters need a lenient one
      {
         int bloomId = int(mc_Entity.x);
         float cutoff = BLOOM_PIXEL_THRESHOLD;

         // lava & magma: fixed glow cap so a retextured, uniformly BRIGHT lava
         // (high luma) glows softly instead of whiting out. note: saturated
         // dark-red lavas sit below the luma cutoff and get no surface glow
         // at all - this cap is then irrelevant for them
         bloomLevelCap = (bloomId == 10068 || bloomId == 10208) ? 0.4 : 1.0;

         // sculk sensors: their active tendrils render fullbright, which the
         // overlay path would glow at FULL strength (blinding white). route
         // them through the luma-shaped overlay (0.5 marker: only the
         // texture's light pixels - tendril tips, calibrated crystal) and cap
         if (bloomId == 10219) {
            bloomOverlayOk = min(bloomOverlayOk, 0.5);
            bloomLevelCap = 0.5;
         }

         // per-category glow tint: the copper flame texture's near-white core
         // makes its bloom read yellow - pull the halo toward the green of
         // the light it casts
         bloomTint = bloomId == 10218 ? vec3(0.5, 1.0, 0.6) : vec3(1.0);

         if (bloomId == 10201 || bloomId == 10218) cutoff += 0.2; // flame-bodied: torch,
                                     // lantern, campfire, copper torch/lantern
         else if (bloomId == 10207 || bloomId == 10213
               || (bloomId >= 10215 && bloomId <= 10217)) cutoff -= 0.1; // glowstone group,
                                     // end rod, froglights
         else if (bloomId == 10214) cutoff -= 0.15; // glow lichen: dim teal texture
         else if (bloomId == 10068 || bloomId == 10208) cutoff += 0.15; // lava, magma: the pack
                                     // brightens lava's vertex color, so only the hottest
                                     // veins should pass the pixel mask, not the whole surface
         else if (bloomId == 10209) cutoff = 9.9;   // candles: the flame is a particle,
                                                    // the block itself is just wax - no glow
         else if (bloomId == 10210 || bloomId == 10211) cutoff += 0.2; // stone-bodied emitters
                                     // (furnace, smoker, ender chest...): only the fire /
                                     // bright opening glows, never the stone body
         else if (bloomId == 10203 || bloomId == 10220) cutoff -= 0.25; // redstone torch head,
                                     // lit redstone ore: dim red emitting pixels
         else if (bloomId == 10204 || bloomId == 10206) cutoff -= 0.2;  // amethyst, portal
                                     // blocks: violet/purple pixels have low luminance
         else if (bloomId == 10212) {
            // brewing stand ("alambic"): emits only light level 1, below the emitter
            // threshold - force it so the blaze rod always glows; the default cutoff
            // masks the rod (bright gold) from the stone base by itself
            lightSourceLevel = max(lightSourceLevel, 0.5);
         }

         #ifdef GBUFFERS_HAND
            // held items have no block id; most handheld lights are flame-bodied
            cutoff = BLOOM_PIXEL_THRESHOLD + 0.2;
         #endif

         bloomCutoff = clamp(cutoff, 0.05, 10.0); // above 1.0 = never glows (candles)
      }
   #endif

   fogMix = getFogMix(feetPos);
   fogMix = mix(fogMix, fogMix*fogMix, lightSourceLevel);
   gradientFogColor = getFogColor(fogMix, feetPos, sunHeight);

   #ifdef VOXY
      // fade the pack's stylized shading back to plain vanilla over the last
      // stretch before the render distance, so the handoff to Voxy's
      // vanilla-shaded LOD terrain has no visible brightness/hue seam
      // (same mechanism the pack already used for water)
      vanillaMix = calcFogMix(feetPos, 0.3, far);
   #endif

   #ifdef ENABLE_SHADOWS
      float skyLight = clamp(lightUV.t, 0.0, 1.0);

      diffuse = getDiffuse(sunHeight, skyLight, isThin);
      lightColor = getLightColor(sunHeight, skyLight);

      // time-of-day shadow opacity: day shadows at half the slider's darkness,
      // night (moon) shadows much fainter; narrow blend masks the sun/moon swap
      shadowOpacity = mix(NIGHT_SHADOW, DAY_SHADOW, clamp(rescale(sunHeight, -3.0, 3.0), 0.0, 1.0));
   #endif
}