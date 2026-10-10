"""Generate a static-only offline shell manifest from the actual Flutter release."""
import hashlib
import json
from pathlib import Path

root = Path(__file__).resolve().parents[1]
build = root / 'build' / 'web'
if not (build / 'main.dart.js').is_file():
    raise SystemExit('Build Flutter Web first.')
exclude = {'offline_worker.js', 'offline_worker_template.js', 'flutter_service_worker.js'}
resources = sorted(p.relative_to(build).as_posix() for p in build.rglob('*')
                   if p.is_file() and p.name not in exclude)
fingerprint = hashlib.sha256()
for resource in resources:
    fingerprint.update(resource.encode())
    fingerprint.update((build / resource).read_bytes())
template = (root / 'web' / 'offline_worker_template.js').read_text(encoding='utf-8')
fingerprint.update(template.encode('utf-8'))
name = 'notetogether-static-' + fingerprint.hexdigest()[:16]
worker = template.replace('__CACHE_NAME__', name).replace('__RESOURCES__', json.dumps(resources))
(build / 'offline_worker.js').write_text(worker, encoding='utf-8')
print(f'Prepared {name}: {len(resources)} static resources. No API/private content cache.')
