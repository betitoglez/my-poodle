"""Construye el atlas del caniche por capas a partir de las imágenes de Meshy.

Uso (desde la raíz del repo):  python3 tool/arte/build_pet_sprites.py

Lee tool/arte/pet_sprites_spec.json y escribe assets/images/pet/*.webp y
assets/data/pet-sprites-v1.json. Todas las capas de una pose comparten lienzo,
escala y ancla, de modo que se superponen sin ajustes en el juego.
Requiere Pillow. No llama a ninguna API.
"""
import json
import os
import sys

from PIL import Image, ImageChops, ImageFilter, ImageStat

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
FUR_HUE = (8, 30)  # tono anaranjado del pelo en escala PIL (0-255)


def load(src_dir, name):
    return Image.open(os.path.join(ROOT, src_dir, name + '.webp')).convert('RGBA')


def on_bg(im, color):
    bg = Image.new('RGBA', im.size, color + (255,))
    bg.alpha_composite(im)
    return bg.convert('RGB')


def defringe(im, px=2):
    """Quita el halo claro del recorte de fondo erosionando el alfa."""
    a = im.split()[-1].filter(ImageFilter.MinFilter(px * 2 + 1)).filter(ImageFilter.GaussianBlur(0.8))
    out = im.copy()
    out.putalpha(a)
    return out


def match_color(src, ref):
    """Iguala media y desviación por canal del pelo de src con ref."""
    ms, mr = src.split()[-1], ref.split()[-1]
    s, r = ImageStat.Stat(src.convert('RGB'), ms), ImageStat.Stat(ref.convert('RGB'), mr)
    chans = []
    for i, c in enumerate(src.convert('RGB').split()):
        k = r.stddev[i] / max(s.stddev[i], 1)
        chans.append(c.point(lambda x, i=i, k=k: max(0, min(255, int((x - s.mean[i]) * k + r.mean[i])))))
    out = Image.merge('RGB', chans).convert('RGBA')
    out.putalpha(ms)
    return out


def extract_layer(variant, base, threshold=38, opening=7, close=15):
    """Capa = píxeles de la variante que difieren de la base.
    Diferencia máxima por canal: distingue tonos de igual luminancia."""
    d = ImageChops.difference(on_bg(variant, (0, 0, 0)), on_bg(base, (0, 0, 0))).split()
    diff = ImageChops.lighter(ImageChops.lighter(d[0], d[1]), d[2])
    m = diff.point(lambda x: 255 if x > threshold else 0)
    m = m.filter(ImageFilter.MinFilter(opening)).filter(ImageFilter.MaxFilter(opening))
    m = m.filter(ImageFilter.MaxFilter(close)).filter(ImageFilter.MinFilter(close))
    m = m.filter(ImageFilter.GaussianBlur(1.0))
    m = ImageChops.multiply(m, variant.split()[-1])
    out = variant.copy()
    out.putalpha(m)
    return out


def strip_fur(layer):
    """Quita el pelo anaranjado de una prenda de otro tono (lo aporta la base
    teñida). No se aplica si la prenda es de un tono cercano al pelo."""
    h, s, _ = layer.convert('RGB').convert('HSV').split()
    a = layer.split()[-1]
    hues = [hv for hv, av, sv in zip(h.getdata(), a.getdata(), s.getdata()) if av > 200 and sv > 60]
    if not hues:
        return layer
    hues.sort()
    dominant = hues[len(hues) // 2]
    if FUR_HUE[0] - 12 <= dominant <= FUR_HUE[1] + 12:
        return layer
    fur = Image.eval(h, lambda x: 255 if FUR_HUE[0] <= x <= FUR_HUE[1] else 0)
    out = layer.copy()
    out.putalpha(ImageChops.subtract(a, fur))
    return out


def feet_anchor(base, mode):
    a = base.split()[-1].point(lambda v: 255 if v > 128 else 0)
    l, t, r, b = a.getbbox()
    if mode == 'bottom':
        return (l + r) / 2, b
    band = a.crop((0, int(b - (b - t) * 0.04), a.width, b)).getbbox()
    return (band[0] + band[2]) / 2, b


def main():
    spec = json.load(open(os.path.join(ROOT, 'tool/arte/pet_sprites_spec.json')))
    src, out_dir = spec['sourceDir'], os.path.join(ROOT, spec['outDir'])
    os.makedirs(out_dir, exist_ok=True)
    for f in os.listdir(out_dir):
        if f.endswith('.webp'):
            os.remove(os.path.join(out_dir, f))
    ref_hair = spec['referenceHair']
    meta = {'schemaVersion': 1, 'unitHeightPx': spec['unitHeightPx'], 'poses': {}, 'hair': {}, 'items': {},
            'expressions': {}, 'coats': spec['coats']}

    # Unidad por pose de origen: altura del caniche de referencia (pies a cabeza).
    unit_src = {}
    for pose in spec['poses']:
        base = load(src, spec['hair'][ref_hair][pose])
        a = base.split()[-1].point(lambda v: 255 if v > 128 else 0)
        _, t, _, b = a.getbbox()
        unit_src[pose] = b - t

    for pose, pinfo in spec['poses'].items():
        ref = defringe(load(src, spec['hair'][ref_hair][pose]))
        layers = {}
        for hid, poses in spec['hair'].items():
            im = defringe(load(src, poses[pose]))
            if hid != ref_hair:
                im = match_color(im, ref)
            layers[('hair', hid)] = im
        for iid, poses in spec['items'].items():
            if pose in poses:
                raw = load(src, poses[pose])
                layers[('items', iid)] = strip_fur(extract_layer(raw, load(src, spec['hair'][ref_hair][pose])))
        for eid, poses in spec.get('expressions', {}).items():
            if pose in poses:
                raw = load(src, poses[pose])
                layers[('expressions', eid)] = extract_layer(raw, load(src, spec['hair'][ref_hair][pose]),
                                                             threshold=30, opening=3, close=11)

        # Lienzo común: unión de las cajas de todas las capas de la pose.
        boxes = [im.split()[-1].point(lambda v: 255 if v > 10 else 0).getbbox() for im in layers.values()]
        boxes = [b for b in boxes if b]
        pad = 6
        box = (max(0, min(b[0] for b in boxes) - pad), max(0, min(b[1] for b in boxes) - pad),
               min(ref.width, max(b[2] for b in boxes) + pad), min(ref.height, max(b[3] for b in boxes) + pad))
        scale = spec['unitHeightPx'] / unit_src[pinfo['unitFrom']]
        size = (round((box[2] - box[0]) * scale), round((box[3] - box[1]) * scale))
        ax, ay = feet_anchor(ref, pinfo['anchor'])
        meta['poses'][pose] = {'size': list(size), 'anchor': [round((ax - box[0]) * scale, 1), round((ay - box[1]) * scale, 1)]}

        for (kind, lid), im in layers.items():
            im = im.crop(box).resize(size, Image.LANCZOS)
            name = f"{pose}__{lid.replace('.', '_')}.webp"
            im.save(os.path.join(out_dir, name), quality=90, method=6)
            meta[kind].setdefault(lid, {})[pose] = name
        print(f'{pose}: lienzo {size}, ancla {meta["poses"][pose]["anchor"]}, {len(layers)} capas')

    with open(os.path.join(ROOT, spec['metaOut']), 'w') as f:
        json.dump(meta, f, indent=2, ensure_ascii=False)
        f.write('\n')
    print('Escrito', spec['metaOut'])


if __name__ == '__main__':
    sys.exit(main())
