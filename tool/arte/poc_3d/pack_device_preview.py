"""Make lightweight, offline preview assets from the Blender PNG frames."""
import argparse
from pathlib import Path

from PIL import Image


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("renders", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    for hair in ("osito", "pompon"):
        for outfit in ("peto", "vestido", "impermeable"):
            prefix = f"{hair}-{outfit}"
            for pose in ("frente", "perfil", "perfil-izquierdo", "arriba",
                         "espalda", "extension", "recogida"):
                with Image.open(args.renders / f"{prefix}-{pose}.png") as shot:
                    shot.save(args.output / f"{prefix}-{pose}.webp", quality=87)
            frames = []
            for index in range(12):
                with Image.open(args.renders / f"{prefix}-carrera-{index:02d}.png") as shot:
                    frames.append(shot.convert("RGBA"))
            frames[0].save(
                args.output / f"{prefix}-carrera.webp", quality=83, save_all=True,
                append_images=frames[1:], duration=[83, 84, 83] * 4, loop=0,
            )


if __name__ == "__main__":
    main()
