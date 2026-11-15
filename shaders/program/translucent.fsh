#include "/shader.h"

uniform float screenBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform sampler2D gtexture;

varying float fogMix;
varying float reflectivity;
varying float waterTexStrength;
varying vec2 lightUV;
varying vec2 texUV;
varying vec3 feetPos;
varying vec3 gradientFogColor;
varying vec3 normal;
varying vec4 ambient;
varying vec4 color;

#if HAND_DYNAMIC_LIGHTING == 0
   uniform int heldBlockLightValue;
#elif HAND_DYNAMIC_LIGHTING == 1
   #define heldBlockLightValue 14
#endif

#ifdef BLOOM
   #define BLOOM_PASS
#endif

#ifdef BLOOM_PASS
   varying float bloomDistFade;
   flat varying float lightSourceLevel;
   flat varying float glowScale;
   flat varying vec4 emissive;
#endif

#ifdef COLORED_LIGHT_ACTIVE
   varying vec3 lpvNormal;
#else
   const vec3 lpvNormal = vec3(0.0);
#endif

#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getTorchColor.fsh"
#include "/common/waterAlpha.glsl"
#include "/common/lightPalette.glsl"

void main() {
   if (fogMix > 0.999) {
      discard;
   }

   vec4 albedo  = texture2D(gtexture, texUV);
   vec4 ambient = ambient;
   vec4 color   = color;

   #ifdef BLOOM_PASS
      float texLuma = luma(albedo.rgb);
      float emissiveMask = getEmissiveMask(albedo.rgb, emissive);
   #endif

   if (reflectivity > WATER_REFLECTIVITY - 0.01) {
      albedo.a = decodeWaterAlpha(albedo.a);

      #if MC_VERSION >= 11300
         albedo.rgb = rescale(albedo.rgb * waterTexStrength, vec3(WATER_GLINT_CUTOFF), vec3(1.0));
         albedo.rgb = vec3(WATER_BRIGHTNESS) + WATER_GLINT_BRIGHTNESS * albedo.rgb;

         #define WATER_BUFFER color
      #else
         #define WATER_BUFFER albedo
      #endif

      WATER_BUFFER.ba = min(WATER_BUFFER.ba, vec2(max(WATER_BUFFER.r, WATER_BUFFER.g)*WATER_B, WATER_A));
   }

   ambient.rgb += getTorchColor(lightUV.s, ambient.rgb, feetPos, lpvNormal);

   albedo *= color * ambient;

   albedo.rgb = mix(albedo.rgb, gradientFogColor, fogMix);

   #ifdef BLOOM_PASS
      /* DRAWBUFFERS:0672 */
   #else
      /* DRAWBUFFERS:067 */
   #endif

   gl_FragData[0] = albedo;
   gl_FragData[1] = vec4(normal, 1.0);
   gl_FragData[2] = vec4(reflectivity, 0.0, 0.5, 1.0);

   #ifdef BLOOM_PASS
      // glow for emissive translucents (nether portal...); water has no emission.
      // shaped by the texture's own bright pixels, matching the terrain glow
      // emitters with an emissive model glow exactly on its texels,
      // normalized like terrain light sources; others by brightness
      float bloomLevel = emissive.w > 0.0
         ? min(emissiveMask / emissive.w, 1.0)
         : lightSourceLevel > 0.12 ? smoothe(rescale(texLuma, 0.25, 0.6)) : 0.0;

      vec3 bloomColor = albedo.rgb * min(4.0, max(1.0, 0.5 / max(texLuma, 0.001)));

      gl_FragData[3] = vec4(
         clamp(bloomColor, 0.0, 1.0) * (bloomLevel * glowScale * (1.0 - fogMix) * bloomDistFade),
         albedo.a
      );
   #endif
}