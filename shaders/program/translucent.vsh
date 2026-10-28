#include "/shader.h"

attribute vec4 mc_Entity;

uniform float frameTimeCounter;
uniform float rainStrength;
uniform float screenBrightness;
uniform int isEyeInWater;
uniform int worldTime;
uniform sampler2D lightmap;
uniform vec3 sunPosition;

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

#ifdef VOXY
   varying float vanillaMix;
#endif

#ifdef BLOOM
   #define BLOOM_PASS
#endif

#ifdef BLOOM_PASS
   varying float bloomDistFade;

   #ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
      attribute vec4 at_midBlock;
   #endif

   flat varying float lightSourceLevel;
#endif

#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getFogMix.vsh"
#include "/common/getFogColor.vsh"
#include "/common/getAmbientColor.glsl"
#include "/common/getViewPosition.vsh"
#include "/common/getWaterTextureStrength.vsh"
#include "/common/getWaterWave.vsh"

void main() {
   gl_Position = ftransform();

   float sunHeight = view2feet(sunPosition).y;

   color        = gl_Color;
   texUV        = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   lightUV      = (gl_TextureMatrix[1] * gl_MultiTexCoord1).st;
   normal       = gl_Normal;
   ambient      = getAmbientColor(lightUV.t, sunHeight);
   reflectivity = GLASS_REFLECTIVITY;

   feetPos = view2feet(getViewPosition());
   fogMix = getFogMix(feetPos);
   gradientFogColor = getFogColor(fogMix, feetPos, sunHeight);

   ambient.rgb *= color.a;
   color.a = 1.0;

   #ifdef VOXY
      vanillaMix = calcFogMix(feetPos, 0.3, far);
   #endif

   #ifdef BLOOM_PASS
      // clip-space depth cap: unfakeable, see textured_lit.vsh
      bloomDistFade = 1.0 - rescale(max(gl_Position.w, length(feetPos)), 96.0, 144.0);

      #ifdef IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE
         lightSourceLevel = at_midBlock.w < 16.0 ? at_midBlock.w / 15.0 : 0.0;

         // reject implausible mid-block data (Voxy LOD water/translucents)
         if (dot(at_midBlock.xyz, at_midBlock.xyz) <= 1.0
          || any(greaterThan(abs(at_midBlock.xyz), vec3(40.0)))) {
            lightSourceLevel = 0.0;
         }
      #else
         lightSourceLevel = 0.0;
      #endif
   #endif

   if (mc_Entity.x == 10008.0) {
      float posRandom = random(floor(feetPos.xz) + floor(cameraPosition.xz));

      #if WATER_WAVE_SIZE > 0

         if (abs(normal.y) > 0.8) {
            normal = normalize(normal + getWaterWave(posRandom, feetPos));
         }

      #endif

      reflectivity = WATER_REFLECTIVITY;
      waterTexStrength = getWaterTextureStrength(posRandom);
   }

   normal = ndc2screen(normal);
}