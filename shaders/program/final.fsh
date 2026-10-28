#include "/shader.h"

uniform float far;
uniform int isEyeInWater;
uniform sampler2D colortex0;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
uniform sampler2D depthtex0;

#ifdef BLOOM
   uniform sampler2D colortex2;
   uniform sampler2D colortex3;
#endif

#if defined SUN_SHAFTS && defined OVERWORLD
   uniform float rainStrength;
   uniform vec3 sunPosition;
#endif

varying vec2 texUV;

#include "/common/math.glsl"
#include "/common/transformations.glsl"
#include "/common/getReflectionColor.fsh"

void main() {
   vec4 color = texture2D(colortex0, texUV);
   vec4 reflectivityAndRoughness = texture2D(colortex7, texUV);
   float reflectivity = reflectivityAndRoughness.x;
   float roughness = reflectivityAndRoughness.y;

   if (reflectivity > MIN_REFLECTIVITY && abs(reflectivityAndRoughness.z - 0.5) < 0.01) {
      // the normal doesn't come premultiplied by the normal matrix to
      // avoid the modelview transformations when view bobbing is on
      // which causes severe artifacts when moving
      vec3 prenormal = screen2ndc(texture2D(colortex6, texUV).xyz);

      #if WATER_WAVE_SIZE > 0

         if ((abs(prenormal.x) > 0.0 || abs(prenormal.z) > 0.0) && abs(prenormal.y) > 0.3333) {
            prenormal.xyz *= 1.0 / prenormal.y;
            prenormal.xz *= 0.01 * WATER_WAVE_SIZE;
         }

      #endif

      float depth  = texture2D(depthtex0, texUV).x;
      vec3 normal  = eye2view(prenormal);
      vec3 viewPos = screen2view(texUV, depth);
      vec3 feetPos = view2feet(viewPos);
      vec3 worldPos = feet2world(feetPos);
      float pixelDistance = min(1.0, length(feetPos)/16.0);
      float stepSize = stepify(mix(1.0/512.0, 1.0/64.0, pixelDistance), 1.0/512.0);

      normal += roughness * random3(stepify(worldPos, stepSize));
      normal = normalize(normal);

      vec4 reflectionColor = getReflectionColor(depth, normal, viewPos);

      color.rgb = mix(
         color.rgb,
         reflectionColor.rgb,
         reflectionColor.a * reflectivity * 0.1*REFLECTIONS
      );
   }

   #if defined SUN_SHAFTS && defined OVERWORLD
      if (rainStrength < 0.999) {
         // sun by day, moon by night
         vec3 srcPos = sunPosition;
         vec3 shaftTint = vec3(1.0, 0.85, 0.6);
         float shaftBase = 0.24;
         float upness = view2eye(normalize(sunPosition)).y;

         if (upness < 0.0) {
            srcPos = -sunPosition;
            shaftTint = vec3(0.55, 0.65, 1.0);
            shaftBase = 0.12;
            upness = -upness;
         }

         float horizonFade = rescale(upness, 0.0, 0.15);

         if (horizonFade > 0.0 && srcPos.z < 0.0) {
            vec3 srcDir = normalize(srcPos);
            vec3 viewDir = normalize(screen2view(texUV, 1.0));
            float closeness = max(0.0, dot(viewDir, srcDir));

            if (closeness > 0.5) {
               // march toward the light accumulating sky visibility (crepuscular rays)
               vec2 srcScreen = view2screen(srcPos).xy;
               vec2 stepUV = (srcScreen - texUV) / 12.0;
               vec2 uv = texUV + stepUV * random(texUV); // dither hides banding

               float shaft = 0.0;
               float weight = 1.0;

               for (int i = 0; i < 12; i++) {
                  uv += stepUV;

                  vec2 cuv = clamp(uv, 0.0, 1.0);
                  shaft += weight * step(1.0, texture2D(depthtex0, cuv).x);
                  weight *= 0.93;
               }

               shaft *= pow3(rescale(closeness, 0.5, 1.0)) / 12.0;

               color.rgb += shaftTint
                  * (shaftBase * SUN_SHAFTS_STRENGTH * shaft * horizonFade * (1.0 - rainStrength));
            }
         }
      }
   #endif

   #ifdef BLOOM
      vec3 glow = texture2D(colortex3, texUV).rgb;

      // crisp core: the emissive pixels themselves stay hot and sharp, the
      // blurred halo spreads around them. same depth-based near-field cap as
      // the blur pass, so distant/depthless geometry carries no core either
      float coreDepth = texture2D(depthtex0, texUV).x;

      if (coreDepth < 1.0) {
         glow += texture2D(colortex2, texUV).rgb
            * (0.35 * (1.0 - pow2(rescale(length(screen2view(texUV, coreDepth)), 96.0, 144.0))));
      }

      glow = mix(vec3(luma(glow)), glow, BLOOM_SOURCE_COLOR);
      glow = clamp(glow * BLOOM_STRENGTH, 0.0, 1.0);

      // screen blend to avoid harsh clipping
      color.rgb = 1.0 - (1.0 - color.rgb) * (1.0 - glow);
   #endif

   gl_FragData[0] = color;
}