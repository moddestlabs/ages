{{flutter_js}}
{{flutter_build_config}}

const serviceWorkerVersion = {{flutter_service_worker_version}};

_flutter.loader.load({
  serviceWorkerSettings: {
    serviceWorkerVersion,
    serviceWorkerUrl: `ages_service_worker.js?v=${serviceWorkerVersion}`,
  },
  config: {
    canvasKitBaseUrl: 'canvaskit/',
  },
});