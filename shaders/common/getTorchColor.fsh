#ifdef COLORED_LIGHT_ACTIVE
   uniform sampler3D voxelLightSampler;
   uniform sampler3D voxelLightAltSampler;
#endif

#ifdef COLORED_LIGHT
   uniform int heldItemId;
   uniform int heldItemId2;

   #include "/common/lightPalette.glsl"
#endif

vec3 getTorchColor(float torchLight, vec3 ambient, vec3 feetPos) {
   float strength = rescale(torchLight, TORCH_UV_SCALE.x, TORCH_UV_SCALE.y);
   float handLight = 0.0;
   float voxelBlend = 0.0; // how much the voxel field claimed this surface's hue

   #if HAND_DYNAMIC_LIGHTING >= 0

      handLight = rescale(float(heldBlockLightValue) - SQRT_2 * length(feetPos), 0.0, 15.0);
      strength = max(strength, handLight);

   #endif

   strength = mix(strength*strength, smoothe(strength), screenBrightness);
   strength = mix(strength*strength, strength, max(1.0 - screenBrightness, eyeBrightnessSmooth.y/240.0));

   // block light softness: an exponent below 1 lifts the low end of the
   // vanilla lightmap curve, smoothing its hard taxicab steps and softening
   // dark corners in closed rooms. purely a remap of vanilla data - light
   // can never appear where vanilla has none, so no leaking is possible
   strength = pow(strength, 1.0 / TORCH_FALLOFF);

   vec3 torchColor = mix(
      mix(TORCH_OUTER_COLOR, TORCH_MIDDLE_COLOR, strength),
      TORCH_INNER_COLOR,
      slopeTo1(strength, 8.0)
   );

   #ifdef COLORED_LIGHT_ACTIVE
      // real colored light: intensity stays vanilla (lightmap falloff, no leaking),
      // hue comes from the flood-filled voxel field written by the shadow pass
      vec3 worldPos = feet2world(feetPos);
      vec3 voxelUV  = mod(worldPos, VOXEL_VOLUME_SIZE) / VOXEL_VOLUME_SIZE;

      // read BOTH ping-pong volumes and keep the stronger sample. at steady
      // state they hold the same converged field, so this changes nothing -
      // but if the compute cadence ever desynchronizes from the render loop
      // (driver / Iris scheduling), a frame-parity read alternates between a
      // fresh and a lagging volume and the light pulses between its color and
      // the warm default. per-sample max selection is cadence-proof
      vec4 voxelLightA = texture3D(voxelLightSampler, voxelUV);
      vec4 voxelLightB = texture3D(voxelLightAltSampler, voxelUV);
      vec4 voxelField  = voxelLightA.a >= voxelLightB.a ? voxelLightA : voxelLightB;

      vec3 voxelLight = voxelField.rgb;   // palette color * intensity
      float voxelRef  = voxelField.a;     // colorless intensity reference
      float voxelLuma = luma(voxelLight);

      // defense in depth: reject NaN/Inf/garbage samples outright (NaN fails
      // every comparison, so this catches it without isnan(), absent in GLSL 120)
      if (!(voxelLuma >= 0.0 && voxelLuma < 1.0e6)
       || !(voxelRef >= 0.0 && voxelRef < 1.0e6)) {
         voxelLight = vec3(0.0);
         voxelLuma = 0.0;
         voxelRef = 0.0;
      }

      // tight vertical fade: the volume wraps every 64 blocks in Y, so light
      // from far above (surface sources over an ocean floor...) would otherwise
      // ghost into terrain below as drifting colored patches
      float fade = (1.0 - rescale(length(feetPos.xz) / CL_RANGE_EFF, 0.8, 1.0))
                 * (1.0 - rescale(abs(feetPos.y) / (0.5*VOXEL_VOLUME_SIZE.y), 0.55, 0.8));
      // HDR field: sources inject level * 256, the average kernel decays steeply.
      // TWO confidence windows on the same field:
      //   - hue adoption reaches far (the hue is a ratio - valid even at tiny
      //     luma), so the source's color covers most of its real lit radius
      //     instead of falling back to the warm default gradient mid-range
      //     (a white end rod made that fallback obvious as a yellow ring)
      //   - the illumination floor stays close to the source, where the field
      //     is strong, so added brightness does not creep outward
      // confidence runs on the colorless reference so a dark palette color
      // (low sliders) does not shorten its own hue reach
      float hueConfidence   = rescale(voxelRef * COLORED_LIGHT_STRENGTH, 0.0001, 0.002) * fade;
      float floorConfidence = rescale(voxelRef * COLORED_LIGHT_STRENGTH, 0.001, 0.012) * fade;

      vec3 voxelHue = voxelLight * (luma(torchColor) / max(voxelLuma, 0.00005));

      // steep adoption curve: the partial-mix band between the warm default
      // gradient and the source hue is squeezed thin - orange x green
      // otherwise reads as a wide YELLOW ring around green sources (copper
      // lantern), a third color the eye picks out immediately
      voxelBlend = pow(min(1.0, hueConfidence), 0.6);
      torchColor = mix(torchColor, voxelHue, voxelBlend);

      // colored light contributes real illumination of its own, so nearby
      // surfaces pick up the hue even when the vanilla blocklight contribution
      // is small (weak sources, surfaces lit mostly by skylight)
      // extra fade factor: the floor adds real light, so wrapped/pop-in field
      // remnants must never illuminate terrain on their own
      float lightFloor = min(0.65, floorConfidence * 0.6 * COLORED_LIGHT_STRENGTH) * fade;

      // the field passes through walls; require at least a trace of real
      // blocklight so surfaces fully occluded from every light source
      // (behind walls, sealed caves) are never lit by field color alone
      lightFloor *= rescale(strength, 0.02, 0.12);

      // taper the floor away where the surface is already brightly lit, so
      // strong lights never get pushed further toward blowout
      lightFloor *= 1.0 - smoothe(rescale(strength, 0.55, 0.9));

      strength = max(strength, lightFloor);

      // the palette color's overall level (its highest slider) sets how BRIGHT
      // the source's light is: rgb/alpha cancels the distance decay, leaving
      // the color's own magnitude. knee at 0.75: any palette whose top slider
      // is >= 0.75 keeps FULL vanilla brightness (the default warm/sea colors
      // top out at 0.9 and must not dim); below the knee brightness scales
      // down proportionally - (0.05, 0.1, 0.15) -> a dim moody light at ~20%
      float sourceBrightness = clamp(
         max(voxelLight.r, max(voxelLight.g, voxelLight.b)) / (0.75 * max(voxelRef, 1.0e-4)),
         0.0, 1.0);

      // dedicated smooth weight for the dimming: fourth root spreads the
      // transition over ~4 blocks, dying out at the same pace as the
      // source's vanilla light - no hard seam at the field's edge
      float dimWeight = clamp(rescale(sqrt(sqrt(voxelRef * COLORED_LIGHT_STRENGTH)), 0.2, 1.0), 0.0, 1.0) * fade;

      strength *= mix(1.0, sourceBrightness, dimWeight);
   #endif

   #ifdef COLORED_LIGHT
      // held-light hue: the light around the player comes from the item in
      // hand (shader hand light and/or LambDynamicLights through the vanilla
      // lightmap), so close to the camera the held item's palette color
      // replaces the default warm torch color - but never the voxel field of
      // placed sources (see voxelBlend below). checks both hands; reach
      // scales with the item's nominal light level
      int handId = heldItemId >= 10000 && heldItemId < 20000 ? heldItemId
                 : heldItemId2 >= 10000 && heldItemId2 < 20000 ? heldItemId2 : 0;

      if (handId != 0) {
         float handReach = 15.0 * getLightPaletteLevel(handId);
         float handMix = 1.0 - rescale(SQRT_2 * length(feetPos), 0.3 * handReach, handReach);

         vec3 handPalette = getLightPaletteColor(handId);
         vec3 handHue = handPalette * (luma(torchColor) / max(luma(handPalette), 0.001));

         // the field wins where placed sources have established their color,
         // but the item in hand is at zero distance: its veto is lifted as the
         // surface approaches the player, so a torch held next to a green
         // lantern still lights the ground at your feet orange. further out
         // (handClose small) placed sources keep their color as before
         float handClose = smoothe(handMix);
         float handApply = handClose * (1.0 - voxelBlend * (1.0 - 0.7 * handClose));

         torchColor = mix(torchColor, handHue, handApply);

         // same rule as placed sources: the palette's highest slider is the
         // light's brightness (0.75 knee), so a dark palette dims the held
         // light too while normal palettes keep full brightness
         strength *= mix(1.0, clamp(max(handPalette.r, max(handPalette.g, handPalette.b)) / 0.75, 0.0, 1.0), handApply);
      }

      // the strength slider deepens the color's saturation. above 1.0 the mix
      // EXTRAPOLATES past the palette color, which is what gives strong hues
      // their punch - but it also inflates the peak channel (lava 1.0 -> 1.23)
      // and that overflow is what floods an area in one blinding hue.
      // so: keep the extrapolation, then RESCALE back to the color's original
      // peak instead of letting it clip. purer hue, same brightness
      float torchPeak = max(torchColor.r, max(torchColor.g, torchColor.b));

      torchColor = max(vec3(0.0), mix(
         vec3(luma(torchColor)),
         torchColor,
         0.5 + 0.5*COLORED_LIGHT_STRENGTH
      ));

      torchColor *= torchPeak / max(max(torchColor.r, max(torchColor.g, torchColor.b)), 1.0e-4);
   #endif

   return max(0.0, 1.0 - luma(ambient)) * strength * torchColor;
}
