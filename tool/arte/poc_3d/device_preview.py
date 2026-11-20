"""Export individual pose previews and the gallop loops for the Flutter preview.

blender -b docs/reviews/wardrobe-3d/My-Poodle-vestuario.blend \
  --python-exit-code 1 --python tool/arte/poc_3d/device_preview.py -- OUTPUT
"""
from pathlib import Path
import sys

import bpy

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build import OUTFITS, POSES, render


def main():
    output = Path(sys.argv[sys.argv.index("--") + 1])
    output.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.resolution_x = scene.render.resolution_y = 420
    scene.cycles.samples = 12
    dog = bpy.data.objects["Caniche · malla Meshy"]
    hairstyle = dog.data.shape_keys.key_blocks["Corte pompón"]
    boots = bpy.data.collections["Botas"]
    for hair in ("osito", "pompon"):
        for outfit, visible in OUTFITS.items():
            for name in set().union(*OUTFITS.values()):
                collection = bpy.data.collections[name]
                collection.hide_render = collection.hide_viewport = name not in visible
            hairstyle.value = (0.10 if outfit == "impermeable" else 1.0) if hair == "pompon" else 0.0
            for boot in boots.objects:
                if boot.data.shape_keys:
                    boot.data.shape_keys.key_blocks["Caña bajo la pernera"].value = float(outfit == "peto")
            prefix = f"{hair}-{outfit}"
            for view, frame in {**POSES, "arriba": 0, "perfil-izquierdo": 0}.items():
                render(scene, scene.camera, frame, view, output / f"{prefix}-{view}.png")
            for index, frame in enumerate(range(1, 25, 2)):
                render(scene, scene.camera, frame, "perfil", output / f"{prefix}-carrera-{index:02d}.png")


if __name__ == "__main__":
    main()
