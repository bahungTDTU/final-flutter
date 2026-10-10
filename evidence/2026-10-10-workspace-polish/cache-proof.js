async page => {
 const result=await page.evaluate(async expected=>{
  const names=(await caches.keys()).filter(n=>n.startsWith('notetogether-static-'));
  const sha=async response=>Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',await response.arrayBuffer()))).map(b=>b.toString(16).padStart(2,'0')).join('');
  const cachesInfo=[];
  for(const name of names){
   const cache=await caches.open(name),keys=await cache.keys();
   const main=await cache.match('main.dart.js'),bootstrap=await cache.match('flutter_bootstrap.js');
   const mainHash=await sha(main.clone()),bootstrapHash=await sha(bootstrap);
   const code=await main.text();
   cachesInfo.push({name,resourceCount:keys.length,mainHash,bootstrapHash,hashesMatch:mainHash===expected.main&&bootstrapHash===expected.bootstrap,qaApi8034:code.includes('127.0.0.1:8034'),oldApi8000:code.includes('127.0.0.1:8000'),staticPaths:keys.map(k=>new URL(k.url).pathname)});
  }
  return {target:location.origin,caches:cachesInfo};
 },{main:'729404660d56f516862e7f98151413051043ad6256a18c44b93684a28ffc5875',bootstrap:'e07103b3fb416699695bce1f717060ca248f425b8245d8773c19597e95a90869'});
 if(result.caches.length!==1 || result.caches.some(c=>!c.hashesMatch||c.resourceCount!==40||!c.qaApi8034||c.oldApi8000||c.staticPaths.some(p=>/^\/(notes|me|auth|shares|files)\b/.test(p)))) throw new Error('Final cache verification failed');
 return {...result,passed:true};
}
