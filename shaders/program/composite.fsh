// bloom pass 1: gather emissive + bright highlights, horizontal blur into colortex3

#include "/shader.h"

varying vec2 texUV;

#ifdef BLOOM

   uniform float viewWidth;
   uniform float viewHeight;
   uniform sampler2D colortex0;
   uniform sampler2D colortex2;
   uniform sampler2D depthtex0;
   uniform vec3 fogColor;
   uniform vec3 sunPosition;

   #include "/common/math.glsl"
   #include "/common/transformations.glsl"

   vec3 getBloomSource(vec2 uv) {
      vec3 glow = texture2D(colortex2, uv).rgb;

      float depth = texture2D(depthtex0, uv).x;

      // authoritative near-field cap, enforced from the depth buffer: a draw
      // cannot fake its depth without breaking its own occlusion, so LOD
      // terrain (Voxy etc.) can never carry glow past this regardless of how
      // it feeds the gbuffer programs. no depth written -> no emissive glow
      if (depth < 1.0) {
         glow *= 1.0 - pow2(rescale(length(screen2view(uv, depth)), 96.0, 144.0));
      } else {
         glow = vec3(0.0);
      }

      // the sky path is a SUN/MOON HALO: it only applies in a tight cone around
      // the sun or moon direction
      #ifdef BLOOM_SKY
         if (depth >= 1.0) {
            vec3 viewDir = normalize(screen2view(uv, 1.0));
            vec3 sunDir  = normalize(sunPosition);
            float proximity = max(dot(viewDir, sunDir), -dot(viewDir, sunDir)); // sun or moon

            float mask = rescale(proximity, 0.92, 0.99);

            if (mask > 0.0) {
               vec3 color = texture2D(colortex0, uv).rgb;

               // fog-colored pixels (haze) never glow
               mask *= rescale(length(color - fogColor), 0.05, 0.25);

               // soft knee above the threshold; safe across the whole slider range
               float highlight = pow2(rescale(luma(color), BLOOM_THRESHOLD, BLOOM_THRESHOLD + 0.2));

               glow = max(glow, color * (highlight * BLOOM_HIGHLIGHTS * mask));
            }
         }
      #endif

      return max(vec3(0.0), mix(vec3(luma(glow)), glow, BLOOM_SATURATION));
   }

   void main() {
      float texelX = BLOOM_DOWNSCALE / viewWidth;

      vec3 total = vec3(0.0);
      float totalWeight = 0.0;

      // radius scales tap spacing: the slider directly controls halo size
      float spacing = max(1.0, 0.35 * float(BLOOM_RADIUS));

      for (int i = -BLOOM_TAPS; i <= BLOOM_TAPS; i++) {
         float x = float(i) / (0.55 * float(BLOOM_TAPS));
         float weight = exp(-0.5 * x * x);

         total += weight * getBloomSource(texUV + vec2(float(i) * spacing * texelX, 0.0));
         totalWeight += weight;
      }

      /* DRAWBUFFERS:3 */
      gl_FragData[0] = vec4(total / totalWeight, 1.0);
   }

#else

   void main() {
      /* DRAWBUFFERS:3 */
      gl_FragData[0] = vec4(0.0);
   }

#endif
