// bloom pass 2: vertical blur of colortex3 (buffers are flipped between composites)

#include "/shader.h"

varying vec2 texUV;

#ifdef BLOOM

   uniform float viewHeight;
   uniform sampler2D colortex3;

   void main() {
      float texelY = BLOOM_DOWNSCALE / viewHeight;

      vec3 total = vec3(0.0);
      float totalWeight = 0.0;

      // radius scales tap spacing: the slider directly controls halo size
      float spacing = max(1.0, 0.35 * float(BLOOM_RADIUS));

      for (int i = -BLOOM_TAPS; i <= BLOOM_TAPS; i++) {
         float x = float(i) / (0.55 * float(BLOOM_TAPS));
         float weight = exp(-0.5 * x * x);

         total += weight * texture2D(colortex3, texUV + vec2(0.0, float(i) * spacing * texelY)).rgb;
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
