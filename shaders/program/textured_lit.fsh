#include "/shader.h"

uniform float screenBrightness;
uniform int entityId;
uniform ivec2 eyeBrightnessSmooth;
uniform sampler2D gtexture;
uniform sampler2D lightmap;
uniform vec4 entityColor;

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

#if HAND_DYNAMIC_LIGHTING == 0
   uniform int heldBlockLightValue;
#elif HAND_DYNAMIC_LIGHTING == 1
   #define heldBlockLightValue 14
#endif

#if defined COLORED_LIGHT_ACTIVE && !defined OVERWORLD
   // the Nether and End cast no shadows, so nothing there samples the shadow
   // map - and Iris SKIPS rendering a shadow pass it believes unused,
   // starving the colored light voxelizer. this sampler (tapped invisibly in
   // main) forces the pass to run
   uniform sampler2D shadowcolor0;
#endif

#ifdef CL_LAVA_TEXTURE
   flat varying float lavaRecolor;
#endif

#ifdef VOXY
   varying float vanillaMix;
#endif

#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getTorchColor.fsh"
#include "/common/getAmbientColor.glsl"

#ifdef ENABLE_SHADOWS
   uniform mat4 shadowModelView;
   uniform mat4 shadowProjection;
   uniform sampler2D shadowtex1;

   varying vec3 lightColor;
   varying float diffuse;
   flat varying float shadowOpacity;

   #include "/common/getLightStrength.fsh"
#endif

void main() {
   if (fogMix > 0.999) {
      discard;
   }

   vec4 albedo = texture2D(gtexture, texUV);
   vec4 color  = color;

   #ifdef GBUFFERS_TERRAIN
      float ambientOcclusion = color.a;
      color.a = 1.0;
   #else
      float ambientOcclusion = 1.0;
   #endif

   #if defined CL_LAVA_TEXTURE && defined GBUFFERS_TERRAIN
      // lava recolor: with a shaderpack, the resource pack's biome lava tint
      // arrives as a plain multiply (texture x tint) - two saturated colors
      // multiplied crush the texture pattern into a flat sheet. recolor as
      // hue x texture-luminance instead: the tint gives the color, the
      // texture keeps its full pattern contrast (matches the no-shader look)
      // chroma gate: vanilla lava carries NO biome tint (vertex color is
      // white), and a white tint would desaturate the texture to gray here.
      // only recolor when a resource pack actually supplies a chromatic tint
      float tintChroma = max(color.r, max(color.g, color.b))
                       - min(color.r, min(color.g, color.b));

      if (lavaRecolor > 0.5 && tintChroma > 0.06) {
         vec3 tintHue = color.rgb / max(max(color.r, max(color.g, color.b)), 0.05);

         // hue swap: chromaticity from the biome tint, pattern from the
         // texture's own luminance. restoring the luminance EXACTLY would
         // divide by luma(tintHue) - 0.58 for a saturated orange, a x1.7 gain
         // that drives the red channel past 1.0 over most of the texture and
         // clips it to a flat sheet ("everything so orange and uniform").
         // the gain is capped so the brightest channel stays inside range and
         // the whole texture pattern survives
         float tintGain = min(1.0 / max(luma(tintHue), 0.05), 1.25);

         albedo.rgb = min(vec3(1.0), tintHue * (luma(albedo.rgb) * tintGain));
         color.rgb = vec3(1.0);
      }
   #endif

   #ifdef MOD_COLORWHEEL
      vec2 lightUV;
      vec4 entityColor;

      clrwl_computeFragment(albedo, albedo, lightUV, ambientOcclusion, entityColor);
   #endif

   vec4 ambient = getAmbientColor(lightUV.t, sunHeight);

   #ifdef THE_END
      ambient.rgb *= endTint;
   #endif

   #ifdef GLOWING_ORES
      ambient.rgb = mix(
         ambient.rgb,
         vec3(1.0, 0.9, 0.9),
         isOre * 0.3333*squaredLength(rescale(albedo.rgb, vec3(0.59), vec3(1.0)))
      );
   #endif

   albedo *= color;

   // render thunder
   albedo.a = entityId == 11000.0 ? 0.15 : albedo.a;
   // render entity color changes (e.g taking damage)
   albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

   float albedoLuma = luma(albedo.rgb);

   #ifdef VOXY
      // plain vanilla reference shading (albedo x AO x lightmap), captured
      // before any of the pack's ambient/shadow/tint work - what Voxy's LOD
      // terrain looks like on the other side of the render distance seam
      vec3 vanillaTerrain = albedo.rgb * ambientOcclusion * texture2D(lightmap, lightUV).rgb;
   #endif

   #ifdef ENABLE_SHADOWS
      float lightStrength = getLightStrength(diffuse, lightUV.t, feetPos);
      float lightBrightness = max(0.0, LIGHT_BRIGHTNESS - 0.5*pow3(albedoLuma));

      lightStrength = max(lightStrength, 0.75*lightSourceLevel);

      // time-of-day opacity applied to the darkening itself: lit areas keep
      // their full brightness, only how DARK a shadow gets is scaled
      ambient.rgb *= mix(mix(vec3(1.0), SHADOW_COLOR, shadowOpacity), vec3(1.0), lightStrength);
      ambient.rgb *= 0.75 + (lightBrightness * lightStrength) * lightColor;
   #endif

   ambient.rgb += getTorchColor(lightUV.s, ambient.rgb, feetPos);

   #if defined BLOOM_PASS && defined GBUFFERS_TERRAIN && defined BLOOM_EMISSIVE_TEXTURES
      // resource pack emissive overlays are SELF-lit: they must keep their own
      // texture color instead of taking the hue of nearby light sources (white
      // quartz sparks turning cyan next to cyan lava). same mask as the
      // overlay glow: fullbright lightmap on a non-emitting block. the ambient
      // is neutralized in hue at identical peak brightness
      float selfLit = rescale(lightUV.s, 0.935, 0.96) * bloomOverlayOk
                    * float(lightSourceLevel <= 0.12);

      ambient.rgb = mix(ambient.rgb, vec3(max(ambient.r, max(ambient.g, ambient.b))), selfLit);
   #endif

   albedo.rgb *= ambientOcclusion;

   albedo *= ambient;

   #if defined THE_NETHER && defined NETHER_COLOR_GRADING
      albedo.rgb = mix(
         vec3(luma(albedo.rgb)),
         albedo.rgb,
         max(rescale(luma(ambient.rgb), 0.2, 0.6), rescale(albedoLuma, 0.15, 0.4))
      );
   #endif

   #ifdef VOXY
      // seam matching: blend to the vanilla reference near the render
      // distance so the LOD handoff carries no brightness or hue step,
      // whatever the time of day (shadows, sun color, sky tints and nether
      // grading all fade out together)
      albedo.rgb = mix(albedo.rgb, vanillaTerrain, vanillaMix);
   #endif

   albedo.rgb = mix(albedo.rgb, gradientFogColor, fogMix);

   #if defined COLORED_LIGHT_ACTIVE && !defined OVERWORLD
      // invisible shadow-map tap (see the sampler declaration above): the
      // 1e-6 contribution cannot be folded away, so the sampler stays active
      // and Iris keeps the Nether/End shadow pass (our voxelizer) alive
      albedo.rgb += texture2D(shadowcolor0, vec2(0.5)).rgb * 1.0e-6;
   #endif

   #ifdef BLOOM_PASS
      /* DRAWBUFFERS:0672 */
   #else
      /* DRAWBUFFERS:067 */
   #endif

   gl_FragData[0] = albedo;

   #if BLOCK_REFLECTIONS > 0
      float reflectivity = max(0.0, (albedoLuma - blockReflectivity.y) * blockReflectivity.x * 0.2*BLOCK_REFLECTIONS);

      gl_FragData[1] = vec4(normal, 1.0);
      gl_FragData[2] = vec4(reflectivity, blockReflectivity.z, 0.5, 1.0);
   #else
      gl_FragData[1] = vec4(vec3(0.0), 1.0);
      gl_FragData[2] = vec4(vec3(0.0), 1.0);
   #endif

   #ifdef BLOOM_PASS
      // selective glow: on light-emitting blocks, only the texture's bright
      // (actually emitting) pixels glow - torch flame yes, torch stick no.
      // every source type gets the same strength once its pixels qualify
      float bloomLevel = lightSourceLevel > 0.12
         ? smoothe(rescale(albedoLuma, bloomCutoff, bloomCutoff + 0.2))
         : 0.0;

      #ifdef BLOOM_EMISSIVE_TEXTURES
         // resource pack emissive overlays are an exact per-pixel mask, but ONLY
         // on non-emitting blocks: a level-15 emitter's own geometry (lantern,
         // campfire) is also rendered fullbright, so the mask cannot separate
         // body from flame there - those use the per-category cutoff above.
         // bloomOverlayOk excludes Voxy LOD geometry, which is fullbright too
         if (lightSourceLevel <= 0.12 && bloomOverlayOk > 0.25) {
            float overlayTerm = rescale(lightUV.s, 0.935, 0.96);

            if (bloomOverlayOk < 0.75) {
               // entities: only bright emissive pixels (glowing eyes...) qualify
               overlayTerm *= smoothe(rescale(albedoLuma, 0.5, 0.8));
            }

            bloomLevel = max(bloomLevel, overlayTerm);
         }
      #endif

      #ifdef GLOWING_ORES
         // masked to the bright ore bits only, never the whole block face
         bloomLevel = max(bloomLevel, isOre * 0.3 * smoothe(rescale(albedoLuma, 0.55, 0.85)));
      #endif

      // per-category glow ceiling, applied AFTER every glow path (emitter,
      // overlay, ores) so nothing can max() past it: keeps uniformly bright
      // retextured lava from whiting out, and softens the fullbright sculk
      // sensor tendrils
      bloomLevel = min(bloomLevel, bloomLevelCap);

      // brightness-normalize the glow color so dark emissive textures (soul fire,
      // sculk, portal...) glow as strongly as bright ones (torch flame)
      vec3 bloomColor = albedo.rgb * min(4.0, max(1.0, 0.5 / max(albedoLuma, 0.001)));

      bloomColor *= bloomTint; // per-category hue correction (copper -> green)

      gl_FragData[3] = vec4(
         clamp(bloomColor, 0.0, 1.0) * (bloomLevel * (1.0 - fogMix) * bloomDistFade),
         albedo.a
      );
   #endif
}