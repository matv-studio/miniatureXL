// beacon beam: always emissive (no lightmap darkening - the beam is pure
// light), and a strong glow contribution that follows the beam's own color
// (white core, stained-glass tinted beams stay tinted)

#include "/shader.h"

uniform sampler2D gtexture;

varying float bloomDist;
varying vec2 texUV;
varying vec4 color;

#include "/common/math.glsl"

void main() {
   vec4 albedo = texture2D(gtexture, texUV) * color;

   /* DRAWBUFFERS:02 */
   gl_FragData[0] = albedo;

   float glow = 0.0;

   #ifdef BLOOM
      glow = 0.6 * (1.0 - rescale(bloomDist, 96.0, 144.0));
   #endif

   gl_FragData[1] = vec4(albedo.rgb * glow, albedo.a);
}
