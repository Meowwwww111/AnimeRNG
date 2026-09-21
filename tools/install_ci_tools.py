"""Install pinned upstream build tools in CI, without third-party Roblox actions."""
import hashlib
import io
import json
import os
from pathlib import Path
import urllib.request
import zipfile

folder = Path('.tools')
folder.mkdir(exist_ok=True)
for repo, tag, match in [
    ('luau-lang/luau', '0.739', lambda name: name == 'luau-ubuntu.zip'),
    ('rojo-rbx/rojo', 'v7.7.0', lambda name: 'linux-x86_64' in name and name.endswith('.zip')),
]:
    headers = {'Accept': 'application/vnd.github+json', 'User-Agent': 'AnimeRNG-CI'}
    if os.environ.get('GH_TOKEN'):
        headers['Authorization'] = 'Bearer ' + os.environ['GH_TOKEN']
    request = urllib.request.Request(f'https://api.github.com/repos/{repo}/releases/tags/{tag}', headers=headers)
    with urllib.request.urlopen(request, timeout=30) as response:
        release = json.load(response)
    asset = next((asset for asset in release['assets'] if match(asset['name'])), None)
    if asset is None:
        raise RuntimeError(f'Expected release asset not found: {repo} {tag}')
    url = asset['browser_download_url']
    if not url.startswith(f'https://github.com/{repo}/releases/download/'):
        raise RuntimeError('Unexpected download host/path')
    with urllib.request.urlopen(url, timeout=60) as response:
        body = response.read()
    digest = asset.get('digest')
    if digest and digest.startswith('sha256:'):
        assert hashlib.sha256(body).hexdigest() == digest.split(':', 1)[1], 'Release digest mismatch'
    with zipfile.ZipFile(io.BytesIO(body)) as archive:
        for member in archive.infolist():
            name = Path(member.filename).name
            if name not in {'luau', 'luau-compile', 'rojo'}:
                continue
            destination = folder / name
            destination.write_bytes(archive.read(member))
            destination.chmod(0o755)
    print(f'Installed {repo} {tag}')
