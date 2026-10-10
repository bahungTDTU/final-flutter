async page => {
 const meta=await page.evaluate(async()=>{
  const names=(await caches.keys()).filter(n=>n.startsWith('notetogether-static-'));
  const cache=await caches.open(names[0]);
  const urls=(await cache.keys()).map(r=>r.url);
  const r=await cache.match('main.dart.js');
  const sha=Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',await r.arrayBuffer()))).map(b=>b.toString(16).padStart(2,'0')).join('');
  const reg=await navigator.serviceWorker.getRegistration();
  return {names,resources:urls.length,mainSha256:sha,active:reg.active?.state,installing:!!reg.installing,waiting:!!reg.waiting,privateCache:urls.some(url=>url.includes('/notes')||url.includes('/auth')||url.includes('/api/'))};
 });
 if(meta.names.length!==1||meta.names[0]!=='notetogether-static-2d7c6fb7d9f140cd'||meta.resources!==40||meta.mainSha256!=='342c083f2bc0ee6759e36b65a7b9db2aa66ea490407aaca86e0e5a3bb239d5c5'||meta.active!=='activated'||meta.installing||meta.waiting||meta.privateCache)throw new Error(JSON.stringify(meta));
 return {passed:true,...meta};
}
