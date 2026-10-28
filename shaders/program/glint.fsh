// enchantment glint (armor, enchanted items): vanilla-equivalent rendering
// plus a glow that follows the glint texture itself, so a custom purple glint
// from a resource pack glows in exactly its own color and pattern.
// toggleable via BLOOM_ENCHANT in the Glow settings screen

#include "/shader.h"

uniform sampler2D gtexture;
uniform sampler2D lightmap;

varying float bloomDist;
varying vec2 lightUV;
varying vec2 texUV;
varying vec4 color;

#include "/common/math.glsl"

void main() {
   vec4 albedo = texture2D(gtexture, texUV)
               * texture2D(lightmap, lightUV)
               * color;

   /* DRAWBUFFERS:02 */
   gl_FragData[0] = albedo;

   float glow = 0.0;

   #if defined BLOOM && defined BLOOM_ENCHANT
      // the glint texture is dim streaks: a low luma window catches the
      // streaks themselves without lifting the whole item
      glow = 0.7 * pow2(rescale(luma(albedo.rgb), 0.15, 0.6))
           * (1.0 - rescale(bloomDist, 96.0, 144.0));
   #endif

   gl_FragData[1] = vec4(albedo.rgb * glow, albedo.a);
}
