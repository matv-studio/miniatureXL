#!/usr/bin/env python3
"""
Offline GLSL validation harness for Miniature XL.

Iris compiles every file under shaders/world0, world-1 and world1 as a
standalone program: each is a thin wrapper holding `#version`, the dimension
define and an `#include` of the shared implementation in shaders/program.
This script reproduces that: it expands the includes itself, applies the two
shims glslangValidator needs (see SHIMS below) and compiles every wrapper, for
every combination of shader options that changes the generated code.

It catches what the GPU would only tell you after a full Minecraft launch:
syntax errors, undeclared identifiers, varyings declared in the vertex stage
but not the fragment stage, and code paths that only exist under some option
combination. It cannot catch linking, uniform binding or runtime behaviour.

Usage:  python3 check.py [-v]
Needs:  glslangValidator  (Debian/Ubuntu: apt install glslang-tools)
Exit:   0 if every variant compiles, 1 otherwise.
"""

import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "shaders")
VERBOSE = "-v" in sys.argv

# Symbols Iris injects into every shader. The pack reads them to gate the
# colored-light path, so validation has to supply them too.
IRIS_DEFINES = [
    "IS_IRIS",
    "IRIS_FEATURE_COMPUTE_SHADERS",
    "IRIS_FEATURE_CUSTOM_IMAGES",
    "IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE",
    "MC_VERSION=12111",
    "SHADOW_ENTITY=1",
]

# ---------------------------------------------------------------- include pass

_INCLUDE = re.compile(r'(?m)^[ \t]*#include[ \t]+"([^"]+)"[ \t]*$')


def expand(path, seen=None, depth=0):
    """Resolve #include "/abs/path/in/shaders" recursively, like Iris does."""
    if depth > 32:
        raise RuntimeError("include depth exceeded at " + path)

    with open(path, "r", encoding="utf-8", errors="replace") as fh:
        src = fh.read()

    def sub(match):
        target = match.group(1).lstrip("/")
        return expand(os.path.join(ROOT, target), seen, depth + 1)

    return _INCLUDE.sub(sub, src)


# ---------------------------------------------------------------------- shims

def apply_shims(text, stage):
    """
    Two deliberate deviations from what the driver sees:

    1. `flat varying` is rejected by glslang in strict GLSL 120 but accepted by
       every real driver (and required: the pack passes per-primitive ints
       through it). Downgraded to plain `varying` for validation only.
    2. image load/store is rejected in GLSL 120 even with the ARB extension
       enabled, while drivers accept it (verified in game). The image3D
       declaration is replaced by a no-op imageStore macro.
    """
    text = re.sub(r"(?m)^(\s*)flat varying", r"\1varying", text)

    # gl_VertexID exists from GLSL 130 on; Iris raises the version itself
    # before handing the shader to the driver, glslang does not
    if "gl_VertexID" in text:
        text = re.sub(r"(?m)^[ \t]*#version[ \t]+120\b.*$", "#version 130", text)

    # Colorwheel compatibility programs call a function the MOD injects at
    # load time; it has no definition inside the pack, so declare a prototype
    if "clrwl_computeFragment" in text:
        text = text.replace(
            "#define MOD_COLORWHEEL",
            "#define MOD_COLORWHEEL\n"
            "void clrwl_computeFragment(vec4 a, out vec4 b, out vec2 c,"
            " out float d, out vec4 e);",
            1,
        )

    if stage in ("vert", "frag") and "image3D" in text:
        text = text.replace(
            "layout (rgba8) uniform image3D voxelData;",
            "#define imageStore(img, p, v)",
        )

    return text


_DEFINE_LINE = "(?m)^[ \\t]*#define[ \\t]+%s\\b.*\\n"


def build_source(wrapper, extra_defines, strip_defines):
    """version line + injected defines + expanded body, options removed."""
    body = expand(wrapper)

    version = ""
    match = re.search(r"(?m)^[ \t]*#version[^\n]*\n", body)
    if match:
        version = match.group(0)
        body = body[: match.start()] + body[match.end():]

    # simulate an option switched off in the Iris menu: Iris deletes the
    # #define line outright, it does not set it to 0
    for name in strip_defines:
        body = re.sub(_DEFINE_LINE % re.escape(name), "", body)

    header = ""
    for d in IRIS_DEFINES + list(extra_defines):
        if "=" in d:
            name, value = d.split("=", 1)
            header += "#define %s %s\n" % (name, value)
        else:
            header += "#define %s\n" % d

    return version + header + body


STAGE_EXT = {".vsh": "vert", ".fsh": "frag", ".csh": "comp"}
GLSL_EXT = {"vert": ".vert", "frag": ".frag", "comp": ".comp"}


def validate(wrapper, label, extra_defines=(), strip_defines=()):
    stage = STAGE_EXT[os.path.splitext(wrapper)[1]]
    text = apply_shims(build_source(wrapper, extra_defines, strip_defines), stage)

    with tempfile.NamedTemporaryFile(
        "w", suffix=GLSL_EXT[stage], delete=False, encoding="utf-8"
    ) as tf:
        tf.write(text)
        tmp = tf.name

    try:
        run = subprocess.run(
            ["glslangValidator", tmp], capture_output=True, text=True
        )
    finally:
        os.unlink(tmp)

    ok = run.returncode == 0

    if not ok:
        print("FAIL  " + label)
        for line in (run.stdout + run.stderr).splitlines():
            if line.strip() and not line.startswith(tmp):
                print("        " + line)
    elif VERBOSE:
        print("pass  " + label)

    return ok


# -------------------------------------------------------------- option matrix

def wrappers():
    """Every program Iris will actually compile, in a stable order."""
    out = []
    for world in ("world0", "world-1", "world1"):
        folder = os.path.join(ROOT, world)
        if not os.path.isdir(folder):
            continue
        for name in sorted(os.listdir(folder)):
            if os.path.splitext(name)[1] in STAGE_EXT:
                out.append((world, name, os.path.join(folder, name)))
    return out


# each entry: (label, extra defines, defines to strip).
# only options that change generated code are worth a full sweep - value
# sliders compile the same code whatever the number.
VARIANTS = [
    ("defaults", (), ()),
    ("no colored light", (), ("COLORED_LIGHT",)),
    ("no entity light", (), ("CL_ENTITY_LIGHT",)),
    ("no item light", (), ("CL_ITEM_LIGHT",)),
    ("no entity+item light", (), ("CL_ENTITY_LIGHT", "CL_ITEM_LIGHT")),
    ("no lava texture", (), ("CL_LAVA_TEXTURE",)),
    ("no bloom", (), ("BLOOM",)),
    ("no emissive textures", (), ("BLOOM_EMISSIVE_TEXTURES",)),
    ("no enchant bloom", (), ("BLOOM_ENCHANT",)),
    ("no shadows", (), ("ENABLE_SHADOWS",)),
    ("no sky", (), ("ENABLE_SKY",)),
    ("flat lighting off", (), ("FLAT_LIGHTING",)),
    ("no glowing ores", (), ("GLOWING_ORES",)),
    ("no fog", (), ("ENABLE_FOG",)),
    ("no sun shafts", (), ("SUN_SHAFTS",)),
    ("no nether grading", (), ("NETHER_COLOR_GRADING",)),
    ("no emission attribute", (), ("IRIS_FEATURE_BLOCK_EMISSION_ATTRIBUTE",)),
    ("voxy", ("VOXY",), ()),
    ("voxy, no colored light", ("VOXY",), ("COLORED_LIGHT",)),
    ("optifine (no iris)", (), ("IS_IRIS",)),
]

# the voxel volume size drives preprocessor branches in shader.h,
# shaders.properties and the compute dispatch - every value gets its own pass
VOXEL_SIZES = [64, 128, 192, 256, 384, 512]
for size in VOXEL_SIZES:
    VARIANTS.append(
        ("VOXEL_SIZE=%d" % size, ("VOXEL_SIZE=%d" % size,), ("VOXEL_SIZE",))
    )

# the range slider is capped against the volume width by a preprocessor
# comparison: check both sides of that branch
VARIANTS.append(
    (
        "range 256 > volume 64 (capped)",
        ("VOXEL_SIZE=64", "COLORED_LIGHT_RANGE=256"),
        ("VOXEL_SIZE", "COLORED_LIGHT_RANGE"),
    )
)


# ------------------------------------------------------- iris-specific checks

def check_work_groups():
    """
    Iris parses `const ivec3 workGroups` TEXTUALLY, before any preprocessing:
    ComputeDirectiveParser reads the literal characters between the commas and
    calls Integer.parseInt on them. `VOXEL_SIZE / 8` throws
    NumberFormatException and the whole pack fails to load with no useful
    message. Every component must be a bare integer literal, which forces the
    per-size #if branches in shadowcomp.csh.
    """
    path = os.path.join(ROOT, "program", "shadowcomp.csh")

    if not os.path.isfile(path):
        print("FAIL  workGroups: shadowcomp.csh missing")
        return False

    with open(path, "r", encoding="utf-8") as fh:
        source = fh.read()

    found = re.findall(
        r"const\s+ivec3\s+workGroups\s*=\s*ivec3\s*\(([^)]*)\)", source
    )

    if not found:
        print("FAIL  workGroups: no declaration found in shadowcomp.csh")
        return False

    ok = True
    for args in found:
        for part in args.split(","):
            if not re.fullmatch(r"\s*\d+\s*", part):
                print(
                    "FAIL  workGroups: '%s' is not an integer literal "
                    "(Iris parses this textually)" % part.strip()
                )
                ok = False

    if ok and VERBOSE:
        print("pass  workGroups: %d declaration(s), all literal" % len(found))

    return ok


def check_block_properties_unique():
    """
    A block may appear in only ONE block.properties group: Iris applies the
    entries top to bottom and a later group silently overwrites an earlier one.
    This cost two debugging rounds (copper lanterns kept their reflectivity
    group and never reached the colored-light palette), so it is checked here.
    """
    path = os.path.join(ROOT, "block.properties")

    if not os.path.isfile(path):
        print("FAIL  block.properties missing")
        return False

    owner = {}
    duplicates = []

    with open(path, "r", encoding="utf-8") as fh:
        for raw in fh:
            line = raw.strip()
            if not line.startswith("block."):
                continue
            head, _, rest = line.partition("=")
            group = head.strip()
            for block in rest.split():
                if block in owner and owner[block] != group:
                    duplicates.append((block, owner[block], group))
                owner[block] = group

    for block, first, second in duplicates:
        print(
            "FAIL  block.properties: '%s' is in both %s and %s "
            "(the last one wins, the first is ignored)" % (block, first, second)
        )

    if not duplicates and VERBOSE:
        print("pass  block.properties: %d unique blocks" % len(owner))

    return not duplicates


# ---------------------------------------------------------------------- main

def main():
    if subprocess.run(
        ["which", "glslangValidator"], capture_output=True
    ).returncode != 0:
        print("glslangValidator not found (apt install glslang-tools)")
        return 1

    programs = wrappers()

    if not programs:
        print("no shader wrappers found under " + ROOT)
        return 1

    failures = 0
    total = 0

    print("%d programs x %d variants" % (len(programs), len(VARIANTS)))

    for label, extra, strip in VARIANTS:
        broken = 0
        for world, name, path in programs:
            total += 1
            if not validate(
                path, "%-30s %s/%s" % (label, world, name), extra, strip
            ):
                broken += 1
        if broken:
            failures += broken
            print("  %-30s %d FAILED" % (label, broken))

    structural = [check_work_groups(), check_block_properties_unique()]
    failures += structural.count(False)

    print("")
    if failures:
        print("FAILED: %d of %d checks" % (failures, total + len(structural)))
        return 1

    print("OK: %d shader compilations + %d structural checks passed"
          % (total, len(structural)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
