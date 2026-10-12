async page => {
  const expected = 'notetogether-static-309b295fab4ba3aa';
  let ready = false;
  for (let attempt = 0; attempt < 80; attempt++) {
    ready = await page.evaluate(async expected => {
      const names = (await caches.keys()).filter(name => name.startsWith('notetogether-static-'));
      const worker = await navigator.serviceWorker.getRegistration();
      return names.length === 1 && names[0] === expected && worker?.active?.state === 'activated'
        && !worker.installing && !worker.waiting;
    }, expected);
    if (ready) break;
    await page.waitForTimeout(250);
  }
  if (!ready) throw Error('Final static worker did not activate');
  await page.reload();
  const accessibility = page.getByRole('button', {name: 'Enable accessibility', exact: true});
  await accessibility.waitFor();
  await accessibility.evaluate(element => element.click());
  await page.getByRole('heading', {name: 'Ghi chú của bạn', exact: true}).waitFor();
  const cache = await page.evaluate(async expected => {
    const store = await caches.open(expected);
    const paths = (await store.keys()).map(request => new URL(request.url).pathname);
    if (paths.length !== 40 || paths.some(path => /\/(me|auth|notes)(\/|$)/.test(path)))
      throw Error('Unexpected private cache resources');
    const hash = async response => Array.from(new Uint8Array(await crypto.subtle.digest(
      'SHA-256', await response.arrayBuffer())), byte => byte.toString(16).padStart(2, '0')).join('');
    const hashes = {};
    for (const path of ['main.dart.js', 'flutter_bootstrap.js']) {
      const cached = await hash(await store.match(path));
      const network = await hash(await fetch(path, {cache: 'no-store'}));
      if (cached !== network) throw Error('Stale resource ' + path);
      hashes[path] = cached;
    }
    return {name: expected, count: paths.length, hashes};
  }, expected);
  for (const [name, width, height] of [['home-desktop-dark',1440,1000],
    ['home-phone-dark',390,844], ['home-small-dark',320,740]]) {
    await page.setViewportSize({width, height});
    await page.mouse.move(0, 0);
    await page.waitForTimeout(400);
    await page.screenshot({path: `output/playwright/ui-system-refresh/${name}.png`});
  }
  return {cache, appErrors: page.uiRefresh.errors, consoleErrors: page.uiRefresh.consoleErrors};
}
