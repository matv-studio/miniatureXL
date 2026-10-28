#extension GL_ARB_shader_image_load_store : enable

#include "/shader.h"

uniform sampler2D gtexture;

varying vec2 texUV;
varying float alpha;

#ifdef COLORED_LIGHT_ACTIVE
   flat varying float voxelLevel;
   flat varying vec3 voxelCenter;
   flat varying vec3 voxelColor;

   #ifdef CL_LAVA_TEXTURE
      flat varying float voxelUseTexture;
      flat varying vec3 voxelTint;
   #endif

   layout (rgba8) uniform image3D voxelData;
#endif

void main() {
   vec4 albedo = texture2D(gtexture, texUV);

   albedo.a *= alpha;

   #ifdef COLORED_LIGHT_ACTIVE
      // threshold skips junk from entities (their emission attribute is a default value).
      // color comes from a fixed per-block-type palette (set in the vertex shader), so
      // every fragment of a block writes the identical value - stable across frames,
      // camera angles and shadow resolutions.
      // BEFORE the alpha discard on purpose: fire's shadow is alpha-zeroed
      // (it must not cast one) but the flames must still feed the light field
      if (voxelLevel > 0.18) {
         ivec3 voxel = ivec3(mod(floor(voxelCenter), VOXEL_VOLUME_SIZE));

         vec3 lightColor = voxelColor;

         #ifdef CL_LAVA_TEXTURE
            // lava & magma take their hue from the ACTUAL texture so resource
            // packs that recolor lava (mcmeta animations) are followed.
            // normalized to max component = 1: only the hue is taken, the
            // luminance jitter between dark crust and bright vein texels is
            // discarded - and the temporal inertia of the flood fill averages
            // the residual per-fragment hue noise into a stable color
            if (voxelUseTexture > 0.5) {
               // MUST follow the same rule as the surface recolor in
               // textured_lit.fsh, or light and surface end up different hues:
               // multiplying an ORANGE lava texture by a BLUE biome tint gives
               // (1.0,0.5,0.1)x(0.2,0.6,0.9) = (0.2,0.3,0.09) -> normalized to
               // GREEN, a hue present in neither. when the resource pack sends
               // a chromatic tint, the tint alone is the hue; the texture only
               // carries it when the tint is neutral (vanilla, white tint)
               float tintChroma = max(voxelTint.r, max(voxelTint.g, voxelTint.b))
                                - min(voxelTint.r, min(voxelTint.g, voxelTint.b));

               vec3 t = tintChroma > 0.06 ? voxelTint : albedo.rgb * voxelTint;

               lightColor = t / max(max(t.r, max(t.g, t.b)), 0.05);
            }
         #endif

         // sqrt compresses the intensity range between sources so weak lights
         // (redstone torch, soul lantern, portal) keep their hue presence even
         // next to strong ones instead of being swamped.
         // alpha = colorless reference intensity: both channels decay the same
         // through the flood fill, so the reader can recover the palette
         // color's own brightness (max(rgb)/alpha) independent of distance
         imageStore(voxelData, voxel, vec4(lightColor, 1.0) * sqrt(voxelLevel));
      }
   #endif

   if (albedo.a < 0.1) {
      discard;
   }

   gl_FragData[0] = albedo;
}
