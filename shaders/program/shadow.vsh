#extension GL_ARB_shader_image_load_store : enable

#include "/shader.h"

attribute vec4 mc_Entity;

varying vec2 texUV;
varying float alpha;

#ifdef COLORED_LIGHT_ACTIVE
   attribute vec4 at_midBlock;

   uniform mat4 shadowModelViewInverse;
   uniform vec3 cameraPosition;
   uniform int entityId;
   uniform int blockEntityId;
   uniform int currentRenderedItemId;

   flat varying float voxelLevel;
   flat varying vec3 voxelCenter;
   flat varying vec3 voxelColor;

   #ifdef CL_LAVA_TEXTURE
      flat varying float voxelUseTexture;
      flat varying vec3 voxelTint;
   #endif

   // entity light sources are written from HERE, not from the fragment stage:
   // the fire overlay on a burning mob is a billboard oriented toward the
   // PLAYER camera even while the shadow pass renders from the sun, so from
   // the light's point of view it can be edge-on, back-facing (the pack uses
   // reversed culling) or otherwise rasterize to no fragments at all - and a
   // fragment-stage write would silently never happen. the vertex stage runs
   // regardless of what the rasterizer does with the primitive
   layout (rgba8) uniform image3D voxelData;
#endif

#ifdef COLORED_LIGHT_ACTIVE
   #include "/common/lightPalette.glsl"
#endif

#include "/common/getShadowDistortion.glsl"

void main() {
   gl_Position = ftransform();
   gl_Position.xyz = getShadowDistortion(gl_Position.xyz);

   texUV = (gl_TextureMatrix[0] * gl_MultiTexCoord0).st;
   alpha = mc_Entity.x == 10072.0 ? 0.0 : gl_Color.a;

   #ifdef COLORED_LIGHT_ACTIVE
      vec3 worldPos = (shadowModelViewInverse * (gl_ModelViewMatrix * gl_Vertex)).xyz + cameraPosition;

      voxelCenter = worldPos + at_midBlock.xyz / 64.0;
      voxelLevel  = at_midBlock.w < 16.0 ? at_midBlock.w / 15.0 : 0.0;

      int lightId = int(mc_Entity.x);

      // ids inside our own light-source range are trusted without a plausible
      // mid-block offset - anything else must carry one (anti-Voxy)
      bool trustedLightId = (lightId > 10200 && lightId < 10221) || lightId == 10068;

      // set by every path whose source is an ENTITY rather than terrain: those
      // are written from the vertex stage (see the voxelData declaration above)
      bool entitySource = false;

      // terrain-path emitters whose vanilla level sits below the junk threshold
      if (lightId == 10211 && voxelLevel < 0.18) voxelLevel = 0.45; // end portal frame
      if (lightId == 10212 && voxelLevel < 0.18) voxelLevel = 0.3;  // brewing stand (level 1)
      // sculk sensors: level 1 ONLY while actively detecting (level 0 idle) -
      // bump the active state above the junk threshold, never the idle one
      if (lightId == 10219 && voxelLevel > 0.02 && voxelLevel < 0.18) voxelLevel = 0.3;

      // block entities (ender chest and its animating lid...): the id arrives
      // via the blockEntityId uniform, NOT mc_Entity, and vertex attributes are
      // unreliable here -> snap to the block cell and use the palette level
      if (blockEntityId > 10200 && blockEntityId < 10213) {
         lightId     = blockEntityId;
         trustedLightId = true;
         entitySource = true;
         voxelCenter = floor(worldPos) + vec3(0.5);
         voxelLevel  = getLightPaletteLevel(lightId);
      }

      #if defined CL_ENTITY_LIGHT || defined CL_ITEM_LIGHT
         // lights carried through the world (Iris currentRenderedItemId):
         // dropped items & item frames (CL_ITEM_LIGHT), items held by other
         // players and mobs - and the shadow-pass player model itself, which
         // anchors the held light's color at the camera (CL_ENTITY_LIGHT)
         if (currentRenderedItemId >= 10000 && currentRenderedItemId < 20000) {
            bool droppedOrFramed = entityId == 10301 || entityId == 10303;

            #ifdef CL_ITEM_LIGHT
               bool carriedOk = droppedOrFramed;
            #else
               bool carriedOk = false;
            #endif
            #ifdef CL_ENTITY_LIGHT
               carriedOk = carriedOk || !droppedOrFramed;
            #endif

            if (carriedOk) {
               lightId     = currentRenderedItemId;
               trustedLightId = true;
               entitySource = true;
               voxelCenter = floor(worldPos) + vec3(0.5);
               voxelLevel  = 0.75 * getLightPaletteLevel(lightId);
            }
         }
      #endif

      #ifdef CL_ENTITY_LIGHT
         // burning entities & flaming arrows (Iris hardcoded flame-overlay id),
         // plus intrinsically glowing mobs
         if (entityId == 10302 || entityId == 10304 || entityId == 10305) {
            lightId     = entityId == 10302 ? 10201   // fire -> flame color
                        : entityId == 10304 ? 10208   // blaze, magma cube -> lava color
                        : 10207;                      // glow squid, allay -> glow color
            trustedLightId = true;
            entitySource = true;
            voxelCenter = floor(worldPos) + vec3(0.5);
            voxelLevel  = entityId == 10302 ? 0.8
                        : entityId == 10304 ? 0.65
                        : 0.4;
         }
      #endif

      bool plausibleTerrain = dot(at_midBlock.xyz, at_midBlock.xyz) > 1.0
                           && all(lessThan(abs(at_midBlock.xyz), vec3(40.0)));

      // in-range test shared by light voxelization and wall marking.
      // CRITICAL vertical window: the volume wraps in Y, so a cave light
      // source below would wrap around and appear ABOVE the surface as a
      // drifting ghost patch - only voxelize a safe window around the player
      bool inRange = length(voxelCenter - cameraPosition) <= CL_RANGE_EFF
                  && abs(voxelCenter.y - cameraPosition.y) <= 0.5*float(VOXEL_HEIGHT) - 8.0;

      // strict sanity gate: Voxy (and other mods) also render into the shadow
      // pass with foreign vertex formats - garbage attributes here would be
      // voxelized as drifting warm light patches
      if ((!trustedLightId && !plausibleTerrain)
       || lightId < -1 || lightId > 30000
       || !inRange) {
         voxelLevel = 0.0;
      }

      // fixed per-block-type palette: stable colors regardless of camera,
      // shadow resolution or texture pack (see Light colors settings screen)
      voxelColor = getLightPaletteColor(lightId);

      // entity sources are written HERE. their geometry is unreliable from the
      // sun's point of view (camera-facing flame billboards, reversed culling,
      // fully transparent overlay quads), so waiting for the fragment stage
      // means the light often never lands. same value the fragment stage
      // writes, so a source that DOES rasterize just writes it twice
      if (entitySource && voxelLevel > 0.18) {
         ivec3 entityVoxel = ivec3(mod(floor(voxelCenter), VOXEL_VOLUME_SIZE));

         imageStore(voxelData, entityVoxel, vec4(voxelColor, 1.0) * sqrt(voxelLevel));
      }

      // lava & magma may instead take their hue from the actual texture
      // (resource packs recolor lava via mcmeta): flag for the fragment stage
      #ifdef CL_LAVA_TEXTURE
         voxelUseTexture = (lightId == 10068 || lightId == 10208) ? 1.0 : 0.0;
         // resource packs recolor lava through the vertex tint, not the
         // texture pixels - the light color must include it
         voxelTint = gl_Color.rgb;
      #endif
   #endif
}
