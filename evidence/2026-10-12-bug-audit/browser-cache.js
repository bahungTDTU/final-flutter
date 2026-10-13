async page => {
  return await page.evaluate(async () => {
    const names = await caches.keys();
    const name = names.find(value => value.startsWith('notetogether-static-'));
    if (!name) throw Error('Static shell cache unavailable');
    const cache = await caches.open(name);
    const requests = await cache.keys();
    if (requests.some(request => /\/(auth|notes|me|ai)(\/|$)/.test(new URL(request.url).pathname))) throw Error('Private API response cached');
    const hashes = {};
    for (const asset of ['main.dart.js', 'flutter_bootstrap.js']) {
      const response = await cache.match(new URL(asset, location.origin + '/').href);
      if (!response) throw Error('Missing cached asset: ' + asset);
      hashes[asset] = Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256', await response.arrayBuffer())), value => value.toString(16).padStart(2, '0')).join('');
    }
    return { result: 'PASS', worker: name, staticResources: requests.length, privateApiCached: false, hashes };
  });
}
