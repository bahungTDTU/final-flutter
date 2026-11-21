{{flutter_js}}
{{flutter_build_config}}

// Filling the offline cache can take longer than rendering the first screen.
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('offline_worker.js', {updateViaCache: 'none'})
    .catch(error => console.warn('Offline application shell unavailable.', error));
}
_flutter.loader.load({config: {canvasKitBaseUrl: 'canvaskit/'}});
