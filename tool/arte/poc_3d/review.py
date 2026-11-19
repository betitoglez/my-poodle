"""Compose contact sheets and the gallop loop from Blender renders."""
import argparse
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont


BACKGROUND = "#F3EDE4"
INK = "#322923"
SUBTLE = "#665750"
FONTS = Path("/System/Library/Fonts/Supplemental/")
VIEWS = {
    "frente": "Frente",
    "perfil": "Perfil",
    "espalda": "Espalda",
    "extension": "Carrera · extensión",
    "recogida": "Carrera · recogida",
}
ANGLES = {
    "frente": "Frente",
    "perfil-izquierdo": "Perfil izquierdo",
    "perfil": "Perfil derecho",
    "arriba": "Desde arriba",
    "espalda": "Espalda",
}
OUTFITS = {
    "peto": ("Peto verde", "Pañuelo coral · botas de lluvia"),
    "vestido": ("Vestido rosa", "Lazo · botas de lluvia"),
    "impermeable": ("Impermeable azul", "Gorro · gafas redondas"),
}
CELL = 294
ROW = 270
HEADER = 104


def font(size, bold=False):
    filename = "Arial Bold.ttf" if bold else "Arial.ttf"
    path = FONTS / filename
    return ImageFont.truetype(str(path) if path.exists() else "DejaVuSans.ttf", size)


def board(title, subtitle, rows, views=VIEWS):
    sheet = Image.new("RGB", (CELL * 5, HEADER + ROW * rows), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    draw.text((23, 16), title, font=font(29, True), fill=INK)
    draw.text((24, 55), subtitle, font=font(16), fill=SUBTLE)
    for i, label in enumerate(views.values()):
        draw.text((i * CELL + CELL / 2, 86), label, anchor="mm", font=font(16), fill=INK)
    return sheet, draw


def with_shadow(image):
    shadow = Image.new("RGBA", image.size)
    span = image.width
    ImageDraw.Draw(shadow).ellipse((span * 0.29, span * 0.769, span * 0.71, span * 0.795),
                                  fill=(65, 51, 40, 54))
    return Image.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(4)), image)


def paste_sprite(sheet, path, column, row, *, overhead=False):
    image = Image.open(path).convert("RGBA")
    side = min(image.size)
    if not overhead:
        image = with_shadow(image).crop((0, 0, side, side * 0.875))
    image.thumbnail((CELL - 6, ROW - 40), Image.Resampling.LANCZOS)
    x = column * CELL + (CELL - image.width) // 2
    y = HEADER + row * ROW + ROW - image.height - 4
    sheet.paste(image, (x, y), image)


def row_heading(draw, row, title, description):
    y = HEADER + row * ROW
    draw.line((22, y, CELL * 5 - 22, y), fill="#DDD1C6")
    draw.text((23, y + 8), title, font=font(19, True), fill=INK)
    draw.text((23, y + 31), description, font=font(14), fill=SUBTLE)


def outfits(renders, output, haircut, label):
    sheet, draw = board(
        f"Vestuario 3D · corte {label}",
        "Renders de Blender de la misma malla de Meshy y el mismo esqueleto",
        len(OUTFITS),
    )
    for row, (outfit, (title, detail)) in enumerate(OUTFITS.items()):
        row_heading(draw, row, title, detail)
        for column, view in enumerate(VIEWS):
            paste_sprite(sheet, renders / f"{haircut}-{outfit}-{view}.png", column, row)
    sheet.save(output / f"{haircut}.png", optimize=True)


def angles(renders, output, haircut, label):
    sheet, draw = board(
        f"Vestuario 3D desde cinco ángulos · corte {label}",
        "Los dos perfiles, la vista cenital y la espalda de cada conjunto",
        len(OUTFITS), ANGLES,
    )
    for row, (outfit, (title, detail)) in enumerate(OUTFITS.items()):
        row_heading(draw, row, title, detail)
        for column, view in enumerate(ANGLES):
            paste_sprite(sheet, renders / f"{haircut}-{outfit}-{view}.png", column, row,
                         overhead=view == "arriba")
    sheet.save(output / f"angulos-{haircut}.png", optimize=True)


def details(renders, output):
    captions = (
        ("Peto de pana", "Bolsillos pespunteados · pañuelo de algodón"),
        ("Vestido de popelina", "Dos volantes · cinta de grosgrain · lazo plegado"),
        ("Impermeable de lona encerada", "Punto de lana · montura de acetato"),
    )
    width, height, cell = 1440, 565, 480
    sheet = Image.new("RGB", (width, height), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    draw.text((26, 21), "Vestuario 3D · detalle de las prendas", font=font(30, True), fill=INK)
    draw.line((25, 68, width - 25, 68), fill="#DCCFC3")
    for column, (outfit, (title, caption)) in enumerate(zip(OUTFITS, captions)):
        image = Image.open(renders / f"detalle-{outfit}.png").convert("RGBA")
        image.thumbnail((464, 456), Image.Resampling.LANCZOS)
        sheet.paste(image, (column * cell + (cell - image.width) // 2, 86), image)
        draw.text((column * cell + 25, 80), title, font=font(19, True), fill=INK)
        draw.text((column * cell + 25, 111), caption, font=font(14), fill=SUBTLE)
    sheet.save(output / "detalles-de-ropa.png", optimize=True)


def glasses_fit(renders, output):
    cell, height = 372, 435
    sheet = Image.new("RGB", (cell * 3, height), BACKGROUND)
    draw = ImageDraw.Draw(sheet)
    draw.text((23, 17), "Montura Meshy · ajuste en Blender", font=font(28, True), fill=INK)
    draw.line((23, 62, cell * 3 - 23, 62), fill="#DDD1C6")
    for column, (view, label) in enumerate((
        ("frente", "Frente"), ("tres-cuartos", "Tres cuartos"), ("perfil", "Perfil derecho"),
    )):
        image = Image.open(renders / f"gafas-{view}.png").convert("RGBA")
        image.thumbnail((cell - 34, 327), Image.Resampling.LANCZOS)
        x = column * cell + (cell - image.width) // 2
        sheet.paste(image, (x, 94), image)
        draw.text((column * cell + 23, 70), label, font=font(15), fill=SUBTLE)
    sheet.save(output / "gafas-ajuste.png", optimize=True)


def compare(renders, output, reference):
    sheet, draw = board("Peto y botas · comparación 2D y 3D",
                         "Corte osito · albaricoque · cinco poses", 2)
    row_heading(draw, 0, "2D articulado", "Captura del pintor de Flutter")
    row_heading(draw, 1, "3D prerenderizado", "Malla de Meshy y ropa de Blender")
    previous = Image.open(reference).convert("RGB")
    for column, view in enumerate(VIEWS):
        cell = previous.crop((354 * column + 4, 112, 354 * (column + 1) - 4, 391))
        cell.thumbnail((CELL - 10, ROW - 50), Image.Resampling.LANCZOS)
        x = column * CELL + (CELL - cell.width) // 2
        y = HEADER + ROW - cell.height - 4
        sheet.paste(cell, (x, y))
        paste_sprite(sheet, renders / f"osito-peto-{view}.png", column, 1)
    row_heading(draw, 0, "2D articulado", "Captura del pintor de Flutter")
    sheet.save(output / "comparativa-2d-3d.png", optimize=True)


def gif(renders, output):
    frames = []
    for path in sorted(renders.glob("carrera-*.png")):
        image = with_shadow(Image.open(path).convert("RGBA"))
        bg = Image.new("RGBA", image.size, BACKGROUND)
        frames.append(Image.alpha_composite(bg, image).convert("RGB"))
    if len(frames) != 12:
        raise ValueError(f"Se esperaban 12 fotogramas, hay {len(frames)}")
    frames[0].save(output / "carrera-peto.gif", save_all=True, append_images=frames[1:],
                   duration=[80, 90] * 6, loop=0, optimize=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("renders", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("reference", type=Path, nargs="?")
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    outfits(args.renders, args.output, "osito", "osito")
    outfits(args.renders, args.output, "pompon", "pompón")
    if args.reference:
        compare(args.renders, args.output, args.reference)
    if (args.renders / "osito-peto-arriba.png").exists():
        angles(args.renders, args.output, "osito", "osito")
        angles(args.renders, args.output, "pompon", "pompón")
    if (args.renders / "detalle-peto.png").exists():
        details(args.renders, args.output)
    if (args.renders / "gafas-frente.png").exists():
        glasses_fit(args.renders, args.output)
    gif(args.renders, args.output)


if __name__ == "__main__":
    main()
