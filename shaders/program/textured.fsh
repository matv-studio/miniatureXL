// particles and other "textured" geometry: vanilla-equivalent shading, plus
// glow output for bright pixels (fire, flames, lava drips...). beacon beams
// have their own dedicated program (beaconbeam.fsh). this program is only
// enabled when BLOOM and BLOOM_PARTICLES are both on (see shaders.properties);
// otherwise these render vanilla as before.

#include "/shader.h"

uniform sampler2D gtexture;
uniform sampler2D lightmap;

varying float bloomDist;
varying vec2 lightUV;
varying vec2 texUV;
varying vec4 color;

#include "/common/math.glsl"

void main() {
   vec4 albedo = texture2D(gtexture, texUV) * color;

   float texLuma = luma(albedo.rgb);

   albedo *= texture2D(lightmap, lightUV);

   /* DRAWBUFFERS:02 */
   gl_FragData[0] = albedo;

   // only bright pixels glow, scaled down so a screenful of particles does not
   // overwhelm the bloom buffer. the hard distance cap keeps anything routed
   // through this fallback program at range (Voxy LOD terrain) out of the glow -
   // particles are near the player by nature
   float bloomFade = 1.0 - rescale(bloomDist, 96.0, 144.0);

   gl_FragData[1] = vec4(albedo.rgb * (0.8 * pow2(rescale(texLuma, 0.6, 0.9)) * bloomFade), albedo.a);
}
