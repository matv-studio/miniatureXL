#define SHADOW_DARKNESS 0.5 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define LIGHT_BRIGHTNESS 0.9 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

#define ENABLE_FOG
#define OVERWORLD_FOG_MAX_SLIDER 7 //[0 1 2 3 4 5 6 7 8 9 10]
#define OVERWORLD_FOG_MIN_SLIDER 0 //[0 1 2 3 4 5 6 7 8 9 10]
#define WEATHER_OPACITY 0.35 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define MOON_R 0.1  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define MOON_G 0.15 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define MOON_B 0.3  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

#define BLOCK_REFLECTIONS 5  //[0 1 2 3 4 5 6 7 8 9 10]
#define REFLECTIONS 10       //[0 1 2 3 4 5 6 7 8 9 10]
#define SSR_MAX_STEPS 10     //[1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 24 32 64 96 128 256 512]
#define SSR_STEP_SIZE 1.6    //[0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SSR_BINARY_STEPS 4   //[1 2 3 4 5 6 7 8 9 10]

#define BLOOM
#define BLOOM_STRENGTH 1.0     //[0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define BLOOM_RADIUS 1         //[1 2 3 4 5 6 7 8 9 10]
#define BLOOM_QUALITY 1        //[0 1 2]
#define BLOOM_SATURATION 1.4   //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define BLOOM_SKY
#define BLOOM_EMISSIVE_TEXTURES
#define BLOOM_PARTICLES
#define BLOOM_ENCHANT
#define BLOOM_PIXEL_THRESHOLD 0.5 //[0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9]
#define BLOOM_HIGHLIGHTS 0.55   //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define BLOOM_THRESHOLD 0.45    //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define COLORED_LIGHT
#define COLORED_LIGHT_STRENGTH 2.0 //[0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define COLORED_LIGHT_RANGE 64 //[16 24 32 40 48 56 64 96 128 160 192 224 256]
#define CL_FALLOFF 0.5 //[0.5 0.75 1.0 1.25 1.5 1.75 2.0]
#define VOXEL_SIZE 128 //[64 128 192 256 384 512]
#define TORCH_FALLOFF 1.0 //[0.6 0.7 0.8 0.9 1.0 1.15 1.3 1.5 1.75 2.0]
#define CL_TRANSITION 0.1 //[0.03 0.05 0.1 0.15 0.25 0.5 1.0]
#define CL_LAVA_TEXTURE
#define CL_ENTITY_LIGHT
#define CL_ITEM_LIGHT

#define SUN_SHAFTS
#define SUN_SHAFTS_STRENGTH 2.0 //[0.25 0.5 0.75 1.0 1.25 1.5 1.75 2.0 2.25 2.5 2.75 3.0]

#define CL_FLAME_R 0.9     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_FLAME_G 0.55    //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_FLAME_B 0.3     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_SOUL_R 0.25     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_SOUL_G 0.7      //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_SOUL_B 1.0      //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_LAVA_R 1.0      //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_LAVA_G 0.4      //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_LAVA_B 0.1      //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_REDSTONE_R 1.0  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_REDSTONE_G 0.1  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_REDSTONE_B 0.05 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_AMETHYST_R 0.65 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_AMETHYST_G 0.4  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_AMETHYST_B 1.0  //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_SEA_R 0.3       //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_SEA_G 0.9       //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_SEA_B 0.9       //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_PORTAL_R 0.6    //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_PORTAL_G 0.25   //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_PORTAL_B 1.0    //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_GLOW_R 1.0      //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_GLOW_G 0.8      //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_GLOW_B 0.6     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_ROD_R 1.0       //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_ROD_G 1.0       //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_ROD_B 1.0       //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_LICHEN_R 0.45   //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_LICHEN_G 0.8    //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define CL_LICHEN_B 0.9    //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]

// Sky colors screen: sun light color (noon / dusk absolute colors) and
// time-of-day sky tint multipliers (1.0 = vanilla look untouched)
#define SUN_NOON_R 1.0     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SUN_NOON_G 0.95    //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SUN_NOON_B 0.9     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SUN_DUSK_R 1.0     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SUN_DUSK_G 0.55    //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SUN_DUSK_B 0.5     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define SKY_DAY_R 1.0      //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SKY_DAY_G 1.0      //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SKY_DAY_B 1.0      //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SKY_DUSK_R 1.0     //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SKY_DUSK_G 0.5     //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SKY_DUSK_B 0.5     //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SKY_NIGHT_R 1.0    //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SKY_NIGHT_G 1.0    //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define SKY_NIGHT_B 1.0    //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]

// real colored light needs Iris compute shaders + custom images. all three
// dimensions (the Nether/End shadow passes cast no shadows - they exist
// purely as the voxelizer feeding the colored light field)
#if defined COLORED_LIGHT && defined IS_IRIS && defined IRIS_FEATURE_CUSTOM_IMAGES && defined IRIS_FEATURE_COMPUTE_SHADERS && (defined OVERWORLD || defined THE_NETHER || defined THE_END)
   #define COLORED_LIGHT_ACTIVE
#endif

// volume dimensions - must match the conditional image declarations in
// shaders.properties. height doubles past the 256 threshold
#if VOXEL_SIZE > 256
   #define VOXEL_HEIGHT 128
#else
   #define VOXEL_HEIGHT 64
#endif
#define VOXEL_VOLUME_SIZE vec3(float(VOXEL_SIZE), float(VOXEL_HEIGHT), float(VOXEL_SIZE))

// effective colored-light range: the user slider, hard-capped at half the
// volume width (beyond that the toroidal wrap would ghost)
#if COLORED_LIGHT_RANGE * 2 > VOXEL_SIZE
   #define CL_RANGE_EFF (0.5 * float(VOXEL_SIZE))
#else
   #define CL_RANGE_EFF float(COLORED_LIGHT_RANGE)
#endif
#define BLOOM_SOURCE_COLOR 1.0 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#if BLOOM_QUALITY == 0
   #define BLOOM_DOWNSCALE 4.0
   #define BLOOM_TAPS 4
#elif BLOOM_QUALITY == 1
   #define BLOOM_DOWNSCALE 2.0
   #define BLOOM_TAPS 6
#else
   #define BLOOM_DOWNSCALE 2.0
   #define BLOOM_TAPS 9
#endif


// time-of-day shadow OPACITY multipliers on top of the Shadow darkness
// slider (not exposed as options). effective darkening = slider x these:
// day 0.5 x 0.5 = 25%, night 0.5 x 0.2 = 10% at the default slider value
#define DAY_SHADOW 0.5
#define NIGHT_SHADOW 0.2

#define SHADOW_PIXEL 16     //[0 4 8 16 32 64 128 256 512 1024 2048]
#define SHADOW_BLUENESS 0.2 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5]

const int   shadowMapResolution = 1024;  //[256 512 1024 2048 3072 4096]
const float shadowDistance      = 128.0; //[8.0 16.0 32.0 64.0 96.0 128.0 192.0 256.0 384.0 512.0 1024.0]
const float shadowIntervalSize  = 7.0;  //[1.0 2.0 3.0 4.0 5.0 6.0 7.0 8.0 9.0 10.0 11.0 12.0 13.0 14.0 15.0 16.0]
const float shadowDistanceRenderMul = 1.0;
const float entityShadowDistanceMul = 0.2; //[0.125 0.2 0.25 0.333 0.5 0.75 1.0]
const float sunPathRotation = 0.0; //[-90.0 -85.0 -80.0 -75.0 -70.0 -65.0 -60.0 -55.0 -50.0 -45.0 -40.0 -35.0 -30.0 -25.0 -20.0 -15.0 -10.0 -5.0 0.0 5.0 10.0 15.0 20.0 25.0 30.0 35.0 40.0 45.0 50.0 55.0 60.0 65.0 70.0 75.0 80.0 85.0 90.0]

#define WATER_WAVE_SIZE 1          //[0 1 2 3 4 5 6 7 8 9 10]
#define WATER_WAVE_SPEED 2         //[1 2 3 4 5 6 7 8 9 10]
#define WATER_BRIGHTNESS 0.4       //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define WATER_B 1.3                //[1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0 2.1 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 3.0]
#define WATER_A 0.7                //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define WATER_MIN_GLINT 6          //[-1 0 1 2 3 4 5 6 7 8 9 10]
#define WATER_GLINT_CUTOFF 0.6     //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0]
#define WATER_GLINT_BRIGHTNESS 0.8 //[0.0 0.05 0.1 0.15 0.2 0.25 0.3 0.35 0.4 0.45 0.5 0.55 0.6 0.65 0.7 0.75 0.8 0.85 0.9 0.95 1.0 1.05 1.1 1.15 1.2 1.25 1.3 1.35 1.4 1.45 1.5 1.55 1.6 1.65 1.7 1.75 1.8 1.85 1.9 1.95 2.0]

#define END_STARS_SPEED  0.05  //[0.002 0.005 0.01 0.02 0.05 0.1 0.5]
#define END_STARS_AMOUNT 256.0 //[128.0 256.0 512.0 1024.0 2048.0]
#define END_STARS_FLOOR  256.0
#define END_STARS_OPACITY 1.0 //[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0]

#define FLAT_LIGHTING
#define GLOWING_ORES
#define HIGHLIGHT_WAXED
#define SHADOW_ENTITY 1 //[-1 0 1]
#define ENABLE_SKY
#define NETHER_COLOR_GRADING

#ifdef OVERWORLD
   #define ENABLE_SHADOWS
#endif

#if MC_VERSION >= 11300
   #define HAND_DYNAMIC_LIGHTING 0 //[-1 0 1]
#endif

// optifine needs these to show on menu
#ifdef ENABLE_FOG
#endif
#ifdef ENABLE_SKY
#endif
#ifdef FLAT_LIGHTING
#endif
#ifdef SHADOW_ENTITY
#endif
#ifdef NETHER_COLOR_GRADING
#endif
#ifdef BLOOM
#endif
#ifdef BLOOM_SKY
#endif
#ifdef BLOOM_EMISSIVE_TEXTURES
#endif
#ifdef BLOOM_PARTICLES
#endif
#ifdef SUN_SHAFTS
#endif
#ifdef COLORED_LIGHT
#endif
#ifdef CL_ENTITY_LIGHT
#endif
#ifdef CL_ITEM_LIGHT
#endif
#ifdef BLOOM_ENCHANT
#endif
#ifdef CL_LAVA_TEXTURE
#endif

//----------------------------------------------------------------------------//

#define MIN_REFLECTIVITY 0.01
#define WATER_REFLECTIVITY 0.99
#define GLASS_REFLECTIVITY 0.3

#define HALF_PI 1.570796326
#define PI 3.141592653
#define TAU 6.283185307
#define SQRT_2 1.414213562
#define NOON 0.25 // 6000
#define SUNSET 0.5325 // 12780
#define MIDNIGHT 0.75 // 18000
#define SUNRISE 0.9675 // 23220

const float INV_PI = 1.0 / PI;
const float INV_TAU = 1.0 / TAU;

const float NORMALIZE_TIME = 1.0/24000.0;

const float OVERWORLD_FOG_MIN = 1.0 - 0.1*OVERWORLD_FOG_MAX_SLIDER;
const float OVERWORLD_FOG_MAX = 1.0 - 0.1*OVERWORLD_FOG_MIN_SLIDER;

const vec2 AMBIENT_UV = vec2(8.0/255.0, 247.0/255.0);
const vec2 TORCH_UV_SCALE = vec2(8.0/255.0, 231.0/255.0);
// fixed blocklight gradient (former inner/middle/outer torch settings): the
// per-category colors in the Light colors screen are the configurable layer now
const vec3 TORCH_INNER_COLOR = vec3(1.0, 0.85, 0.7);
const vec3 TORCH_MIDDLE_COLOR = vec3(1.0, 0.8, 0.6);
const vec3 TORCH_OUTER_COLOR = vec3(1.0, 0.55, 0.2);
const vec3 MOON_COLOR = vec3(MOON_R, MOON_G, MOON_B);
const vec3 CL_FLAME    = vec3(CL_FLAME_R, CL_FLAME_G, CL_FLAME_B);
const vec3 CL_SOUL     = vec3(CL_SOUL_R, CL_SOUL_G, CL_SOUL_B);
const vec3 CL_LAVA     = vec3(CL_LAVA_R, CL_LAVA_G, CL_LAVA_B);
const vec3 CL_REDSTONE = vec3(CL_REDSTONE_R, CL_REDSTONE_G, CL_REDSTONE_B);
const vec3 CL_AMETHYST = vec3(CL_AMETHYST_R, CL_AMETHYST_G, CL_AMETHYST_B);
const vec3 CL_SEA      = vec3(CL_SEA_R, CL_SEA_G, CL_SEA_B);
const vec3 CL_PORTAL   = vec3(CL_PORTAL_R, CL_PORTAL_G, CL_PORTAL_B);
const vec3 CL_GLOW     = vec3(CL_GLOW_R, CL_GLOW_G, CL_GLOW_B);
const vec3 CL_ROD      = vec3(CL_ROD_R, CL_ROD_G, CL_ROD_B);
const vec3 CL_LICHEN   = vec3(CL_LICHEN_R, CL_LICHEN_G, CL_LICHEN_B);
const vec3 CL_DEFAULT  = vec3(1.0, 0.78, 0.55);

const vec3 SUN_NOON_COLOR  = vec3(SUN_NOON_R, SUN_NOON_G, SUN_NOON_B);
const vec3 SUN_DUSK_COLOR  = vec3(SUN_DUSK_R, SUN_DUSK_G, SUN_DUSK_B);
const vec3 SKY_DAY_TINT    = vec3(SKY_DAY_R, SKY_DAY_G, SKY_DAY_B);
const vec3 SKY_DUSK_TINT   = vec3(SKY_DUSK_R, SKY_DUSK_G, SKY_DUSK_B);
const vec3 SKY_NIGHT_TINT  = vec3(SKY_NIGHT_R, SKY_NIGHT_G, SKY_NIGHT_B);

const vec4 END_STARS_DRAG = vec4(200, 500, 100, 100);
const vec3 END_AMBIENT    = vec3(0.83, 0.7, 1.0);

const vec3 SHADOW_COLOR = vec3(1.0 - SHADOW_DARKNESS) + vec3(0.0, 0.3333, 1.0) * SHADOW_BLUENESS;

const float SHADOW_MAX_DIST_SQUARED = shadowDistance * shadowDistance;
const float INV_SHADOW_MAX_DIST_SQUARED = 1.0/SHADOW_MAX_DIST_SQUARED;