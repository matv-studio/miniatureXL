// colored light propagation, modeled on Complementary Reimagined's flood fill:
//   - 6-neighbor AVERAGE (/ 6.42) instead of max: hues from different sources
//     blend smoothly where they meet instead of hard-switching
//   - HDR rgba16f volumes: sources inject large values (level * 64) so the
//     average still reaches useful distances, with no 8-bit quantization cycles
//   - exactly ONE dispatch per frame, ping-ponging two persistent volumes by
//     frame parity: fully deterministic, no reliance on inter-dispatch barriers
//       even frames: voxelLight    = step(voxelLightAlt)   (samplers read voxelLight)
//       odd frames:  voxelLightAlt = step(voxelLight)      (samplers read voxelLightAlt)
// voxelData (r32ui, cleared every frame) holds brightness-packed emission
// written by the shadow pass via imageAtomicMax.

#include "/shader.h"

layout (local_size_x = 8, local_size_y = 4, local_size_z = 8) in;

// Iris's ComputeDirectiveParser reads this directive TEXTUALLY and cannot
// evaluate arithmetic ("ivec3(128 / 8, ...)" throws NumberFormatException and
// kills the dispatch) - literal integers only, one branch per volume size.
// values = (VOXEL_SIZE/8, VOXEL_HEIGHT/4, VOXEL_SIZE/8)
#if VOXEL_SIZE == 64
   const ivec3 workGroups = ivec3(8, 16, 8);
#endif
#if VOXEL_SIZE == 128
   const ivec3 workGroups = ivec3(16, 16, 16);
#endif
#if VOXEL_SIZE == 192
   const ivec3 workGroups = ivec3(24, 16, 24);
#endif
#if VOXEL_SIZE == 256
   const ivec3 workGroups = ivec3(32, 16, 32);
#endif
#if VOXEL_SIZE == 384
   const ivec3 workGroups = ivec3(48, 32, 48);
#endif
#if VOXEL_SIZE == 512
   const ivec3 workGroups = ivec3(64, 32, 64);
#endif

#ifdef COLORED_LIGHT_ACTIVE

   uniform int frameCounter;

   layout (rgba16f) uniform image3D voxelLight;
   layout (rgba16f) uniform image3D voxelLightAlt;
   layout (rgba8) uniform image3D voxelData;

   const ivec3 VOLUME = ivec3(VOXEL_SIZE, VOXEL_HEIGHT, VOXEL_SIZE); // = VOXEL_VOLUME_SIZE

   vec4 readPrevious(ivec3 p, ivec3 offset) {
      ivec3 q = ivec3(mod(vec3(p + offset), vec3(VOLUME))); // toroidal wrap

      if (frameCounter % 2 == 0) {
         return imageLoad(voxelLightAlt, q);
      } else {
         return imageLoad(voxelLight, q);
      }
   }

   void main() {
      ivec3 p = ivec3(gl_GlobalInvocationID);

      // the volumes are persistent and never cleared by Iris: on pack load they
      // contain arbitrary GPU memory (huge values, Inf, NaN) which would drift
      // through the scene as glowing patches. wipe both volumes deterministically
      // during the first frames after every shader (re)load
      if (frameCounter < 2) {
         imageStore(voxelLight, p, vec4(0.0));
         imageStore(voxelLightAlt, p, vec4(0.0));
         return;
      }

      vec4 light = readPrevious(p, ivec3( 1, 0, 0))
                 + readPrevious(p, ivec3(-1, 0, 0))
                 + readPrevious(p, ivec3( 0, 1, 0))
                 + readPrevious(p, ivec3( 0,-1, 0))
                 + readPrevious(p, ivec3( 0, 0, 1))
                 + readPrevious(p, ivec3( 0, 0,-1));

      // falloff softness (Colored light settings): higher CL_FALLOFF -> divisor
      // closer to 6.0 -> light decays slower, travels farther and the hues of
      // neighboring sources overlap and merge over a wider band
      light /= 6.0 + 0.2 / CL_FALLOFF;

      // temporal inertia (Color transition speed setting): each cell EASES
      // toward its new value instead of jumping, so a newly placed or removed
      // source fades its color in and out smoothly rather than snapping from
      // the default warm lightmap to the voxel hue. the steady state is
      // unchanged - only the speed of change is.
      // applied to the PROPAGATED field only - see the injection below
      light = mix(readPrevious(p, ivec3(0, 0, 0)), light, CL_TRANSITION);

      // HDR injection (x256: hue must stay readable near the edge of a
      // level-14 light's radius). rgb = palette color * level, alpha =
      // colorless level reference - both propagate identically so rgb/alpha
      // stays the palette magnitude.
      // AFTER the temporal filter: a cell that actually CONTAINS a source
      // holds its full value on the very first frame. filtering the injection
      // instead capped a source at CL_TRANSITION of its strength unless it
      // stayed in the same cell for ~1/CL_TRANSITION frames - which lights
      // that MOVE (burning mobs, dropped items, the player's own held light)
      // never do, so they were drowned out by the static field around them
      light = max(light, imageLoad(voxelData, p) * 256.0);

      // full clamp, Complementary-style: "prevents a random NaN from consuming
      // the volume" - NaN/Inf entering from any source dies here every frame
      light = clamp(light, vec4(0.0), vec4(512.0));

      if (frameCounter % 2 == 0) {
         imageStore(voxelLight, p, light);
      } else {
         imageStore(voxelLightAlt, p, light);
      }
   }

#else

   void main() {}

#endif
