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


def centroid(im, thr=200):
    a = im.split()[-1].point(lambda v: 255 if v > thr else 0).filter(ImageFilter.MinFilter(5))
    sx = sy = n = 0
    w, h = a.size
    px = a.load()
    for y in range(0, h, 2):
        for x in range(0, w, 2):
            if px[x, y]:
                sx += x
                sy += y
                n += 1
    return (sx / n, sy / n) if n else None


def row_extent(mask, y):
    px = mask.load()
    xs = [x for x in range(mask.width) if px[x, int(y)]]
    return (xs[0], xs[-1]) if xs else None


def landmarks(pose, base, layers, view):
    """Puntos del cuerpo en píxeles del lienzo original (antes de recortar),
    calculados de la silueta y de las capas. Sirven para colocar espuma,
    mechones, el disco del frisbee o futuros accesorios sin tocar código."""
    m = base.split()[-1].point(lambda v: 255 if v > 128 else 0)
    l, t, r, b = m.getbbox()
    h = b - t
    out = {'paws': ((l + r) / 2, b - h * 0.05), 'headTop': None}
    top = row_extent(m, t + h * 0.03)
    out['headTop'] = ((top[0] + top[1]) / 2 if top else (l + r) / 2, t + h * 0.06)
    if view == 'front':
        eyes = centroid(layers[('expressions', 'blink')], 60) if ('expressions', 'blink') in layers else None
        eyes = eyes or ((l + r) / 2, t + h * 0.19)
        out['eyes'] = eyes
        mouth = centroid(layers[('expressions', 'happy')], 60) if ('expressions', 'happy') in layers else None
        out['mouth'] = mouth or (eyes[0], eyes[1] + h * 0.15)
        ear = row_extent(m, eyes[1] + h * 0.06)
        out['earRight'] = (ear[1] - h * 0.06, eyes[1] + h * 0.06)
        out['earLeft'] = (ear[0] + h * 0.06, eyes[1] + h * 0.06)
        neck = centroid(layers[('items', 'neck.coral')]) if ('items', 'neck.coral') in layers else None
        out['neck'] = neck or (eyes[0], t + h * 0.45)
        # Pecho por debajo del pañuelo; costados en los bordes del torso.
        chest_y = out['neck'][1] + h * 0.18
        out['chest'] = (out['neck'][0], chest_y)
        flank_y = out['neck'][1] + h * 0.1
        side = row_extent(m, flank_y)
        out['flankRight'] = (side[1] - h * 0.035, flank_y)
        out['flankLeft'] = (side[0] + h * 0.035, flank_y)
        shoulder = row_extent(m, out['neck'][1] + h * 0.02)
        out['shoulderLeft'] = (shoulder[0] + h * 0.07, out['neck'][1] + h * 0.02)
        out['shoulderRight'] = (shoulder[1] - h * 0.07, out['neck'][1] + h * 0.02)
    elif view == 'side':
        # Perfil mirando a la derecha: hocico = punto más a la derecha de la
        # mitad superior; boca un poco por debajo y detrás.
        upper = m.crop((0, t, m.width, int(t + h * 0.5)))
        ub = upper.getbbox()
        nose_x = ub[2]
        col = [y for y in range(upper.height) if upper.getpixel((nose_x - 3, y))]
        nose_y = t + (sum(col) / len(col) if col else h * 0.25)
        out['mouth'] = (nose_x - h * 0.08, nose_y + h * 0.05)
        neck = centroid(layers[('items', 'neck.coral')]) if ('items', 'neck.coral') in layers else None
        out['neck'] = neck or (nose_x - h * 0.3, nose_y + h * 0.15)
    return out


def params_for(spec, item_id):
    """Parámetros de extracción: coincidencia exacta o por categoría («head.*»)."""
    ex = spec.get('extract', {})
    base = {}
    for key in (item_id.split('.')[0] + '.*', item_id):
        if key in ex:
            base = {**base, **ex[key]}
    return base


def alpha_box(im, thr=10):
    return im.split()[-1].point(lambda v: 255 if v > thr else 0).getbbox()


def main():
    spec = json.load(open(os.path.join(ROOT, 'tool/arte/pet_sprites_spec.json')))
    src, out_dir = spec['sourceDir'], os.path.join(ROOT, spec['outDir'])
    os.makedirs(out_dir, exist_ok=True)
    for f in os.listdir(out_dir):
        if f.endswith('.webp'):
            os.remove(os.path.join(out_dir, f))
    ref_hair = spec['referenceHair']
    meta = {'schemaVersion': 1, 'unitHeightPx': spec['unitHeightPx'], 'poses': {}, 'hair': {}, 'items': {},
            'expressions': {}, 'coats': spec['coats'], 'variants': spec.get('variants', {})}

    # Unidad por pose de origen: altura del caniche de referencia (pies a cabeza).
    unit_src = {}
    for pose, pinfo in spec['poses'].items():
        base = load(src, spec['hair'][ref_hair][pose])
        a = base.split()[-1].point(lambda v: 255 if v > 128 else 0)
        _, t, _, b = a.getbbox()
        unit_src[pose] = b - t

    for pose, pinfo in spec['poses'].items():
        ref_raw = load(src, spec['hair'][ref_hair][pose])
        ref = defringe(ref_raw)
        layers = {}      # (tipo, id) -> imagen RGBA a lienzo completo
        invisible = []   # artículos que no se ven en esta pose (null)
        for hid, poses in spec['hair'].items():
            if pose not in poses:
                continue
            im = defringe(load(src, poses[pose]))
            if hid != ref_hair:
                im = match_color(im, ref)
            layers[('hair', hid)] = im
        for iid, poses in spec['items'].items():
            if pose not in poses:
                continue
            if poses[pose] is None:
                invisible.append(iid)
                continue
            prm = params_for(spec, iid)
            raw = load(src, poses[pose])
            layers[('items', iid)] = strip_fur(extract_layer(raw, ref_raw, **prm))
        for sid, by_hair in spec.get('states', {}).items():
            for hid, poses in by_hair.items():
                if pose in poses:
                    im = defringe(load(src, poses[pose]))
                    if hid != ref_hair:
                        im = match_color(im, ref)
                    layers[('states', f'{sid}|{hid}')] = im
        for eid, poses in spec.get('expressions', {}).items():
            if pose in poses:
                raw = load(src, poses[pose])
                layers[('expressions', eid)] = extract_layer(raw, ref_raw, threshold=30, opening=3, close=11)

        # Lienzo común: unión de las cajas de todas las capas de la pose.
        boxes = [b for b in (alpha_box(im) for im in layers.values()) if b]
        pad = 6
        box = (max(0, min(b[0] for b in boxes) - pad), max(0, min(b[1] for b in boxes) - pad),
               min(ref.width, max(b[2] for b in boxes) + pad), min(ref.height, max(b[3] for b in boxes) + pad))
        scale = spec['unitHeightPx'] / unit_src[pinfo['unitFrom']]
        size = (round((box[2] - box[0]) * scale), round((box[3] - box[1]) * scale))
        ax, ay = feet_anchor(ref, pinfo['anchor'])
        meta['poses'][pose] = {'size': list(size), 'anchor': [round((ax - box[0]) * scale, 1), round((ay - box[1]) * scale, 1)]}
        # Referencias del cuerpo en unidades (altura = 1, origen en el ancla).
        unit = unit_src[pinfo['unitFrom']]
        lm = landmarks(pose, ref, layers, pinfo.get('view', 'none'))
        meta['poses'][pose]['landmarks'] = {
            k: [round((v[0] - ax) / unit, 3), round((v[1] - ay) / unit, 3)] for k, v in lm.items() if v
        }

        # Referencias medidas para poses donde la silueta no define las facciones.
        meta['poses'][pose]['landmarks'].update(pinfo.get('landmarks', {}))

        for (kind, lid), im in layers.items():
            im = im.crop(box).resize(size, Image.LANCZOS)
            name = f"{pose}__{lid.replace('.', '_').replace('|', '__')}.webp"
            entry = name
            if kind in ('items', 'expressions'):
                # Las capas pequeñas se recortan a su contenido: ocupan menos
                # memoria. box = [x, y, ancho, alto] en el lienzo de la pose.
                bb = alpha_box(im)
                if bb is None:
                    continue
                im = im.crop(bb)
                entry = {'file': name, 'box': [bb[0], bb[1], bb[2] - bb[0], bb[3] - bb[1]]}
            im.save(os.path.join(out_dir, name), quality=90, method=6)
            if kind == 'states':
                sid, hid = lid.split('|')
                meta.setdefault('states', {}).setdefault(sid, {}).setdefault(hid, {})[pose] = entry
            else:
                meta[kind].setdefault(lid, {})[pose] = entry
        for iid in invisible:
            meta['items'].setdefault(iid, {})[pose] = None
        print(f'{pose}: lienzo {size}, ancla {meta["poses"][pose]["anchor"]}, {len(layers)} capas')

    with open(os.path.join(ROOT, spec['metaOut']), 'w') as f:
        json.dump(meta, f, indent=1, ensure_ascii=False)
        f.write('\n')
    print('Escrito', spec['metaOut'])


if __name__ == '__main__':
    sys.exit(main())
