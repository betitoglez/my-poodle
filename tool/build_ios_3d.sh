#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
flutter build ios --profile --target lib/main.dart --dart-define=POODLE_LIVE_3D=true "$@"
python3 - <<'VERIFY'
import base64
from pathlib import Path
config = Path('ios/Flutter/Generated.xcconfig').read_text().splitlines()
encoded = next(line.split('=', 1)[1] for line in config if line.startswith('DART_DEFINES='))
defines = dict(base64.b64decode(item).decode().split('=', 1) for item in encoded.split(',') if item)
if defines.get('POODLE_LIVE_3D') != 'true':
    raise SystemExit('ERROR: la compilación no tiene el visor 3D activado.')
model = Path('build/ios/iphoneos/Runner.app/Frameworks/App.framework/flutter_assets/assets/wardrobe_live/caniche.glb')
if not model.is_file() or model.stat().st_size < 1000:
    raise SystemExit('ERROR: falta el modelo 3D en el paquete.')
print('Verificado: POODLE_LIVE_3D=true y modelo 3D empaquetado.')
VERIFY
