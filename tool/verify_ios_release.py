import base64, hashlib, json, plistlib, re, subprocess, sys
from pathlib import Path
app=Path(sys.argv[1])
config=Path('ios/Flutter/Generated.xcconfig').read_text().splitlines()
encoded=next(line.split('=',1)[1] for line in config if line.startswith('DART_DEFINES='))
defines=dict(base64.b64decode(item).decode().split('=',1) for item in encoded.split(',') if item)
assert defines.get('POODLE_LIVE_3D')=='true', '3D flag missing'
assets=app/'Frameworks/App.framework/flutter_assets'
assert (assets/'assets/wardrobe_live/caniche.glb').stat().st_size>1000, '3D model missing'
with (app/'Info.plist').open('rb') as f:info=plistlib.load(f)
assert info['CFBundleIdentifier']=='com.betitoglez.mypoodle'
assert info.get('CFBundleDevelopmentRegion')=='en', 'English fallback missing'
assert info.get('ITSAppUsesNonExemptEncryption') is False
for tag in ['en','es','fr','de','pt-BR','it','ru','ko','ja','zh-Hans','zh-Hant']:
 assert (app/f'{tag}.lproj/InfoPlist.strings').is_file(), f'Native name missing: {tag}'
 packaged=assets/f'assets/l10n/{tag}.json'
 assert packaged.read_bytes()==Path(f'assets/l10n/{tag}.json').read_bytes(), f'Stale catalog: {tag}'
 assert len(json.loads(packaged.read_text()))>500, f'Empty catalog: {tag}'
 expected=re.search(r'"CFBundleDisplayName" = "([^"]+)";', Path(f'ios/Runner/{tag}.lproj/InfoPlist.strings').read_text())[1]
 localized=plistlib.loads(subprocess.check_output(['plutil','-convert','xml1','-o','-',str(app/f'{tag}.lproj/InfoPlist.strings')]))
 assert localized['CFBundleDisplayName']==expected, f'Incorrect native name: {tag}'
assert not list(app.rglob('*.storekit')), 'Local StoreKit configuration must not ship'
print(f"Verified iOS {info['CFBundleShortVersionString']} ({info['CFBundleVersion']}): 3D, 11 languages, native names and native IAP.")
