# Miniature XL

A fork of [Miniature Shader](https://github.com/MateusKreuch/miniature-shader) 2.19 by Mateus A. Kreuch, extended with voxel-based colored lighting and a set of related features. MIT licensed, as the original is.

Built and tested against **Minecraft 1.21.11 / Iris 1.10.7**. Other versions are untested.

## Installing

Download or clone this repository, zip the contents (`shaders/` and `LICENSE` must be at the archive root, not inside an extra folder), and drop the zip into `.minecraft/shaderpacks`.

```
MiniatureXL_1.0.zip
├── LICENSE
└── shaders/
```

Alternatively, place the unzipped folder directly in `shaderpacks` — Iris loads folders too, which is more convenient while editing.

> **Iris stores your in-game option values in `<packname>.zip.txt` next to the pack, and those override the pack's own defaults.** Renaming the zip orphans the old settings file and reverts everything to defaults; keeping the name means new defaults shipped in an update will *not* apply to options you have already touched. Delete that file to pick up the shipped defaults.

## What this fork adds

**Voxel colored lighting.** Light sources write their palette color into a 3D volume during the shadow pass; a compute shader flood-fills it every frame; the gbuffers read it back and tint the vanilla light accordingly. Intensity stays vanilla — only the hue comes from the voxel field, so light never appears where Minecraft has none.

- per-block-type palette with configurable colors (torch, soul, lava, redstone, amethyst, sea, portal, glowstone, end rod, glow lichen), plus fixed colors for froglights, copper torches/lanterns and sculk sensors
- adjustable volume size (64–512 blocks, height doubles past 256), range, falloff softness, block light softness and color transition speed
- works in the Overworld, the Nether and the End
- dynamic lights from held items, dropped items, item frames, burning mobs and flaming arrows, and intrinsically glowing mobs
- lava follows a resource pack's biome tint (tested with Nature X) for both its surface and the light it casts

**Lighting and sky.** Sky color screen (sun at noon/dusk, sky tint by time of day) wired into the ambient ground light; time-of-day shadow opacity (full strength by day, faint at night) instead of shadows fading out entirely.

**Bloom.** Per-category pixel cutoffs so only the emitting pixels of a block glow (torch flame yes, torch stick no), per-category glow ceilings and hue correction, beacon beam glow, and an optional enchantment glint glow.

**Voxy compatibility.** LOD terrain is excluded from the emissive-overlay glow path, the pack's stylized shading fades back to vanilla before the render distance so the LOD handoff has no visible seam, and translucent blocks purge the glow buffer so LODs seen through tinted glass do not light up.

## Settings

Everything lives in the in-game shader options under **Colored light**, **Light colors**, **Sky colors**, **Shadows** and **Bloom**. `shaders/shader.h` holds the defaults.

## Validating changes

```sh
apt install glslang-tools      # or your platform's equivalent
python3 check.py               # -v to list every variant
```

`check.py` expands the includes the way Iris does and compiles every program in every dimension across all the option combinations that change generated code — 2781 compilations — plus two structural checks that encode Iris quirks this pack has already been bitten by. It runs on every push via GitHub Actions.

It catches syntax errors, undeclared identifiers and varying mismatches before a Minecraft launch. It cannot catch linking, uniform binding or runtime behaviour.

## For maintainers

`CLAUDE.md` holds the Iris constraints, the colored-light architecture and the rules that changes must respect. `DEVLOG.md` holds the history: every bug, its actual cause, and the approaches that were tried and rejected.

## Credits

Original shader © 2022 Mateus A. Kreuch, MIT. See `LICENSE` for the full text and the list of modifications.
