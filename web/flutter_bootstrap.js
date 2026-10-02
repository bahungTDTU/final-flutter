{{flutter_js}}
{{flutter_build_config}}

(async () => {
  if ('serviceWorker' in navigator) {
    try {
      await navigator.serviceWorker.register('offline_worker.js');
      await Promise.race([navigator.serviceWorker.ready, new Promise(resolve => setTimeout(resolve, 5000))]);
    } catch (error) {
      console.warn('Offline application shell unavailable.', error);
    }
  }
  _flutter.loader.load({config: {canvasKitBaseUrl: 'canvaskit/'}});
})();
