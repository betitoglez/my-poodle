"""Genera el icono de la app y la imagen de arranque nativa de My Poodle.

Uso (desde la raíz del repo):  python3 tool/arte/build_app_icons.py

Parte de la cabeza del caniche feliz de Meshy
(docs/arte/meshy/originales/front_happy.webp), limpia el halo gris del recorte
y la compone sobre el ciruela de la paleta (AppColors.plum). Escribe:

  docs/arte/icono/             originales de 1024 px (icono, capas y arranque)
  android/app/src/main/res/    mipmap-* (heredado + capas adaptativas) y
                               drawable-*/splash_icon.png
  ios/Runner/Assets.xcassets/  AppIcon (sin alfa) y LaunchImage
  web/                         favicon, Icon-192/512, maskable y splash.png

Solo requiere Pillow y numpy. No llama a ninguna API ni añade dependencias
al proyecto Flutter. Es determinista: volver a ejecutarlo da los mismos PNG.
"""
import json
import os

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
SOURCE = 'docs/arte/meshy/originales/front_happy.webp'
# Caja de la cabeza con orejas en la fuente de 896 x 1200 (medida a mano).
HEAD = (172, 97, 709, 470)
# Rasgos de la cara en esa misma fuente, para la silueta monocroma.
EYES = ((385, 310), (515, 297))
NOSE = (461, 366)
MOUTH = (414, 380, 512, 448)  # caja de la elipse; se usa su mitad inferior

# Paleta (lib/ui/theme.dart). El arranque usa AppColors.cream, que es el fondo
# del Scaffold de LoadingScreen, para que no haya destello al pasar a Flutter.
CREAM = (255, 248, 233)          # AppColors.cream  #FFF8E9
PLUM = (92, 53, 78)              # AppColors.plum   #5C354E
PLUM_LIGHT = (128, 84, 113)      # centro del degradado del fondo
PLUM_DARK = (70, 38, 59)         # borde del degradado del fondo

M = 1024  # tamaño de trabajo


def path(*parts):
    return os.path.join(ROOT, *parts)


def save(img, rel, rgb=False):
    out = path(rel)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    if rgb:
        img = img.convert('RGB')
    img.save(out, optimize=True)
    return out


# --------------------------------------------------------------- limpieza ---

def _box(x, r, axis):
    pad = [(r + 1, r) if i == axis else (0, 0) for i in range(x.ndim)]
    c = np.cumsum(np.pad(x, pad, mode='edge'), axis=axis)
    n = c.shape[axis]
    return (np.take(c, range(2 * r + 1, n), axis=axis)
            - np.take(c, range(0, n - 2 * r - 1), axis=axis)) / (2 * r + 1)


def _blur(x, r):
    for _ in range(2):
        x = _box(_box(x, r, 0), r, 1)
    return x


def clean_cutout(img, band=14, erode=2):
    """Quita el halo gris que deja el recorte de fondo de Meshy.

    En una franja de `band` px junto al borde, los píxeles poco saturados se
    sustituyen por el color del pelo difundido desde el interior; después se
    erosiona un poco el alfa."""
    arr = np.array(img.convert('RGBA')).astype(np.float32)
    rgb, a = arr[..., :3], arr[..., 3]
    solid = Image.fromarray(((a > 200) * 255).astype(np.uint8))
    inner = np.array(solid.filter(ImageFilter.MinFilter(2 * band + 1))) > 0
    grey = (a > 0) & ~inner & ((rgb[..., 0] - rgb[..., 2]) < 70)
    good = ((a > 200) & ~grey).astype(np.float32)
    num = rgb * good[..., None]
    fill = np.zeros_like(rgb)
    done = np.zeros(a.shape, bool)
    for r in (3, 6, 12, 24):
        d = _blur(good, r)
        n = np.stack([_blur(num[..., i], r) for i in range(3)], -1)
        ok = (d > 0.05) & ~done
        fill[ok] = n[ok] / d[ok][:, None]
        done |= ok
    rgb[grey] = fill[grey]
    alpha = Image.fromarray(a.astype(np.uint8))
    alpha = alpha.filter(ImageFilter.MinFilter(2 * erode + 1)).filter(ImageFilter.GaussianBlur(0.8))
    out = Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8)).convert('RGBA')
    out.putalpha(alpha)
    return out


# ------------------------------------------------------------ composición ---

def plum_background(size):
    """Degradado radial ciruela, más claro detrás de la cara."""
    y, x = np.mgrid[0:size, 0:size].astype(np.float32)
    r = np.clip(np.hypot(x - size / 2, y - size * 0.42) / (size * 0.72), 0, 1)[..., None]
    c0, c1 = np.array(PLUM_LIGHT, np.float32), np.array(PLUM_DARK, np.float32)
    arr = (c0 * (1 - r) + c1 * r).astype(np.uint8)
    return Image.fromarray(arr).convert('RGBA')


def place_dog(dog, size, head_width, head_cy):
    """Lienzo transparente con la cabeza ocupando `head_width` del ancho y su
    centro a `head_cy` de la altura; el pecho sale por abajo."""
    hw = HEAD[2] - HEAD[0]
    s = size * head_width / hw
    im = dog.resize((round(dog.width * s), round(dog.height * s)), Image.LANCZOS)
    cx = (HEAD[0] + HEAD[2]) / 2 * s
    cy = (HEAD[1] + HEAD[3]) / 2 * s
    layer = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    layer.alpha_composite(im, (round(size / 2 - cx), round(size * head_cy - cy)))
    return layer


def circle_mask(size, diameter, supersample=4):
    big = size * supersample
    d = diameter * supersample
    m = Image.new('L', (big, big), 0)
    o = (big - d) / 2
    ImageDraw.Draw(m).ellipse((o, o, o + d, o + d), fill=255)
    return m.resize((size, size), Image.LANCZOS)


def rounded_mask(size, radius_ratio=0.2237, supersample=4):
    big = size * supersample
    m = Image.new('L', (big, big), 0)
    ImageDraw.Draw(m).rounded_rectangle((0, 0, big - 1, big - 1), radius=big * radius_ratio, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def face_features(size):
    """Ojos, trufa y boca dibujados como formas simples sobre la fuente: en
    una silueta de un solo color se leen mejor que las sombras reales."""
    m = Image.new('RGBA', size, (0, 0, 0, 0))
    d = ImageDraw.Draw(m)
    white = (255, 255, 255, 255)
    for cx, cy in EYES:
        d.ellipse((cx - 21, cy - 19, cx + 21, cy + 19), fill=white)
    nx, ny = NOSE
    d.ellipse((nx - 27, ny - 21, nx + 27, ny + 21), fill=white)
    d.pieslice(MOUTH, 0, 180, fill=white)
    return m


def monochrome(fg, features):
    """Silueta para iconos temáticos (Android 13): alfa del caniche con la
    cara (`features`, ya colocada) recortada."""
    a = fg.split()[-1].filter(ImageFilter.GaussianBlur(3))
    sil = a.point(lambda v: 0 if v < 100 else (255 if v > 156 else (v - 100) * 255 // 56))
    holes = features.split()[-1]
    alpha = np.clip(np.array(sil, np.int16) - np.array(holes, np.int16), 0, 255)
    out = np.zeros((fg.height, fg.width, 4), np.uint8)
    out[..., :3] = 255
    out[..., 3] = alpha.astype(np.uint8)
    return Image.fromarray(out)


def scaled(img, px):
    return img.resize((px, px), Image.LANCZOS)


def main():
    dog = clean_cutout(Image.open(path(SOURCE)))

    # Icono maestro (iOS, web, Android heredado): cara grande, fondo opaco.
    master = plum_background(M)
    master.alpha_composite(place_dog(dog, M, head_width=0.74, head_cy=0.45))
    save(master, 'docs/arte/icono/icono-1024.png', rgb=True)

    # Capas adaptativas (lienzo de 108 dp; zona segura: círculo de 66 dp).
    fg = place_dog(dog, M, head_width=0.60, head_cy=0.47)
    bg = plum_background(M)
    mono = monochrome(fg, place_dog(face_features(dog.size), M, head_width=0.60, head_cy=0.47))
    save(fg, 'docs/arte/icono/adaptativo-primer-plano-1024.png')
    save(bg, 'docs/arte/icono/adaptativo-fondo-1024.png', rgb=True)
    save(mono, 'docs/arte/icono/adaptativo-monocromo-1024.png')
    adaptive = bg.copy()
    adaptive.alpha_composite(fg)

    # Arranque: disco ciruela (2/3 del lienzo, como pide Android 12) sobre
    # transparente; el fondo crema lo pone cada plataforma.
    disc = plum_background(M)
    disc.alpha_composite(place_dog(dog, M, head_width=0.66, head_cy=0.47))
    splash_disc = Image.new('RGBA', (M, M), (0, 0, 0, 0))
    splash_disc.paste(disc, (0, 0), circle_mask(M, M))
    splash = Image.new('RGBA', (M, M), (0, 0, 0, 0))
    inner = round(M * 190 / 288)  # 190 dp de 288: deja margen a la máscara de 192 dp
    splash.alpha_composite(splash_disc.resize((inner, inner), Image.LANCZOS),
                           ((M - inner) // 2, (M - inner) // 2))
    save(splash, 'docs/arte/icono/arranque-1024.png')

    # ---- Android
    res = 'android/app/src/main/res'
    densities = {'mdpi': 1, 'hdpi': 1.5, 'xhdpi': 2, 'xxhdpi': 3, 'xxxhdpi': 4}
    legacy = Image.new('RGBA', (M, M), (0, 0, 0, 0))
    legacy.paste(master, (0, 0), rounded_mask(M, 0.18))
    for name, k in densities.items():
        save(scaled(legacy, round(48 * k)), f'{res}/mipmap-{name}/ic_launcher.png')
        save(scaled(fg, round(108 * k)), f'{res}/mipmap-{name}/ic_launcher_foreground.png')
        save(scaled(bg, round(108 * k)), f'{res}/mipmap-{name}/ic_launcher_background.png', rgb=True)
        save(scaled(mono, round(108 * k)), f'{res}/mipmap-{name}/ic_launcher_monochrome.png')
        save(scaled(splash, round(288 * k)), f'{res}/drawable-{name}/splash_icon.png')

    # ---- iOS
    appicon = 'ios/Runner/Assets.xcassets/AppIcon.appiconset'
    with open(path(appicon, 'Contents.json')) as f:
        contents = json.load(f)
    for entry in contents['images']:
        pt = float(entry['size'].split('x')[0])
        px = round(pt * int(entry['scale'][0]))
        save(scaled(master, px), f"{appicon}/{entry['filename']}", rgb=True)
    launch = 'ios/Runner/Assets.xcassets/LaunchImage.imageset'
    # 192 pt: mismo disco que Android (192 dp) sin el margen transparente.
    for suffix, k in (('', 1), ('@2x', 2), ('@3x', 3)):
        save(scaled(splash_disc, 192 * k), f'{launch}/LaunchImage{suffix}.png')

    # ---- Web
    save(scaled(master, 32), 'web/favicon.png', rgb=True)
    save(scaled(master, 192), 'web/icons/Icon-192.png', rgb=True)
    save(scaled(master, 512), 'web/icons/Icon-512.png', rgb=True)
    # Maskable: zona segura del 80 %; reutiliza la composición adaptativa.
    save(scaled(adaptive, 192), 'web/icons/Icon-maskable-192.png', rgb=True)
    save(scaled(adaptive, 512), 'web/icons/Icon-maskable-512.png', rgb=True)
    save(scaled(splash_disc, 384), 'web/icons/splash.png')

    print('Iconos y arranque generados.')


if __name__ == '__main__':
    main()
